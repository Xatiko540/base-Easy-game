import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/registrationlevel.dart';

import 'levels.dart';

class ExpressGameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            // Image.asset(
            //   'assets/express_logo.png', // Логотип
            //   height: 30,
            // ),
            SizedBox(width: 10),
            Text(
              "express.game",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "0xC5...48",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            SizedBox(width: 10),
          ],
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.black,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.grey[900]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[700],
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "0xC5...48",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Binance Smart Chain BEP-20",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.home, color: Colors.white),
                title: Text("Home", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Get.to(() => LevelsScreen());
                },
              ),
              ListTile(
                leading: Icon(Icons.account_balance_wallet, color: Colors.white),
                title: Text("Wallet", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Get.to(() => WalletScreen());
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.white),
                title: Text("Settings", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Get.to(() => SettingsScreen());
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.white),
                title: Text("Logout", style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Add logout logic here
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10CFCF), Color(0xFF047CF9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Image.asset(
                          //   'assets/people_icon.png', // Первая иконка
                          //   height: 50,
                          // ),
                          SizedBox(width: 10),
                          Icon(Icons.add, size: 40, color: Colors.white),
                          SizedBox(width: 10),
                          // Image.asset(
                          //   'assets/controller_icon.png', // Вторая иконка
                          //   height: 50,
                          // ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Express Game",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Join Forsage BUSD and Activate Express in one transaction with BNB",
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {

                              Get.to(() => RegistrationScreen());

                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Fast Registration",
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.send, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    "Level 2 available in: 01d 00h 55m 55s",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Preview Mode",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Look up any Express game member account in preview mode. Enter ID or BNB address to preview.",
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ),
          ],
        ),
      ),

    );
  }
}

// Заглушки для других экранов
class WalletScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text("Wallet Screen", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text("Settings Screen", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}