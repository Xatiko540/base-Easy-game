// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./SharedGameplayLogic.sol";

abstract contract RewardsLogic is SharedGameplayLogic {
    function _splitPayment(uint8 level, address playerAddress, uint256 amount) internal {
        uint256 matrixPrizeAmount = (amount * MATRIX_PRIZE_BPS) / BPS;
        uint256 directReferralAmount = (amount * DIRECT_REF_BPS) / BPS;
        uint256 secondLineAmount = (amount * SECOND_REF_BPS) / BPS;
        uint256 thirdLineAmount = (amount * THIRD_REF_BPS) / BPS;
        uint256 projectFeeAmount = amount -
            matrixPrizeAmount -
            directReferralAmount -
            secondLineAmount -
            thirdLineAmount;

        Player storage player = players[playerAddress];
        matrixPrizePools[level] += matrixPrizeAmount;

        _creditReferral(
            player.inviter,
            playerAddress,
            level,
            directReferralAmount,
            DIRECT_REF_WEIGHT,
            1
        );
        _creditReferral(
            player.secondLine,
            playerAddress,
            level,
            secondLineAmount,
            SECOND_REF_WEIGHT,
            2
        );
        _creditReferral(
            player.thirdLine,
            playerAddress,
            level,
            thirdLineAmount,
            THIRD_REF_WEIGHT,
            3
        );

        projectFeesAccrued += projectFeeAmount;

        emit PaymentSplit(
            playerAddress,
            level,
            matrixPrizeAmount,
            directReferralAmount,
            secondLineAmount,
            thirdLineAmount,
            projectFeeAmount
        );
        emit ProjectFeeAccrued(level, projectFeeAmount, projectFeesAccrued);
    }

    function _splitUsdcPayment(uint8 level, address playerAddress, uint256 amount) internal {
        uint256 matrixPrizeAmount = (amount * MATRIX_PRIZE_BPS) / BPS;
        uint256 directReferralAmount = (amount * DIRECT_REF_BPS) / BPS;
        uint256 secondLineAmount = (amount * SECOND_REF_BPS) / BPS;
        uint256 thirdLineAmount = (amount * THIRD_REF_BPS) / BPS;
        uint256 projectFeeAmount = amount -
            matrixPrizeAmount -
            directReferralAmount -
            secondLineAmount -
            thirdLineAmount;

        Player storage player = players[playerAddress];
        matrixPrizePoolsUsdc[level] += matrixPrizeAmount;

        _creditReferralUsdc(
            player.inviter,
            playerAddress,
            level,
            directReferralAmount,
            DIRECT_REF_WEIGHT,
            1
        );
        _creditReferralUsdc(
            player.secondLine,
            playerAddress,
            level,
            secondLineAmount,
            SECOND_REF_WEIGHT,
            2
        );
        _creditReferralUsdc(
            player.thirdLine,
            playerAddress,
            level,
            thirdLineAmount,
            THIRD_REF_WEIGHT,
            3
        );

        projectFeesAccruedUsdc += projectFeeAmount;

        emit TokenPaymentSplit(
            playerAddress,
            level,
            address(usdcToken),
            matrixPrizeAmount,
            directReferralAmount,
            secondLineAmount,
            thirdLineAmount,
            projectFeeAmount
        );
        emit TokenProjectFeeAccrued(
            address(usdcToken),
            level,
            projectFeeAmount,
            projectFeesAccruedUsdc
        );
    }

    function _creditReferral(
        address inviter,
        address invitee,
        uint8 level,
        uint256 amount,
        uint256 weight,
        uint8 line
    ) internal {
        if (inviter == address(0) || !players[inviter].exists) {
            matrixPrizePools[level] += amount;
            return;
        }

        players[inviter].claimableReferralBonus += amount;
        _addWeight(inviter, level, weight, 1);

        if (line == 1) {
            emit ReferralBonusAdded(inviter, invitee, level, amount, weight);
        } else if (line == 2) {
            emit SecondLineBonusAdded(inviter, invitee, level, amount, weight);
        } else {
            emit ThirdLineBonusAdded(inviter, invitee, level, amount, weight);
        }
    }

    function _creditReferralUsdc(
        address inviter,
        address invitee,
        uint8 level,
        uint256 amount,
        uint256 weight,
        uint8 line
    ) internal {
        if (inviter == address(0) || !players[inviter].exists) {
            matrixPrizePoolsUsdc[level] += amount;
            return;
        }

        claimableReferralBonusUsdc[inviter] += amount;
        _addWeight(inviter, level, weight, 1);

        if (line == 1) {
            emit ReferralBonusAdded(inviter, invitee, level, amount, weight);
        } else if (line == 2) {
            emit SecondLineBonusAdded(inviter, invitee, level, amount, weight);
        } else {
            emit ThirdLineBonusAdded(inviter, invitee, level, amount, weight);
        }
    }

    function _awardPrizePosition(
        address playerAddress,
        uint8 level,
        uint256 cellId,
        bool prizeCell
    ) internal override {
        if (!prizeCell) {
            return;
        }

        uint256 reward = (matrixPrizePools[level] * PRIZE_POSITION_BPS) / BPS;
        uint256 usdcReward = (matrixPrizePoolsUsdc[level] * PRIZE_POSITION_BPS) / BPS;

        if (reward > 0) {
            matrixPrizePools[level] -= reward;
            _creditPrize(playerAddress, level, reward);

            emit PrizePositionReached(
                playerAddress,
                level,
                cellId,
                reward,
                playerLevels[playerAddress][level].frozen
            );
        }

        if (usdcReward > 0) {
            matrixPrizePoolsUsdc[level] -= usdcReward;
            _creditPrizeUsdc(playerAddress, level, usdcReward);

            emit TokenPrizePositionReached(
                playerAddress,
                level,
                address(usdcToken),
                cellId,
                usdcReward,
                playerLevels[playerAddress][level].frozen
            );
        }
    }

    function _creditPrize(address playerAddress, uint8 level, uint256 amount) internal override {
        PlayerLevel storage state = playerLevels[playerAddress][level];
        Player storage player = players[playerAddress];

        if (state.frozen) {
            state.pendingPrize += amount;
            player.pendingPrize += amount;
            return;
        }

        state.claimablePrize += amount;
        player.claimablePrize += amount;
    }

    function _creditPrizeUsdc(address playerAddress, uint8 level, uint256 amount) internal override {
        PlayerLevel storage state = playerLevels[playerAddress][level];

        if (state.frozen) {
            pendingPrizeUsdcByLevel[playerAddress][level] += amount;
            pendingPrizeUsdc[playerAddress] += amount;
            return;
        }

        claimablePrizeUsdcByLevel[playerAddress][level] += amount;
        claimablePrizeUsdc[playerAddress] += amount;
    }
}
