// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../base/Types.sol";

interface IEasyGameRoundManager {
    function initializeAndRegisterEntry(
        RoundConfig calldata config,
        bytes calldata signature,
        address player,
        address inviter
    ) external returns (bytes32 configHash);

    function getRoundConfig(uint256 roundId)
        external
        view
        returns (RoundConfig memory);

    function getRoundState(uint256 roundId)
        external
        view
        returns (RoundState memory);

    function getRoundPhase(uint256 roundId) external view returns (RoundPhase);

    function markRoundSettled(uint256 roundId, uint16 winnersRegistered) external;

    function getSeasonState(uint256 seasonId)
        external
        view
        returns (SeasonState memory);

    function getCommittedRoundHash(uint256 seasonId, uint8 level)
        external
        view
        returns (bytes32);

    function getPlayerSeasonProgress(uint256 seasonId, address player)
        external
        view
        returns (
            bool started,
            uint8 startLevel,
            uint8 highestLevel,
            uint16 activatedLevels,
            uint32 directInvites,
            uint32 inviteCapacity
        );
}
