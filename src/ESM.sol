pragma solidity ^0.5.6;

import "ds-auth/auth.sol";
import "ds-note/note.sol";

contract GemLike {
    function balanceOf(address) public view returns (uint256);
    function transfer(address, uint256) public returns (bool);
    function transferFrom(address, address, uint256) public returns (bool);
}

contract EndLike {
    function cage() public;
}

contract ESM is DSAuth, DSNote {
    uint256 public cap;
    GemLike public gem;
    EndLike public end;
    uint256 public sum;
    address public sun;

    mapping(address => uint256) public gems;

    enum hops { BASIC, FREED, BURNT, FIRED }
    hops public hop;
    bool public spent;

    constructor(address gem_, address end_, address sun_, uint256 cap_, address owner_, address authority_) public {
        gem = GemLike(gem_);
        end = EndLike(end_);
        sun = sun_;
        cap = cap_;
        owner = owner_;
        authority = DSAuthority(authority_);
    }

    // -- math --
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
        require(z <= x);
    }

    // -- admin --
    function file(bytes32 job, address obj) external auth note {
        if (job == "end") end = EndLike(obj);
        if (job == "sun") sun = obj;
    }

    function file(bytes32 job, uint256 val) external auth note {
        if (job == "cap") cap = val;
    }

    // -- hop changes --
    function fire() external note {
        require(!spent && full(), "esm/not-fireable");

        end.cage();

        spent = true;
        hop = hops.FIRED;
    }

    function free() external auth note {
        require(hop != hops.BURNT, "esm/already-burnt");

        hop = hops.FREED;
    }

    function lock() external auth note {
        require(hop == hops.FREED, "esm/not-freed");

        hop = hops.BASIC;
    }

    function burn() external auth note {
        sum = 0;
        spent = true;
        hop = hops.BURNT;

        bool ok = gem.transfer(address(sun), gem.balanceOf(address(this)));

        require(ok, "esm/failed-transfer");

    }

    // -- user actions --
    function join(uint256 wad) external note {
        require(hop == hops.BASIC && !spent, "esm/not-joinable");

        gems[msg.sender] = add(gems[msg.sender], wad);
        sum = add(sum, wad);

        bool ok = gem.transferFrom(msg.sender, address(this), wad);

        require(ok, "esm/failed-transfer");
    }

    function exit(address usr, uint256 wad) external note {
        require(hop == hops.FREED, "esm/not-freed");

        gems[msg.sender] = sub(gems[msg.sender], wad);
        sum = sub(sum, wad);

        bool ok = gem.transfer(usr, wad);

        require(ok, "esm/failed-transfer");
    }

    // -- helpers --
    function full() public view returns (bool) {
        return sum >= cap;
    }

    function at() public view returns (uint256) {
        return uint256(hop);
    }
}
