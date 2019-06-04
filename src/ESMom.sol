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

import {ESM} from "./ESM.sol";

import {DSNote} from "ds-note/note.sol";

contract EndLike {
    function rely(address) public;
    function deny(address) public;
}

contract ESMom is DSNote {
    ESM     public esm;
    address public gem;
    EndLike public end;
    address public sun;
    uint256 public cap;

    mapping(address => uint256) public old;

    mapping(address => uint256) public wards;
    function rely(address usr) public auth note { wards[usr] = 1; }
    function deny(address usr) public auth note { wards[usr] = 0; }
    modifier auth() { require(wards[msg.sender] == 1, "esmom/unauthorized"); _; }

    constructor(address ward, address gem_, address end_, address sun_, uint256 cap_) public {
        wards[ward] = 1;
        gem = gem_;
        end = EndLike(end_);
        sun = sun_;
        cap = cap_;

        esm = new ESM(address(this), gem_, end_, sun_, cap_);
    }

    function file(bytes32 job, address obj) external auth note {
        if (job == "end") end = EndLike(obj);
        if (job == "sun") sun = obj;
    }

    function file(bytes32 job, uint256 val) external auth note {
        if (job == "cap") cap = val;
    }

    // -- actions --
    function free(address esm_) external auth note {
        require(old[esm_] == 1, "esmom/not-an-old-esm");

        ESM(esm_).free();
    }
    function burn(address esm_) external auth note {
        require(old[esm_] == 1, "esmom/not-an-old-esm");

        ESM(esm_).burn();
    }

    function swap() external auth note returns (address) {
        end.deny(address(esm));
        old[address(esm)] = 1;

        esm = new ESM(address(this), gem, address(end), sun, cap);
        end.rely(address(esm));

        return address(esm);
    }
}
