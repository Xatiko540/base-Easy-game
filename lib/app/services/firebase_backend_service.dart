import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/firebase_options.dart';

import '../models/game_transaction_model.dart';
import '../models/wallet_auth_models.dart';
import 'app_config_service.dart';
import 'notifications_service.dart';
import 'wallet_connect_service.dart';

class FirebaseBackendService extends GetxService {
  static const _region = 'us-central1';

  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final NotificationsService notifications = Get.find<NotificationsService>();
  final RxBool isReady = false.obs;
  final Rxn<WalletAuthSession> session = Rxn<WalletAuthSession>();
  final RxString errorMessage = ''.obs;

  String _recaptchaSiteKey = '';
  String _vapidKey = '';

  FirebaseFunctions? _functions;
  Future<void>? _initialization;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<User?>? _authSubscription;
  Worker? _paymentWorker;

  bool get isAuthenticated => session.value != null;

  Future<void> init() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    isReady.value = false;
    errorMessage.value = '';

    try {
      await _initializeFirebase();
      isReady.value = true;
    } catch (error) {
      errorMessage.value = _firebaseErrorMessage(error);
      rethrow;
    }
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }

    _functions = FirebaseFunctions.instanceFor(region: _region);
    await _fetchConfig();

    if (!kDebugMode || _recaptchaSiteKey.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        providerWeb: kIsWeb && _recaptchaSiteKey.isNotEmpty
            ? ReCaptchaV3Provider(_recaptchaSiteKey)
            : null,
        providerAndroid: const AndroidPlayIntegrityProvider(),
        providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    }

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
          (user) => unawaited(_restoreWalletSession(user)),
        );
    await _ensureBootstrapSession();
    await _restoreWalletSession(FirebaseAuth.instance.currentUser);

    await _configureMessaging();
    _paymentWorker = ever<String>(walletService.lastPaymentTxHash, (hash) {
      if (hash.isEmpty) return;
      unawaited(trackTransaction(hash).catchError((Object error) {
        debugPrint('Firebase transaction tracking skipped: $error');
      }));
    });
  }

  String _firebaseErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('recaptcha-error') ||
        message.contains('App Check token')) {
      return 'Firebase App Check could not verify this browser.';
    }
    return message;
  }

  Future<void> _fetchConfig() async {
    try {
      final config = Get.find<AppConfigService>();
      if (!config.isLoaded.value) {
        await config.fetch();
      }
      _recaptchaSiteKey = config.get('recaptchaSiteKey');
      _vapidKey = config.get('vapidKey');
    } catch (e) {
      debugPrint('Firebase config fetch failed: $e');
      rethrow;
    }
  }

  Future<void> _configureMessaging() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        unawaited(notifications.showNotification(
          title: notification.title ?? 'Easy Game',
          body: notification.body ?? '',
          id: message.messageId?.hashCode ?? 0,
        ));
      }
    });
  }

  Future<void> authenticateWallet({
    required String address,
    required int chainId,
    required Future<String> Function(String message) signMessage,
  }) async {
    _requireReady();
    await _prepareAuthenticationSession(address, chainId);
    if (session.value?.matches(address, chainId) == true) return;
    final configuredOrigin = Get.find<AppConfigService>().get('appPublicUrl');
    final origin = kIsWeb
        ? Uri.base.origin
        : configuredOrigin.isNotEmpty
            ? configuredOrigin
            : 'https://lottery-advance.web.app';
    final challenge = await _functions!
        .httpsCallable('requestSiweNonce')
        .call(<String, dynamic>{
      'wallet': address,
      'chainId': chainId,
      'origin': origin,
    });
    final challengeData = Map<String, dynamic>.from(challenge.data as Map);
    final message = challengeData['message']?.toString() ?? '';
    if (message.isEmpty) {
      throw StateError('SIWE challenge is missing.');
    }
    final signature = await signMessage(message);
    final authentication = await _functions!
        .httpsCallable('authenticateWallet')
        .call(<String, dynamic>{
      'address': address,
      'message': message,
      'signature': signature,
    });
    final data = Map<String, dynamic>.from(authentication.data as Map);
    final customToken = data['customToken']?.toString() ?? '';
    if (customToken.isEmpty) {
      throw StateError('Firebase custom token is missing.');
    }
    final credential =
        await FirebaseAuth.instance.signInWithCustomToken(customToken);
    await _restoreWalletSession(credential.user);
    if (session.value?.matches(address, chainId) != true) {
      throw StateError('Authenticated wallet does not match the connection.');
    }
    await registerDevice();
  }

  Future<void> ensureAuthenticated() async {
    _requireReady();
    final activeSession = session.value;
    if (activeSession == null ||
        !activeSession.matches(
          walletService.currentAddress.value,
          walletService.chainId.value,
        )) {
      throw StateError('Authenticate the connected wallet first.');
    }
    await registerDevice();
  }

  Future<void> signOutWalletSession() async {
    if (Firebase.apps.isEmpty) return;
    session.value = null;
    await FirebaseAuth.instance.signOut();
    if (isReady.value) await _ensureBootstrapSession();
  }

  Future<void> registerDevice() async {
    _requireReady();
    if (!isAuthenticated) return;
    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb && _vapidKey.isNotEmpty ? _vapidKey : null,
    );
    if (token == null || token.isEmpty) return;
    await _functions!.httpsCallable('registerDevice').call(<String, dynamic>{
      'token': token,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    });
  }

  Future<void> trackTransaction(String transactionHash) async {
    _requireReady();
    final activeSession = session.value;
    if (activeSession == null ||
        !activeSession.matches(
          walletService.currentAddress.value,
          walletService.chainId.value,
        )) {
      return;
    }
    await _functions!.httpsCallable('trackTransaction').call(<String, dynamic>{
      'transactionHash': transactionHash,
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchTransaction(
    String transactionHash,
  ) {
    final chainId =
        walletService.chainId.value ?? WalletConnectService.baseMainnetChainId;
    return FirebaseFirestore.instance
        .collection('transactions')
        .doc('${chainId}_${transactionHash.toLowerCase()}')
        .snapshots();
  }

  Stream<List<GameTransaction>> watchRecentTransactions({
    int limit = 30,
    int? chainId,
    String? wallet,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream<List<GameTransaction>>.value(const <GameTransaction>[]);
    }

    final activeChainId = chainId ??
        walletService.chainId.value ??
        WalletConnectService.baseMainnetChainId;
    final normalizedWallet = wallet?.trim().toLowerCase() ?? '';

    return FirebaseFirestore.instance
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .where('chainId', isEqualTo: activeChainId)
        .orderBy('createdAt', descending: true)
        .limit(limit * 3)
        .snapshots()
        .map((snapshot) {
      final transactions = snapshot.docs
          .map((document) {
            final data = document.data();
            return GameTransaction(
              id: document.id,
              chainId: (data['chainId'] as num?)?.toInt() ?? 0,
              transactionHash: data['transactionHash']?.toString() ?? '',
              wallet: data['wallet']?.toString() ?? '',
              status: data['status']?.toString().toLowerCase() ?? 'submitted',
              operation: data['operation']?.toString() ?? 'onChainTransaction',
              level: (data['level'] as num?)?.toInt(),
              amount: data['amount']?.toString() ?? '',
              currency: data['currency']?.toString().toUpperCase() ?? '',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
              updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
            );
          })
          .where((item) {
            return normalizedWallet.isEmpty ||
                item.wallet.toLowerCase() == normalizedWallet;
          })
          .take(limit)
          .toList()
        ..sort((a, b) {
          final aDate = a.updatedAt ?? a.createdAt;
          final bDate = b.updatedAt ?? b.createdAt;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
      return transactions;
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchPlayer() {
    final chainId =
        walletService.chainId.value ?? WalletConnectService.baseMainnetChainId;
    final wallet = walletService.currentAddress.value.toLowerCase();
    return FirebaseFirestore.instance
        .collection('users')
        .doc('${chainId}_$wallet')
        .snapshots();
  }

  void _requireReady() {
    if (!isReady.value || _functions == null) {
      throw StateError(errorMessage.value.isEmpty
          ? 'Firebase backend is not initialized'
          : errorMessage.value);
    }
  }

  Future<void> _ensureBootstrapSession() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  Future<void> _prepareAuthenticationSession(
    String address,
    int chainId,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      if (session.value?.matches(address, chainId) == true) return;
      session.value = null;
      await FirebaseAuth.instance.signOut();
    }
    await _ensureBootstrapSession();
  }

  Future<void> _restoreWalletSession(User? user) async {
    if (user == null || user.isAnonymous) {
      session.value = null;
      return;
    }
    try {
      final token = await user.getIdTokenResult();
      final claims = token.claims ?? const <String, dynamic>{};
      final wallet = claims['wallet']?.toString() ?? '';
      final chainId = int.tryParse(claims['chainId']?.toString() ?? '');
      final authProvider = claims['authProvider']?.toString() ?? '';
      if (wallet.isEmpty || chainId == null || authProvider != 'siwe') {
        session.value = null;
        return;
      }
      session.value = WalletAuthSession(
        wallet: wallet,
        chainId: chainId,
        firebaseUid: user.uid,
      );
    } catch (error) {
      session.value = null;
      debugPrint('Firebase wallet session restore failed: $error');
    }
  }

  @override
  void onClose() {
    _messageSubscription?.cancel();
    _authSubscription?.cancel();
    _paymentWorker?.dispose();
    super.onClose();
  }
}
