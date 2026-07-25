import 'dart:async';

import 'package:get/get.dart';
import 'package:lottery_advance/app/models/wallet_auth_models.dart';
import 'package:lottery_advance/app/services/firebase_backend_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class WalletAuthController extends GetxController {
  WalletAuthController({
    WalletConnectService? walletService,
    FirebaseBackendService? backendService,
  })  : walletService = walletService ?? Get.find<WalletConnectService>(),
        backendService = backendService ?? Get.find<FirebaseBackendService>();

  final WalletConnectService walletService;
  final FirebaseBackendService backendService;

  final phase = WalletAuthPhase.initializing.obs;
  final errorMessage = ''.obs;

  final List<Worker> _workers = <Worker>[];
  bool _authenticationInFlight = false;
  bool _clearingMismatchedSession = false;
  Completer<void>? _authCompleter;

  bool get isAuthenticated =>
      phase.value == WalletAuthPhase.authenticated &&
      backendService.session.value?.matches(
            walletService.currentAddress.value,
            walletService.chainId.value,
          ) ==
          true;

  @override
  void onInit() {
    super.onInit();
    _workers.addAll(<Worker>[
      ever<bool>(walletService.isConnected, (_) => _reconcile()),
      ever<String>(walletService.currentAddress, (_) => _reconcile()),
      ever<int?>(walletService.chainId, (_) => _reconcile()),
      ever<bool>(backendService.isReady, (_) => _reconcile()),
      ever<WalletAuthSession?>(backendService.session, (_) => _reconcile()),
    ]);
    _reconcile();
  }

  Future<void> connectAndAuthenticate() async {
    if (_authCompleter != null) {
      await _authCompleter!.future;
      return;
    }
    _authCompleter = Completer<void>();
    errorMessage.value = '';
    try {
      await backendService.init();
      if (!walletService.isConnected.value) {
        phase.value = WalletAuthPhase.connecting;
        await walletService.connectWallet();
        await _waitForWalletConnection();
      }
      await walletService.ensureBaseNetwork();
      await _authenticateConnectedWallet();
      _authCompleter!.complete();
    } catch (error) {
      if (!_authCompleter!.isCompleted) {
        _authCompleter!.completeError(error);
      }
      if (WalletConnectService.isUserRejection(error)) {
        _reconcile();
        return;
      }
      errorMessage.value = error.toString();
      phase.value = WalletAuthPhase.error;
      rethrow;
    } finally {
      _authCompleter = null;
    }
  }

  Future<void> ensureAuthenticated() async {
    if (isAuthenticated) return;
    await connectAndAuthenticate();
    if (!isAuthenticated) {
      throw StateError('Wallet authentication was not completed.');
    }
  }

  Future<void> logout() async {
    errorMessage.value = '';
    await backendService.signOutWalletSession();
    await walletService.disconnectWallet();
    phase.value = WalletAuthPhase.disconnected;
  }

  Future<void> _authenticateConnectedWallet() async {
    if (_authenticationInFlight || isAuthenticated) return;
    final address = walletService.currentAddress.value;
    final chainId = walletService.chainId.value;
    if (address.isEmpty || chainId == null) {
      throw StateError('Wallet connection is incomplete.');
    }

    _authenticationInFlight = true;
    phase.value = WalletAuthPhase.authenticating;
    try {
      await backendService.authenticateWallet(
        address: address,
        chainId: chainId,
        signMessage: walletService.signMessage,
      );
      phase.value = WalletAuthPhase.authenticated;
    } finally {
      _authenticationInFlight = false;
    }
  }

  Future<void> _waitForWalletConnection() async {
    if (walletService.isConnected.value &&
        walletService.currentAddress.value.isNotEmpty) {
      return;
    }
    final completer = Completer<void>();
    final workers = <Worker>[];
    void completeIfReady() {
      if (walletService.isConnected.value &&
          walletService.currentAddress.value.isNotEmpty) {
        if (!completer.isCompleted) completer.complete();
      }
    }

    workers.addAll(<Worker>[
      ever<bool>(walletService.isConnected, (_) => completeIfReady()),
      ever<String>(walletService.currentAddress, (_) => completeIfReady()),
    ]);
    completeIfReady();
    try {
      await completer.future.timeout(const Duration(minutes: 2));
    } finally {
      for (final worker in workers) {
        worker.dispose();
      }
    }
  }

  void _reconcile() {
    if (!backendService.isReady.value) {
      phase.value = WalletAuthPhase.initializing;
      return;
    }
    if (!walletService.isInitialized.value) {
      phase.value = WalletAuthPhase.initializing;
      return;
    }
    if (!walletService.isConnected.value ||
        walletService.currentAddress.value.isEmpty) {
      phase.value = WalletAuthPhase.disconnected;
      return;
    }
    final activeSession = backendService.session.value;
    final activeChainId = walletService.chainId.value;

    if (activeSession != null && activeChainId == null) {
      // Session exists but wagmi hasn't reported chainId yet — don't glitch phase.
      return;
    }

    if (activeSession?.matches(
          walletService.currentAddress.value,
          activeChainId,
        ) ==
        true) {
      phase.value = WalletAuthPhase.authenticated;
      return;
    }
    if (activeSession != null &&
        activeSession.wallet.toLowerCase() !=
            walletService.currentAddress.value.toLowerCase()) {
      phase.value = WalletAuthPhase.connected;
      if (!_clearingMismatchedSession) {
        unawaited(_clearMismatchedSession());
      }
      return;
    }
    if (_authenticationInFlight) {
      phase.value = WalletAuthPhase.authenticating;
      return;
    }
    phase.value = WalletAuthPhase.connected;
  }

  Future<void> _clearMismatchedSession() async {
    _clearingMismatchedSession = true;
    try {
      await backendService.signOutWalletSession();
    } finally {
      _clearingMismatchedSession = false;
      _reconcile();
    }
  }

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }
}
