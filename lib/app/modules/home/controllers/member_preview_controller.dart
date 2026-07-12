part of '../views/utility_screens.dart';

class _MemberPreviewController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final String query;
  late final FirebaseDataService _firebaseData;

  _MemberPreviewController({
    required this.query,
  });

  final snapshot = Rxn<_MemberPreviewSnapshot>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _firebaseData = Get.find<FirebaseDataService>();
    _firebaseData.init();
    refreshPreview();
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
    // Try to read from Firebase levels/events first
    // Fallback to direct contract call for each level
    for (var level = 1; level <= easyGameLevelCount; level++) {
      try {
        result.add(
          await walletService.getEasyGameLevel(
            playerAddress: normalized,
            level: level,
          ),
        );
      } catch (_) {
        result.add(EasyGameLevelState(
          active: false,
          frozen: false,
          cycles: BigInt.zero,
          positionId: BigInt.zero,
          earnedWei: BigInt.zero,
        ));
      }
    }

    return _MemberPreviewSnapshot(
      query: query,
      normalizedAddress: normalized,
      levels: result,
    );
  }
}
