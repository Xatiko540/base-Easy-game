// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../base/Types.sol";

abstract contract RoundManagerStorage {
    address public owner;
    address public scheduleSigner;
    mapping(address => bool) public allowedScheduleSigners;
    address public gameCore;

    mapping(uint256 => RoundConfig) internal _roundConfigs;
    mapping(uint256 => RoundState) internal _roundStates;
    mapping(uint8 => uint256) public activeRoundByLevel;
}
