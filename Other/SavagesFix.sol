// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


contract arrayloopinjs {

    struct teststruct{
        uint256 information1;
        uint256 information2;
    }

    uint8 public lastnum;

    uint8 structids;

    mapping(uint256 => teststruct) public structmapping;

    function createsomestructs(uint256 howmany) public {
        for(uint8 i = 0; i < howmany; i++){
            teststruct memory newstruct;
            newstruct.information1 = lastnum;
            lastnum = lastnum + 1;
            newstruct.information2 = i;
            structmapping[i] = newstruct;
            structids = structids + 1;
        }
    }
}