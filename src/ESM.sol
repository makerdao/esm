pragma solidity ^0.5.6;

import "ds-note/note.sol";

contract GemLike {
    function balanceOf(address) public view returns (uint256);
    function transfer(address, uint256) public returns (bool);
    function transferFrom(address, address, uint256) public returns (bool);
}

contract EndLike {
    function cage() public;
}

contract ESM is DSNote {
    GemLike public gem; // collateral
    EndLike public end; // cage module
    address public pit; // burner
    uint256 public min; // threshold
    uint256 public fired;

    mapping(address => uint256) public sum; // per-address balance
    uint256 public Sum; // total balance

    constructor(address gem_, address end_, address pit_, uint256 min_) public {
        gem = GemLike(gem_);
        end = EndLike(end_);
        pit = pit_;
        min = min_;
    }

    // -- math --
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);
    }

    function fire() external note {
        require(fired == 0, "esm/already-fired");
        require(Sum >= min,  "esm/min-not-reached");

        end.cage();

        fired = 1;
    }

    function join(uint256 wad) external note {
        require(fired == 0, "esm/already-fired");

        sum[msg.sender] = add(sum[msg.sender], wad);
        Sum = add(Sum, wad);

        require(gem.transferFrom(msg.sender, pit, wad), "esm/transfer-failed");
    }
}
