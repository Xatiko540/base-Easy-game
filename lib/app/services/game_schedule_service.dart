import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/services/app_config_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/firebase_options.dart';

class GameScheduleService extends GetxService {
  final WalletConnectService _walletService = Get.find<WalletConnectService>();

  final RxList<GameRoundSchedule> schedules = <GameRoundSchedule>[].obs;
  final RxBool isReady = false.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  Worker? _chainWorker;

  Future<GameScheduleService> init() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _chainWorker ??= ever<int?>(_walletService.chainId, (_) => _watchRounds());
    await _watchRounds();
    isReady.value = true;
    return this;
  }

  Future<void> _watchRounds() async {
    await _subscription?.cancel();
    final chainId =
        _walletService.chainId.value ?? WalletConnectService.targetBaseChainId;
    final configuredContract = Get.find<AppConfigService>()
        .get('easyGameContractAddress')
        .toLowerCase();
    final configuredManager =
        Get.find<AppConfigService>().get('roundManagerAddress').toLowerCase();
    if (configuredContract.isEmpty || configuredManager.isEmpty) {
      schedules.clear();
      errorMessage.value = 'Round contract configuration is incomplete';
      return;
    }

    _subscription = FirebaseFirestore.instance
        .collection('rounds')
        .where('chainId', isEqualTo: chainId)
        .snapshots()
        .listen(
      (snapshot) {
        final parsed = <GameRoundSchedule>[];
        for (final document in snapshot.docs) {
          try {
            final round = GameRoundSchedule.fromFirestore(document);
            if (round.contractAddress == configuredContract &&
                round.roundManagerAddress == configuredManager) {
              parsed.add(round);
            }
          } catch (error) {
            if (kDebugMode) {
              debugPrint('Invalid round ${document.id}: $error');
            }
          }
        }
        parsed.sort((a, b) => a.startsAt.compareTo(b.startsAt));
        schedules.assignAll(parsed);
        errorMessage.value = '';
      },
      onError: (Object error) {
        errorMessage.value = '$error';
        if (kDebugMode) debugPrint('Round schedule stream failed: $error');
      },
    );
  }

  @override
  void onClose() {
    _chainWorker?.dispose();
    _subscription?.cancel();
    super.onClose();
  }
}
