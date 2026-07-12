part of '../views/utility_screens.dart';

class _MatrixArenaController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();

  _MatrixArenaController();

  final selectedLevel = 1.obs;
  final snapshot = _MatrixArenaSnapshot.empty(1).obs;
  final isLoading = false.obs;
  final isSkillActionRunning = false.obs;
  final selectedOpponent = ''.obs;
  final errorMessage = ''.obs;

  Worker? _connectionWorker;
  Worker? _addressWorker;
  Worker? _scheduleWorker;

  @override
  void onInit() {
    super.onInit();
    _bootstrapArena();
    _connectionWorker = ever<bool>(
      walletService.isConnected,
      (_) => _bootstrapArena(),
    );
    _addressWorker = ever<String>(
      walletService.currentAddress,
      (_) => _bootstrapArena(),
    );
    _scheduleWorker = ever<bool>(
      Get.find<GameRoundsController>().isScheduleReady,
      (ready) {
        if (ready) _bootstrapArena();
      },
    );
  }

  @override
  void onClose() {
    _connectionWorker?.dispose();
    _addressWorker?.dispose();
    _scheduleWorker?.dispose();
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

  Future<void> _bootstrapArena() async {
    final initialLevel = await _findInitialLevel();
    selectedLevel.value = initialLevel;
    await refreshArena();
  }

  Future<int> _findInitialLevel() async {
    if (!walletService.isConnected.value ||
        walletService.currentAddress.value.isEmpty) {
      return 1;
    }

    final roundsController = Get.find<GameRoundsController>();
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
    isLoading.value = true;
    errorMessage.value = '';
    try {
      snapshot.value = await _load(selectedLevel.value);
    } catch (error) {
      snapshot.value = _MatrixArenaSnapshot.empty(selectedLevel.value);
      errorMessage.value = '$error';
    } finally {
      isLoading.value = false;
    }
  }

  Future<_MatrixArenaSnapshot> _load(int level) async {
    final round = Get.find<GameRoundsController>().roundForLevel(level);
    if (round == null) return _MatrixArenaSnapshot.empty(level);
    final roundId = BigInt.from(round.schedule.roundId);
    final stats = await walletService.getRoundMatrixStats(roundId);
    RoundPlayerState? playerRound;
    ArenaSkillStatus? playerSkill;
    EasyGamePlayerSummary? player;
    if (walletService.isConnected.value) {
      playerRound = await walletService.getRoundPlayerState(roundId);
      player = await walletService.getEasyGamePlayerSummary();
      if (playerRound.active) {
        playerSkill = await walletService.getArenaSkillStatus(roundId);
      }
    }
    final count = math.min(stats.activeCells.toInt(), 15);
    final participants = <MatrixParticipant>[];
    for (var cell = 1; cell <= count; cell++) {
      final node = await walletService.getRoundMatrixNode(
        roundId,
        BigInt.from(cell),
      );
      final summary = await walletService.getEasyGamePlayerSummary(
        playerAddress: node.player,
      );
      ArenaSkillStatus? skill;
      try {
        skill = await walletService.getArenaSkillStatus(
          roundId,
          playerAddress: node.player,
        );
      } catch (_) {}
      participants.add(MatrixParticipant(
        cellId: node.cellId,
        wallet: node.player,
        isCurrentPlayer: node.player.toLowerCase() ==
            walletService.currentAddress.value.toLowerCase(),
        isInvited: player != null &&
            summary.inviter.toLowerCase() ==
                walletService.currentAddress.value.toLowerCase(),
        skillStatus: skill,
      ));
    }
    final playerWeight = playerRound?.totalWeight ?? BigInt.zero;
    final chanceBps = stats.totalWeight == BigInt.zero
        ? BigInt.zero
        : playerWeight * BigInt.from(10000) ~/ stats.totalWeight;
    final duration = round.schedule.endsAt.difference(round.schedule.startsAt);

    return _MatrixArenaSnapshot(
      level: level,
      roundId: roundId,
      priceWei: round.schedule.ethPriceWei,
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
      skillRules: _MatrixSkillRules.fromArena(
        prizePoolWei: stats.prizePoolEth,
        playerFrozen: playerSkill?.frozen ?? false,
        freezeLimit: round.schedule.freezeLimit,
        freezeHitsTaken: playerSkill?.freezeHits ?? 0,
        roundHours: duration.inHours,
      ),
      participants: participants,
      playerSkillStatus: playerSkill,
    );
  }

  Future<void> buyFreezeSkill() async {
    await _runSkillAction(
      () => walletService.buyArenaFreezeToken(snapshot.value.roundId),
      'matrix.freezeSkillTitle'.tr,
    );
  }

  Future<void> freezeClosestOpponent() async {
    String? target =
        selectedOpponent.value.isNotEmpty ? selectedOpponent.value : null;
    if (target == null) {
      for (final participant in snapshot.value.participants) {
        if (!participant.isCurrentPlayer) {
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

  void selectOpponent(String wallet) => selectedOpponent.value = wallet;

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
