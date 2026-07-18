part of '../views/utility_screens.dart';

class _MemberPreviewController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final GameRoundsRepository _rounds = Get.find<GameRoundsRepository>();
  final String query;

  _MemberPreviewController({required this.query});

  final snapshot = Rxn<_MemberPreviewSnapshot>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Worker? _roundsWorker;
  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    _roundsWorker = ever<Map<int, int>>(
      _rounds.selectedRoundIds,
      (_) => refreshPreview(),
    );
    refreshPreview();
  }

  @override
  void onClose() {
    _requestId++;
    _roundsWorker?.dispose();
    super.onClose();
  }

  Future<void> refreshPreview() async {
    final requestId = ++_requestId;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final next = await _load();
      if (!isClosed && requestId == _requestId) snapshot.value = next;
    } catch (error) {
      if (!isClosed && requestId == _requestId) {
        errorMessage.value = error.toString();
      }
    } finally {
      if (!isClosed && requestId == _requestId) isLoading.value = false;
    }
  }

  Future<_MemberPreviewSnapshot> _load() async {
    final normalized = ReferralLinkService.normalizeAddress(query);
    if (normalized.isEmpty) {
      return _MemberPreviewSnapshot(
        query: query,
        normalizedAddress: normalized,
        rounds: const [],
        claimableEth: BigInt.zero,
      );
    }

    final rounds = _rounds.roundsByLevel.values.toList(growable: false);
    final states = await Future.wait(
      rounds.map((round) => _loadPlayerRound(round, normalized)),
    );
    final rewards = await walletService.getSettlementClaimable(
      playerAddress: normalized,
    );
    return _MemberPreviewSnapshot(
      query: query,
      normalizedAddress: normalized,
      rounds: states,
      claimableEth: rewards.ethAmount,
    );
  }

  Future<_MemberPreviewRoundState> _loadPlayerRound(
    GameRoundViewState round,
    String playerAddress,
  ) async {
    final roundId = BigInt.from(round.schedule.roundId);
    try {
      final player = await walletService.getRoundPlayerState(roundId);
      if (player == null || !player.active) return const _MemberPreviewRoundState();
      var frozen = false;
      try {
        frozen = (await walletService.getArenaSkillStatus(roundId))?.frozen ?? false;
      } catch (_) {}
      return _MemberPreviewRoundState(active: true, frozen: frozen);
    } catch (_) {
      return const _MemberPreviewRoundState();
    }
  }
}
