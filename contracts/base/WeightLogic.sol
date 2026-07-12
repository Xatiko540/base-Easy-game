// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./SharedGameplayLogic.sol";

abstract contract WeightLogic is SharedGameplayLogic {
    function _addWeight(
        address playerAddress,
        uint8 level,
        uint256 amount,
        uint8 weightType
    ) internal override {
        if (amount == 0) {
            return;
        }

        WeightBreakdown storage breakdown = _levelWeights[playerAddress][level];
        Player storage player = players[playerAddress];
        PlayerLevel storage state = playerLevels[playerAddress][level];

        uint256 accepted = amount;
        if (weightType == 0) {
            accepted = _acceptedWeight(
                breakdown.baseWeight,
                amount,
                MAX_BASE_WEIGHT_PER_LEVEL
            );
            accepted = _acceptedWeight(state.levelWeight, accepted, MAX_TOTAL_WEIGHT_PER_LEVEL);
            breakdown.baseWeight += accepted;
            player.baseWeight += accepted;
        } else if (weightType == 1) {
            accepted = _acceptedWeight(
                breakdown.referralWeight,
                amount,
                MAX_REFERRAL_WEIGHT_PER_LEVEL
            );
            accepted = _acceptedWeight(state.levelWeight, accepted, MAX_TOTAL_WEIGHT_PER_LEVEL);
            breakdown.referralWeight += accepted;
            player.referralWeight += accepted;
        } else if (weightType == 2) {
            accepted = _acceptedWeight(
                breakdown.loyaltyWeight,
                amount,
                MAX_LOYALTY_WEIGHT_PER_LEVEL
            );
            accepted = _acceptedWeight(state.levelWeight, accepted, MAX_TOTAL_WEIGHT_PER_LEVEL);
            breakdown.loyaltyWeight += accepted;
            player.loyaltyWeight += accepted;
        } else if (weightType == 3) {
            accepted = _acceptedWeight(
                breakdown.matrixWeight,
                amount,
                MAX_MATRIX_WEIGHT_PER_LEVEL
            );
            accepted = _acceptedWeight(state.levelWeight, accepted, MAX_TOTAL_WEIGHT_PER_LEVEL);
            breakdown.matrixWeight += accepted;
            player.matrixWeight += accepted;
        } else {
            accepted = _acceptedWeight(
                breakdown.nftWeight,
                amount,
                MAX_NFT_WEIGHT_PER_LEVEL
            );
            accepted = _acceptedWeight(state.levelWeight, accepted, MAX_TOTAL_WEIGHT_PER_LEVEL);
            breakdown.nftWeight += accepted;
            player.nftWeight += accepted;
        }

        if (accepted == 0) {
            return;
        }

        state.levelWeight += accepted;
        player.totalWeight += accepted;
        totalWeightByLevel[level] += accepted;

        emit WeightUpdated(playerAddress, level, state.levelWeight);
    }

    function _acceptedWeight(
        uint256 current,
        uint256 requested,
        uint256 cap
    ) internal pure override returns (uint256) {
        if (current >= cap) {
            return 0;
        }
        uint256 room = cap - current;
        return requested > room ? room : requested;
    }

}
