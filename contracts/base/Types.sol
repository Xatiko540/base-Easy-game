// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20Minimal {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

struct Player {
    bool exists;
    address wallet;
    address inviter;
    address secondLine;
    address thirdLine;
    uint256 totalTickets;
    uint256 baseWeight;
    uint256 referralWeight;
    uint256 loyaltyWeight;
    uint256 matrixWeight;
    uint256 nftWeight;
    uint256 totalWeight;
    uint256 boxTokens;
    uint256 recycleCount;
    uint256 claimableReferralBonus;
    uint256 claimablePrize;
    uint256 pendingPrize;
    uint256 joinedAt;
    uint256 lastActiveAt;
}

struct PlayerLevel {
    bool active;
    bool frozen;
    uint256 tickets;
    uint256 cellId;
    uint256 parentCellId;
    uint256 leftChildCellId;
    uint256 rightChildCellId;
    uint256 cycleCount;
    uint256 levelWeight;
    uint256 claimablePrize;
    uint256 pendingPrize;
}

struct MatrixNode {
    uint256 cellId;
    address player;
    uint8 level;
    uint256 parentCellId;
    uint256 leftChildCellId;
    uint256 rightChildCellId;
    bool closed;
    bool prizeCell;
}

struct WeightBreakdown {
    uint256 baseWeight;
    uint256 referralWeight;
    uint256 loyaltyWeight;
    uint256 matrixWeight;
    uint256 nftWeight;
}
