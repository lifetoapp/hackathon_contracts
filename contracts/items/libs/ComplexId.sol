// SPDX-License-Identifier: ULINCENSED
pragma solidity ^0.8.19;

library ComplexId {
    uint8 private constant numberOfParts = 4;
    uint8 private constant partSize = 64;
    
    function getPart(uint complexId, uint8 index) internal pure returns (uint64) {
        return uint64(complexId >> getShift(index));
    }

    function fromParts(
        uint64 part1,
        uint64 part2,
        uint64 part3,
        uint64 part4
    ) internal pure returns (uint) {
        return (
            (uint(part1) << getShift(1)) +
            (uint(part2) << getShift(2)) +
            (uint(part3) << getShift(3)) +
            (uint(part4) << getShift(4))
        );
    }

    function getShift(uint8 index) private pure returns (uint8) {
        return (numberOfParts - index) * partSize;
    }
}