// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Storage.sol";
import "./Errors.sol";
import "./Validation.sol";
import "./PlayerRegistryLogic.sol";
import "../rounds/IEasyGameRoundManager.sol";

abstract contract RoundGameLogic is EasyGameAdvanceStorage, PlayerRegistryLogic {
    event RoundActivated(
        address indexed player,
        uint256 indexed roundId,
        uint8 indexed level,
        uint256 amount,
        uint256 cellId,
        bool paidWithUsdc
    );
    event RoundMatrixPlaced(
        address indexed player,
        uint256 indexed roundId,
        uint256 indexed cellId,
        uint256 parentCellId
    );
    event RoundRecycled(
        address indexed player,
        uint256 indexed roundId,
        uint256 cycleCount,
        uint256 newCellId
    );
    event RoundPaymentSplit(
        address indexed player,
        uint256 indexed roundId,
        uint256 matrixPrizeAmount,
        uint256 directReferralAmount,
        uint256 secondLineAmount,
        uint256 thirdLineAmount,
        uint256 projectFeeAmount,
        bool paidWithUsdc
    );
    event RoundWeightUpdated(
        address indexed player,
        uint256 indexed roundId,
        uint256 totalWeight
    );
    event ReferralBonusPositionGranted(
        address indexed player,
        uint256 indexed roundId,
        uint256 indexed cellId,
        uint256 tickets
    );

    function _activateRoundState(
        RoundConfig calldata config,
        bytes calldata signature,
        address playerAddress,
        address inviter,
        bool paidWithUsdc
    ) internal returns (uint256 cellId) {
        Player storage player = players[playerAddress];
        address effectiveInviter = player.exists ? player.inviter : inviter;
        if (
            effectiveInviter == playerAddress ||
            (effectiveInviter != address(0) && !players[effectiveInviter].exists)
        ) {
            effectiveInviter = address(0);
        }
        IEasyGameRoundManager(roundManager).initializeAndRegisterEntry(
            config,
            signature,
            playerAddress,
            effectiveInviter
        );
        if (!levelAvailable[config.level]) {
            revert LevelEmergencyPaused(config.level);
        }

        _registerPlayer(player, playerAddress, effectiveInviter);
        PlayerRound storage state = playerRounds[playerAddress][config.roundId];
        if (state.active) {
            revert RoundTicketAlreadyActive(config.roundId, playerAddress);
        }

        state.active = true;
        state.level = config.level;
        state.tickets = 1;
        player.totalTickets += 1;
        player.lastActiveAt = block.timestamp;

        cellId = _placeRoundPlayer(config.roundId, config.level, playerAddress);
        _addRoundWeight(playerAddress, config.roundId, BASE_ACTIVATION_WEIGHT, 0);
        _processRoundRecycles(config.roundId, config.level, MAX_RECYCLE_STEPS_PER_TX);

        emit RoundActivated(
            playerAddress,
            config.roundId,
            config.level,
            paidWithUsdc ? config.usdcPrice : config.ethPrice,
            cellId,
            paidWithUsdc
        );
    }

    function _placeRoundPlayer(
        uint256 roundId,
        uint8 level,
        address playerAddress
    ) internal returns (uint256 cellId) {
        if (roundNextCellId[roundId] == 0) roundNextCellId[roundId] = 1;
        cellId = roundNextCellId[roundId]++;
        uint256 parentCellId = cellId == 1 ? 0 : cellId / 2;

        MatrixNode storage node = roundMatrixNodes[roundId][cellId];
        node.cellId = cellId;
        node.player = playerAddress;
        node.level = level;
        node.parentCellId = parentCellId;

        PlayerRound storage playerState = playerRounds[playerAddress][roundId];
        playerState.cellId = cellId;
        playerState.parentCellId = parentCellId;
        roundActiveCells[roundId] += 1;

        if (parentCellId != 0) {
            MatrixNode storage parent = roundMatrixNodes[roundId][parentCellId];
            if (parent.leftChildCellId == 0) {
                parent.leftChildCellId = cellId;
                playerRounds[parent.player][roundId].leftChildCellId = cellId;
            } else if (parent.rightChildCellId == 0) {
                parent.rightChildCellId = cellId;
                parent.closed = true;
                playerRounds[parent.player][roundId].rightChildCellId = cellId;
                _queueRoundRecycle(roundId, parent.player);
            } else {
                revert RoundParentAlreadyClosed(roundId, parentCellId);
            }
        }

        _advanceRoundOpenParent(roundId);
        emit RoundMatrixPlaced(playerAddress, roundId, cellId, parentCellId);
    }

    function _queueRoundRecycle(uint256 roundId, address playerAddress) internal {
        uint256 tail = _roundRecycleTail[roundId];
        _roundRecycleQueue[roundId][tail] = playerAddress;
        _roundRecycleTail[roundId] = tail + 1;
    }

    function _processRoundRecycles(
        uint256 roundId,
        uint8 level,
        uint256 maxSteps
    ) internal returns (uint256 processed) {
        uint256 head = _roundRecycleHead[roundId];
        uint256 tail = _roundRecycleTail[roundId];
        while (head < tail && processed < maxSteps) {
            address playerAddress = _roundRecycleQueue[roundId][head];
            delete _roundRecycleQueue[roundId][head++];
            processed++;

            PlayerRound storage state = playerRounds[playerAddress][roundId];
            if (state.active) {
                state.cycleCount += 1;
                players[playerAddress].recycleCount += 1;
                players[playerAddress].boxTokens += 1;
                _addRoundWeight(playerAddress, roundId, RECYCLE_MATRIX_WEIGHT, 3);
                _addRoundWeight(playerAddress, roundId, BOX_NFT_WEIGHT, 4);
                uint256 newCellId = _placeRoundPlayer(roundId, level, playerAddress);
                emit RoundRecycled(playerAddress, roundId, state.cycleCount, newCellId);
            }
            tail = _roundRecycleTail[roundId];
        }
        _roundRecycleHead[roundId] = head;
    }

    function _advanceRoundOpenParent(uint256 roundId) internal {
        uint256 nextOpen = roundNextOpenParentCellId[roundId];
        if (nextOpen == 0) nextOpen = 1;
        while (
            nextOpen < roundNextCellId[roundId] &&
            roundMatrixNodes[roundId][nextOpen].closed
        ) nextOpen++;
        roundNextOpenParentCellId[roundId] =
            nextOpen < roundNextCellId[roundId] ? nextOpen : 0;
    }

    function _addRoundWeight(
        address playerAddress,
        uint256 roundId,
        uint256 amount,
        uint8 weightType
    ) internal returns (uint256 accepted) {
        if (amount == 0 || !playerRounds[playerAddress][roundId].active) return 0;
        WeightBreakdown storage breakdown = _roundWeights[playerAddress][roundId];
        PlayerRound storage state = playerRounds[playerAddress][roundId];
        uint256 current;
        uint256 cap;
        if (weightType == 0) {
            current = breakdown.baseWeight;
            cap = MAX_BASE_WEIGHT_PER_LEVEL;
        } else if (weightType == 1) {
            current = breakdown.referralWeight;
            cap = MAX_REFERRAL_WEIGHT_PER_LEVEL;
        } else if (weightType == 3) {
            current = breakdown.matrixWeight;
            cap = MAX_MATRIX_WEIGHT_PER_LEVEL;
        } else {
            current = breakdown.nftWeight;
            cap = MAX_NFT_WEIGHT_PER_LEVEL;
        }
        accepted = _acceptedWeight(current, amount, cap);
        accepted = _acceptedWeight(state.totalWeight, accepted, MAX_TOTAL_WEIGHT_PER_LEVEL);
        if (accepted == 0) return 0;

        Player storage player = players[playerAddress];
        if (weightType == 0) {
            breakdown.baseWeight += accepted;
            player.baseWeight += accepted;
        } else if (weightType == 1) {
            breakdown.referralWeight += accepted;
            player.referralWeight += accepted;
        } else if (weightType == 3) {
            breakdown.matrixWeight += accepted;
            player.matrixWeight += accepted;
        } else {
            breakdown.nftWeight += accepted;
            player.nftWeight += accepted;
        }

        state.totalWeight += accepted;
        roundTotalWeight[roundId] += accepted;
        player.totalWeight += accepted;
        emit RoundWeightUpdated(playerAddress, roundId, state.totalWeight);
    }

    function _acceptedWeight(
        uint256 current,
        uint256 requested,
        uint256 cap
    ) private pure returns (uint256) {
        if (current >= cap) return 0;
        uint256 remaining = cap - current;
        return requested > remaining ? remaining : requested;
    }

    function _splitRoundPayment(
        RoundConfig calldata config,
        address playerAddress,
        uint256 amount,
        bool paidWithUsdc
    ) internal {
        uint256 matrixAmount = (amount * MATRIX_PRIZE_BPS) / BPS;
        uint256 directAmount = (amount * DIRECT_REF_BPS) / BPS;
        uint256 secondAmount = (amount * SECOND_REF_BPS) / BPS;
        uint256 thirdAmount = (amount * THIRD_REF_BPS) / BPS;
        uint256 feeAmount = amount - matrixAmount - directAmount - secondAmount - thirdAmount;

        if (paidWithUsdc) roundPrizePoolsUsdc[config.roundId] += matrixAmount;
        else roundPrizePools[config.roundId] += matrixAmount;

        Player storage player = players[playerAddress];
        _creditRoundReferral(
            config.roundId,
            config.level,
            player.inviter,
            directAmount,
            DIRECT_REF_WEIGHT,
            paidWithUsdc
        );
        _creditRoundReferral(
            config.roundId,
            config.level,
            player.secondLine,
            secondAmount,
            SECOND_REF_WEIGHT,
            paidWithUsdc
        );
        _creditRoundReferral(
            config.roundId,
            config.level,
            player.thirdLine,
            thirdAmount,
            THIRD_REF_WEIGHT,
            paidWithUsdc
        );

        if (paidWithUsdc) projectFeesAccruedUsdc += feeAmount;
        else projectFeesAccrued += feeAmount;
        emit RoundPaymentSplit(
            playerAddress,
            config.roundId,
            matrixAmount,
            directAmount,
            secondAmount,
            thirdAmount,
            feeAmount,
            paidWithUsdc
        );
    }

    function _creditRoundReferral(
        uint256 roundId,
        uint8 level,
        address inviter,
        uint256 amount,
        uint256 weight,
        bool paidWithUsdc
    ) internal {
        if (inviter == address(0) || !players[inviter].exists) {
            if (paidWithUsdc) roundPrizePoolsUsdc[roundId] += amount;
            else roundPrizePools[roundId] += amount;
            return;
        }
        if (paidWithUsdc) claimableReferralBonusUsdc[inviter] += amount;
        else players[inviter].claimableReferralBonus += amount;
        uint256 accepted = _addRoundWeight(inviter, roundId, weight, 1);
        _grantReferralBonusPositions(roundId, level, inviter, accepted);
    }

    /// @dev Every accumulated 100 referral-weight points grant one additional
    /// deterministic matrix ticket. This makes referrals increase the actual
    /// probability of occupying a precommitted winning cell, while preserving
    /// auditable left-to-right placement.
    function _grantReferralBonusPositions(
        uint256 roundId,
        uint8 level,
        address playerAddress,
        uint256 acceptedWeight
    ) private {
        if (acceptedWeight == 0) return;
        uint256 accumulated =
            roundReferralWeightRemainder[playerAddress][roundId] +
            acceptedWeight;
        uint256 positions = accumulated / DIRECT_REF_WEIGHT;
        roundReferralWeightRemainder[playerAddress][roundId] =
            accumulated % DIRECT_REF_WEIGHT;

        PlayerRound storage state = playerRounds[playerAddress][roundId];
        for (uint256 i = 0; i < positions; i++) {
            state.tickets += 1;
            players[playerAddress].totalTickets += 1;
            uint256 cellId = _placeRoundPlayer(
                roundId,
                level,
                playerAddress
            );
            emit ReferralBonusPositionGranted(
                playerAddress,
                roundId,
                cellId,
                state.tickets
            );
        }
    }
}
