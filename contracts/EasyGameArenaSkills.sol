// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./base/Types.sol";
import "./rounds/IEasyGameRoundManager.sol";

interface IEasyGameRoundCore {
    function getPlayerRound(address player, uint256 roundId)
        external view returns (PlayerRound memory);
    function getRoundGameStats(uint256 roundId) external view returns (
        uint256 prizePoolEth,
        uint256 prizePoolUsdc,
        uint256 totalWeight,
        uint256 activeCells,
        uint256 nextCell,
        uint256 nextOpenParent
    );
}

contract EasyGameArenaSkills {
    uint256 public constant FREEZE_TOKEN_PRICE_USDC = 300_000;
    uint256 public constant MIN_UNFREEZE_PRICE_USDC = 1_000_000;
    uint256 public constant UNFREEZE_EXPECTED_PRIZE_BPS = 700;
    uint256 private constant BPS = 10_000;

    struct ArenaStatus {
        uint64 frozenUntil;
        uint16 freezeHits;
        uint16 freezeTokens;
    }

    IERC20Minimal public immutable usdcToken;
    IEasyGameRoundCore public immutable gameCore;
    IEasyGameRoundManager public immutable roundManager;
    address public immutable skillTreasury;
    mapping(uint256 => mapping(address => ArenaStatus)) public arenaStatus;
    uint256 private _lock = 1;

    event FreezeTokenPurchased(address indexed player, uint256 indexed roundId, uint256 price);
    event PlayerFrozen(address indexed attacker, address indexed target, uint256 indexed roundId, uint64 frozenUntil, uint16 hits);
    event PlayerUnfrozen(address indexed player, uint256 indexed roundId, uint256 price);

    modifier nonReentrant() {
        require(_lock == 1, "Reentrant call");
        _lock = 2;
        _;
        _lock = 1;
    }

    constructor(address core_, address manager_, address usdc_, address treasury_) {
        require(core_ != address(0) && manager_ != address(0), "Invalid game");
        require(usdc_ != address(0) && treasury_ != address(0), "Invalid payment");
        gameCore = IEasyGameRoundCore(core_);
        roundManager = IEasyGameRoundManager(manager_);
        usdcToken = IERC20Minimal(usdc_);
        skillTreasury = treasury_;
    }

    function buyFreezeToken(uint256 roundId) external nonReentrant {
        _requireFreezeWindow(roundId);
        _requireParticipant(roundId, msg.sender);
        require(usdcToken.transferFrom(msg.sender, skillTreasury, FREEZE_TOKEN_PRICE_USDC), "USDC transfer failed");
        arenaStatus[roundId][msg.sender].freezeTokens += 1;
        emit FreezeTokenPurchased(msg.sender, roundId, FREEZE_TOKEN_PRICE_USDC);
    }

    function freezePlayer(uint256 roundId, address target) external {
        _requireFreezeWindow(roundId);
        require(target != address(0) && target != msg.sender, "Invalid target");
        _requireParticipant(roundId, msg.sender);
        _requireParticipant(roundId, target);
        ArenaStatus storage attacker = arenaStatus[roundId][msg.sender];
        require(attacker.freezeTokens > 0, "Buy freeze token first");
        ArenaStatus storage targetStatus = arenaStatus[roundId][target];
        RoundConfig memory config = roundManager.getRoundConfig(roundId);
        require(targetStatus.freezeHits < config.freezeLimit, "Target is immune");
        attacker.freezeTokens -= 1;
        targetStatus.freezeHits += 1;
        uint256 duration = (config.freezeClosesAt - config.startsAt) / config.freezeLimit;
        if (duration == 0) duration = 1;
        uint256 until = block.timestamp + duration;
        if (until > config.freezeClosesAt) until = config.freezeClosesAt;
        targetStatus.frozenUntil = uint64(until);
        emit PlayerFrozen(msg.sender, target, roundId, uint64(until), targetStatus.freezeHits);
    }

    function buyUnfreeze(uint256 roundId) external nonReentrant {
        ArenaStatus storage status = arenaStatus[roundId][msg.sender];
        require(block.timestamp < status.frozenUntil, "Player is not frozen");
        uint256 price = getUnfreezePriceUsdc(roundId, msg.sender);
        require(usdcToken.transferFrom(msg.sender, skillTreasury, price), "USDC transfer failed");
        status.frozenUntil = 0;
        emit PlayerUnfrozen(msg.sender, roundId, price);
    }

    function getUnfreezePriceUsdc(uint256 roundId, address player) public view returns (uint256) {
        PlayerRound memory state = gameCore.getPlayerRound(player, roundId);
        (, uint256 pool, uint256 totalWeight,,,) = gameCore.getRoundGameStats(roundId);
        if (!state.active || totalWeight == 0 || pool == 0) return MIN_UNFREEZE_PRICE_USDC;
        uint256 expectedPrize = pool * state.totalWeight / totalWeight;
        uint256 dynamicPrice = expectedPrize * UNFREEZE_EXPECTED_PRIZE_BPS / BPS;
        return dynamicPrice > MIN_UNFREEZE_PRICE_USDC ? dynamicPrice : MIN_UNFREEZE_PRICE_USDC;
    }

    function getArenaStatus(uint256 roundId, address player) external view returns (
        bool frozen,
        bool immune,
        uint64 frozenUntil,
        uint16 freezeHits,
        uint16 freezeTokens
    ) {
        ArenaStatus memory status = arenaStatus[roundId][player];
        RoundConfig memory config = roundManager.getRoundConfig(roundId);
        return (
            block.timestamp < status.frozenUntil,
            status.freezeHits >= config.freezeLimit,
            status.frozenUntil,
            status.freezeHits,
            status.freezeTokens
        );
    }

    function isFrozen(uint256 roundId, address player) external view returns (bool) {
        return block.timestamp < arenaStatus[roundId][player].frozenUntil;
    }

    function _requireParticipant(uint256 roundId, address player) private view {
        require(gameCore.getPlayerRound(player, roundId).active, "Round participant required");
    }

    function _requireFreezeWindow(uint256 roundId) private view {
        RoundConfig memory config = roundManager.getRoundConfig(roundId);
        require(block.timestamp >= config.startsAt && block.timestamp < config.freezeClosesAt, "Freeze window closed");
        RoundPhase phase = roundManager.getRoundPhase(roundId);
        require(phase == RoundPhase.Open || phase == RoundPhase.Locked, "Round is not playable");
    }
}
