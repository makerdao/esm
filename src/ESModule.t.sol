pragma solidity ^0.5.6;

import "ds-test/test.sol";

import "./ESModule.sol";

contract ESModuleTest is DSTest {
    ESModule module;

    function setUp() public {
        module = new ESModule();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
