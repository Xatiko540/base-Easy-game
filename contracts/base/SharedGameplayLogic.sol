// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";
import "./Storage.sol";
import "./GameplayEvents.sol";

abstract contract SharedGameplayLogic is EasyGameAdvanceStorage, GameplayEvents {
    function _placePlayer(uint8 level, address playerAddress)
        internal
        virtual
        returns (uint256 cellId);

    function _handleRecycle(uint8 level, address playerAddress)
        internal
        virtual;

    function _awardPrizePosition(
        address playerAddress,
        uint8 level,
        uint256 cellId,
        bool prizeCell
    ) internal virtual;

    function _creditPrize(address playerAddress, uint8 level, uint256 amount)
        internal
        virtual;

    function _creditPrizeUsdc(address playerAddress, uint8 level, uint256 amount)
        internal
        virtual;

    function _addWeight(
        address playerAddress,
        uint8 level,
        uint256 amount,
        uint8 weightType
    ) internal virtual;

    function _acceptedWeight(
        uint256 current,
        uint256 requested,
        uint256 cap
    ) internal pure virtual returns (uint256);

    function _advanceNextOpenParent(uint8 level) internal virtual;

    function _freezeAfterRecycle(address playerAddress, uint8 level) internal virtual;

    function _unfreezeLowerLevels(address playerAddress, uint8 level) internal virtual;
}
