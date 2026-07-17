part of '../views/utility_screens.dart';

class _MatrixArenaController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final GameRoundsController roundsController = Get.find<GameRoundsController>();
  final GameClockService clockService = Get.find<GameClockService>();

  _MatrixArenaController();

  final selectedLevel = 1.obs;
  final availableLevels = <int>[].obs;
  final snapshot = _MatrixArenaSnapshot.empty(1).obs;
  final isLoading = false.obs;
  final isSkillActionRunning = false.obs;
  final selectedOpponent = ''.obs;
  final errorMessage = ''.obs;

  Worker? _connectionWorker;
  Worker? _addressWorker;
  Worker? _chainWorker;
  Worker? _scheduleWorker;
  Worker? _timelineWorker;
  int _loadRequest = 0;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    final requestedLevel = arguments is Map ? arguments['level'] : null;
    _bootstrapArena(
      requestedLevel is num ? requestedLevel.toInt() : null,
    );
    _connectionWorker = ever<bool>(
      walletService.isConnected,
      (_) => _bootstrapArena(),
    );
    _addressWorker = ever<String>(
      walletService.currentAddress,
      (_) => _bootstrapArena(),
    );
    _chainWorker = ever<int?>(
      walletService.chainId,
      (_) => _bootstrapArena(),
    );
    _scheduleWorker = ever<bool>(
      roundsController.isScheduleReady,
      (ready) {
        if (ready) _bootstrapArena();
      },
    );
    _timelineWorker = ever<List<GameRoundViewState>>(
      roundsController.timeline,
      (_) => _handleTimelineUpdate(),
    );
  }

  @override
  void onClose() {
    _connectionWorker?.dispose();
    _addressWorker?.dispose();
    _chainWorker?.dispose();
    _scheduleWorker?.dispose();
    _timelineWorker?.dispose();
    _loadRequest++;
    super.onClose();
  }

  Future<void> selectLevel(int level) async {
    if (selectedLevel.value == level) {
      return;
    }
    selectedLevel.value = level;
    selectedOpponent.value = '';
    await refreshArena();
  }

  Future<void> _bootstrapArena([int? requestedLevel]) async {
    _syncAvailableLevels();
    final hasRequestedRound = requestedLevel != null &&
        requestedLevel >= 1 &&
        requestedLevel <= easyGameLevelCount &&
        roundsController.roundForLevel(requestedLevel) != null;
    final initialLevel =
        hasRequestedRound ? requestedLevel : await _findInitialLevel();
    selectedLevel.value = initialLevel;
    await refreshArena();
  }

  Future<int> _findInitialLevel() async {
    if (!walletService.isConnected.value ||
        walletService.currentAddress.value.isEmpty) {
      return 1;
    }

    final levels = roundsController.roundsByLevel.keys.toList()
      ..sort((left, right) => right.compareTo(left));
    for (final level in levels) {
      final round = roundsController.roundForLevel(level);
      if (round == null) continue;
      try {
        final state = await walletService.getRoundPlayerState(
          BigInt.from(round.schedule.roundId),
        );
        if (state.active) {
          return level;
        }
      } catch (_) {
        continue;
      }
    }
    return 1;
  }

  Future<void> refreshArena() async {
    final request = ++_loadRequest;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final next = await _load(selectedLevel.value);
      if (request != _loadRequest) return;
      snapshot.value = next;
      _validateSelectedOpponent(next);
    } catch (error) {
      if (request != _loadRequest) return;
      errorMessage.value = '$error';
    } finally {
      if (request == _loadRequest) isLoading.value = false;
    }
  }

  Future<_MatrixArenaSnapshot> _load(int level) async {
    final round = roundsController.roundForLevel(level);
    if (round == null) return _MatrixArenaSnapshot.empty(level);
    final roundId = BigInt.from(round.schedule.roundId);
    final baseValues = await Future.wait<Object>([
      walletService.getRoundMatrixStats(roundId),
      walletService.getArenaFreezeTokenPriceUsdc(),
    ]);
    final stats = baseValues[0] as RoundMatrixStats;
    final freezeTokenPriceUsdc = baseValues[1] as BigInt;
    RoundPlayerState? playerRound;
    ArenaSkillStatus? playerSkill;
    EasyGamePlayerSummary? player;
    if (walletService.isConnected.value) {
      final playerValues = await Future.wait<Object>([
        walletService.getRoundPlayerState(roundId),
        walletService.getEasyGamePlayerSummary(),
      ]);
      playerRound = playerValues[0] as RoundPlayerState;
      player = playerValues[1] as EasyGamePlayerSummary;
      if (playerRound.active) {
        playerSkill = await walletService.getArenaSkillStatus(roundId);
      }
    }
    final count = math.min(stats.activeCells.toInt(), 15);
    final participantResults = await Future.wait([
      for (var cell = 1; cell <= count; cell++)
        _loadParticipant(roundId, cell),
    ]);
    final participants = participantResults
        .whereType<MatrixParticipant>()
        .toList(growable: false);
    final playerWeight = playerRound?.totalWeight ?? BigInt.zero;
    final chanceBps = stats.totalWeight == BigInt.zero
        ? BigInt.zero
        : playerWeight * BigInt.from(10000) ~/ stats.totalWeight;
    final now = clockService.chainTime.value.toUtc();
    final freezeWindowOpen = round.isConfigurationTrusted &&
        (round.phase == GameRoundPhase.open ||
            round.phase == GameRoundPhase.locked) &&
        !now.isBefore(round.schedule.startsAt.toUtc()) &&
        now.isBefore(round.schedule.freezeClosesAt.toUtc());

    return _MatrixArenaSnapshot(
      level: level,
      roundId: roundId,
      priceWei: round.ethPriceWei,
      activeCells: stats.activeCells,
      totalWeight: stats.totalWeight,
      prizePoolWei: stats.prizePoolEth,
      nextCellId: stats.nextCellId,
      nextOpenParentId: stats.nextOpenParentId,
      playerCellId: playerRound?.cellId ?? BigInt.zero,
      playerActive: playerRound?.active ?? false,
      playerFrozen: playerSkill?.frozen ?? false,
      recycleCount: playerRound?.cycleCount ?? BigInt.zero,
      playerWeight: playerWeight,
      chanceBps: chanceBps,
      boxTokens: player?.boxTokens ?? BigInt.zero,
      maxPlayers: round.schedule.maxPlayers,
      phase: round.phase,
      freezeClosesAt: round.schedule.freezeClosesAt,
      freezeWindowOpen: freezeWindowOpen,
      freezeTokenPriceUsdc: freezeTokenPriceUsdc,
      skillRules: _MatrixSkillRules.fromArena(
        freezeLimit: round.schedule.freezeLimit,
        freezeHitsTaken: playerSkill?.freezeHits ?? 0,
      ),
      participants: participants,
      playerSkillStatus: playerSkill,
    );
  }

  Future<MatrixParticipant?> _loadParticipant(
    BigInt roundId,
    int cell,
  ) async {
    try {
      final node = await walletService.getRoundMatrixNode(
        roundId,
        BigInt.from(cell),
      );
      if (_isZeroAddress(node.player)) return null;
      final values = await Future.wait<Object?>([
        _safePlayerSummary(node.player),
        _safeSkillStatus(roundId, node.player),
      ]);
      final summary = values[0] as EasyGamePlayerSummary?;
      final skill = values[1] as ArenaSkillStatus?;
      final current = walletService.currentAddress.value.toLowerCase();
      return MatrixParticipant(
        cellId: node.cellId,
        wallet: node.player,
        isCurrentPlayer:
            current.isNotEmpty && node.player.toLowerCase() == current,
        isInvited: current.isNotEmpty &&
            summary?.inviter.toLowerCase() == current,
        skillStatus: skill,
      );
    } catch (_) {
      return null;
    }
  }

  Future<EasyGamePlayerSummary?> _safePlayerSummary(String player) async {
    try {
      return await walletService.getEasyGamePlayerSummary(
        playerAddress: player,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ArenaSkillStatus?> _safeSkillStatus(
    BigInt roundId,
    String player,
  ) async {
    try {
      return await walletService.getArenaSkillStatus(
        roundId,
        playerAddress: player,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> buyFreezeSkill() async {
    if (!snapshot.value.canUseFreezeSkills) {
      _showMessage('matrix.freezeSkillTitle'.tr, 'matrix.freezeUnavailable'.tr);
      return;
    }
    await _runSkillAction(
      () => walletService.buyArenaFreezeToken(snapshot.value.roundId),
      'matrix.freezeSkillTitle'.tr,
    );
  }

  Future<void> freezeClosestOpponent() async {
    if (!snapshot.value.canUseFreezeSkills) {
      _showMessage(
        'matrix.freezeOpponentTitle'.tr,
        'matrix.freezeUnavailable'.tr,
      );
      return;
    }
    String? target =
        selectedOpponent.value.isNotEmpty ? selectedOpponent.value : null;
    final selected = _participantByWallet(target);
    if (selected?.isCurrentPlayer == true || selected?.skillStatus?.immune == true) {
      target = null;
    }
    if (target == null) {
      for (final participant in snapshot.value.participants) {
        if (!participant.isCurrentPlayer &&
            participant.skillStatus?.immune != true) {
          target = participant.wallet;
          break;
        }
      }
    }
    if (target == null) {
      _showMessage('matrix.freezeOpponentTitle'.tr, 'matrix.noOpponent'.tr);
      return;
    }
    await _runSkillAction(
      () => walletService.freezeArenaPlayer(snapshot.value.roundId, target!),
      'matrix.freezeOpponentTitle'.tr,
    );
  }

  Future<void> buyUnfreezeSkill() async {
    await _runSkillAction(
      () => walletService.buyArenaUnfreeze(snapshot.value.roundId),
      'matrix.unfreezeSkillTitle'.tr,
    );
  }

  void selectOpponent(String wallet) {
    final participant = _participantByWallet(wallet);
    if (participant == null ||
        participant.isCurrentPlayer ||
        participant.skillStatus?.immune == true) {
      return;
    }
    selectedOpponent.value = wallet;
  }

  MatrixParticipant? _participantByWallet(String? wallet) {
    if (wallet == null || wallet.isEmpty) return null;
    final normalized = wallet.toLowerCase();
    for (final participant in snapshot.value.participants) {
      if (participant.wallet.toLowerCase() == normalized) return participant;
    }
    return null;
  }

  void _validateSelectedOpponent(_MatrixArenaSnapshot next) {
    final normalized = selectedOpponent.value.toLowerCase();
    if (normalized.isEmpty) return;
    final valid = next.participants.any(
      (participant) =>
          participant.wallet.toLowerCase() == normalized &&
          !participant.isCurrentPlayer &&
          participant.skillStatus?.immune != true,
    );
    if (!valid) selectedOpponent.value = '';
  }

  void _syncAvailableLevels() {
    final levels = roundsController.roundsByLevel.keys.toList()..sort();
    final unchanged = availableLevels.length == levels.length &&
        List.generate(levels.length, (index) => index)
            .every((index) => availableLevels[index] == levels[index]);
    if (!unchanged) {
      availableLevels.assignAll(levels);
    }
  }

  void _handleTimelineUpdate() {
    _syncAvailableLevels();
    final round = roundsController.roundForLevel(selectedLevel.value);
    final nextRoundId = round?.schedule.roundId ?? 0;
    final now = clockService.chainTime.value.toUtc();
    final nextFreezeOpen = round != null &&
        round.isConfigurationTrusted &&
        (round.phase == GameRoundPhase.open ||
            round.phase == GameRoundPhase.locked) &&
        now.isBefore(round.schedule.freezeClosesAt.toUtc());
    if (snapshot.value.roundId != BigInt.from(nextRoundId) ||
        snapshot.value.phase !=
            (round?.phase ?? GameRoundPhase.uninitialized) ||
        snapshot.value.freezeWindowOpen != nextFreezeOpen) {
      refreshArena();
    }
  }

  bool _isZeroAddress(String address) =>
      RegExp(r'^0x0{40}$', caseSensitive: false).hasMatch(address);

  Future<void> _runSkillAction(
    Future<String> Function() action,
    String title,
  ) async {
    if (snapshot.value.roundId == BigInt.zero) return;
    isSkillActionRunning.value = true;
    try {
      final hash = await action();
      _showMessage(title, hash);
      await refreshArena();
    } catch (error) {
      _showMessage(title, '$error');
    } finally {
      isSkillActionRunning.value = false;
    }
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: EasyGameTheme.cardDark,
      colorText: Colors.white,
      borderColor: EasyGameTheme.teal.withValues(alpha: 0.35),
      borderWidth: 1,
    );
  }
}
