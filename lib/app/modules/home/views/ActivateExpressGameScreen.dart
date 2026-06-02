import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class ActivateExpressGameScreen extends StatelessWidget {
  final int level;
  final double totalAmount;
  final String inviter;

  ActivateExpressGameScreen({
    Key? key,
    this.level = 4,
    this.totalAmount = 0.28,
    this.inviter = '',
  }) : super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();

  @override
  Widget build(BuildContext context) {
    double horizontalPadding = MediaQuery.of(context).size.width * 0.10;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the Drawer icon color to white
        ),
        elevation: 0,
        title: Text(
          "Activate Easy Game",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: BackButton(color: Colors.white),
      ),
      body: Center(
        child: Padding(
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
                      "Level $level",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Reward distribution",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    _buildRewardRow("Matrix parent", "80%", "level reward"),
                    SizedBox(height: 8),
                    _buildRewardRow("Direct partner", "9.5%", "referral"),
                    SizedBox(height: 8),
                    _buildRewardRow("Operations", "0.5%", "system"),
                    SizedBox(height: 8),
                    _buildRewardRow("2nd line partner", "6%", "referral"),
                    SizedBox(height: 8),
                    _buildRewardRow("3rd line partner", "4%", "referral"),
                    SizedBox(height: 8),
                    Divider(color: Colors.grey),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Obx(
                          () => Text(
                            walletService.chainId.value ==
                                        WalletConnectService
                                            .baseSepoliaChainId ||
                                    walletService.chainId.value ==
                                        WalletConnectService.ganacheChainId ||
                                    walletService.chainId.value ==
                                        WalletConnectService
                                            .ganacheDefaultChainId
                                ? "Network check OK"
                                : "Switch network to Base Sepolia or Ganache",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Obx(
                          () => Icon(
                            walletService.isConnected.value
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: walletService.isConnected.value
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Payment amount ${totalAmount.toStringAsFixed(3)} ETH(base)",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Obx(
                      () => ElevatedButton(
                        onPressed: walletService.isPaying.value
                            ? null
                            : () async {
                                try {
                                  final txHash =
                                      await walletService.activateEasyGameLevel(
                                    level: level,
                                    inviter: inviter,
                                  );
                                  Get.snackbar(
                                    'Payment sent',
                                    'Transaction: $txHash',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                } catch (e) {
                                  Get.snackbar(
                                    'Payment unavailable',
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
                            walletService.isPaying.value
                                ? "Waiting for wallet..."
                                : "Pay ${totalAmount.toStringAsFixed(3)} ETH(base)",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                            "Level $level",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.monetization_on,
                                  color: Colors.yellow, size: 16),
                              SizedBox(width: 4),
                              Text(
                                "${totalAmount.toStringAsFixed(3)} base",
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
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "3.64 base",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        "Affiliate Bonus",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        "20.72 base",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        "Profit Level",
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
}
