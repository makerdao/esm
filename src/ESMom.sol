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
    function free() external auth note { esm.free(); }
    function burn() external auth note { esm.burn(); }

    function swap() external auth note returns (address) {
        end.deny(address(esm));

        esm = new ESM(address(this), gem, address(end), sun, cap);
        end.rely(address(esm));

        return address(esm);
    }
}
