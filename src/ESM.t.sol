// SPDX-License-Identifier: AGPL-3.0-or-later

/// ESM.t.sol

// Copyright (C) 2019-2021 Maker Ecosystem Growth Holdings, INC.
// Copyright (C) 2021-2022 Dai Foundation

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
        vat.cage();
    }
}

contract VatMock {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { require(live == 1, "VatMock/not-live"); wards[usr] = 1; }
    function deny(address usr) external auth { require(live == 1, "VatMock/not-live"); wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "VatMock/not-authorized");
        _;
    }

    uint256 public live;

    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
    }

    function cage() external auth {
        live = 0;
    }
}

contract AuthedContractMock {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "AuthedContractMock/not-authorized");
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

    function callJoin(ESM esm, uint256 wad) external {
        gem.approve(address(esm), uint256(-1));

        esm.join(wad);
    }

    function callFire(ESM esm) external {
        esm.fire();
    }

    function callDenyProxy(ESM esm, address target) external {
        esm.denyProxy(target);
    }

    function callBurn(ESM esm) external {
        esm.burn();
    }

    function callFile(ESM esm, bytes32 what, uint256 data) external {
        esm.file(what, data);
    }
}

contract Authority {
  function canCall(address, address, bytes4 sig)
      public pure returns (bool)
  {
    if (sig == bytes4(0x42966c68)) { // burn(uint256)
      return true;
    } else {
      return false;
    }
  }
}

contract ESMTest is DSTest {
    
    uint256 constant WAD = 10 ** 18;

    ESM     esm;
    DSToken gem;
    address pauseProxy = address(123);
    VatMock vat;
    EndMock end;
    uint256 min;
    TestUsr usr;
    TestUsr gov;

    function setUp() public {
        gem = new DSToken("GOLD");
        gem.setAuthority(DSAuthority(address(new Authority())));
        vat = new VatMock();
        vat.rely(pauseProxy);
        end = new EndMock(vat);
        vat.rely(address(end));
        usr = new TestUsr(gem);
    }

    function test_constructor() public {
        esm = new ESM(address(gem), address(end), pauseProxy, 10_000 * WAD);

        assertEq(address(esm.gem()), address(gem));
        assertEq(address(esm.end()), address(end));
        assertEq(address(esm.proxy()), pauseProxy);
        assertEq(esm.min(), 10_000 * WAD);
        assertEq(end.live(), 1);
        assertTrue(esm.revokesGovernanceAccess());

        ESM esm2 = new ESM(address(gem), address(end), address(0), 10_000 * WAD);
        assertTrue(!esm2.revokesGovernanceAccess());
    }

    function test_Sum_is_internal_balance() public {
        esm = new ESM(address(gem), address(end), address(0), 10_000 * WAD);
        gem.mint(address(esm), 10_000 * WAD);

        assertEq(esm.Sum(), 0);
    }

    function test_fire_deny_proxy() public {
        esm = new ESM(address(gem), address(end), pauseProxy, 0);
        vat.rely(address(esm));
        assertEq(vat.wards(pauseProxy), 1);
        usr.callFire(esm);
        assertEq(vat.wards(pauseProxy), 0);

        assertEq(end.live(), 0);
    }

    function test_fire_no_proxy_action() public {
        esm = new ESM(address(gem), address(end), address(0), 0);
        assertEq(vat.wards(pauseProxy), 1);
        usr.callFire(esm);
        assertEq(vat.wards(pauseProxy), 1);

        assertEq(end.live(), 0);
    }

    function test_fire_then_deny() public {
        esm = new ESM(address(gem), address(end), pauseProxy, 0);
        AuthedContractMock someContract = new AuthedContractMock();
        someContract.rely(pauseProxy);
        someContract.rely(address(esm));
        vat.rely(address(someContract));
        vat.rely(address(esm));
        assertEq(vat.wards(pauseProxy), 1);
        assertEq(vat.wards(address(someContract)), 1);
        assertEq(someContract.wards(pauseProxy), 1);
        usr.callFire(esm);
        assertEq(vat.wards(pauseProxy), 0);
        assertEq(vat.wards(address(someContract)), 1);
        assertEq(someContract.wards(pauseProxy), 1);
        usr.callDenyProxy(esm, address(someContract));
        assertEq(vat.wards(pauseProxy), 0);
        assertEq(vat.wards(address(someContract)), 1);
        assertEq(someContract.wards(pauseProxy), 0);

        assertEq(end.live(), 0);
    }

    function test_deny_then_fire() public {
        esm = new ESM(address(gem), address(end), pauseProxy, 0);
        vat.rely(address(esm));
        assertEq(vat.wards(pauseProxy), 1);
        usr.callDenyProxy(esm, address(vat));
        assertEq(vat.wards(pauseProxy), 0);
        usr.callFire(esm);
        assertEq(vat.wards(pauseProxy), 0);

        assertEq(end.live(), 0);
    }

    function testFail_deny_insufficient_mkr() public {
        esm = new ESM(address(gem), address(end), pauseProxy, 10_000 * WAD);
        vat.rely(address(esm));
        usr.callDenyProxy(esm, address(vat));
    }

    function testFail_fire_twice() public {
        esm = new ESM(address(gem), address(end), address(0), 0);
        usr.callFire(esm);

        usr.callFire(esm);
    }

    function testFail_join_after_fired() public {
        esm = new ESM(address(gem), address(end), address(0), 0);
        usr.callFire(esm);
        gem.mint(address(usr), 10_000 * WAD);

        usr.callJoin(esm, 10_000 * WAD);
    }

    function testFail_fire_min_not_met() public {
        esm = new ESM(address(gem), address(end), address(0), 10_000 * WAD);
        assertTrue(esm.Sum() <= esm.min());

        usr.callFire(esm);
    }

    // -- user actions --
    function test_join_burn() public {
        gem.mint(address(usr), 10_000 * WAD);
        esm = new ESM(address(gem), address(end), address(0), 10_000 * WAD);

        usr.callJoin(esm, 6_000 * WAD);
        assertEq(esm.Sum(), 6_000 * WAD);
        assertEq(gem.balanceOf(address(esm)), 6_000 * WAD);
        assertEq(gem.balanceOf(address(usr)), 4_000 * WAD);

        esm.burn();
        assertEq(esm.Sum(), 6_000 * WAD);
        assertEq(gem.balanceOf(address(esm)), 0);
        assertEq(gem.balanceOf(address(usr)), 4_000 * WAD);

        usr.callJoin(esm, 4_000 * WAD);
        assertEq(esm.Sum(), 10_000 * WAD);
        assertEq(gem.balanceOf(address(esm)), 4_000 * WAD);
        assertEq(gem.balanceOf(address(usr)), 0);

        esm.burn();
        assertEq(esm.Sum(), 10_000 * WAD);
        assertEq(gem.balanceOf(address(esm)), 0);
        assertEq(gem.balanceOf(address(usr)), 0);
    }

    function test_burn_before_fire() public {
        gem.mint(address(usr), 10_000 * WAD);
        esm = new ESM(address(gem), address(end), address(0), 10_000 * WAD);
        usr.callJoin(esm, 10_000 * WAD);
        assertEq(gem.balanceOf(address(esm)), 10_000 * WAD);
        usr.callBurn(esm);
        assertEq(gem.balanceOf(address(esm)), 0);
        usr.callFire(esm);
    }

    function test_burn_after_fire() public {
        gem.mint(address(usr), 10_000 * WAD);
        esm = new ESM(address(gem), address(end), address(0), 10_000 * WAD);
        usr.callJoin(esm, 10_000 * WAD);
        assertEq(gem.balanceOf(address(esm)), 10_000 * WAD);
        usr.callFire(esm);
        usr.callBurn(esm);
        assertEq(gem.balanceOf(address(esm)), 0);
    }

    function test_join_over_min() public {
        gem.mint(address(usr), 20_000 * WAD);
        esm = new ESM(address(gem), address(end), address(0), 10_000 * WAD);

        usr.callJoin(esm, 10_000 * WAD);
        usr.callJoin(esm, 10_000 * WAD);
    }

    function testFail_join_insufficient_balance() public {
        esm = new ESM(address(gem), address(end), address(0), 10_000 * WAD);
        assertEq(gem.balanceOf(address(usr)), 0);

        usr.callJoin(esm, 10_000 * WAD);
    }

    function test_file_new_min() public {
        esm = new ESM(address(gem), address(end), address(this), 10_000 * WAD);
        assertEq(esm.min(), 10_000 * WAD);

        esm.file("min", 20_000 * WAD);

        assertEq(esm.min(), 20_000 * WAD);
    }

    function test_file_new_min_then_fire() public {
        gem.mint(address(usr), 10_000 * WAD);
        esm = new ESM(address(gem), address(end), address(this), 20_000 * WAD);
        vat.rely(address(esm));

        assertEq(esm.min(), 20_000 * WAD);
        assertEq(vat.wards(address(this)), 1);

        usr.callJoin(esm, 10_000 * WAD);
        esm.file("min", 10_000 * WAD);

        assertEq(esm.min(), 10_000 * WAD);

        usr.callFire(esm);

        assertEq(vat.wards(address(this)), 0);
        assertEq(end.live(), 0);
    }

    function testFail_file_revoked_gov() public {
        esm = new ESM(address(gem), address(end), address(0), 10_000 * WAD);
        esm.deny(address(this));
        assertEq(esm.min(), 10_000 * WAD);

        esm.file("min", 20_000 * WAD);
    }

    function testFail_file_not_gov() public {
        esm = new ESM(address(gem), address(end), pauseProxy, 10_000 * WAD);
        assertEq(esm.min(), 10_000 * WAD);

        usr.callFile(esm, "min", 20_000 * WAD);
    }
    
    function testFail_file_no_min() public {
        esm = new ESM(address(gem), address(end), address(this), 10_000 * WAD);
        assertEq(esm.min(), 10_000 * WAD);

        esm.file("min", 0);
    }

    function testFail_file_wrong_what() public {
        esm = new ESM(address(gem), address(end), address(this), 10_000 * WAD);
        assertEq(esm.min(), 10_000 * WAD);

        esm.file("wrong", 20_000 * WAD);
    }
}
