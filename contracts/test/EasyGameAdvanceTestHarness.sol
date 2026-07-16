// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../EasyGameAdvance.sol";

/// @dev Test-only harness for exercising bounded queue finalization.
contract EasyGameAdvanceTestHarness is EasyGameAdvance {
    constructor(
        address projectWallet_,
        address treasuryWallet_,
        address operatorWallet_,
        address usdcToken_,
        address roundManager_
    ) EasyGameAdvance(
        projectWallet_,
        treasuryWallet_,
        operatorWallet_,
        usdcToken_,
        roundManager_
    ) {}

    function forceQueueRoundRecycle(uint256 roundId, address player) external {
        _queueRoundRecycle(roundId, player);
    }
}
