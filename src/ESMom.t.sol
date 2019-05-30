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
        ESM     prev = mom.esm();
        address post = mom.free();

        assertTrue(address(prev) != post);
        assertTrue(prev.state()  == prev.FREED());
        assertEq(post, address(mom.esm()));
    }

    function test_burn() public {
        ESM     prev = mom.esm();
        address post = mom.burn();

        assertTrue(address(prev) != post);
        assertTrue(prev.state()  == prev.BURNT());
        assertEq(post, address(mom.esm()));
    }

    function testFail_unauthorized_free() public {
        ESMom mum = new ESMom(address(0x0), address(gem), address(end), address(sun), 10);

        mum.free();
    }

    function testFail_unauthorized_burn() public {
        ESMom mum = new ESMom(address(0x0), address(gem), address(end), address(sun), 10);

        mum.burn();
    }

}
