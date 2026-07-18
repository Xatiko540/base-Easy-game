// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../base/Types.sol";

struct PlayerSeasonProgress {
    bool started;
    uint8 startLevel;
    uint8 highestLevel;
    uint16 activatedLevels;
    uint32 directInvites;
}

abstract contract RoundManagerStorage {
    address public owner;
    address public scheduleSigner;
    mapping(address => bool) public allowedScheduleSigners;
    address public gameCore;
    address public arenaSkills;
    bool public systemContractsFinalized;

    mapping(uint256 => RoundConfig) internal _roundConfigs;
    mapping(uint256 => RoundState) internal _roundStates;
    mapping(uint8 => uint256) public activeRoundByLevel;
    mapping(uint256 => mapping(uint8 => uint256)) public roundBySeasonLevel;
    mapping(uint256 => mapping(address => PlayerSeasonProgress))
        internal _playerSeasonProgress;
    mapping(uint256 => mapping(address => bool)) public roundEntryRegistered;
    mapping(uint256 => mapping(address => mapping(address => bool)))
        public directInviteRegistered;
    mapping(uint256 => SeasonState) internal _seasonStates;
    mapping(uint256 => mapping(uint8 => bytes32))
        internal _seasonRoundConfigHashes;
    mapping(uint256 => uint256) internal _committedRoundSeason;
}
