// Copyright (C) 2019 Maker Ecosystem Growth Foundation
//
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

pragma solidity ^0.5.6;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "./ESM.sol";

contract EndMock {
    uint256 public live;

    constructor()   public { live = 1; }
    function cage() public { live = 0; }
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
    EndMock end;
    uint256 min;
    address pit;
    TestUsr usr;
    TestUsr gov;

    function setUp() public {
        gem = new DSToken("GOLD");
        end = new EndMock();
        usr = new TestUsr(gem);
        gov = new TestUsr(gem);
        pit = address(0x42);
    }

    function test_constructor() public {
        esm = makeWithCap(10);

        assertEq(address(esm.gem()), address(gem));
        assertEq(address(esm.end()), address(end));
        assertEq(esm.min(), 10);
        assertTrue(!esm.fired());
    }

    function test_fire() public {
        esm = makeWithCap(0);
        gov.callFire(esm);

        assertTrue(esm.fired());
        assertEq(end.live(), 0);
    }

    function testFail_fire_twice() public {
        esm = makeWithCap(0);
        gov.callFire(esm);

        gov.callFire(esm);
    }

    function testFail_join_after_fired() public {
        esm = makeWithCap(0);
        gov.callFire(esm);
        gem.mint(address(usr), 10);

        usr.callJoin(esm, 10);
    }

    function testFail_fire_min_not_met() public {
        assertTrue(!esm.full());

        gov.callFire(esm);
    }

    // -- user actions --
    function test_join() public {
        gem.mint(address(usr), 10);
        esm = makeWithCap(10);

        usr.callJoin(esm, 10);

        assertEq(esm.Sum(), 10);
        assertEq(gem.balanceOf(address(esm)), 0);
        assertEq(gem.balanceOf(address(usr)), 0);
        assertEq(gem.balanceOf(address(pit)), 10);
    }

    function test_join_over_min() public {
        gem.mint(address(usr), 20);
        esm = makeWithCap(10);

        usr.callJoin(esm, 10);
        usr.callJoin(esm, 10);
    }

    function testFail_join_insufficient_balance() public {
        assertEq(gem.balanceOf(address(usr)), 0);

        usr.callJoin(esm, 10);
    }

    // -- helpers --
    function test_full() public {
        esm = makeWithCap(10);

        assertTrue(!esm.full());
        gem.mint(address(usr), 10);

        usr.callJoin(esm, 5);
        assertTrue(!esm.full());

        usr.callJoin(esm, 5);
        assertTrue(esm.full());
    }

    function test_full_keeps_internal_balance() public {
        esm = makeWithCap(10);
        gem.mint(address(esm), 10);

        assertEq(esm.Sum(), 0);
        assertTrue(!esm.full());
    }

    // -- internal test helpers --
    function makeWithCap(uint256 min_) internal returns (ESM) {
        return new ESM(address(gem), address(end), pit, min_);
    }
}
