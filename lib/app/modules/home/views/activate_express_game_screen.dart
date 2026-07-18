import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/controllers/round_payment_controller.dart';
import 'package:lottery_advance/app/modules/home/views/app_shell.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';

class ActivateExpressGameScreen extends StatelessWidget {
  final int level;
  final String inviter;
  final EasyGamePaymentAsset paymentAsset;
  final GameRoundViewState initialRound;

  ActivateExpressGameScreen({
    super.key,
    this.level = 4,
    this.inviter = '',
    this.paymentAsset = EasyGamePaymentAsset.native,
    required this.initialRound,
  });

  final WalletConnectService walletService = Get.find<WalletConnectService>();

  @override
  Widget build(BuildContext context) {
    double horizontalPadding = MediaQuery.of(context).size.width * 0.10;
    final tag = '${initialRound.schedule.roundId}-${paymentAsset.name}';

    return GetX<RoundPaymentController>(
      init: RoundPaymentController(
        level: level,
        inviter: inviter,
        paymentAsset: paymentAsset,
        initialRound: initialRound,
      ),
      tag: tag,
      dispose: (_) {
        if (Get.isRegistered<RoundPaymentController>(tag: tag)) {
          Get.delete<RoundPaymentController>(tag: tag);
        }
      },
      builder: (paymentController) {
        final currency = paymentController.currency;
        final amountLabel = paymentController.amountLabel;
        final networkOk = walletService.isOnSupportedNetwork;
        final isProcessing = paymentController.isProcessing;

        return ExpressAppShell(
          title: 'payment.title'.tr,
          breadcrumb:
              '${'app.name'.tr} / ${'common.level'.tr} $level / ${'payment.title'.tr}',
          activeSection: 'Dashboard',
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A1F2E), Color(0xFF0F131A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 50), // Adjust for the overlapping card
                        Text(
                          "${'common.level'.tr} $level",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'payment.rewardDistribution'.tr,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(height: 16),
                        _buildRewardRow('payment.prizePool'.tr, "75.5%",
                            'payment.matrixPool'.tr),
                        SizedBox(height: 8),
                        _buildRewardRow('payment.nearestLine'.tr, "9.5%",
                            'payment.partner'.tr),
                        SizedBox(height: 8),
                        _buildRewardRow('payment.secondNearest'.tr, "6%",
                            'payment.partner'.tr),
                        SizedBox(height: 8),
                        _buildRewardRow('payment.thirdNearest'.tr, "4%",
                            'payment.partner'.tr),
                        SizedBox(height: 8),
                        _buildRewardRow('payment.projectFee'.tr, "5%",
                            'payment.project'.tr),
                        SizedBox(height: 8),
                        Divider(color: Colors.grey),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              networkOk
                                  ? CupertinoIcons.check_mark_circled
                                  : CupertinoIcons.exclamationmark_triangle,
                              color: networkOk ? Colors.green : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              networkOk
                                  ? '${'payment.networkOk'.tr}: ${walletService.networkLabel}'
                                  : 'payment.switchNetwork'.trParams({
                                      'network': walletService
                                          .targetNetwork.displayName,
                                    }),
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              walletService.isConnected.value
                                  ? CupertinoIcons.check_mark_circled
                                  : CupertinoIcons.xmark_circle,
                              color: walletService.isConnected.value
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'payment.amount'.trParams({
                                'amount': amountLabel,
                                'currency': currency,
                              }),
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _PaymentStateLine(
                          icon: CupertinoIcons.doc_text_fill,
                          color: Colors.tealAccent,
                          label: 'registration.totalContractCharge'.tr,
                          value:
                              '$amountLabel $currency + ${'registration.networkGasExtra'.tr}',
                        ),
                        const SizedBox(height: 8),
                        _PaymentStateLine(
                          icon: CupertinoIcons.money_dollar_circle,
                          color: paymentController.hasEnoughBalance == false
                              ? Colors.orangeAccent
                              : Colors.tealAccent,
                          label: 'payment.availableBalance'.tr,
                          value: paymentController.isBalanceLoading.value
                              ? 'common.loading'.tr
                              : paymentController.balanceError.value.isNotEmpty
                                  ? 'payment.balanceUnavailable'.tr
                                  : '${paymentController.availableBalanceLabel} $currency',
                          trailing: IconButton(
                            tooltip: 'payment.refreshBalance'.tr,
                            onPressed: paymentController.isBalanceLoading.value
                                ? null
                                : paymentController.refreshBalance,
                            icon: const Icon(
                              CupertinoIcons.refresh,
                              size: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _PaymentStateLine(
                          icon:
                              paymentController.contractLevelAvailable.value ==
                                      true
                                  ? CupertinoIcons.shield_lefthalf_fill
                                  : CupertinoIcons.pause_circle,
                          color:
                              paymentController.contractLevelAvailable.value ==
                                      true
                                  ? Colors.tealAccent
                                  : Colors.orangeAccent,
                          label: 'payment.contractPreflight'.tr,
                          value: paymentController.isPreflightLoading.value
                              ? 'common.loading'.tr
                              : paymentController
                                      .preflightError.value.isNotEmpty
                                  ? paymentController.preflightError.value
                                  : paymentController
                                              .contractLevelAvailable.value ==
                                          true
                                      ? 'common.ready'.tr
                                      : 'payment.preflightUnavailable'.tr,
                          trailing: IconButton(
                            tooltip: 'common.refresh'.tr,
                            onPressed:
                                paymentController.isPreflightLoading.value
                                    ? null
                                    : paymentController.refreshPaymentReadiness,
                            icon: const Icon(
                              CupertinoIcons.refresh,
                              size: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        if (paymentController.hasEnoughBalance == false) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'payment.insufficientBalance'.tr,
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        if (paymentController.needsEthFunding) ...[
                          const SizedBox(height: 12),
                          _OnRampButton(
                            loading: walletService.isOpeningOnRamp.value,
                            label: paymentController
                                .fundingButtonTranslationKey.tr,
                            onPressed: paymentController.openEthFunding,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            paymentController.fundingHintTranslationKey.tr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _PaymentStateLine(
                          icon: _statusIcon(walletService.paymentStatus.value),
                          color:
                              _statusColor(walletService.paymentStatus.value),
                          label: walletService.paymentStatusLabel,
                          value: walletService.paymentStatusMessage.value,
                        ),
                        if (walletService.lastGasEstimate.value != null) ...[
                          const SizedBox(height: 8),
                          _PaymentStateLine(
                            icon: CupertinoIcons.bolt_fill,
                            color: Colors.lightBlueAccent,
                            label: 'payment.gasEstimate'.tr,
                            value:
                                '${walletService.lastGasEstimate.value} gas units',
                          ),
                        ],
                        if (walletService
                            .lastPaymentTxHash.value.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _PaymentStateLine(
                            icon: CupertinoIcons.doc_text,
                            color: Colors.white70,
                            label: 'payment.transaction'.tr,
                            value: _shortHash(
                                walletService.lastPaymentTxHash.value),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: !paymentController.canSubmit
                              ? null
                              : () async {
                                  try {
                                    await paymentController.submitPayment();
                                  } catch (e) {
                                    Get.snackbar(
                                      'payment.unavailable'.tr,
                                      '$e',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isProcessing
                                  ? walletService.paymentStatusLabel
                                  : 'payment.pay'.trParams({
                                      'amount': amountLabel,
                                      'currency': currency,
                                    }),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -85,
                    right: 16, // Align the small card to the right
                    child: Container(
                      width: 180,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1F203A), Color(0xFF14151F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF6A4BFF),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${'common.level'.tr} $level",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(CupertinoIcons.money_dollar,
                                      color: Colors.yellow, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    "$amountLabel $currency",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: 0.0,
                            backgroundColor: Colors.grey[700],
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Text(
                              //   "Заполнение текущей строки",
                              //   style: TextStyle(
                              //       color: Colors.grey, fontSize: 12),
                              // ),
                              Text(
                                "0%",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            "0 $currency",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'levels.partnerBonus'.tr,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            "0 $currency",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'levels.levelProfits'.tr,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardRow(String title, String percentage, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            percentage,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  IconData _statusIcon(PaymentFlowStatus status) {
    switch (status) {
      case PaymentFlowStatus.success:
        return CupertinoIcons.check_mark_circled;
      case PaymentFlowStatus.failed:
        return CupertinoIcons.exclamationmark_circle;
      case PaymentFlowStatus.estimatingGas:
      case PaymentFlowStatus.confirming:
      case PaymentFlowStatus.waitingForWallet:
      case PaymentFlowStatus.preparing:
      case PaymentFlowStatus.submitted:
        return CupertinoIcons.clock;
      case PaymentFlowStatus.idle:
        return CupertinoIcons.info;
    }
  }

  Color _statusColor(PaymentFlowStatus status) {
    switch (status) {
      case PaymentFlowStatus.success:
        return Colors.green;
      case PaymentFlowStatus.failed:
        return Colors.redAccent;
      case PaymentFlowStatus.idle:
        return Colors.grey;
      default:
        return Colors.orangeAccent;
    }
  }

  String _shortHash(String hash) {
    if (hash.length <= 14) {
      return hash;
    }
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 6)}';
  }
}

class _OnRampButton extends StatelessWidget {
  const _OnRampButton({
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final bool loading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B20D7), Color(0xFF4B69EA), Color(0xFF0EC8BD)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(CupertinoIcons.creditcard, color: Colors.white),
          label: Text(
            loading ? 'payment.onRampOpening'.tr : label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentStateLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Widget? trailing;

  const _PaymentStateLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isEmpty ? label : '$label: $value',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
