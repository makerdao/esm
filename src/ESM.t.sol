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
    function test_initial_state() public view {
        assertStateEq(esm.START());
    }

    function test_start_to_freed() public {
        assertStateEq(esm.START());
        gov.callFree();
        assertStateEq(esm.FREED());
    }

    function test_start_to_burnt() public {
        assertStateEq(esm.START());
        gov.callBurn();
        assertStateEq(esm.BURNT());

    }

    function test_start_to_fired() public {
        assertStateEq(esm.START());
        gov.callFile("cap", 0);
        gov.callFire();
        assertStateEq(esm.FIRED());
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

    function testFail_freed_to_burnt() public {
        gov.callFree();
        gov.callBurn();
    }

    function testFail_freed_to_fired() public {
        gov.callFile("cap", 0);
        gov.callFree();
        gov.callFire();
    }

    function testFail_freed_to_freed() public {
        gov.callFile("cap", 0);
        gov.callFree();
        gov.callFree();
        assertStateEq(esm.FREED());
    }

    function testFail_burnt_to_burnt() public {
        gov.callBurn();
        gov.callBurn();
    }

    function testFail_burnt_to_freed() public {
        gov.callBurn();
        gov.callFree();
    }

    function testFail_burnt_to_fired() public {
        gov.callBurn();
        gov.callFire();
    }

    function testFail_fired_to_fired() public {
        gov.callFile("cap", 0);
        gov.callFire();

        gov.callFire();
    }

    function testFail_join_after_fired() public {
        gov.callFile("cap", 0);
        gov.callFire();
        gem.mint(address(usr), 10);
        usr.callJoin(10);
    }

    function testFail_join_after_burnt() public {
        gov.callBurn();
        gem.mint(address(usr), 10);
        usr.callJoin(10);
    }

    function testFail_exit_before_freed() public {
        gem.mint(address(usr), 10);
        usr.callJoin(10);

        usr.callExit(address(usr), 10);
    }
    function testFail_fire_cap_not_met() public {
        assertTrue(!esm.full());

        gov.callFire();
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

    function test_burn_whole_balance() public {
        gem.mint(address(esm), 10);

        gov.callBurn();

        assertEq(gem.balanceOf(address(esm)), 0);
    }

    // -- user actions --
    function test_join() public {
        gem.mint(address(usr), 10);

        assertStateEq(esm.START());
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

    // -- auth --
    function testFail_unauthorized_rely() public {
        esm.rely(address(0x0));
    }
    function testFail_unauthorized_deny() public {
        esm.deny(address(0x0));
    }

    function testFail_unauthorized_file_uint256() public {
        esm.file("cap", 10);
    }

    function testFail_unauthorized_file_address() public {
        esm.file("cap", address(0x0));
    }

    function testFail_unauthorized_free() public {
        esm.free();
    }

    function testFail_unauthorized_burn() public {
        esm.burn();
    }

    // -- helpers --
    function test_full() public {
        gov.callFile("cap", 10);

        assertTrue(!esm.full());
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
    function assertStateEq(uint256 state) internal view {
        esm.state() == state;
    }
}
