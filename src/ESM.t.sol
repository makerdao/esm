pragma solidity ^0.5.6;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "./ESM.sol";

contract EndTest is EndLike {
    uint256 public live;

    constructor()   public { live = 1; }
    function cage() public { live = 0; }
}

contract TestUsr {
    ESM esm;

    function setESM(ESM esm_) external {
        esm = esm_;
    }

    function callApprove(DSToken gem) external {
        gem.approve(address(esm), uint256(-1));
    }

    function callFile(bytes32 job, address val) external {
        esm.file(job, val);
    }

    function callFile(bytes32 job, uint256 val) external {
        esm.file(job, val);
    }


    function callFire() external {
        esm.fire();
    }

    function callFree() external {
        esm.free();
    }

    function callLock() external {
        esm.lock();
    }

    function callBurn() external {
        esm.burn();
    }

    function callJoin(uint256 wad) external {
        esm.join(wad);
    }

    function callExit(address who, uint256 wad) external {
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

        gov.setESM(esm);
        usr.setESM(esm);
        usr.callApprove(gem);
    }

    function test_constructor() public {
        assertEq(esm.wards(address(gov)), 1);
        assertEq(address(esm.gem()), address(gem));
        assertEq(address(esm.end()), address(end));
        assertEq(esm.sun(), address(0x1));
        assertEq(esm.cap(), 10);
    }

    // -- admin --
    function test_file() public {
        gov.callFile("end", address(0x42));
        assertEq(address(esm.end()), address(0x42));

        gov.callFile("sun", address(0x42));
        assertEq(address(esm.sun()), address(0x42));

        gov.callFile("cap", 42);
        assertEq(esm.cap(), 42);
    }

    // -- state transitions --
    function test_initial_state() public {
        assertStateEq(esm.BASIC());
    }

    function test_basic_to_freed() public {
        assertStateEq(esm.BASIC());
        gov.callFree();
    }

    function test_basic_to_burnt() public {
        assertStateEq(esm.BASIC());
        gov.callBurn();
    }

    function test_basic_to_fired() public {
        assertStateEq(esm.BASIC());
        gov.callFile("cap", 0);
        gov.callFire();
    }

    function test_freed_to_basic() public {
        gov.callFree();
        gov.callLock();
    }

    function test_freed_to_burnt() public {
        gov.callFree();
        gov.callBurn();
    }

    function test_freed_to_fired() public {
        gov.callFile("cap", 0);
        gov.callFree();
        gov.callFire();
    }

    function test_freed_to_freed() public {
        gov.callFile("cap", 0);
        gov.callFree();
        gov.callFree();
    }

    function test_burnt_to_burnt() public {
        gov.callBurn();
        gov.callBurn();
    }

    function testFail_burnt_to_freed() public {
        gov.callBurn();
        gov.callFree();
    }


    function test_fired_to_freed() public {
        gov.callFile("cap", 0);
        gov.callFire();

        gov.callFree();
    }

    function test_fired_to_burnt() public {
        gov.callFile("cap", 0);
        gov.callFire();

        gov.callBurn();
    }

    function testFail_fired_to_fired() public {
        gov.callFile("cap", 0);
        gov.callFire();

        gov.callFire();
    }

    function testFail_join_after_fired() public {
        gov.callFile("cap", 0);
        gov.callFire();
        gov.callFree();
        gov.callLock();
        gem.mint(address(usr), 10);
        usr.callJoin(10);
    }

    // -- state enum assignments --
    function test_freed() public {
        assertStateNEq(esm.FREED());
        gov.callFile("cap", 0);
        gov.callFire();

        gov.callFree();

        assertStateEq(esm.FREED());
    }

    function test_burnt() public {
        assertStateNEq(esm.BURNT());
        gov.callFile("cap", 0);
        gov.callFire();

        gov.callBurn();

        assertStateEq(esm.BURNT());
    }

    function test_fired() public {
        assertTrue(!esm.spent());
        gov.callFile("cap", 0);

        gov.callFire();

        assertTrue(esm.spent());
    }

    function testFail_fire_cap_not_met() public {
        assertTrue(!esm.full());

        gov.callFire();
    }

    function testFail_lock_when_not_freed() public {
        assertStateNEq(esm.FREED());

        gov.callLock();
    }

    // -- side effects --
    function test_fire() public {
        gov.callFile("cap", 0);
        gov.callFire();

        assertEq(end.live(), 0);
    }

    function test_burn_balance() public {
        gem.mint(address(usr), 10);

        usr.callJoin(5);

        gov.callBurn();

        assertEq(gem.balanceOf(address(esm)), 0);
        assertEq(gem.balanceOf(address(sun)), 5);
    }

    // -- user actions --
    function test_join() public {
        gem.mint(address(usr), 10);

        usr.callJoin(10);

        assertEq(esm.sum(), 10);
        assertEq(gem.balanceOf(address(esm)), 10);
        assertEq(gem.balanceOf(address(usr)), 0);
    }

    function test_join_over_cap() public {
        gem.mint(address(usr), 20);
        gov.callFile("cap", 10);

        usr.callJoin(10);
        usr.callJoin(10);
    }

    function test_exit() public {
        gem.mint(address(usr), 10);

        usr.callJoin(10);
        gov.callFree();

        usr.callExit(address(usr), 10);

        assertEq(esm.sum(), 0);
        assertEq(gem.balanceOf(address(esm)), 0);
        assertEq(gem.balanceOf(address(usr)), 10);
    }

    function test_exit_gift() public {
        gem.mint(address(usr), 10);

        usr.callJoin(10);
        gov.callFree();

        assertEq(gem.balanceOf(address(0x0)), 0);
        usr.callExit(address(0xdeadbeef), 10);

        assertEq(gem.balanceOf(address(esm)), 0);
        assertEq(gem.balanceOf(address(0xdeadbeef)), 10);
    }

    function testFail_join_insufficient_balance() public {
        assertEq(gem.balanceOf(address(usr)), 0);

        usr.callJoin(10);
    }

    function testFail_exit_insufficient_balance() public {
        gov.callFree();
        assertEq(gem.balanceOf(address(usr)), 0);

        usr.callExit(address(usr), 10);
    }

    // -- helpers --
    function test_full() public {
        gov.callFile("cap", 10);

        gem.mint(address(usr), 10);

        usr.callJoin(5);
        assertTrue(!esm.full());

        usr.callJoin(5);
        assertTrue(esm.full());
    }

    function test_full_keeps_internal_balance() public {
        gov.callFile("cap", 10);
        gem.mint(address(esm), 10);

        assertEq(esm.sum(), 0);
        assertTrue(!esm.full());
    }

    // -- internal test helpers --
    function assertStateEq(uint256 state) internal {
        esm.state() == state;
    }

    function assertStateNEq(uint256 state) internal {
        esm.state() != state;
    }
}
