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

import 'app_config_service.dart';
import 'notifications_service.dart';
import 'wallet_connect_service.dart';

class FirebaseBackendService extends GetxService {
  static const _region = 'us-central1';

  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final NotificationsService notifications = Get.find<NotificationsService>();
  final RxBool isReady = false.obs;
  final RxBool walletLinked = false.obs;
  final RxString errorMessage = ''.obs;

  String _recaptchaSiteKey = '';
  String _vapidKey = '';

  FirebaseFunctions? _functions;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  Worker? _paymentWorker;
  Worker? _walletWorker;

  Future<void> init() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
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

    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    await _configureMessaging();
    await _loadWalletLink();
    _paymentWorker = ever<String>(walletService.lastPaymentTxHash, (hash) {
      if (hash.isEmpty) return;
      unawaited(trackTransaction(hash).catchError((Object error) {
        debugPrint('Firebase transaction tracking skipped: $error');
      }));
    });
    _walletWorker = ever<String>(walletService.currentAddress, (_) {
      walletLinked.value = false;
    });
    isReady.value = true;
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
      debugPrint('Firebase config fetch failed (non-critical): $e');
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

  Future<void> _loadWalletLink() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('walletLinks')
        .doc(uid)
        .get();
    walletLinked.value = snapshot.exists &&
        snapshot.data()?['wallet']?.toString().toLowerCase() ==
            walletService.currentAddress.value.toLowerCase();
  }

  Future<void> linkCurrentWallet() async {
    _requireReady();
    if (!walletService.isConnected.value) {
      await walletService.connectBaseAccount();
    }
    final wallet = walletService.currentAddress.value;
    final nonceResult = await _functions!
        .httpsCallable('requestWalletNonce')
        .call(<String, dynamic>{'wallet': wallet});
    final message =
        Map<String, dynamic>.from(nonceResult.data as Map)['message']
            .toString();
    final signature = await walletService.signMessage(message);
    await _functions!.httpsCallable('linkWallet').call(<String, dynamic>{
      'signature': signature,
    });
    walletLinked.value = true;
    await registerDevice();
  }

  Future<void> ensureCurrentWalletLinked() async {
    _requireReady();
    await _loadWalletLink();
    if (walletLinked.value) {
      await registerDevice();
      return;
    }
    await linkCurrentWallet();
  }

  Future<void> registerDevice() async {
    _requireReady();
    if (!walletLinked.value) return;
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

  @override
  void onClose() {
    _messageSubscription?.cancel();
    _paymentWorker?.dispose();
    _walletWorker?.dispose();
    super.onClose();
  }
}
