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

import {ESM} from "./ESM.sol";
import {ESMom} from "./ESMom.sol";

import {DSToken} from "ds-token/token.sol";
import {End} from "dss/end.sol";

import "ds-test/test.sol";

contract ESMomTest is DSTest {
    ESMom   mom;
    DSToken gem;
    End     end;
    address sun;

    function setUp() public {
        gem = new DSToken("GOLD");
        end = new End();
        sun = address(0x1);

        mom = new ESMom(address(this), address(gem), address(end), address(sun), 10);
        end.rely(address(mom));
    }

    function test_constructor() public {
        assertEq(mom.wards(address(this)), 1);
        assert(address(mom.esm) != address(0));
    }

    // -- admin --
    function test_file() public {
        assertTrue(address(mom.end()) != address(0x42));
        mom.file("end", address(0x42));
        assertTrue(address(mom.end()) == address(0x42));

        assertTrue(address(mom.sun()) != address(0x42));
        mom.file("sun", address(0x42));
        assertTrue(address(mom.sun()) == address(0x42));

        assertTrue(mom.cap() != 0x42);
        mom.file("cap", 0x42);
        assertTrue(mom.cap() == 0x42);
    }

    function testFail_unauthorized_file_end() public {
        mom = new ESMom(address(0x0), address(gem), address(end), address(sun), 10);
        mom.file("end", address(0x42));
    }

    function testFail_unauthorized_file_sun() public {
        mom = new ESMom(address(0x0), address(gem), address(end), address(sun), 10);
        mom.file("sun", address(0x42));
    }

    function testFail_unauthorized_file_cap() public {
        mom = new ESMom(address(0x0), address(gem), address(end), address(sun), 10);
        mom.file("cap", 0x42);
    }

    // -- actions --
    function test_free() public {
        ESM esm = mom.esm();
        mom.swap();

        mom.free(address(esm));

        assertTrue(esm.state() == esm.FREED());
    }

    function test_free_old_esm() public {
        ESM old = mom.esm();
        mom.swap();

        mom.free(address(old));

        assertTrue(old.state() == old.FREED());
    }

    function test_burn() public {
        ESM esm = mom.esm();
        mom.swap();
        mom.burn(address(esm));

        assertTrue(esm.state() == esm.BURNT());
    }

    function test_burn_old_esm() public {
        ESM old = mom.esm();
        mom.swap();

        mom.burn(address(old));

        assertTrue(old.state() == old.BURNT());
    }

    function test_swap() public {
        address prev = address(mom.esm());
        address post = mom.swap();

        assertTrue(prev != post);
        assertEq(post, address(mom.esm()));
        assertEq(end.wards(prev), 0);
        assertEq(end.wards(post), 1);
    }

    function testFail_free_unknown_esm() public {
        mom.swap();
        mom.free(address(0x0));
    }

    function testFail_burn_unknown_esm() public {
        mom.swap();
        mom.burn(address(0x0));
    }

    function testFail_free_current_esm() public {
        mom.free(address(mom.esm()));
    }

    function testFail_burn_current_esm() public {
        mom.burn(address(mom.esm()));
    }

    function testFail_unauthorized_free() public {
        ESMom mum = new ESMom(address(0x0), address(gem), address(end), address(sun), 10);
        ESM esm = mum.esm();

        mom.swap();
        mum.free(address(esm));
    }

    function testFail_unauthorized_burn() public {
        ESMom mum = new ESMom(address(0x0), address(gem), address(end), address(sun), 10);
        ESM esm = mum.esm();

        mom.swap();
        mum.burn(address(esm));
    }

    function testFail_unauthorized_swap() public {
        ESMom mum = new ESMom(address(0x0), address(gem), address(end), address(sun), 10);

        mum.swap();
    }
}
