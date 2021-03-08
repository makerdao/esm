// SPDX-License-Identifier: AGPL-3.0-or-later

/// ESM.sol

// Copyright (C) 2019-2021 Maker Ecosystem Growth Holdings, INC.

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

pragma solidity >=0.6.12;

interface GemLike {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface EndLike {
    function cage() external;
}

contract ESM {
    GemLike public immutable gem; // collateral
    EndLike public immutable end; // cage module
    address public immutable pit; // burner
    uint256 public immutable min; // threshold
    uint256 public fired;

    mapping(address => uint256) public sum; // per-address balance
    uint256 public Sum; // total balance

    event Fire();
    event Join(address indexed usr, uint256 wad);

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

    function fire() external {
        require(fired == 0,  "esm/already-fired");
        require(Sum >= min,  "esm/min-not-reached");

        end.cage();

        fired = 1;
        emit Fire();
    }

    function join(uint256 wad) external {
        require(fired == 0, "esm/already-fired");

        sum[msg.sender] = add(sum[msg.sender], wad);
        Sum = add(Sum, wad);

        require(gem.transferFrom(msg.sender, pit, wad), "esm/transfer-failed");
        emit Join(msg.sender, wad);
    }
}
