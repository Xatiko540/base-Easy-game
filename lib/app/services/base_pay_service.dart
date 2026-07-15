import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';

import 'app_config_service.dart';
import 'base_account_bridge.dart';
import 'firebase_backend_service.dart';
import 'wallet_connect_service.dart';

enum BasePayFlowStatus {
  idle,
  opening,
  confirming,
  fulfilling,
  success,
  failed,
}

class BasePayService extends GetxService {
  final status = BasePayFlowStatus.idle.obs;
  final statusMessage = ''.obs;
  final paymentId = ''.obs;
  final fulfillmentTransactionHash = ''.obs;

  bool get isAvailable {
    if (!kIsWeb || !isBasePayBridgeAvailable) return false;
    final config = Get.find<AppConfigService>();
    final chainId = config.getInt('targetBaseChainId');
    if (chainId != WalletConnectService.baseMainnetChainId &&
        chainId != WalletConnectService.baseSepoliaChainId) {
      return false;
    }
    return config.get('basePayGatewayAddress').isNotEmpty;
  }

  bool get isProcessing => const {
        BasePayFlowStatus.opening,
        BasePayFlowStatus.confirming,
        BasePayFlowStatus.fulfilling,
      }.contains(status.value);

  Future<String> payRound({
    required GameRoundSchedule round,
    required String inviter,
  }) async {
    if (isProcessing) {
      throw StateError('payment.alreadyProcessing'.tr);
    }
    if (!isAvailable) {
      throw StateError('payment.basePayUnavailable'.tr);
    }
    final wallet = Get.find<WalletConnectService>();
    if (!wallet.isConnected.value) await wallet.connectBaseAccount();
    await wallet.ensureBaseNetwork();
    if (!await wallet.isEasyGameLevelAvailable(round.level)) {
      throw StateError('payment.levelEmergencyPausedHint'.tr);
    }
    final backend = Get.find<FirebaseBackendService>();
    await backend.ensureCurrentWalletLinked();

    final config = Get.find<AppConfigService>();
    final gateway = await wallet.resolveBasePayGatewayAddress();
    final testnet = config.getInt('targetBaseChainId') ==
        WalletConnectService.baseSepoliaChainId;
    final amount = _formatUsdc(round.usdcPrice);

    status.value = BasePayFlowStatus.opening;
    statusMessage.value = 'payment.basePayOpening'.tr;
    paymentId.value = '';
    fulfillmentTransactionHash.value = '';
    try {
      final payment = await sendBasePay(
        amount: amount,
        recipient: gateway,
        testnet: testnet,
        dataSuffix: config.get('baseBuilderDataSuffix'),
      );
      if (payment.id.isEmpty) {
        throw StateError('Base Pay did not return a transaction ID.');
      }
      paymentId.value = payment.id;
      status.value = BasePayFlowStatus.confirming;
      statusMessage.value = 'payment.basePayVerifying'.tr;
      await _waitForCompletion(payment.id, testnet);

      status.value = BasePayFlowStatus.fulfilling;
      statusMessage.value = 'payment.basePayFulfilling'.tr;
      final fulfillment = await backend.fulfillBasePayRound(
        paymentId: payment.id,
        roundId: round.roundId,
        inviter: inviter,
      );
      fulfillmentTransactionHash.value = fulfillment;
      wallet.lastPaymentTxHash.value = fulfillment;
      status.value = BasePayFlowStatus.success;
      statusMessage.value = 'payment.basePayActivated'.tr;
      return fulfillment;
    } catch (error) {
      status.value = BasePayFlowStatus.failed;
      statusMessage.value = error.toString();
      rethrow;
    }
  }

  Future<void> _waitForCompletion(String id, bool testnet) async {
    for (var attempt = 0; attempt < 30; attempt++) {
      final payment = await readBasePayStatus(
        paymentId: id,
        testnet: testnet,
      );
      if (payment.status == 'completed') return;
      if (payment.status == 'failed' || payment.status == 'not_found') {
        throw StateError('Base Pay status: ${payment.status}');
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    throw TimeoutException('payment.basePayTimeout'.tr);
  }

  String _formatUsdc(BigInt amount) {
    final whole = amount ~/ BigInt.from(1000000);
    final fraction = (amount % BigInt.from(1000000))
        .toString()
        .padLeft(6, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return fraction.isEmpty ? whole.toString() : '$whole.$fraction';
  }
}
