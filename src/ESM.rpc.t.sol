// SPDX-License-Identifier: AGPL-3.0-or-later

/// ESM.rpc.t.sol -- Simulation tests for the ESM

// Copyright (C) 2019-2021 Maker Ecosystem Growth Holdings, INC.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.6.12;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "dss-interfaces/Interfaces.sol";

import "./ESM.sol";

interface Hevm {
    function store(address,bytes32,bytes32) external;
}

contract EsmTestRpc is DSTest {

    Hevm hevm;
    ESM esm;
    DSToken mkr;
    VatAbstract vat;
    EndAbstract end;
    DSPauseProxyAbstract pauseProxy;

    uint256 constant WAD = 1E18;
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        ChainlogHelper helper = new ChainlogHelper();
        ChainlogAbstract chainlog = helper.ABSTRACT();
        mkr = new DSToken("MKR");
        vat = VatAbstract(chainlog.getAddress("MCD_VAT"));
        end = EndAbstract(chainlog.getAddress("MCD_END"));
        pauseProxy = DSPauseProxyAbstract(
            chainlog.getAddress("MCD_PAUSE_PROXY")
        );
        esm = new ESM(
            address(mkr),
            address(end),
            address(pauseProxy),
            50000 * WAD
        );
        hevm.store( // vat.rely(esm);
            address(vat),
            keccak256(abi.encode(address(esm), uint256(0))),
            bytes32(uint256(1))
        );
        hevm.store( // end.rely(esm);
            address(end),
            keccak256(abi.encode(address(esm), uint256(0))),
            bytes32(uint256(1))
        );
    }

    function test_rpc_governance_attack_fire() public {
        assertTrue(esm.revokesGovernanceAccess());
        mkr.mint(50000 * WAD);
        mkr.approve(address(esm));
        esm.join(50000 * WAD);
        assertEq(vat.wards(address(pauseProxy)), 1);
        assertEq(vat.live(), 1);
        esm.fire();
        assertEq(vat.wards(address(pauseProxy)), 0);
        assertEq(vat.live(), 0);
    }

    function test_rpc_governance_attack_deny_fire() public {
        assertTrue(esm.revokesGovernanceAccess());
        mkr.mint(50000 * WAD);
        mkr.approve(address(esm));
        esm.join(50000 * WAD);
        assertEq(vat.wards(address(pauseProxy)), 1);
        assertEq(end.wards(address(pauseProxy)), 1);
        esm.deny(address(vat));
        esm.deny(address(end));
        assertEq(vat.wards(address(pauseProxy)), 0);
        assertEq(end.wards(address(pauseProxy)), 0);
        assertEq(vat.live(), 1);
        esm.fire();
        assertEq(vat.live(), 0);
    }
}
