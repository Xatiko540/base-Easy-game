// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../base/Types.sol";

interface IEasyGameRoundManager {
    function initializeAndRegisterEntry(
        RoundConfig calldata config,
        bytes calldata signature,
        address player
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
}
