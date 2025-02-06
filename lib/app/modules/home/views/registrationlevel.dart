import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/profilescreen.dart';

import 'PartnerBonusScreen.dart';
import 'levels.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen(LevelStatus level1, {Key? key}) : super(key: key);

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
                    title: Text("Панель приборов", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Dashboard
                      Get.to(() => const ProfileScreen());
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.bar_chart, color: Colors.white),
                    title: Text("Статистика", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Statistics
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.people, color: Colors.white),
                    title: Text("Партнерский бонус", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Partner Bonus
                      Get.to(() =>  PartnerBonusScreen());
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: Colors.white),
                    title: Text("Информация", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Information
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.telegram, color: Colors.white),
                    title: Text("Telegram-боты", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Telegram Bots
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.campaign, color: Colors.white),
                    title: Text("Промо", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Promo
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
                  title: Text("Бот-уведомитель", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    // Navigate to Bot Notifier
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.white),
                  title: Text("Настройки", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    // Navigate to Settings
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.white),
                  title: Text("Выход", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    // Handle Logout
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
              "Fast Registration\nin Express Game",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Activate Express Game in one transaction with BNB",
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
                    child: Text(
                      "0x47F77fe423981863c1bbd3DD57216f97c49346CB",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
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
                value: "Level 3 (0.1 BNB)",
                items: [
                  DropdownMenuItem(
                    value: "Level 3 (0.1 BNB)",
                    child: Text(
                      "Level 3 (0.1 BNB)",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Level 4 (0.2 BNB)",
                    child: Text(
                      "Level 4 (0.2 BNB)",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                onChanged: (value) {},
                underline: SizedBox(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
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
                    onPressed: () {},
                    icon: Icon(Icons.warning, color: Colors.red),
                    label: Text(
                      "0.1 BNB to open this level",
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
                "Check again (0.12729 BNB)",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}