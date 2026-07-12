// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./base/Types.sol";
import "./base/Errors.sol";
import "./base/Validation.sol";
import "./base/Storage.sol";
import "./base/GameLogic.sol";
import "./base/AdminInterface.sol";
import "./base/RoundGameLogic.sol";
import "./rounds/IEasyGameRoundManager.sol";

contract EasyGameAdvance is EasyGameAdvanceStorage, GameLogic, AdminInterface, RoundGameLogic {

    event LevelActivated(
        address indexed player,
        uint8 indexed level,
        uint256 value,
        uint256 cellId
    );
    event ProjectFeesWithdrawn(address indexed wallet, uint256 amount);
    event TokenProjectFeesWithdrawn(address indexed token, address indexed wallet, uint256 amount);
    event RoundPoolsReleased(uint256 indexed roundId, address indexed settlement, uint256 ethAmount, uint256 usdcAmount);
    event ReferralBonusClaimed(address indexed player, uint256 amount);
    event PrizeClaimed(address indexed player, uint8 indexed level, uint256 amount);
    event TokenReferralBonusClaimed(address indexed player, address indexed token, uint256 amount);
    event TokenPrizeClaimed(address indexed player, address indexed token, uint8 indexed level, uint256 amount);
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
        legacyActivationEnabled = false;

        levelPrices[1] = 0.05 ether;
        levelPrices[2] = 0.07 ether;
        levelPrices[3] = 0.1 ether;
        levelPrices[4] = 0.14 ether;
        levelPrices[5] = 0.2 ether;
        levelPrices[6] = 0.28 ether;
        levelPrices[7] = 0.4 ether;
        levelPrices[8] = 0.55 ether;
        levelPrices[9] = 0.8 ether;
        levelPrices[10] = 1.1 ether;
        levelPrices[11] = 1.6 ether;
        levelPrices[12] = 2.2 ether;
        levelPrices[13] = 3.2 ether;
        levelPrices[14] = 4.4 ether;
        levelPrices[15] = 6.5 ether;
        levelPrices[16] = 8 ether;
        levelPrices[17] = 12 ether;

        levelPricesUsdc[1] = 50000;
        levelPricesUsdc[2] = 70000;
        levelPricesUsdc[3] = 100000;
        levelPricesUsdc[4] = 140000;
        levelPricesUsdc[5] = 200000;
        levelPricesUsdc[6] = 280000;
        levelPricesUsdc[7] = 400000;
        levelPricesUsdc[8] = 550000;
        levelPricesUsdc[9] = 800000;
        levelPricesUsdc[10] = 1100000;
        levelPricesUsdc[11] = 1600000;
        levelPricesUsdc[12] = 2200000;
        levelPricesUsdc[13] = 3200000;
        levelPricesUsdc[14] = 4400000;
        levelPricesUsdc[15] = 6500000;
        levelPricesUsdc[16] = 8000000;
        levelPricesUsdc[17] = 12000000;

        for (uint8 level = 3; level <= LEVEL_COUNT; level++) {
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

    function claimPrize(uint8 level) external nonReentrant {
        _validateLevel(level);
        PlayerLevel storage state = playerLevels[msg.sender][level];
        require(!state.frozen, "Level is frozen");

        uint256 amount = state.claimablePrize;
        require(amount > 0, "No prize");

        state.claimablePrize = 0;
        players[msg.sender].claimablePrize -= amount;
        _safeTransfer(payable(msg.sender), amount);

        emit PrizeClaimed(msg.sender, level, amount);
    }

    function claimPrizeUSDC(uint8 level) external nonReentrant {
        _validateLevel(level);
        require(address(usdcToken) != address(0), "USDC token not configured");
        PlayerLevel storage state = playerLevels[msg.sender][level];
        require(!state.frozen, "Level is frozen");

        uint256 amount = claimablePrizeUsdcByLevel[msg.sender][level];
        require(amount > 0, "No USDC prize");

        claimablePrizeUsdcByLevel[msg.sender][level] = 0;
        claimablePrizeUsdc[msg.sender] -= amount;
        _safeTransferToken(usdcToken, msg.sender, amount);

        emit TokenPrizeClaimed(msg.sender, address(usdcToken), level, amount);
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
        ethAmount = roundPrizePools[roundId];
        usdcAmount = roundPrizePoolsUsdc[roundId];
        roundPrizePools[roundId] = 0;
        roundPrizePoolsUsdc[roundId] = 0;
        _safeTransfer(payable(settlementContract), ethAmount);
        _safeTransferToken(usdcToken, settlementContract, usdcAmount);
        emit RoundPoolsReleased(roundId, settlementContract, ethAmount, usdcAmount);
    }

}
