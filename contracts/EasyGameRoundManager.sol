// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./base/Types.sol";
import "./base/Errors.sol";
import "./base/RoundScheduleLogic.sol";

contract EasyGameRoundManager is RoundScheduleLogic {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ScheduleSignerChanged(address indexed oldSigner, address indexed newSigner);
    event ScheduleSignerPermissionChanged(address indexed signer, bool allowed);
    event GameCoreChanged(address indexed oldCore, address indexed newCore);
    event ArenaSkillsChanged(address indexed oldSkills, address indexed newSkills);
    event RoundPauseChanged(uint256 indexed roundId, bool paused);
    event RoundCancelled(uint256 indexed roundId);
    event SettlementContractChanged(address indexed oldSettlement, address indexed newSettlement);
    event RoundSettled(uint256 indexed roundId, uint16 winnersRegistered);
    event SystemContractsFinalized(
        address indexed gameCore,
        address indexed arenaSkills,
        address indexed settlementContract
    );

    address public settlementContract;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(address scheduleSigner_) {
        if (scheduleSigner_ == address(0)) revert ZeroAddress();
        owner = msg.sender;
        scheduleSigner = scheduleSigner_;
        allowedScheduleSigners[scheduleSigner_] = true;
    }

    function setGameCore(address newCore) external onlyOwner {
        if (systemContractsFinalized) revert SystemContractsAlreadyFinalized();
        if (newCore == address(0)) revert ZeroAddress();
        address oldCore = gameCore;
        gameCore = newCore;
        emit GameCoreChanged(oldCore, newCore);
    }

    function setArenaSkills(address newSkills) external onlyOwner {
        if (systemContractsFinalized) revert SystemContractsAlreadyFinalized();
        if (newSkills == address(0)) revert ZeroAddress();
        address oldSkills = arenaSkills;
        arenaSkills = newSkills;
        emit ArenaSkillsChanged(oldSkills, newSkills);
    }

    function setSettlementContract(address newSettlement) external onlyOwner {
        if (systemContractsFinalized) revert SystemContractsAlreadyFinalized();
        if (newSettlement == address(0)) revert ZeroAddress();
        address oldSettlement = settlementContract;
        settlementContract = newSettlement;
        emit SettlementContractChanged(oldSettlement, newSettlement);
    }

    /// @notice Permanently pins the contracts that may register entries,
    /// report freeze state, and settle prize pools.
    function finalizeSystemContracts() external onlyOwner {
        if (systemContractsFinalized) revert SystemContractsAlreadyFinalized();
        _requireDeployedContract(gameCore);
        _requireDeployedContract(arenaSkills);
        _requireDeployedContract(settlementContract);
        systemContractsFinalized = true;
        emit SystemContractsFinalized(gameCore, arenaSkills, settlementContract);
    }

    function _requireDeployedContract(address target) private view {
        if (target == address(0) || target.code.length == 0) {
            revert InvalidSystemContract(target);
        }
    }

    function markRoundSettled(uint256 roundId, uint16 winnersRegistered) external {
        if (!systemContractsFinalized) revert SystemContractsNotFinalized();
        require(msg.sender == settlementContract, "Only settlement");
        RoundState storage state = _roundStates[roundId];
        if (!state.initialized) revert RoundNotInitialized(roundId);
        if (state.settled) revert RoundAlreadySettled(roundId);
        require(getRoundPhase(roundId) == RoundPhase.SettlementReady, "Round is not ready");
        state.settled = true;
        state.winnersRegistered = winnersRegistered;
        state.paused = false;
        RoundConfig storage config = _roundConfigs[roundId];
        if (activeRoundByLevel[config.level] == roundId) {
            activeRoundByLevel[config.level] = 0;
        }
        emit RoundSettled(roundId, winnersRegistered);
    }

    function setScheduleSigner(address newSigner) external onlyOwner {
        if (newSigner == address(0)) revert ZeroAddress();
        address oldSigner = scheduleSigner;
        if (oldSigner == newSigner) return;
        allowedScheduleSigners[oldSigner] = false;
        scheduleSigner = newSigner;
        allowedScheduleSigners[newSigner] = true;
        emit ScheduleSignerChanged(oldSigner, newSigner);
        emit ScheduleSignerPermissionChanged(oldSigner, false);
        emit ScheduleSignerPermissionChanged(newSigner, true);
    }

    function setScheduleSignerAllowed(address signer, bool allowed) external onlyOwner {
        if (signer == address(0)) revert ZeroAddress();
        require(allowed || signer != scheduleSigner, "Cannot revoke current signer");
        allowedScheduleSigners[signer] = allowed;
        emit ScheduleSignerPermissionChanged(signer, allowed);
    }

    function setRoundPaused(uint256 roundId, bool paused) external onlyOwner {
        RoundState storage state = _roundStates[roundId];
        if (!state.initialized) revert RoundNotInitialized(roundId);
        if (state.settled) revert RoundAlreadySettled(roundId);
        state.paused = paused;
        emit RoundPauseChanged(roundId, paused);
    }

    function cancelRound(uint256 roundId) external onlyOwner {
        RoundState storage state = _roundStates[roundId];
        if (!state.initialized) revert RoundNotInitialized(roundId);
        if (state.settled) revert RoundAlreadySettled(roundId);
        require(state.occupiedCells == 0, "Round has entries");
        state.cancelled = true;
        state.paused = false;
        RoundConfig storage config = _roundConfigs[roundId];
        if (activeRoundByLevel[config.level] == roundId) {
            activeRoundByLevel[config.level] = 0;
        }
        emit RoundCancelled(roundId);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
}
