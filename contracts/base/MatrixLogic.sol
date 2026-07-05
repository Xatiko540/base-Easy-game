// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./SharedGameplayLogic.sol";
import "./Validation.sol";

abstract contract MatrixLogic is SharedGameplayLogic {
    function _registerPlayer(
        Player storage player,
        address playerAddress,
        address inviter
    ) internal {
        if (player.exists) {
            return;
        }

        player.exists = true;
        player.wallet = playerAddress;
        player.joinedAt = block.timestamp;

        if (
            inviter != address(0) &&
            inviter != playerAddress &&
            players[inviter].exists
        ) {
            player.inviter = inviter;
            player.secondLine = players[inviter].inviter;
            player.thirdLine = player.secondLine == address(0)
                ? address(0)
                : players[player.secondLine].inviter;
        }
    }

    function _placePlayer(uint8 level, address playerAddress)
        internal
        override
        returns (uint256 cellId)
    {
        if (nextCellId[level] == 0) {
            nextCellId[level] = 1;
        }

        cellId = nextCellId[level];
        nextCellId[level] = cellId + 1;

        uint256 parentCellId = cellId == 1 ? 0 : cellId / 2;
        bool prizeCell = Validation.isPrizeCell(cellId);

        MatrixNode storage node = matrixNodes[level][cellId];
        node.cellId = cellId;
        node.player = playerAddress;
        node.level = level;
        node.parentCellId = parentCellId;
        node.prizeCell = prizeCell;

        PlayerLevel storage state = playerLevels[playerAddress][level];
        state.cellId = cellId;
        state.parentCellId = parentCellId;

        activeCellsByLevel[level] += 1;
        levelMatrixSize[level] = activeCellsByLevel[level];

        if (!_levelPlayerSeen[level][playerAddress]) {
            _levelPlayerSeen[level][playerAddress] = true;
            _levelPlayers[level].push(playerAddress);
        }

        if (parentCellId != 0) {
            MatrixNode storage parent = matrixNodes[level][parentCellId];
            if (parent.leftChildCellId == 0) {
                parent.leftChildCellId = cellId;
                playerLevels[parent.player][level].leftChildCellId = cellId;
            } else if (parent.rightChildCellId == 0) {
                parent.rightChildCellId = cellId;
                parent.closed = true;
                playerLevels[parent.player][level].rightChildCellId = cellId;
                _handleRecycle(level, parent.player);
            } else {
                revert("Parent already closed");
            }
        }

        _advanceNextOpenParent(level);
        _awardPrizePosition(playerAddress, level, cellId, prizeCell);

        emit MatrixPlaced(playerAddress, level, cellId, parentCellId);
    }

    function _handleRecycle(uint8 level, address playerAddress) internal override {
        PlayerLevel storage state = playerLevels[playerAddress][level];
        if (!state.active) {
            return;
        }

        state.cycleCount += 1;
        players[playerAddress].recycleCount += 1;
        players[playerAddress].boxTokens += 1;

        _addWeight(playerAddress, level, RECYCLE_MATRIX_WEIGHT, 3);
        _addWeight(playerAddress, level, BOX_NFT_WEIGHT, 4);

        uint256 newCellId = _placePlayer(level, playerAddress);

        emit Recycled(playerAddress, level, state.cycleCount, newCellId);
        emit BoxTokenGranted(playerAddress, level, 1);

        _freezeAfterRecycle(playerAddress, level);
    }

    function _advanceNextOpenParent(uint8 level) internal override {
        uint256 nextOpen = nextOpenParentCellId[level];
        if (nextOpen == 0) {
            nextOpen = 1;
        }

        while (
            nextOpen < nextCellId[level] &&
            matrixNodes[level][nextOpen].closed
        ) {
            nextOpen++;
        }

        nextOpenParentCellId[level] = nextOpen < nextCellId[level] ? nextOpen : 0;
    }

    function _freezeAfterRecycle(address playerAddress, uint8 level) internal override {
        PlayerLevel storage state = playerLevels[playerAddress][level];
        if (
            level < LEVEL_COUNT &&
            state.cycleCount >= 2 &&
            !playerLevels[playerAddress][level + 1].active &&
            !state.frozen
        ) {
            state.frozen = true;
            emit LevelFrozen(playerAddress, level);
        }
    }

    function _unfreezeLowerLevels(address playerAddress, uint8 level) internal override {
        if (level <= 1) {
            return;
        }

        for (uint8 lowerLevel = 1; lowerLevel < level; lowerLevel++) {
            PlayerLevel storage previous = playerLevels[playerAddress][lowerLevel];
            if (previous.frozen) {
                previous.frozen = false;
                if (previous.pendingPrize > 0) {
                    uint256 pending = previous.pendingPrize;
                    previous.pendingPrize = 0;
                    previous.claimablePrize += pending;
                    players[playerAddress].pendingPrize -= pending;
                    players[playerAddress].claimablePrize += pending;
                }
                if (pendingPrizeUsdcByLevel[playerAddress][lowerLevel] > 0) {
                    uint256 pendingUsdc = pendingPrizeUsdcByLevel[playerAddress][lowerLevel];
                    pendingPrizeUsdcByLevel[playerAddress][lowerLevel] = 0;
                    claimablePrizeUsdcByLevel[playerAddress][lowerLevel] += pendingUsdc;
                    pendingPrizeUsdc[playerAddress] -= pendingUsdc;
                    claimablePrizeUsdc[playerAddress] += pendingUsdc;
                }
                emit LevelUnfrozen(playerAddress, lowerLevel);
            }
        }
    }
}
