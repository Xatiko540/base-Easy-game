// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";
import "./Errors.sol";
import "./Validation.sol";
import "./Storage.sol";
import "./GameLogic.sol";

abstract contract AdminInterface is EasyGameAdvanceStorage, GameLogic {
    event LevelPriceChanged(uint8 indexed level, uint256 oldPrice, uint256 newPrice);
    event LevelUsdcPriceChanged(uint8 indexed level, uint256 oldPrice, uint256 newPrice);
    event LevelAvailabilityChanged(uint8 indexed level, bool available);
    event WalletsChanged(address projectWallet, address treasuryWallet, address operatorWallet);
    event UsdcTokenChanged(address indexed oldToken, address indexed newToken);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RoundManagerChanged(address indexed oldManager, address indexed newManager);
    event SettlementContractChanged(address indexed oldSettlement, address indexed newSettlement);
    event BasePayGatewayChanged(address indexed oldGateway, address indexed newGateway);
    event LegacyActivationChanged(bool enabled);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier nonReentrant() {
        require(_reentrancyLock == 1, "Reentrant call");
        _reentrancyLock = 2;
        _;
        _reentrancyLock = 1;
    }

    function _validateLevel(uint8 level) internal pure {
        Validation.validateLevel(level);
    }

    function _validateLevelPure(uint8 level) internal pure {
        Validation.validateLevel(level);
    }

    function _isPrizeCell(uint256 cellId) internal pure returns (bool) {
        return Validation.isPrizeCell(cellId);
    }

    function _safeTransfer(address payable receiver, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        (bool ok, ) = receiver.call{value: amount}("");
        require(ok, "Transfer failed");
    }

    function _safeTransferToken(
        IERC20Minimal token,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        require(token.transfer(receiver, amount), "Token transfer failed");
    }

    function setRoundManager(address newManager) external onlyOwner {
        if (newManager == address(0)) revert ZeroAddress();
        address oldManager = roundManager;
        roundManager = newManager;
        emit RoundManagerChanged(oldManager, newManager);
    }

    function setSettlementContract(address newSettlement) external onlyOwner {
        if (newSettlement == address(0)) revert ZeroAddress();
        address oldSettlement = settlementContract;
        settlementContract = newSettlement;
        emit SettlementContractChanged(oldSettlement, newSettlement);
    }

    function setBasePayGateway(address newGateway) external onlyOwner {
        if (newGateway == address(0)) revert ZeroAddress();
        address oldGateway = basePayGateway;
        basePayGateway = newGateway;
        emit BasePayGatewayChanged(oldGateway, newGateway);
    }

    function setLegacyActivationEnabled(bool enabled) external onlyOwner {
        legacyActivationEnabled = enabled;
        emit LegacyActivationChanged(enabled);
    }

    function getPlayer(address playerAddress) external view returns (Player memory) {
        return players[playerAddress];
    }

    function getPlayerLevel(address playerAddress, uint8 level)
        external
        view
        returns (
            bool active,
            bool frozen,
            uint256 cycles,
            uint256 positionId,
            uint256 earned
        )
    {
        _validateLevel(level);
        PlayerLevel storage state = playerLevels[playerAddress][level];
        return (
            state.active,
            state.frozen,
            state.cycleCount,
            state.cellId,
            state.claimablePrize + state.pendingPrize
        );
    }

    function getPlayerLevelFull(address playerAddress, uint8 level)
        external
        view
        returns (PlayerLevel memory)
    {
        _validateLevel(level);
        return playerLevels[playerAddress][level];
    }

    function getPlayerWeight(address playerAddress, uint8 level)
        external
        view
        returns (uint256)
    {
        _validateLevel(level);
        return playerLevels[playerAddress][level].levelWeight;
    }

    function getPlayerChance(address playerAddress, uint8 level)
        external
        view
        returns (uint256 chanceBps)
    {
        _validateLevel(level);
        uint256 total = totalWeightByLevel[level];
        if (total == 0) {
            return 0;
        }
        return (playerLevels[playerAddress][level].levelWeight * BPS) / total;
    }

    function getLevelStats(uint8 level)
        external
        view
        returns (
            uint256 prizePool,
            uint256 totalWeight,
            uint256 activeCells,
            uint256 nextOpenParent,
            uint256 nextCell
        )
    {
        _validateLevel(level);
        return (
            matrixPrizePools[level],
            totalWeightByLevel[level],
            activeCellsByLevel[level],
            nextOpenParentCellId[level],
            nextCellId[level]
        );
    }

    function getLevelStatsUSDC(uint8 level)
        external
        view
        returns (
            uint256 prizePool,
            uint256 totalWeight,
            uint256 activeCells,
            uint256 nextOpenParent,
            uint256 nextCell
        )
    {
        _validateLevel(level);
        return (
            matrixPrizePoolsUsdc[level],
            totalWeightByLevel[level],
            activeCellsByLevel[level],
            nextOpenParentCellId[level],
            nextCellId[level]
        );
    }

    function getPlayerTokenRewards(address playerAddress, uint8 level)
        external
        view
        returns (
            uint256 referralBonus,
            uint256 claimablePrize,
            uint256 pendingPrize
        )
    {
        _validateLevel(level);
        return (
            claimableReferralBonusUsdc[playerAddress],
            claimablePrizeUsdcByLevel[playerAddress][level],
            pendingPrizeUsdcByLevel[playerAddress][level]
        );
    }

    function getLevelMatrixStats(uint8 level)
        external
        view
        returns (uint256 size, uint256 nextOpenParentId)
    {
        _validateLevel(level);
        return (activeCellsByLevel[level], nextOpenParentCellId[level]);
    }

    function getPendingRecycleCount(uint8 level)
        external
        view
        returns (uint256)
    {
        _validateLevel(level);
        return _pendingRecycleTail[level] - _pendingRecycleHead[level];
    }

    function getMatrixNode(uint8 level, uint256 cellId)
        external
        view
        returns (MatrixNode memory)
    {
        _validateLevel(level);
        require(cellId > 0 && cellId < nextCellId[level], "Invalid cell");
        return matrixNodes[level][cellId];
    }

    function getPlayerPosition(address playerAddress, uint8 level)
        external
        view
        returns (
            uint256 positionId,
            uint256 parentId,
            uint256 leftChildId,
            uint256 rightChildId,
            uint256 depth,
            bool closed
        )
    {
        _validateLevel(level);
        uint256 cellId = playerLevels[playerAddress][level].cellId;
        if (cellId == 0) {
            return (0, 0, 0, 0, 0, false);
        }

        MatrixNode storage node = matrixNodes[level][cellId];
        return (
            node.cellId,
            node.parentCellId,
            node.leftChildCellId,
            node.rightChildCellId,
            _depthOf(cellId),
            node.closed
        );
    }

    function isLevelActive(address playerAddress, uint8 level)
        external
        view
        returns (bool)
    {
        _validateLevel(level);
        return playerLevels[playerAddress][level].active;
    }

    function isLevelFrozen(address playerAddress, uint8 level)
        external
        view
        returns (bool)
    {
        _validateLevel(level);
        return playerLevels[playerAddress][level].frozen;
    }

    function getNextPrizeCell(uint8 level, uint256 currentCellId)
        external
        pure
        returns (uint256)
    {
        Validation.validateLevel(level);
        uint256 candidate = 7;
        while (candidate <= currentCellId) {
            candidate = ((candidate + 1) << 1) - 1;
        }
        return candidate;
    }

    function setLevelPrice(uint8 level, uint256 newPrice) external onlyOwner {
        _validateLevel(level);
        require(newPrice > 0, "Price is required");

        uint256 oldPrice = levelPrices[level];
        levelPrices[level] = newPrice;

        emit LevelPriceChanged(level, oldPrice, newPrice);
    }

    function setLevelPriceUSDC(uint8 level, uint256 newPrice) external onlyOwner {
        _validateLevel(level);
        require(newPrice > 0, "USDC price is required");

        uint256 oldPrice = levelPricesUsdc[level];
        levelPricesUsdc[level] = newPrice;

        emit LevelUsdcPriceChanged(level, oldPrice, newPrice);
    }

    /// @notice USDC is shared with immutable gateway, skills and settlement
    /// contracts. Changing only the core token would split accounting between
    /// different assets, so token migration requires a coordinated redeploy.
    function setUsdcToken(address) external view onlyOwner {
        revert UsdcTokenLocked();
    }

    function setAllLevelPrices(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price is required");
        for (uint8 level = 1; level <= LEVEL_COUNT; level++) {
            uint256 oldPrice = levelPrices[level];
            levelPrices[level] = newPrice;
            emit LevelPriceChanged(level, oldPrice, newPrice);
        }
    }

    function setLevelAvailable(uint8 level, bool available) external onlyOwner {
        _validateLevel(level);
        levelAvailable[level] = available;
        emit LevelAvailabilityChanged(level, available);
    }

    function setWallets(
        address newProjectWallet,
        address newTreasuryWallet,
        address newOperatorWallet
    ) external onlyOwner {
        require(newProjectWallet != address(0), "Project wallet required");
        require(newTreasuryWallet != address(0), "Treasury wallet required");
        require(newOperatorWallet != address(0), "Operator wallet required");

        projectWallet = newProjectWallet;
        treasuryWallet = newTreasuryWallet;
        operatorWallet = newOperatorWallet;

        emit WalletsChanged(projectWallet, treasuryWallet, operatorWallet);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner required");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
