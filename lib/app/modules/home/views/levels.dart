import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:lottery_advance/app/modules/home/views/profilescreen.dart';
import 'package:lottery_advance/app/modules/home/views/registrationlevel.dart';

import '../../lottery/lotteries_view.dart';

class LevelsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 10),
            Text(
              "Express Smart Game",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  "0x47...CB",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    // backgroundImage: AssetImage('assets/avatar.png'),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "0x47...CB",
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
              title: Text(" Profile", style: TextStyle(color: Colors.white)),
              onTap: () {

                     Get.to(() => ProfileScreen());
              },



            ),
            ListTile(
              leading: Icon(Icons.account_balance_wallet, color: Colors.white),
              title: Text("Wallet", style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.white),
              title: Text("Settings", style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.white),
              title: Text("Logout", style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;

          int crossAxisCount = width < 480
              ? 1
              : width < 800
              ? 2
              : width < 1200
              ? 3
              : 4;

          double childAspectRatio = width < 480 ? 1 : 0.85;

          return GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: 9, // 6 levels + 3 special cards
            itemBuilder: (context, index) {
              if (index < 6) {
                return LevelCard(
                  level: 6 - index,
                  coin: 0.1 + (index * 0.1),
                  partnerBonus: 0.05 * (6 - index),
                  levelProfit: 0.4 * (6 - index),
                  fillPercent: (index % 2 == 0) ? 25.99 : 65.46,
                );
              } else if (index == 6) {
                return ActivateCard(
                  level: 4,
                  coin: 0.14,
                );
              } else if (index == 7) {
                return TimeCard(
                  level: 2,
                  coin: 0.07,
                  availableTime: "13 hours",
                );
              } else {
                return TimeCard(
                  level: 1,
                  coin: 0.05,
                  availableTime: "3 days",
                );
              }
            },
          );
        },
      ),
    );
  }
}

class LevelCard extends StatelessWidget {
  final int level;
  final double coin, partnerBonus, levelProfit, fillPercent;

  const LevelCard({
    required this.level,
    required this.coin,
    required this.partnerBonus,
    required this.levelProfit,
    required this.fillPercent,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 1.2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A1F2E),
              Color(0xFF0F131A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Color(0xFF6A4BFF),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6A4BFF).withOpacity(0.7),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Lvl $level",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orangeAccent,
                        radius: 10,
                        child: Icon(
                          Icons.monetization_on,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        coin.toStringAsFixed(2),
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              Spacer(),
              Text(
                "Waiting next line...",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey[800],
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fillPercent / 100,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF2AF598),
                            Color(0xFF009EFD),
                            Color(0xFF6A4BFF),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                "Current line fill",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                "${fillPercent.toStringAsFixed(2)}%",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerBonus.toStringAsFixed(4) + " BNB",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Partner bonus",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        levelProfit.toStringAsFixed(4) + " BNB",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Level profits",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivateCard extends StatelessWidget {
  final int level;
  final double coin;

  const ActivateCard({
    required this.level,
    required this.coin,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 1.2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color(0xFF1A1F2E),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: Text(
                "Lvl $level",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    radius: 10,
                    child: Icon(
                      Icons.monetization_on,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    coin.toStringAsFixed(2),
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Available for activation",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: 120,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF6A4BFF),
                          Color(0xFF2AF598),
                        ],
                      ),
                    ),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(() => RegistrationScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // Закругленные углы
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Внутренние отступы
                        ),
                        child: Text(
                          "Activate",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeCard extends StatelessWidget {
  final int level;
  final double coin;
  final String availableTime;

  const TimeCard({
    required this.level,
    required this.coin,
    required this.availableTime,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 1.2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color(0xFF1A1F2E),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: Text(
                "Lvl $level",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    radius: 10,
                    child: Icon(
                      Icons.monetization_on,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    coin.toStringAsFixed(2),
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, size: 50, color: Colors.orangeAccent),
                  SizedBox(height: 16),
                  Text(
                    "Available in:",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    availableTime,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}