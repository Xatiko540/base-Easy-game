import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/app_shell.dart';
import 'package:lottery_advance/app/modules/home/views/levels.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/app/services/base_pay_service.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';

class ActivateExpressGameScreen extends StatelessWidget {
  final int level;
  final double totalAmount;
  final String inviter;
  final EasyGamePaymentAsset paymentAsset;
  final GameRoundSchedule round;

  ActivateExpressGameScreen({
    Key? key,
    this.level = 4,
    this.totalAmount = 0.28,
    this.inviter = '',
    this.paymentAsset = EasyGamePaymentAsset.native,
    required this.round,
  }) : super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final BasePayService basePayService = Get.find<BasePayService>();

  @override
  Widget build(BuildContext context) {
    double horizontalPadding = MediaQuery.of(context).size.width * 0.10;

    return Obx(() {
      final currency = paymentAsset == EasyGamePaymentAsset.native
          ? walletService.nativeSymbol
          : 'USDC';
      final networkOk = walletService.isOnSupportedNetwork;
      final usesBasePay = paymentAsset == EasyGamePaymentAsset.basePay;
      final isProcessing = usesBasePay
          ? basePayService.isProcessing
          : walletService.isPaying.value;

      return ExpressAppShell(
        title: 'payment.title'.tr,
        breadcrumb:
            '${'app.name'.tr} / ${'common.level'.tr} $level / ${'payment.title'.tr}',
        balanceLabel: '${totalAmount.toStringAsFixed(3)} $currency',
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
                      _buildRewardRow(
                          'payment.projectFee'.tr, "5%", 'payment.project'.tr),
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
                                    'network':
                                        walletService.targetNetwork.displayName,
                                  }),
                            style: TextStyle(color: Colors.grey, fontSize: 14),
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
                              'amount': totalAmount.toStringAsFixed(3),
                              'currency': currency,
                            }),
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _PaymentStateLine(
                        icon: usesBasePay
                            ? CupertinoIcons.creditcard_fill
                            : _statusIcon(walletService.paymentStatus.value),
                        color: usesBasePay
                            ? const Color(0xFF0052FF)
                            : _statusColor(walletService.paymentStatus.value),
                        label: usesBasePay
                            ? 'Base Pay'
                            : walletService.paymentStatusLabel,
                        value: usesBasePay
                            ? (basePayService.statusMessage.value.isEmpty
                                ? 'payment.basePaySponsored'.tr
                                : basePayService.statusMessage.value)
                            : walletService.paymentStatusMessage.value,
                      ),
                      if (!usesBasePay &&
                          walletService.lastGasEstimate.value != null) ...[
                        const SizedBox(height: 8),
                        _PaymentStateLine(
                          icon: CupertinoIcons.bolt_fill,
                          color: Colors.lightBlueAccent,
                          label: 'payment.gasEstimate'.tr,
                          value:
                              '${walletService.lastGasEstimate.value} gas units',
                        ),
                      ],
                      if (walletService.lastPaymentTxHash.value.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _PaymentStateLine(
                          icon: CupertinoIcons.doc_text,
                          color: Colors.white70,
                          label: 'payment.transaction'.tr,
                          value:
                              _shortHash(walletService.lastPaymentTxHash.value),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                try {
                                  final String txHash;
                                  if (usesBasePay) {
                                    txHash = await basePayService.payRound(
                                      round: round,
                                      inviter: inviter,
                                    );
                                  } else if (paymentAsset ==
                                      EasyGamePaymentAsset.usdc) {
                                    txHash = await walletService
                                        .activateEasyGameRoundWithUSDC(
                                      round: round,
                                      inviter: inviter,
                                    );
                                  } else {
                                    txHash = await walletService
                                        .activateEasyGameRound(
                                      round: round,
                                      inviter: inviter,
                                    );
                                  }
                                  Get.snackbar(
                                    'payment.confirmed'.tr,
                                    '${'payment.transaction'.tr}: $txHash',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  Get.offAll(() => LevelsScreen());
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
                                ? (usesBasePay
                                    ? 'payment.basePayProcessing'.tr
                                    : walletService.paymentStatusLabel)
                                : usesBasePay
                                    ? 'payment.payBasePay'.trParams({
                                        'amount':
                                            totalAmount.toStringAsFixed(3),
                                      })
                                    : 'payment.pay'.trParams({
                                        'amount':
                                            totalAmount.toStringAsFixed(3),
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
                                  "${totalAmount.toStringAsFixed(3)} $currency",
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
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
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
    });
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

class _PaymentStateLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _PaymentStateLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
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
      ],
    );
  }
}
