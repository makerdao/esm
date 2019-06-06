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
    uint256 public cap;
    GemLike public gem;
    EndLike public end;
    uint256 public sum;

    mapping(address => uint256) public gems;

    uint256 public constant START = 0;
    uint256 public constant FREED = 1;
    uint256 public constant BURNT = 2;
    uint256 public constant FIRED = 3;
    uint256 public          state = START;

    constructor(address gem_, address end_, uint256 cap_) public {
        gem = GemLike(gem_);
        end = EndLike(end_);
        cap = cap_;
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
        require(state == START && sum >= cap, "esm/not-fireable");

        end.cage();

        state = FIRED;
    }

    function join(uint256 wad) external note {
        require(state == START, "esm/not-joinable");

        gems[msg.sender] = add(gems[msg.sender], wad);
        sum = add(sum, wad);

        require(gem.transferFrom(msg.sender, address(0x0), wad), "esm/failed-transfer");
    }

    // -- helpers --
    function full() external view returns (bool) {
        return sum >= cap;
    }
}
