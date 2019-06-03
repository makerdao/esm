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
        mom.free();

        assertTrue(esm.state() == esm.FREED());
    }

    function test_burn() public {
        ESM esm = mom.esm();
        mom.burn();

        assertTrue(esm.state() == esm.BURNT());
    }

    function test_swap() public {
        address prev = address(mom.esm());
        address post = mom.swap();

        assertTrue(prev != post);
        assertEq(post, address(mom.esm()));
        assertEq(end.wards(prev), 0);
        assertEq(end.wards(post), 1);
    }

    function testFail_unauthorized_free() public {
        ESMom mum = new ESMom(address(0x0), address(gem), address(end), address(sun), 10);

        mum.free();
    }

    function testFail_unauthorized_burn() public {
        ESMom mum = new ESMom(address(0x0), address(gem), address(end), address(sun), 10);

        mum.burn();
    }

    function testFail_unauthorized_swap() public {
        ESMom mum = new ESMom(address(0x0), address(gem), address(end), address(sun), 10);

        mum.swap();
    }
}
