// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";
import "./Errors.sol";
import "./Validation.sol";
import "./Storage.sol";
import "./GameplayEvents.sol";
import "./SharedGameplayLogic.sol";
import "./MatrixLogic.sol";
import "./RewardsLogic.sol";
import "./WeightLogic.sol";

abstract contract GameLogic is
    EasyGameAdvanceStorage,
    SharedGameplayLogic,
    MatrixLogic,
    RewardsLogic,
    WeightLogic
{

    function _depthOf(uint256 cellId) internal pure virtual returns (uint256 depth) {
        return Validation.depthOf(cellId);
    }
}
