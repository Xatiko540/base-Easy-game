import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/ActivateExpressGameScreen.dart';
import 'package:lottery_advance/app/modules/home/views/profilescreen.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

import 'PartnerBonusScreen.dart';
import 'levels.dart';

class RegistrationScreen extends StatefulWidget {
  final int level;
  final double amount;
  final String? inviter;

  RegistrationScreen(
    LevelStatus level1, {
    Key? key,
    this.level = 3,
    this.amount = 0.1,
    String? inviter,
  })  : inviter = inviter ?? WalletConnectService.easyGameInviter,
        super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  late final TextEditingController uplineController;
  late int selectedLevel;
  late double selectedAmount;

  @override
  void initState() {
    super.initState();
    selectedLevel = widget.level;
    selectedAmount = widget.amount;
    uplineController = TextEditingController(text: widget.inviter ?? '');
  }

  @override
  void dispose() {
    uplineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the Drawer icon color to white
        ),
        title: Row(
          children: [
            Text(
              "Easy Game",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Spacer(),
            // Text(
            //   "Binance Smart Chain BEP-20",
            //   style: TextStyle(color: Colors.grey, fontSize: 12),
            // ),
          ],
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.purple,
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Color(0xFF1A1F2E), // Background color for the drawer
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            // DrawerHeader(
            //   decoration: BoxDecoration(color: Colors.black),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       // CircleAvatar(
            //       //   radius: 30,
            //       //   backgroundColor: Colors.grey, // Placeholder for avatar
            //       // ),
            //       // SizedBox(height: 8),
            //       // Text(
            //       //   "0x47...CB",
            //       //   style: TextStyle(color: Colors.white, fontSize: 16),
            //       // ),
            //       // SizedBox(height: 4),
            //       // Text(
            //       //   "Binance Smart Chain BEP-20",
            //       //   style: TextStyle(color: Colors.grey, fontSize: 14),
            //       // ),
            //     ],
            //   ),
            // ),

            // Top Section Menu Items

            SizedBox(height: 42),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(Icons.dashboard, color: Colors.white),
                    title: Text("Dashboard",
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Dashboard
                      Get.to(() => ProfileScreen());
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.bar_chart, color: Colors.white),
                    title: Text("Statistics",
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      UiNavigationService.openStatistics();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.people, color: Colors.white),
                    title: Text("Affiliate Bonus",
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Partner Bonus
                      Get.to(() => PartnerBonusScreen());
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: Colors.white),
                    title: Text("Information",
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      UiNavigationService.openInformation();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.telegram, color: Colors.white),
                    title: Text("Telegram Bots",
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      UiNavigationService.openTelegramBots();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.campaign, color: Colors.white),
                    title: Text("Promo", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      UiNavigationService.openPromo();
                    },
                  ),
                ],
              ),
            ),

            // Bottom Section Menu Items
            Column(
              children: [
                Divider(color: Colors.grey),
                ListTile(
                  leading: Icon(Icons.notifications, color: Colors.white),
                  title: Text("Notifier Bot",
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    UiNavigationService.openNotifierBot();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.white),
                  title:
                      Text("Settings", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    UiNavigationService.openSettings();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.white),
                  title: Text("Exit", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    walletService.disconnectWallet();
                    Get.offAllNamed('/home');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Fast Registration\nin Easy Game ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Activate Easy Game in one transaction with ETH(base)",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              "Your upline address and ID",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: uplineController,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: "0x...",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final entered = uplineController.text.trim();
                    if (entered.isEmpty) {
                      walletService.clearReferralInviter();
                      Get.snackbar(
                        'Upline cleared',
                        'No upline address will be used',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }

                    final normalized =
                        ReferralLinkService.normalizeAddress(entered);
                    if (normalized.isEmpty) {
                      Get.snackbar(
                        'Invalid upline',
                        'Enter a valid 0x wallet address',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }

                    walletService.setReferralInviter(normalized);
                    uplineController.text = normalized;
                    Get.snackbar(
                      'Upline saved',
                      normalized,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text("Approve upline"),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              "Choose game level",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: Colors.grey[900],
                value:
                    "Level $selectedLevel (${selectedAmount.toStringAsFixed(3)} ETH(base))",
                items: [
                  for (var i = 1; i <= 17; i++)
                    DropdownMenuItem(
                      value:
                          "Level $i (${levelPrice(i).toStringAsFixed(3)} ETH(base))",
                      child: Text(
                        "Level $i (${levelPrice(i).toStringAsFixed(3)} ETH(base))",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  final match = RegExp(r'Level (\d+)').firstMatch(value);
                  final parsedLevel = int.tryParse(match?.group(1) ?? '');
                  if (parsedLevel == null) {
                    return;
                  }
                  setState(() {
                    selectedLevel = parsedLevel;
                    selectedAmount = levelPrice(parsedLevel);
                  });
                },
                underline: SizedBox(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await walletService.ensureBaseSepolia();
                        Get.snackbar(
                          'Network check OK',
                          'Wallet is on Base Sepolia or Ganache',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } catch (e) {
                        Get.snackbar(
                          'Network check failed',
                          '$e',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                    icon: Icon(Icons.network_check, color: Colors.teal),
                    label: Text(
                      "Network check",
                      style: TextStyle(color: Colors.teal, fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.teal, width: 2),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.to(() => ActivateExpressGameScreen(
                            level: selectedLevel,
                            totalAmount: selectedAmount,
                            inviter: uplineController.text.trim(),
                          ));
                    },
                    icon: Icon(Icons.warning, color: Colors.red),
                    label: Text(
                      "${selectedAmount.toStringAsFixed(3)} ETH(base) to open this level",
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red, width: 2),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Get.to(() => ActivateExpressGameScreen(
                      level: selectedLevel,
                      totalAmount: selectedAmount,
                      inviter: uplineController.text.trim(),
                    ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 12),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "Continue to payment (${selectedAmount.toStringAsFixed(3)} ETH(base))",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
