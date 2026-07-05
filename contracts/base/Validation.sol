// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Errors.sol";

library Validation {
    uint8 internal constant LEVEL_COUNT = 17;

    function validateLevel(uint8 level) internal pure {
        if (level < 1 || level > LEVEL_COUNT) {
            revert InvalidLevel(level);
        }
    }

    function isPrizeCell(uint256 cellId) internal pure returns (bool) {
        return cellId >= 7 && ((cellId + 1) & cellId) == 0;
    }

    function depthOf(uint256 cellId) internal pure returns (uint256 depth) {
        while (cellId > 1) {
            cellId = cellId / 2;
            depth++;
        }
    }
}
