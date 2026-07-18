// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20Minimal {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
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
    uint256 matrixWeight;
    uint256 nftWeight;
    uint256 totalWeight;
    uint256 boxTokens;
    uint256 recycleCount;
    uint256 claimableReferralBonus;
    uint256 joinedAt;
    uint256 lastActiveAt;
}

struct MatrixNode {
    uint256 cellId;
    address player;
    uint8 level;
    uint256 parentCellId;
    uint256 leftChildCellId;
    uint256 rightChildCellId;
    bool closed;
}

struct WeightBreakdown {
    uint256 baseWeight;
    uint256 referralWeight;
    uint256 matrixWeight;
    uint256 nftWeight;
}

enum RoundPhase {
    Uninitialized,
    Scheduled,
    Open,
    Locked,
    SettlementReady,
    Settled,
    Cancelled,
    Paused
}

struct RoundConfig {
    uint256 seasonId;
    uint256 roundId;
    uint8 level;
    uint64 startsAt;
    uint64 entriesCloseAt;
    uint64 endsAt;
    uint64 freezeClosesAt;
    uint32 maxPlayers;
    uint16 maxWinners;
    bytes32 winningCellsRoot;
    uint256 ethPrice;
    uint256 usdcPrice;
    uint16 freezeLimit;
    uint16 paymentSplitVersion;
}

struct RoundState {
    bytes32 configHash;
    uint64 initializedAt;
    uint32 occupiedCells;
    uint16 winnersRegistered;
    bool initialized;
    bool settled;
    bool cancelled;
    bool paused;
}

struct SeasonState {
    bytes32 configRoot;
    uint64 firstStartsAt;
    uint64 lastEndsAt;
    bool committed;
}

struct PlayerRound {
    bool active;
    uint8 level;
    uint256 tickets;
    uint256 cellId;
    uint256 parentCellId;
    uint256 leftChildCellId;
    uint256 rightChildCellId;
    uint256 cycleCount;
    uint256 totalWeight;
}
