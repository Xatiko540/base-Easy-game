import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:lottery_advance/app/modules/home/views/profilescreen.dart';

import '../../../services/Notifications.dart';

class PartnerBonusScreen extends StatelessWidget {
  final String walletAddress = "0x7C...65";

  const PartnerBonusScreen({Key? key}) : super(key: key); // Пример значения кошелька

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
              "Partner Bonus",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(width: 8),
            Text(
              "ID 308435",
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              // "Умная сеть"
              // Container(
              //   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //   decoration: BoxDecoration(
              //     color: Colors.grey[800],
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(Icons.network_cell, color: Colors.yellow, size: 16),
              //       SizedBox(width: 4),
              //       Text(
              //         "Умная сеть",
              //         style: TextStyle(color: Colors.white, fontSize: 14),
              //       ),
              //     ],
              //   ),
              // ),
              // SizedBox(width: 8),

              // "0.265 BNB"
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.monetization_on, color: Colors.yellow, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "0.265 BNB",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),

              // "Кошелек"
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  walletAddress,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              SizedBox(width: 8),

              // Icons
              // IconButton(
              //   onPressed: () {
              //     // Search action
              //   },
              //   icon: Icon(Icons.search, color: Colors.white),
              // ),
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    backgroundColor: Colors.black,
                    builder: (context) => NotificationsBottomSheet(),
                  );
                },
                icon: Icon(Icons.notifications, color: Colors.white),
              ),
              IconButton(
                onPressed: () {
                  // Refresh action
                },
                icon: Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1A1F2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Color(0xFF1A1F2E)),
                  columnSpacing: 16,
                  columns: [
                    DataColumn(
                      label: Text(
                        "Date",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Wallet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "ID",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Partner Bonus %",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Express Levels",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Total Bonus Received",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                  rows: List<DataRow>.generate(
                    2,
                        (index) => DataRow(
                      cells: [
                        DataCell(Text(
                          index == 0 ? "02.04.2022 13:13" : "01.04.2022 23:50",
                          style: TextStyle(color: Colors.white),
                        )),
                        DataCell(Row(
                          children: [
                            Text(
                              index == 0 ? "0x8E32...762E" : "0xB8F3...9708",
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.copy, color: Colors.white, size: 16),
                          ],
                        )),
                        DataCell(Text(
                          index == 0 ? "ID 310112" : "ID 308783",
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        )),
                        DataCell(Text(
                          index == 0 ? "0" : "13",
                          style: TextStyle(color: Colors.white),
                        )),
                        DataCell(Text(
                          index == 0 ? "4" : "5",
                          style: TextStyle(color: Colors.white),
                        )),
                        DataCell(Text(
                          "0.0442 BNB",
                          style: TextStyle(color: Colors.white),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),)
          ],
        ),
      ),
    );
  }
}