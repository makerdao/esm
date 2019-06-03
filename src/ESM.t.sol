pragma solidity ^0.5.6;

import "ds-test/test.sol";
import {DSToken} from "ds-token/token.sol";

import "./ESM.sol";

contract EndTest {
    uint256 public live;

    constructor()   public { live = 1; }
    function cage() public { live = 0; }
}

contract TestUsr {
    function callApprove(ESM esm, DSToken gem) external {
        gem.approve(address(esm), uint256(-1));
    }

    function callFire(ESM esm) external {
        esm.fire();
    }

    function callFree(ESM esm) external {
        esm.free();
    }

    function callBurn(ESM esm) external {
        esm.burn();
    }

    function callJoin(ESM esm, uint256 wad) external {
        esm.join(wad);
    }

    function callExit(ESM esm, address who, uint256 wad) external {
        esm.exit(who, wad);
    }
}

contract ESMTest is DSTest {
    ESM     esm;
    DSToken gem;
    EndTest end;
    uint256 cap;
    address sun;
    TestUsr usr;
    TestUsr gov;

    function setUp() public {
        gem = new DSToken("GOLD");
        end = new EndTest();
        sun = address(0x1);
        usr = new TestUsr();
        gov = new TestUsr();
        esm = new ESM(address(gov), address(gem), address(end), sun, 10);

        usr.callApprove(esm, gem);
    }

    function test_constructor() public {
        assertEq(esm.owner(), address(gov));
        assertEq(address(esm.gem()), address(gem));
        assertEq(address(esm.end()), address(end));
        assertEq(esm.sun(), address(0x1));
        assertEq(esm.cap(), 10);
    }

    // -- state transitions --
    function test_initial_state() public view {
        assertStateEq(esm.START());
    }

    function test_start_to_freed() public {
        assertStateEq(esm.START());
        gov.callFree(esm);
        assertStateEq(esm.FREED());
    }

    function test_start_to_burnt() public {
        assertStateEq(esm.START());
        gov.callBurn(esm);
        assertStateEq(esm.BURNT());

    }

    function test_start_to_fired() public {
        esm = makeWithCap(0);
        assertTrue(esm.full());
        assertStateEq(esm.START());
        gov.callFire(esm);
        assertStateEq(esm.FIRED());
    }

    function test_fired_to_freed() public {
        esm = makeWithCap(0);
        gov.callFire(esm);

        gov.callFree(esm);
    }

    function test_fired_to_burnt() public {
        esm = makeWithCap(0);
        gov.callFire(esm);

        gov.callBurn(esm);
    }

    function testFail_freed_to_burnt() public {
        gov.callFree(esm);
        gov.callBurn(esm);
    }

    function testFail_freed_to_fired() public {
        esm = makeWithCap(0);
        gov.callFree(esm);
        gov.callFire(esm);
    }

    function testFail_freed_to_freed() public {
        esm = makeWithCap(0);
        gov.callFree(esm);
        gov.callFree(esm);
        assertStateEq(esm.FREED());
    }

    function testFail_burnt_to_burnt() public {
        gov.callBurn(esm);
        gov.callBurn(esm);
    }

    function testFail_burnt_to_freed() public {
        gov.callBurn(esm);
        gov.callFree(esm);
    }

    function testFail_burnt_to_fired() public {
        gov.callBurn(esm);
        gov.callFire(esm);
    }

    function testFail_fired_to_fired() public {
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

    function testFail_join_after_burnt() public {
        gov.callBurn(esm);
        gem.mint(address(usr), 10);
        usr.callJoin(esm, 10);
    }

    function testFail_exit_before_freed() public {
        gem.mint(address(usr), 10);
        usr.callJoin(esm, 10);

        usr.callExit(esm, address(usr), 10);
    }
    function testFail_fire_cap_not_met() public {
        assertTrue(!esm.full());

        gov.callFire(esm);
    }

    // -- side effects --
    function test_fire() public {
        esm = makeWithCap(0);
        gov.callFire(esm);

        assertEq(end.live(), 0);
    }

    function test_burn_balance() public {
        gem.mint(address(usr), 10);

        usr.callJoin(esm, 5);

        gov.callBurn(esm);

        assertEq(gem.balanceOf(address(esm)), 0);
        assertEq(gem.balanceOf(address(sun)), 5);
    }

    function test_burn_whole_balance() public {
        gem.mint(address(esm), 10);

        gov.callBurn(esm);

        assertEq(gem.balanceOf(address(esm)), 0);
    }

    // -- user actions --
    function test_join() public {
        gem.mint(address(usr), 10);

        assertStateEq(esm.START());
        usr.callJoin(esm, 10);

        assertEq(esm.sum(), 10);
        assertEq(gem.balanceOf(address(esm)), 10);
        assertEq(gem.balanceOf(address(usr)), 0);
    }

    function test_join_over_cap() public {
        assertEq(esm.cap(), 10);
        gem.mint(address(usr), 20);

        usr.callJoin(esm, 10);
        usr.callJoin(esm, 10);
    }

    function test_exit() public {
        gem.mint(address(usr), 10);

        usr.callJoin(esm, 10);
        gov.callFree(esm);

        usr.callExit(esm, address(usr), 10);

        assertEq(esm.sum(), 0);
        assertEq(gem.balanceOf(address(esm)), 0);
        assertEq(gem.balanceOf(address(usr)), 10);
    }

    function test_exit_gift() public {
        gem.mint(address(usr), 10);

        usr.callJoin(esm, 10);
        gov.callFree(esm);

        assertEq(gem.balanceOf(address(0x0)), 0);
        usr.callExit(esm, address(0xdeadbeef), 10);

        assertEq(gem.balanceOf(address(esm)), 0);
        assertEq(gem.balanceOf(address(0xdeadbeef)), 10);
    }

    function testFail_join_insufficient_balance() public {
        assertEq(gem.balanceOf(address(usr)), 0);

        usr.callJoin(esm, 10);
    }

    function testFail_exit_insufficient_balance() public {
        gov.callFree(esm);
        assertEq(gem.balanceOf(address(usr)), 0);

        usr.callExit(esm, address(usr), 10);
    }

    // -- auth --
    function testFail_unauthorized_free() public {
        esm.free();
    }

    function testFail_unauthorized_burn() public {
        esm.burn();
    }

    // -- helpers --
    function test_full() public {
        esm = makeWithCap(10);
        usr.callApprove(esm, gem);

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

        assertEq(esm.sum(), 0);
        assertTrue(!esm.full());
    }

    // -- internal test helpers --
    function assertStateEq(uint256 state) internal view {
        esm.state() == state;
    }

    function makeWithCap(uint256 cap_) internal returns (ESM) {
        return new ESM(address(gov), address(gem), address(end), sun, cap_);
    }
}
