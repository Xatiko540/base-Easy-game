// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";

abstract contract EasyGameAdvanceStorage {
    uint8 public constant LEVEL_COUNT = 17;

    uint256 public constant BPS = 10000;
    uint256 public constant MATRIX_PRIZE_BPS = 7550;
    uint256 public constant DIRECT_REF_BPS = 950;
    uint256 public constant SECOND_REF_BPS = 600;
    uint256 public constant THIRD_REF_BPS = 400;
    uint256 public constant PROJECT_FEE_BPS = 500;

    uint256 public constant BASE_ACTIVATION_WEIGHT = 100;
    uint256 public constant DIRECT_REF_WEIGHT = 100;
    uint256 public constant SECOND_REF_WEIGHT = 50;
    uint256 public constant THIRD_REF_WEIGHT = 25;
    uint256 public constant RECYCLE_MATRIX_WEIGHT = 50;
    uint256 public constant BOX_NFT_WEIGHT = 10;

    uint256 public constant MAX_BASE_WEIGHT_PER_LEVEL = 1000;
    uint256 public constant MAX_REFERRAL_WEIGHT_PER_LEVEL = 2000;
    uint256 public constant MAX_MATRIX_WEIGHT_PER_LEVEL = 2000;
    uint256 public constant MAX_NFT_WEIGHT_PER_LEVEL = 500;
    uint256 public constant MAX_TOTAL_WEIGHT_PER_LEVEL = 5000;

    uint8 public constant MAX_RECYCLE_STEPS_PER_TX = 4;

    address public owner;
    address public projectWallet;
    address public treasuryWallet;
    address public operatorWallet;
    address public roundManager;
    address public settlementContract;
    bool public systemContractsFinalized;
    IERC20Minimal public usdcToken;

    mapping(uint8 => bool) public levelAvailable;

    mapping(address => Player) public players;

    mapping(address => mapping(uint256 => PlayerRound)) public playerRounds;
    mapping(uint256 => mapping(uint256 => MatrixNode)) public roundMatrixNodes;
    mapping(uint256 => uint256) public roundNextCellId;
    mapping(uint256 => uint256) public roundNextOpenParentCellId;
    mapping(uint256 => uint256) public roundActiveCells;
    mapping(uint256 => uint256) public roundTotalWeight;
    mapping(uint256 => uint256) public roundPrizePools;
    mapping(uint256 => uint256) public roundPrizePoolsUsdc;
    mapping(address => mapping(uint256 => WeightBreakdown)) internal _roundWeights;
    mapping(address => mapping(uint256 => uint256)) public roundReferralWeightRemainder;
    mapping(uint256 => mapping(uint256 => address)) internal _roundRecycleQueue;
    mapping(uint256 => uint256) internal _roundRecycleHead;
    mapping(uint256 => uint256) internal _roundRecycleTail;
    uint256 public projectFeesAccrued;
    uint256 public projectFeesAccruedUsdc;
    mapping(address => uint256) public claimableReferralBonusUsdc;

    uint256 internal _reentrancyLock = 1;
}
