part of '../views/utility_screens.dart';

class _MemberPreviewController extends GetxController {
  final WalletConnectService walletService;
  final String query;

  _MemberPreviewController({
    required this.walletService,
    required this.query,
  });

  final snapshot = Rxn<_MemberPreviewSnapshot>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Worker? _connectionWorker;
  Worker? _addressWorker;

  @override
  void onInit() {
    super.onInit();
    refreshPreview();
    _connectionWorker = ever<bool>(
      walletService.isConnected,
      (_) => refreshPreview(),
    );
    _addressWorker = ever<String>(
      walletService.currentAddress,
      (_) => refreshPreview(),
    );
  }

  @override
  void onClose() {
    _connectionWorker?.dispose();
    _addressWorker?.dispose();
    super.onClose();
  }

  Future<void> refreshPreview() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      snapshot.value = await _load();
    } catch (error) {
      errorMessage.value = error.toString();
      snapshot.value = _MemberPreviewSnapshot(
        query: query,
        normalizedAddress: ReferralLinkService.normalizeAddress(query),
        levels: const [],
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<_MemberPreviewSnapshot> _load() async {
    final normalized = ReferralLinkService.normalizeAddress(query);
    if (normalized.isEmpty) {
      return _MemberPreviewSnapshot(
        query: query,
        normalizedAddress: normalized,
        levels: const [],
      );
    }

    final result = <EasyGameLevelState>[];
    for (var level = 1; level <= easyGameLevelCount; level++) {
      try {
        result.add(
          await walletService.getEasyGameLevel(
            playerAddress: normalized,
            level: level,
          ),
        );
      } catch (_) {
        result.add(
          EasyGameLevelState(
            active: false,
            frozen: false,
            cycles: BigInt.zero,
            positionId: BigInt.zero,
            earnedWei: BigInt.zero,
          ),
        );
      }
    }

    return _MemberPreviewSnapshot(
      query: query,
      normalizedAddress: normalized,
      levels: result,
    );
  }
}
