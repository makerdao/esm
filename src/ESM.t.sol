// SPDX-License-Identifier: AGPL-3.0-or-later

/// ESM.t.sol

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

import "./ESM.sol";

contract EndMock {
    uint256 public live;
    VatMock public vat;

    constructor(VatMock vat_) public {
        vat = vat_;
        live = 1;
    }
    function cage() public {
        require(live == 1, "EndMock/system-already-shutdown");
        live = 0;
    }
}

contract VatMock {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "VatMock/not-authorized");
        _;
    }

    constructor() public {
        wards[msg.sender] = 1;
    }
}

contract TestUsr {
    DSToken gem;

    constructor(DSToken gem_) public {
        gem = gem_;
    }
    function callFire(ESM esm) external {
        esm.fire();
    }

    function callJoin(ESM esm, uint256 wad) external {
        gem.approve(address(esm), uint256(-1));

        esm.join(wad);
    }
}

contract ESMTest is DSTest {
    ESM     esm;
    DSToken gem;
    address pauseProxy = address(123);
    VatMock vat;
    EndMock end;
    uint256 min;
    address pit;
    TestUsr usr;
    TestUsr gov;

    function setUp() public {
        gem = new DSToken("GOLD");
        vat = new VatMock();
        vat.rely(pauseProxy);
        end = new EndMock(vat);
        usr = new TestUsr(gem);
        gov = new TestUsr(gem);
        pit = address(0x42);
    }

    function test_constructor() public {
        esm = new ESM(address(gem), address(end), pauseProxy, pit, 10);

        assertEq(address(esm.gem()), address(gem));
        assertEq(address(esm.end()), address(end));
        assertEq(address(esm.proxy()), pauseProxy);
        assertEq(esm.min(), 10);
        assertEq(end.live(), 1);
    }

    function test_Sum_is_internal_balance() public {
        esm = new ESM(address(gem), address(end), address(0), pit, 10);
        gem.mint(address(esm), 10);

        assertEq(esm.Sum(), 0);
    }

    function test_fire_deny_proxy() public {
        esm = new ESM(address(gem), address(end), pauseProxy, pit, 0);
        vat.rely(address(esm));
        assertEq(vat.wards(pauseProxy), 1);
        gov.callFire(esm);
        assertEq(vat.wards(pauseProxy), 0);

        assertEq(end.live(), 0);
    }

    function test_fire_no_proxy_action() public {
        esm = new ESM(address(gem), address(end), address(0), pit, 0);
        assertEq(vat.wards(pauseProxy), 1);
        gov.callFire(esm);
        assertEq(vat.wards(pauseProxy), 1);

        assertEq(end.live(), 0);
    }

    function testFail_fire_twice() public {
        esm = new ESM(address(gem), address(end), address(0), pit, 0);
        gov.callFire(esm);

        gov.callFire(esm);
    }

    function testFail_join_after_fired() public {
        esm = new ESM(address(gem), address(end), address(0), pit, 0);
        gov.callFire(esm);
        gem.mint(address(usr), 10);

        usr.callJoin(esm, 10);
    }

    function testFail_fire_min_not_met() public {
        esm = new ESM(address(gem), address(end), address(0), pit, 10);
        assertTrue(esm.Sum() <= esm.min());

        gov.callFire(esm);
    }

    // -- user actions --
    function test_join() public {
        gem.mint(address(usr), 10);
        esm = new ESM(address(gem), address(end), address(0), pit, 10);

        usr.callJoin(esm, 10);

        assertEq(esm.Sum(), 10);
        assertEq(gem.balanceOf(address(esm)), 0);
        assertEq(gem.balanceOf(address(usr)), 0);
        assertEq(gem.balanceOf(address(pit)), 10);
    }

    function test_join_over_min() public {
        gem.mint(address(usr), 20);
        esm = new ESM(address(gem), address(end), address(0), pit, 10);

        usr.callJoin(esm, 10);
        usr.callJoin(esm, 10);
    }

    function testFail_join_insufficient_balance() public {
        esm = new ESM(address(gem), address(end), address(0), pit, 10);
        assertEq(gem.balanceOf(address(usr)), 0);

        usr.callJoin(esm, 10);
    }
}
