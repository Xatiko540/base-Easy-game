// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";
import "./Errors.sol";
import "./Validation.sol";
import "../rounds/RoundManagerStorage.sol";

interface IEasyGameArenaProgression {
    function isFrozen(uint256 roundId, address player)
        external
        view
        returns (bool);
}

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
    uint32 public constant MAX_PLAYERS_PER_ROUND = 1_000_000;
    uint64 public constant MIN_LEVEL_OPEN_INTERVAL = 5 hours;
    uint64 public constant MIN_ROUND_DURATION = 1 hours;
    uint32 public constant DIRECT_INVITES_PER_LEVEL = 4;
    uint8 public constant SEASON_LEVEL_COUNT = 17;
    uint256 public constant MAX_ETH_PRICE = 1_000 ether;
    uint256 public constant MAX_USDC_PRICE = 1_000_000_000 * 1e6;
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
    event PlayerSeasonStarted(
        uint256 indexed seasonId,
        address indexed player,
        uint8 startLevel
    );
    event PlayerSeasonAdvanced(
        uint256 indexed seasonId,
        address indexed player,
        uint8 level,
        uint16 activatedLevels
    );
    event DirectInviteRegistered(
        uint256 indexed seasonId,
        address indexed inviter,
        address indexed invitee,
        uint32 used,
        uint32 capacity
    );
    event SeasonCommitted(
        uint256 indexed seasonId,
        bytes32 indexed configRoot,
        uint64 firstStartsAt,
        uint64 lastEndsAt
    );

    /// @notice Commits the complete, ordered 17-round season before any round
    /// can be initialized. Firebase may distribute these manifests, but the
    /// chain independently verifies completeness, signatures, and spacing.
    function commitSeason(
        RoundConfig[] calldata configs,
        bytes[] calldata signatures
    ) external returns (bytes32 configRoot) {
        if (!systemContractsFinalized) revert SystemContractsNotFinalized();
        if (
            configs.length != SEASON_LEVEL_COUNT ||
            signatures.length != SEASON_LEVEL_COUNT
        ) {
            revert InvalidSeasonRoundCount(
                configs.length,
                SEASON_LEVEL_COUNT
            );
        }

        uint256 seasonId = configs[0].seasonId;
        if (_seasonStates[seasonId].committed) {
            revert SeasonAlreadyCommitted(seasonId);
        }

        configRoot = keccak256(
            abi.encodePacked(seasonId, SEASON_LEVEL_COUNT)
        );
        uint64 lastEndsAt = configs[0].endsAt;
        for (uint256 i = 0; i < SEASON_LEVEL_COUNT; i++) {
            RoundConfig calldata config = configs[i];
            uint8 expectedLevel = uint8(i + 1);
            if (config.level != expectedLevel) {
                revert InvalidSeasonLevel(expectedLevel, config.level);
            }
            if (config.seasonId != seasonId) {
                revert SeasonRoundConfigMismatch(seasonId, expectedLevel);
            }
            if (_committedRoundSeason[config.roundId] != 0) {
                revert DuplicateSeasonRoundId(config.roundId);
            }
            _validateRoundConfig(config);
            if (
                !allowedScheduleSigners[
                    _recoverSigner(
                        roundConfigDigest(config),
                        signatures[i]
                    )
                ]
            ) {
                revert InvalidScheduleSignature();
            }
            if (
                i > 0 &&
                config.startsAt <
                    configs[i - 1].startsAt + MIN_LEVEL_OPEN_INTERVAL
            ) {
                revert LevelOpeningIntervalTooShort(
                    seasonId,
                    expectedLevel - 1,
                    expectedLevel
                );
            }
            bytes32 configHash = hashRoundConfig(config);
            _committedRoundSeason[config.roundId] = seasonId;
            _seasonRoundConfigHashes[seasonId][expectedLevel] = configHash;
            configRoot = keccak256(
                abi.encodePacked(configRoot, configHash)
            );
            if (config.endsAt > lastEndsAt) {
                lastEndsAt = config.endsAt;
            }
        }

        _seasonStates[seasonId] = SeasonState({
            configRoot: configRoot,
            firstStartsAt: configs[0].startsAt,
            lastEndsAt: lastEndsAt,
            committed: true
        });
        emit SeasonCommitted(
            seasonId,
            configRoot,
            configs[0].startsAt,
            lastEndsAt
        );
    }

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
        address player,
        address inviter
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
        if (roundEntryRegistered[config.roundId][player]) {
            revert RoundEntryAlreadyRegistered(config.roundId, player);
        }
        _registerPlayerProgression(config, player, inviter);
        roundEntryRegistered[config.roundId][player] = true;
        state.occupiedCells += 1;
        emit RoundEntryRegistered(config.roundId, player, state.occupiedCells);
    }

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
        )
    {
        PlayerSeasonProgress memory progress =
            _playerSeasonProgress[seasonId][player];
        return (
            progress.started,
            progress.startLevel,
            progress.highestLevel,
            progress.activatedLevels,
            progress.directInvites,
            uint32(progress.activatedLevels) * DIRECT_INVITES_PER_LEVEL
        );
    }

    function getEntryEligibility(
        uint256 seasonId,
        uint8 level,
        address player
    ) external view returns (
        uint8 reason,
        uint8 requiredLevel,
        uint256 blockingRoundId
    ) {
        PlayerSeasonProgress memory progress =
            _playerSeasonProgress[seasonId][player];
        if (!progress.started) return (0, 0, 0);
        if (level <= progress.highestLevel) return (1, progress.highestLevel, 0);

        requiredLevel = progress.highestLevel + 1;
        if (level != requiredLevel) return (2, requiredLevel, 0);

        blockingRoundId = roundBySeasonLevel[seasonId][progress.highestLevel];
        if (
            arenaSkills != address(0) &&
            IEasyGameArenaProgression(arenaSkills).isFrozen(
                blockingRoundId,
                player
            )
        ) {
            return (3, requiredLevel, blockingRoundId);
        }
        return (0, requiredLevel, 0);
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

    function getSeasonState(uint256 seasonId)
        external
        view
        returns (SeasonState memory)
    {
        return _seasonStates[seasonId];
    }

    function getCommittedRoundHash(uint256 seasonId, uint8 level)
        external
        view
        returns (bytes32)
    {
        Validation.validateLevel(level);
        return _seasonRoundConfigHashes[seasonId][level];
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
        // Manifests may be published in advance, but a third party must not be
        // able to make a future round the active round for its level early.
        if (block.timestamp < config.startsAt) {
            revert RoundNotStarted(config.roundId);
        }
        if (!allowedScheduleSigners[_recoverSigner(roundConfigDigest(config), signature)]) {
            revert InvalidScheduleSignature();
        }

        configHash = hashRoundConfig(config);
        if (!_seasonStates[config.seasonId].committed) {
            revert SeasonNotCommitted(config.seasonId);
        }
        if (
            _seasonRoundConfigHashes[config.seasonId][config.level] !=
            configHash
        ) {
            revert SeasonRoundConfigMismatch(
                config.seasonId,
                config.level
            );
        }
        RoundState storage state = _roundStates[config.roundId];
        if (state.initialized) {
            if (state.configHash != configHash) {
                revert RoundConfigMismatch(config.roundId);
            }
            return configHash;
        }

        _validateSeasonLevelSchedule(config);


        uint256 existingRoundId = activeRoundByLevel[config.level];
        if (existingRoundId != 0 && existingRoundId != config.roundId) {
            RoundState storage existingState = _roundStates[existingRoundId];
            RoundConfig storage existingConfig = _roundConfigs[existingRoundId];
            bool overlaps =
                config.startsAt < existingConfig.endsAt &&
                existingConfig.startsAt < config.endsAt;
            if (!existingState.cancelled && !existingState.settled && overlaps) {
                revert RoundConfigMismatch(config.roundId);
            }
        }

        _roundConfigs[config.roundId] = config;
        state.configHash = configHash;
        state.initializedAt = uint64(block.timestamp);
        state.initialized = true;
        activeRoundByLevel[config.level] = config.roundId;
        roundBySeasonLevel[config.seasonId][config.level] = config.roundId;

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
            config.freezeClosesAt != config.endsAt ||
            config.endsAt - config.startsAt < MIN_ROUND_DURATION
        ) {
            revert InvalidRoundTimeRange();
        }
        if (
            config.maxPlayers == 0 ||
            config.maxPlayers > MAX_PLAYERS_PER_ROUND ||
            config.maxWinners == 0 ||
            config.maxWinners > MAX_WINNERS_PER_ROUND ||
            config.winningCellsRoot == bytes32(0)
        ) {
            revert InvalidRoundCapacity();
        }
        uint16 expectedFreezeLimit = uint16(
            ((config.endsAt - config.startsAt + 1 days - 1) / 1 days) * 10
        );
        if (config.freezeLimit != expectedFreezeLimit) {
            revert InvalidFreezeLimit(expectedFreezeLimit, config.freezeLimit);
        }
        if (config.ethPrice == 0 && config.usdcPrice == 0) {
            revert InvalidRoundPrice();
        }
        if (
            config.ethPrice > MAX_ETH_PRICE ||
            config.usdcPrice > MAX_USDC_PRICE
        ) {
            revert InvalidRoundPrice();
        }
        if (config.paymentSplitVersion != CURRENT_PAYMENT_SPLIT_VERSION) {
            revert InvalidPaymentSplitVersion(config.paymentSplitVersion);
        }
    }

    function _validateSeasonLevelSchedule(RoundConfig calldata config)
        private
        view
    {
        uint256 configured = roundBySeasonLevel[config.seasonId][config.level];
        if (configured != 0 && configured != config.roundId) {
            RoundState storage configuredState = _roundStates[configured];
            if (!configuredState.cancelled || configuredState.occupiedCells != 0) {
                revert SeasonLevelAlreadyConfigured(config.seasonId, config.level);
            }
        }

        if (config.level > 1) {
            uint256 lowerRoundId =
                roundBySeasonLevel[config.seasonId][config.level - 1];
            if (
                lowerRoundId != 0 &&
                config.startsAt <
                    _roundConfigs[lowerRoundId].startsAt + MIN_LEVEL_OPEN_INTERVAL
            ) {
                revert LevelOpeningIntervalTooShort(
                    config.seasonId,
                    config.level - 1,
                    config.level
                );
            }
        }
        if (config.level < 17) {
            uint256 upperRoundId =
                roundBySeasonLevel[config.seasonId][config.level + 1];
            if (
                upperRoundId != 0 &&
                _roundConfigs[upperRoundId].startsAt <
                    config.startsAt + MIN_LEVEL_OPEN_INTERVAL
            ) {
                revert LevelOpeningIntervalTooShort(
                    config.seasonId,
                    config.level,
                    config.level + 1
                );
            }
        }
    }

    function _registerPlayerProgression(
        RoundConfig calldata config,
        address player,
        address inviter
    ) private {
        PlayerSeasonProgress storage progress =
            _playerSeasonProgress[config.seasonId][player];
        bool startsSeason = !progress.started;

        if (startsSeason) {
            progress.started = true;
            progress.startLevel = config.level;
            progress.highestLevel = config.level;
            progress.activatedLevels = 1;
            emit PlayerSeasonStarted(config.seasonId, player, config.level);
        } else {
            if (progress.highestLevel == 17) {
                revert InvalidPlayerLevelProgression(17, config.level);
            }
            uint8 requiredLevel = progress.highestLevel + 1;
            if (config.level != requiredLevel) {
                revert InvalidPlayerLevelProgression(
                    requiredLevel,
                    config.level
                );
            }
            if (arenaSkills == address(0)) revert ArenaSkillsNotConfigured();
            uint256 previousRoundId =
                roundBySeasonLevel[config.seasonId][progress.highestLevel];
            if (
                IEasyGameArenaProgression(arenaSkills).isFrozen(
                    previousRoundId,
                    player
                )
            ) {
                revert PlayerProgressionFrozen(previousRoundId, player);
            }
            progress.highestLevel = config.level;
            progress.activatedLevels += 1;
            emit PlayerSeasonAdvanced(
                config.seasonId,
                player,
                config.level,
                progress.activatedLevels
            );
        }

        if (
            startsSeason &&
            inviter != address(0) &&
            !directInviteRegistered[config.seasonId][inviter][player]
        ) {
            PlayerSeasonProgress storage inviterProgress =
                _playerSeasonProgress[config.seasonId][inviter];
            if (!inviterProgress.started) {
                revert ReferralInviterNotActive(inviter, config.seasonId);
            }
            uint32 capacity =
                uint32(inviterProgress.activatedLevels) *
                DIRECT_INVITES_PER_LEVEL;
            if (inviterProgress.directInvites >= capacity) {
                revert ReferralCapacityReached(
                    inviter,
                    inviterProgress.directInvites,
                    capacity
                );
            }
            directInviteRegistered[config.seasonId][inviter][player] = true;
            inviterProgress.directInvites += 1;
            emit DirectInviteRegistered(
                config.seasonId,
                inviter,
                player,
                inviterProgress.directInvites,
                capacity
            );
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
