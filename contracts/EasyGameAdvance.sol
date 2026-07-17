// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./base/Types.sol";
import "./base/Errors.sol";
import "./base/Storage.sol";
import "./base/AdminInterface.sol";
import "./base/RoundGameLogic.sol";
import "./rounds/IEasyGameRoundManager.sol";

contract EasyGameAdvance is EasyGameAdvanceStorage, AdminInterface, RoundGameLogic {
    event ProjectFeesWithdrawn(address indexed wallet, uint256 amount);
    event TokenProjectFeesWithdrawn(address indexed token, address indexed wallet, uint256 amount);
    event RoundPoolsReleased(uint256 indexed roundId, address indexed settlement, uint256 ethAmount, uint256 usdcAmount);
    event ReferralBonusClaimed(address indexed player, uint256 amount);
    event TokenReferralBonusClaimed(address indexed player, address indexed token, uint256 amount);
    event RoundRecycleBatchProcessed(
        uint256 indexed roundId,
        uint256 processed,
        uint256 remaining
    );
    constructor(
        address projectWallet_,
        address treasuryWallet_,
        address operatorWallet_,
        address usdcToken_,
        address roundManager_
    ) {
        if (projectWallet_ == address(0)) revert ZeroAddress();
        if (treasuryWallet_ == address(0)) revert ZeroAddress();
        if (operatorWallet_ == address(0)) revert ZeroAddress();
        if (usdcToken_ == address(0)) revert ZeroAddress();
        if (roundManager_ == address(0)) revert ZeroAddress();

        owner = msg.sender;
        projectWallet = projectWallet_;
        treasuryWallet = treasuryWallet_;
        operatorWallet = operatorWallet_;
        usdcToken = IERC20Minimal(usdcToken_);
        roundManager = roundManager_;
        // Round timestamps control normal availability. This switch is only an
        // emergency pause, so every configured level starts enabled.
        for (uint8 level = 1; level <= LEVEL_COUNT; level++) {
            levelAvailable[level] = true;
        }
    }

    function activateRound(
        RoundConfig calldata config,
        bytes calldata signature,
        address inviter
    ) external payable nonReentrant {
        if (msg.value != config.ethPrice || config.ethPrice == 0) {
            revert IncorrectRoundPayment();
        }
        _activateRoundState(
            config,
            signature,
            msg.sender,
            inviter,
            false
        );
        _splitRoundPayment(config, msg.sender, msg.value, false);
    }

    function activateRoundWithUSDC(
        RoundConfig calldata config,
        bytes calldata signature,
        address inviter
    ) external nonReentrant {
        if (config.usdcPrice == 0) revert RoundUsdcDisabled();
        if (!usdcToken.transferFrom(msg.sender, address(this), config.usdcPrice)) {
            revert TokenTransferFailed();
        }
        _activateRoundState(config, signature, msg.sender, inviter, true);
        _splitRoundPayment(config, msg.sender, config.usdcPrice, true);
    }

    function activateRoundFromBasePay(
        RoundConfig calldata config,
        bytes calldata signature,
        address player,
        address inviter
    ) external nonReentrant {
        require(msg.sender == basePayGateway, "Only Base Pay gateway");
        if (player == address(0)) revert ZeroAddress();
        if (config.usdcPrice == 0) revert RoundUsdcDisabled();
        if (!usdcToken.transferFrom(msg.sender, address(this), config.usdcPrice)) {
            revert TokenTransferFailed();
        }
        _activateRoundState(config, signature, player, inviter, true);
        _splitRoundPayment(config, player, config.usdcPrice, true);
    }

    function getPlayerRound(address playerAddress, uint256 roundId)
        external
        view
        returns (PlayerRound memory)
    {
        return playerRounds[playerAddress][roundId];
    }

    function getRoundGameStats(uint256 roundId)
        external
        view
        returns (
            uint256 prizePoolEth,
            uint256 prizePoolUsdc,
            uint256 totalWeight,
            uint256 activeCells,
            uint256 nextCell,
            uint256 nextOpenParent
        )
    {
        return (
            roundPrizePools[roundId],
            roundPrizePoolsUsdc[roundId],
            roundTotalWeight[roundId],
            roundActiveCells[roundId],
            roundNextCellId[roundId],
            roundNextOpenParentCellId[roundId]
        );
    }

    function getRoundMatrixNode(uint256 roundId, uint256 cellId)
        external
        view
        returns (MatrixNode memory)
    {
        if (cellId == 0 || cellId >= roundNextCellId[roundId]) {
            revert InvalidRoundCell(roundId, cellId);
        }
        return roundMatrixNodes[roundId][cellId];
    }

    function getRoundRecycleQueueState(uint256 roundId)
        public
        view
        returns (uint256 head, uint256 tail, uint256 pending)
    {
        head = _roundRecycleHead[roundId];
        tail = _roundRecycleTail[roundId];
        pending = tail - head;
    }

    function hasPendingRoundRecycles(uint256 roundId) public view returns (bool) {
        return _roundRecycleHead[roundId] < _roundRecycleTail[roundId];
    }

    /// @notice Completes deterministic FIFO recycle work in bounded batches.
    /// Anyone may call this after entries close so settlement cannot depend on
    /// another paid activation arriving.
    function processRoundRecycles(uint256 roundId, uint256 maxSteps)
        external
        nonReentrant
        returns (uint256 processed, uint256 remaining)
    {
        if (maxSteps == 0 || maxSteps > 64) {
            revert InvalidRecycleBatch(maxSteps, 64);
        }
        IEasyGameRoundManager manager = IEasyGameRoundManager(roundManager);
        RoundPhase phase = manager.getRoundPhase(roundId);
        require(
            phase == RoundPhase.Open ||
                phase == RoundPhase.Locked ||
                phase == RoundPhase.SettlementReady,
            "Round recycle unavailable"
        );
        RoundConfig memory config = manager.getRoundConfig(roundId);
        processed = _processRoundRecycles(roundId, config.level, maxSteps);
        remaining = _roundRecycleTail[roundId] - _roundRecycleHead[roundId];
        emit RoundRecycleBatchProcessed(roundId, processed, remaining);
    }

    function claimReferralBonus() external nonReentrant {
        uint256 amount = players[msg.sender].claimableReferralBonus;
        require(amount > 0, "No referral bonus");

        players[msg.sender].claimableReferralBonus = 0;
        _safeTransfer(payable(msg.sender), amount);

        emit ReferralBonusClaimed(msg.sender, amount);
    }

    function claimReferralBonusUSDC() external nonReentrant {
        uint256 amount = claimableReferralBonusUsdc[msg.sender];
        require(amount > 0, "No USDC referral bonus");
        require(address(usdcToken) != address(0), "USDC token not configured");

        claimableReferralBonusUsdc[msg.sender] = 0;
        _safeTransferToken(usdcToken, msg.sender, amount);

        emit TokenReferralBonusClaimed(msg.sender, address(usdcToken), amount);
    }

    function withdrawProjectFees() external onlyOwner nonReentrant {
        uint256 amount = projectFeesAccrued;
        require(amount > 0, "No project fees");

        projectFeesAccrued = 0;
        _safeTransfer(payable(projectWallet), amount);

        emit ProjectFeesWithdrawn(projectWallet, amount);
    }

    function withdrawProjectFeesUSDC() external onlyOwner nonReentrant {
        require(address(usdcToken) != address(0), "USDC token not configured");
        uint256 amount = projectFeesAccruedUsdc;
        require(amount > 0, "No USDC project fees");

        projectFeesAccruedUsdc = 0;
        _safeTransferToken(usdcToken, projectWallet, amount);

        emit TokenProjectFeesWithdrawn(address(usdcToken), projectWallet, amount);
    }

    function releaseRoundPools(uint256 roundId)
        external
        nonReentrant
        returns (uint256 ethAmount, uint256 usdcAmount)
    {
        require(msg.sender == settlementContract, "Only settlement");
        require(
            IEasyGameRoundManager(roundManager).getRoundPhase(roundId) ==
                RoundPhase.SettlementReady,
            "Round is not ready"
        );
        uint256 pending = _roundRecycleTail[roundId] - _roundRecycleHead[roundId];
        if (pending != 0) revert PendingRoundRecycles(roundId, pending);
        ethAmount = roundPrizePools[roundId];
        usdcAmount = roundPrizePoolsUsdc[roundId];
        roundPrizePools[roundId] = 0;
        roundPrizePoolsUsdc[roundId] = 0;
        _safeTransfer(payable(settlementContract), ethAmount);
        _safeTransferToken(usdcToken, settlementContract, usdcAmount);
        emit RoundPoolsReleased(roundId, settlementContract, ethAmount, usdcAmount);
    }

}
