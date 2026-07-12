// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";
import "./Errors.sol";
import "./Validation.sol";
import "../rounds/RoundManagerStorage.sol";

abstract contract RoundScheduleLogic is RoundManagerStorage {
    bytes32 public constant ROUND_CONFIG_TYPEHASH = keccak256(
        "RoundConfig(uint256 seasonId,uint256 roundId,uint8 level,uint64 startsAt,uint64 entriesCloseAt,uint64 endsAt,uint64 freezeClosesAt,uint32 maxPlayers,uint16 maxWinners,bytes32 winningCellsRoot,uint256 ethPrice,uint256 usdcPrice,uint16 freezeLimit,uint16 paymentSplitVersion)"
    );
    bytes32 private constant _EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 private constant _NAME_HASH = keccak256("EasyGameAdvance");
    bytes32 private constant _VERSION_HASH = keccak256("2");
    uint16 public constant CURRENT_PAYMENT_SPLIT_VERSION = 1;
    uint16 public constant MAX_WINNERS_PER_ROUND = 8;
    uint256 private constant _SECP256K1_HALF_ORDER =
        0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    event RoundInitialized(
        uint256 indexed seasonId,
        uint256 indexed roundId,
        uint8 indexed level,
        bytes32 configHash,
        uint64 startsAt,
        uint64 entriesCloseAt,
        uint64 endsAt
    );
    event RoundEntryRegistered(
        uint256 indexed roundId,
        address indexed player,
        uint32 occupiedCells
    );

    function domainSeparator() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                _EIP712_DOMAIN_TYPEHASH,
                _NAME_HASH,
                _VERSION_HASH,
                block.chainid,
                address(this)
            )
        );
    }

    function hashRoundConfig(RoundConfig calldata config)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                ROUND_CONFIG_TYPEHASH,
                config.seasonId,
                config.roundId,
                config.level,
                config.startsAt,
                config.entriesCloseAt,
                config.endsAt,
                config.freezeClosesAt,
                config.maxPlayers,
                config.maxWinners,
                config.winningCellsRoot,
                config.ethPrice,
                config.usdcPrice,
                config.freezeLimit,
                config.paymentSplitVersion
            )
        );
    }

    function roundConfigDigest(RoundConfig calldata config)
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19\x01", domainSeparator(), hashRoundConfig(config))
        );
    }

    function verifyRoundConfig(RoundConfig calldata config, bytes calldata signature)
        public
        view
        returns (bool)
    {
        _validateRoundConfig(config);
        return allowedScheduleSigners[
            _recoverSigner(roundConfigDigest(config), signature)
        ];
    }

    function initializeRound(RoundConfig calldata config, bytes calldata signature)
        external
        returns (bytes32 configHash)
    {
        return _initializeRound(config, signature);
    }

    function initializeAndRegisterEntry(
        RoundConfig calldata config,
        bytes calldata signature,
        address player
    ) external returns (bytes32 configHash) {
        require(msg.sender == gameCore, "Only game core");
        configHash = _initializeRound(config, signature);
        if (getRoundPhase(config.roundId) != RoundPhase.Open) {
            revert InvalidRoundTimeRange();
        }
        RoundState storage state = _roundStates[config.roundId];
        if (state.occupiedCells >= config.maxPlayers) {
            revert InvalidRoundCapacity();
        }
        state.occupiedCells += 1;
        emit RoundEntryRegistered(config.roundId, player, state.occupiedCells);
    }

    function getRoundConfig(uint256 roundId)
        external
        view
        returns (RoundConfig memory)
    {
        if (!_roundStates[roundId].initialized) revert RoundNotInitialized(roundId);
        return _roundConfigs[roundId];
    }

    function getRoundState(uint256 roundId)
        external
        view
        returns (RoundState memory)
    {
        return _roundStates[roundId];
    }

    function getRoundPhase(uint256 roundId) public view returns (RoundPhase) {
        RoundState storage state = _roundStates[roundId];
        if (!state.initialized) return RoundPhase.Uninitialized;
        if (state.cancelled) return RoundPhase.Cancelled;
        if (state.paused) return RoundPhase.Paused;
        if (state.settled) return RoundPhase.Settled;

        RoundConfig storage config = _roundConfigs[roundId];
        if (block.timestamp < config.startsAt) return RoundPhase.Scheduled;
        if (block.timestamp < config.entriesCloseAt) return RoundPhase.Open;
        if (block.timestamp < config.endsAt) return RoundPhase.Locked;
        return RoundPhase.SettlementReady;
    }

    function _initializeRound(RoundConfig calldata config, bytes calldata signature)
        internal
        returns (bytes32 configHash)
    {
        _validateRoundConfig(config);
        if (!allowedScheduleSigners[_recoverSigner(roundConfigDigest(config), signature)]) {
            revert InvalidScheduleSignature();
        }

        configHash = hashRoundConfig(config);
        RoundState storage state = _roundStates[config.roundId];
        if (state.initialized) {
            if (state.configHash != configHash) {
                revert RoundConfigMismatch(config.roundId);
            }
            return configHash;
        }


        uint256 existingRoundId = activeRoundByLevel[config.level];
        if (existingRoundId != 0 && existingRoundId != config.roundId) {
            RoundState storage existingState = _roundStates[existingRoundId];
            RoundConfig storage existingConfig = _roundConfigs[existingRoundId];
            if (
                !existingState.cancelled &&
                !existingState.settled &&
                existingConfig.endsAt > config.startsAt
            ) {
                revert RoundConfigMismatch(config.roundId);
            }
        }

        _roundConfigs[config.roundId] = config;
        state.configHash = configHash;
        state.initializedAt = uint64(block.timestamp);
        state.initialized = true;
        activeRoundByLevel[config.level] = config.roundId;

        emit RoundInitialized(
            config.seasonId,
            config.roundId,
            config.level,
            configHash,
            config.startsAt,
            config.entriesCloseAt,
            config.endsAt
        );
    }

    function _validateRoundConfig(RoundConfig calldata config) internal pure {
        if (config.seasonId == 0 || config.roundId == 0) {
            revert InvalidRoundId(config.roundId);
        }
        Validation.validateLevel(config.level);
        if (
            config.startsAt >= config.entriesCloseAt ||
            config.entriesCloseAt >= config.endsAt ||
            config.freezeClosesAt < config.startsAt ||
            config.freezeClosesAt > config.endsAt
        ) {
            revert InvalidRoundTimeRange();
        }
        if (
            config.maxPlayers == 0 ||
            config.maxWinners == 0 ||
            config.maxWinners > MAX_WINNERS_PER_ROUND ||
            config.freezeLimit == 0 ||
            config.winningCellsRoot == bytes32(0)
        ) {
            revert InvalidRoundCapacity();
        }
        if (config.ethPrice == 0 && config.usdcPrice == 0) {
            revert InvalidRoundPrice();
        }
        if (config.paymentSplitVersion != CURRENT_PAYMENT_SPLIT_VERSION) {
            revert InvalidPaymentSplitVersion(config.paymentSplitVersion);
        }
    }

    function _recoverSigner(bytes32 digest, bytes calldata signature)
        internal
        pure
        returns (address signer)
    {
        if (signature.length != 65) revert InvalidSignatureLength(signature.length);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := calldataload(signature.offset)
            s := calldataload(add(signature.offset, 32))
            v := byte(0, calldataload(add(signature.offset, 64)))
        }
        if (uint256(s) > _SECP256K1_HALF_ORDER) revert InvalidSignatureS();
        if (v != 27 && v != 28) revert InvalidSignatureV(v);

        signer = ecrecover(digest, v, r, s);
        if (signer == address(0)) revert InvalidScheduleSignature();
    }
}
