part of '../views/utility_screens.dart';

class _MatrixArenaController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final WalletAuthController authController = Get.find<WalletAuthController>();
  final GameRoundsController roundsController =
      Get.find<GameRoundsController>();
  final GameClockService clockService = Get.find<GameClockService>();
  final MatrixArenaRepository arenaRepository =
      Get.find<MatrixArenaRepository>();
  final GameContractEventsService contractEvents =
      Get.find<GameContractEventsService>();

  _MatrixArenaController();

  final selectedLevel = 1.obs;
  final availableLevels = <int>[].obs;
  final snapshot = _MatrixArenaSnapshot.empty(1).obs;
  final isLoading = false.obs;
  final isSkillActionRunning = false.obs;
  final isLoadingMoreParticipants = false.obs;
  final selectedOpponent = ''.obs;
  final errorMessage = ''.obs;

  Worker? _connectionWorker;
  Worker? _addressWorker;
  Worker? _chainWorker;
  Worker? _scheduleWorker;
  Worker? _timelineWorker;
  Worker? _authWorker;
  Worker? _eventWorker;
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
      (_) => _handleIdentityChange(),
    );
    _addressWorker = ever<String>(
      walletService.currentAddress,
      (_) => _handleIdentityChange(),
    );
    _chainWorker = ever<int?>(
      walletService.chainId,
      (_) => _handleIdentityChange(),
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
    _authWorker = ever<WalletAuthPhase>(
      authController.phase,
      (_) => _handleIdentityChange(),
    );
    _eventWorker = debounce<int>(
      contractEvents.eventRevision,
      (_) {
        final roundId = snapshot.value.roundId;
        if (roundId > BigInt.zero) arenaRepository.invalidateRound(roundId);
        unawaited(refreshArena());
      },
      time: const Duration(milliseconds: 700),
    );
  }

  @override
  void onClose() {
    _connectionWorker?.dispose();
    _addressWorker?.dispose();
    _chainWorker?.dispose();
    _scheduleWorker?.dispose();
    _timelineWorker?.dispose();
    _authWorker?.dispose();
    _eventWorker?.dispose();
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

  void _handleIdentityChange() {
    arenaRepository.clear();
    selectedOpponent.value = '';
    unawaited(_bootstrapArena());
  }

  Future<int> _findInitialLevel() async {
    if (!authController.isAuthenticated ||
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
        if (state?.active ?? false) {
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
    final baseValues = await Future.wait<Object?>([
      walletService.getRoundMatrixStats(roundId),
      walletService.getArenaFreezeTokenPriceUsdc(),
    ]);
    final stats = baseValues[0] as RoundMatrixStats? ?? RoundMatrixStats.zero;
    final freezeTokenPriceUsdc = baseValues[1] as BigInt;
    RoundPlayerState? playerRound;
    ArenaSkillStatus? playerSkill;
    EasyGamePlayerSummary? player;
    if (authController.isAuthenticated) {
      final playerValues = await Future.wait<Object?>([
        walletService.getRoundPlayerState(roundId),
        walletService.getEasyGamePlayerSummary(),
      ]);
      playerRound = playerValues[0] as RoundPlayerState?;
      player = playerValues[1] as EasyGamePlayerSummary?;
      if (playerRound?.active == true) {
        playerSkill = await walletService.getArenaSkillStatus(roundId);
      }
    }
    final roster = await arenaRepository.loadRosterPage(
      roundId: roundId,
      activeCells: stats.activeCells,
      currentPlayerCellId: playerRound?.cellId ?? BigInt.zero,
      page: 0,
    );
    final playerWeight = playerRound?.totalWeight ?? BigInt.zero;
    final weightShareBps = stats.totalWeight == BigInt.zero
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
      prizePoolUsdc: stats.prizePoolUsdc,
      nextCellId: stats.nextCellId,
      nextOpenParentId: stats.nextOpenParentId,
      playerCellId: playerRound?.cellId ?? BigInt.zero,
      playerActive: playerRound?.active ?? false,
      playerFrozen: playerSkill?.frozen ?? false,
      recycleCount: playerRound?.cycleCount ?? BigInt.zero,
      playerWeight: playerWeight,
      weightShareBps: weightShareBps,
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
      participants: roster.participants,
      playerSkillStatus: playerSkill,
      participantPage: roster.page,
      hasMoreParticipants: roster.hasMore,
    );
  }

  Future<void> loadMoreParticipants() async {
    final current = snapshot.value;
    if (!current.hasMoreParticipants ||
        current.roundId == BigInt.zero ||
        isLoadingMoreParticipants.value) {
      return;
    }
    isLoadingMoreParticipants.value = true;
    try {
      final page = await arenaRepository.loadRosterPage(
        roundId: current.roundId,
        activeCells: current.activeCells,
        currentPlayerCellId: current.playerCellId,
        page: current.participantPage + 1,
      );
      if (snapshot.value.roundId != current.roundId) return;
      final byCell = <BigInt, MatrixParticipant>{
        for (final participant in current.participants)
          participant.cellId: participant,
        for (final participant in page.participants)
          participant.cellId: participant,
      };
      final merged = byCell.values.toList()
        ..sort((left, right) => left.cellId.compareTo(right.cellId));
      snapshot.value = current.copyWith(
        participants: merged,
        participantPage: page.page,
        hasMoreParticipants: page.hasMore,
      );
    } finally {
      isLoadingMoreParticipants.value = false;
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
    if (selected?.isCurrentPlayer == true ||
        selected?.skillStatus?.immune == true) {
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

  Future<void> _runSkillAction(
    Future<String> Function() action,
    String title,
  ) async {
    if (snapshot.value.roundId == BigInt.zero) return;
    isSkillActionRunning.value = true;
    try {
      await Get.find<WalletAuthController>().ensureAuthenticated();
      final hash = await action();
      _showMessage(title, hash);
      arenaRepository.invalidateRound(snapshot.value.roundId);
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
