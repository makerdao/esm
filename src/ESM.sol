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
    GemLike public gem;
    EndLike public end;
    uint256 public min;
    uint256 public Sum;
    address public sun;
    bool    public fired;

    mapping(address => uint256) public sum;

    constructor(address gem_, address end_, address sun_, uint256 min_) public {
        gem = GemLike(gem_);
        end = EndLike(end_);
        sun = sun_;
        min = min_;
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

    function fire() external note {
        require(!fired,  "esm/already-fired");
        require(full(),  "esm/min-not-reached");

        end.cage();

        fired = true;
    }

    function join(uint256 wad) external note {
        require(!fired, "esm/already-fired");

        sum[msg.sender] = add(sum[msg.sender], wad);
        Sum = add(Sum, wad);

        require(gem.transferFrom(msg.sender, sun, wad), "esm/transfer-failed");
    }

    // -- helpers --
    function full() public view returns (bool) {
        return Sum >= min;
    }
}
