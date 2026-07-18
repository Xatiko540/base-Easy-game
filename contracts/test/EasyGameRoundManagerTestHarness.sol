// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../EasyGameRoundManager.sol";

/// @dev Test-only helper. Production managers require a complete 17-round
/// season commitment; focused unit tests can pin one manifest at a time.
contract EasyGameRoundManagerTestHarness is EasyGameRoundManager {
    constructor(address scheduleSigner_)
        EasyGameRoundManager(scheduleSigner_)
    {}

    function forceCommitRoundConfig(RoundConfig calldata config) external {
        bytes32 configHash = hashRoundConfig(config);
        _seasonRoundConfigHashes[config.seasonId][config.level] = configHash;
        SeasonState storage season = _seasonStates[config.seasonId];
        season.configRoot = keccak256(
            abi.encodePacked(season.configRoot, configHash)
        );
        season.firstStartsAt = config.startsAt;
        season.lastEndsAt = config.endsAt;
        season.committed = true;
    }
}
