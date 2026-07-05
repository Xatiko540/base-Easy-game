// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Storage.sol";

abstract contract GameplayEvents is EasyGameAdvanceStorage {
    event PaymentSplit(
        address indexed player,
        uint8 indexed level,
        uint256 matrixPrizeAmount,
        uint256 directReferralAmount,
        uint256 secondLineAmount,
        uint256 thirdLineAmount,
        uint256 projectFeeAmount
    );
    event TokenPaymentSplit(
        address indexed player,
        uint8 indexed level,
        address indexed token,
        uint256 matrixPrizeAmount,
        uint256 directReferralAmount,
        uint256 secondLineAmount,
        uint256 thirdLineAmount,
        uint256 projectFeeAmount
    );
    event ProjectFeeAccrued(
        uint8 indexed level,
        uint256 amount,
        uint256 totalAccrued
    );
    event TokenProjectFeeAccrued(
        address indexed token,
        uint8 indexed level,
        uint256 amount,
        uint256 totalAccrued
    );
    event ReferralBonusAdded(
        address indexed inviter,
        address indexed invitee,
        uint8 indexed level,
        uint256 bonusAmount,
        uint256 weightAdded
    );
    event SecondLineBonusAdded(
        address indexed inviter,
        address indexed invitee,
        uint8 indexed level,
        uint256 bonusAmount,
        uint256 weightAdded
    );
    event ThirdLineBonusAdded(
        address indexed inviter,
        address indexed invitee,
        uint8 indexed level,
        uint256 bonusAmount,
        uint256 weightAdded
    );
    event MatrixPlaced(
        address indexed player,
        uint8 indexed level,
        uint256 indexed cellId,
        uint256 parentCellId
    );
    event Recycled(
        address indexed player,
        uint8 indexed level,
        uint256 recycleCount,
        uint256 newCellId
    );
    event BoxTokenGranted(
        address indexed player,
        uint8 indexed level,
        uint256 amount
    );
    event PrizePositionReached(
        address indexed player,
        uint8 indexed level,
        uint256 indexed cellId,
        uint256 amount,
        bool pending
    );
    event TokenPrizePositionReached(
        address indexed player,
        uint8 indexed level,
        address indexed token,
        uint256 cellId,
        uint256 amount,
        bool pending
    );
    event WeightUpdated(
        address indexed player,
        uint8 indexed level,
        uint256 totalWeight
    );
    event LevelFrozen(address indexed player, uint8 indexed level);
    event LevelUnfrozen(address indexed player, uint8 indexed level);
}
