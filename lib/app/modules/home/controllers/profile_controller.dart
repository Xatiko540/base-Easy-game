import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_settlement_models.dart';
import 'package:lottery_advance/app/models/game_transaction_model.dart';
import 'package:lottery_advance/app/models/wallet_auth_models.dart';
import 'package:lottery_advance/app/modules/home/models/profile_models.dart';
import 'package:lottery_advance/app/modules/home/controllers/wallet_auth_controller.dart';
import 'package:lottery_advance/app/modules/home/models/round_level_card_state.dart';
import 'package:lottery_advance/app/repositories/game_rounds_repository.dart';
import 'package:lottery_advance/app/repositories/round_levels_repository.dart';
import 'package:lottery_advance/app/services/firebase_backend_service.dart';
import 'package:lottery_advance/app/services/game_settlement_service.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final WalletAuthController authController = Get.find<WalletAuthController>();
  final RoundLevelsRepository _roundLevels = Get.find<RoundLevelsRepository>();
  final GameRoundsRepository _rounds = Get.find<GameRoundsRepository>();
  final GameSettlementService _settlement = Get.find<GameSettlementService>();
  final FirebaseBackendService _backend = Get.find<FirebaseBackendService>();

  final dashboard = ProfileDashboardSnapshot.empty().obs;
  final isLoading = false.obs;
  final isClaimingPrize = false.obs;
  final isClaimingReferral = false.obs;
  final isClaimingReferralUsdc = false.obs;
  final errorMessage = ''.obs;
  final transactionsError = ''.obs;

  final List<Worker> _workers = [];
  StreamSubscription<List<GameTransaction>>? _transactionsSubscription;
  int _refreshRun = 0;

  bool get isWalletConnected => authController.isAuthenticated;

  bool get isGameRegistered => dashboard.value.player?.exists == true;

  String get referralLink => ReferralLinkService.buildReferralLink(
        walletService.currentAddress.value,
      );

  String get profileId {
    final normalized = ReferralLinkService.normalizeAddress(
      walletService.currentAddress.value,
    );
    if (normalized.isEmpty) return '------';
    final numeric =
        BigInt.parse(normalized.substring(2), radix: 16) % BigInt.from(1000000);
    return numeric.toString().padLeft(6, '0');
  }

  @override
  void onInit() {
    super.onInit();
    _workers.addAll([
      ever<bool>(walletService.isConnected, (_) => _handleIdentityChange()),
      ever<String>(
          walletService.currentAddress, (_) => _handleIdentityChange()),
      ever<int?>(walletService.chainId, (_) => _handleIdentityChange()),
      ever<WalletAuthPhase>(
          authController.phase, (_) => _handleIdentityChange()),
      ever<Map<int, int>>(_rounds.selectedRoundIds, (_) => refreshDashboard()),
      ever<bool>(_backend.isReady, (ready) {
        if (ready) _subscribeToTransactions();
      }),
    ]);
    _subscribeToTransactions();
    unawaited(refreshDashboard());
  }

  @override
  void onClose() {
    _refreshRun++;
    _transactionsSubscription?.cancel();
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }

  void _handleIdentityChange() {
    if (isClosed) return;
    dashboard.value = ProfileDashboardSnapshot.empty();
    _subscribeToTransactions();
    unawaited(refreshDashboard());
  }

  void _subscribeToTransactions() {
    _transactionsSubscription?.cancel();
    transactionsError.value = '';
    if (!isWalletConnected || !_backend.isReady.value) {
      dashboard.value = dashboard.value.copyWith(transactions: const []);
      return;
    }

    _transactionsSubscription = _backend
        .watchRecentTransactions(
      chainId: walletService.chainId.value,
      wallet: walletService.currentAddress.value,
    )
        .listen(
      (transactions) {
        if (isClosed) return;
        dashboard.value = dashboard.value.copyWith(transactions: transactions);
      },
      onError: (Object error) {
        if (isClosed) return;
        transactionsError.value = error.toString();
      },
    );
  }

  Future<void> refreshDashboard() async {
    final run = ++_refreshRun;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final snapshot = await _loadDashboard();
      if (isClosed || run != _refreshRun) return;
      dashboard.value = snapshot.copyWith(
        transactions: dashboard.value.transactions,
      );
    } catch (error) {
      if (isClosed || run != _refreshRun) return;
      errorMessage.value = error.toString();
    } finally {
      if (!isClosed && run == _refreshRun) isLoading.value = false;
    }
  }

  void copyReferralLink() {
    if (!isWalletConnected) {
      _showWalletRequired();
      return;
    }
    Clipboard.setData(ClipboardData(text: referralLink));
    Get.snackbar(
      'common.copy'.tr,
      referralLink,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> shareReferralLink() async {
    if (!isWalletConnected) {
      _showWalletRequired();
      return;
    }
    final url = Uri.parse(referralLink);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }
    Get.snackbar(
      'common.linkUnavailable'.tr,
      referralLink,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void copyContractAddress() {
    final address = dashboard.value.contractAddress;
    if (_isZeroAddress(address)) return;
    Clipboard.setData(ClipboardData(text: address));
    Get.snackbar(
      'common.copied'.tr,
      shortProfileAddress(address),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> openContractExplorer() async {
    final address = dashboard.value.contractAddress;
    final explorer = walletService.currentNetwork.explorerUrl;
    if (_isZeroAddress(address) || explorer.isEmpty) return;
    await launchUrl(
      Uri.parse('$explorer/address/$address'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> claimPrize() async {
    if (!isWalletConnected) {
      _showWalletRequired();
      return;
    }
    if (dashboard.value.claimablePrizeWei <= BigInt.zero &&
        dashboard.value.settlementPrizeUsdc <= BigInt.zero) {
      Get.snackbar('profile.claimPrize'.tr, 'profile.nothingToClaim'.tr);
      return;
    }
    isClaimingPrize.value = true;
    try {
      await authController.ensureAuthenticated();
      await _settlement.claimPrize();
      Get.snackbar('common.ready'.tr, 'profile.claimConfirmed'.tr);
      await refreshDashboard();
    } catch (error) {
      Get.snackbar('common.error'.tr, error.toString());
    } finally {
      isClaimingPrize.value = false;
    }
  }

  Future<void> claimReferralBonus() async {
    if (!isWalletConnected) {
      _showWalletRequired();
      return;
    }
    if (dashboard.value.referralBonusWei <= BigInt.zero) {
      Get.snackbar('profile.claimReferral'.tr, 'profile.nothingToClaim'.tr);
      return;
    }
    isClaimingReferral.value = true;
    try {
      await authController.ensureAuthenticated();
      await walletService.claimEasyGameReferralBonus();
      Get.snackbar('common.ready'.tr, 'profile.claimConfirmed'.tr);
      await refreshDashboard();
    } catch (error) {
      Get.snackbar('common.error'.tr, error.toString());
    } finally {
      isClaimingReferral.value = false;
    }
  }

  Future<void> claimReferralBonusUSDC() async {
    if (!isWalletConnected) {
      _showWalletRequired();
      return;
    }
    if (dashboard.value.referralBonusUsdc <= BigInt.zero) {
      Get.snackbar('profile.claimReferral'.tr, 'profile.nothingToClaim'.tr);
      return;
    }
    isClaimingReferralUsdc.value = true;
    try {
      await authController.ensureAuthenticated();
      await walletService.claimEasyGameReferralBonusUSDC();
      Get.snackbar('common.ready'.tr, 'profile.claimConfirmed'.tr);
      await refreshDashboard();
    } catch (error) {
      Get.snackbar('common.error'.tr, error.toString());
    } finally {
      isClaimingReferralUsdc.value = false;
    }
  }

  Future<ProfileDashboardSnapshot> _loadDashboard() async {
    final values = await Future.wait<Object?>([
      _safeLoad(walletService.resolveEasyGameAddress),
      isWalletConnected
          ? _safeLoad<EasyGamePlayerSummary?>(
              () => walletService.getEasyGamePlayerSummary())
          : Future<Object?>.value(null),
      _safeLoad(() => _roundLevels.loadCards(
            playerAddress:
                isWalletConnected ? walletService.currentAddress.value : null,
          )),
      isWalletConnected
          ? _safeLoad(_settlement.getClaimable)
          : Future<Object?>.value(SettlementClaimable.zero),
    ]);

    final contractAddress =
        values[0] as String? ?? '0x0000000000000000000000000000000000000000';
    final player = values[1] as EasyGamePlayerSummary?;
    final levels = values[2] as List<RoundLevelCardState>? ??
        const <RoundLevelCardState>[];
    final settlement =
        values[3] as SettlementClaimable? ?? SettlementClaimable.zero;

    final activeCount = levels.where((level) => level.isPlayerActive).length;
    final frozenCount = levels.where((level) => level.isFrozen).length;
    final totalPrizePoolWei = levels.fold<BigInt>(
      BigInt.zero,
      (sum, level) => sum + level.prizePoolWei,
    );
    final totalActiveCells = levels.fold<BigInt>(
      BigInt.zero,
      (sum, level) => sum + level.activeCells,
    );
    final totalWeight = levels.fold<BigInt>(
      BigInt.zero,
      (sum, level) => sum + level.totalWeight,
    );

    return ProfileDashboardSnapshot(
      contractAddress: contractAddress,
      player: player,
      levels: levels,
      transactions: dashboard.value.transactions,
      activeCount: activeCount,
      frozenCount: frozenCount,
      totalPrizePoolWei: totalPrizePoolWei,
      totalActiveCells: totalActiveCells,
      totalWeight: totalWeight,
      settlementPrizeWei: settlement.ethAmount,
      settlementPrizeUsdc: settlement.usdcAmount,
    );
  }

  Future<T?> _safeLoad<T>(Future<T> Function() load) async {
    try {
      return await load();
    } catch (_) {
      return null;
    }
  }

  bool _isZeroAddress(String address) =>
      address.isEmpty ||
      address == '0x0000000000000000000000000000000000000000';

  void _showWalletRequired() {
    Get.snackbar('common.error'.tr, 'common.walletNotConnected'.tr);
  }
}
