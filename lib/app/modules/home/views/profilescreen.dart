import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/Notifications.dart';
import 'PartnerBonusScreen.dart';
import 'levels.dart';




class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key, this.walletAddress}) : super(key: key);

  final String? walletAddress;

  final String referralLink = "https://express.game/npalce";

  void copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: referralLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Link copied to clipboard!")),
    );
  }

  void shareLink(BuildContext context) async {
    final Uri url = Uri.parse(referralLink);

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to open link!")),
      );
    }
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
              // SizedBox(width: 2),

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
                      "0.265 ETH(base)",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2),

              // "0x7C...65"
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  walletAddress == null
                      ? "Not logged in" // Текст до логина
                      : walletAddress!, // Адрес кошелька после логина
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              SizedBox(width: 2),

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
                    title: Text("Instrument panel", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Dashboard
                      Get.to(() => const ProfileScreen());
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.bar_chart, color: Colors.white),
                    title: Text("Statistics", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Statistics
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.people, color: Colors.white),
                    title: Text("Affiliate bonus", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Partner Bonus
                      Get.to(() =>  PartnerBonusScreen());
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: Colors.white),
                    title: Text("Information", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Information
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.telegram, color: Colors.white),
                    title: Text("Telegram bots", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to Telegram Bots
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.campaign, color: Colors.white),
                    title: Text("Promo", style: TextStyle(color: Colors.white)),
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
                  title: Text("Notifier Bot", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    // Navigate to Bot Notifier
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.white),
                  title: Text("Settings", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    // Navigate to Settings
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.white),
                  title: Text("Exit", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    // Handle Logout
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(

        padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.10),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Easy game",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "ID 308435",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "My personal link",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Tooltip(
                            message: "Read more",
                            child: Icon(Icons.info_outline, color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "express.game/npalce",
                            style: TextStyle(color: Colors.blue, fontSize: 16),
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => copyToClipboard(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text("Copy"),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => shareLink(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text("Share"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Special games with unique logic and mechanics, based entirely on smart contracts.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 16),


            // Секция карточек
            Text(
              "Program",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: index % 2 == 0
                          ? [Color(0xFF1A1F2E), Color(0xFF0F131A)]
                          : [Color(0xFF8A00D4), Color(0xFF0078FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "x${index + 3}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        // Добавляем сетку ячеек внутри карточки
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: List.generate(
                                3, // Количество ячеек в первом ряду
                                    (i) => Container(
                                  width: 20,
                                  height: 20,
                                  margin: EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: i == 2 ? Colors.green : Colors.grey[800],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: i == 2
                                      ? Icon(Icons.check, color: Colors.white, size: 12)
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: List.generate(
                                3, // Количество ячеек во втором ряду
                                    (i) => Container(
                                  width: 20,
                                  height: 20,
                                  margin: EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: i == 5 ? Colors.purple : Colors.grey[800],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: i == 5
                                      ? Icon(Icons.star, color: Colors.white, size: 12)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        Text(
                          "${(index + 1) * 20} ETH(base)",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text("Upgrade ${(index + 1) * 10} ETH(base)",

                              style: TextStyle(fontSize: 16, color: Colors.white),

                          ),



                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16),





            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1F2E), Color(0xFF0F131A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Easy game",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "0.192 ETH(base)",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Column(
                    children: [
                      // Первый ряд ячеек
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start, // Выравнивание влево
                        children: List.generate(
                          3,
                              (index) => Container(
                            width: 32, // Ширина ячейки
                            height: 32, // Высота ячейки
                            margin: EdgeInsets.only(right: 8), // Промежуток между ячейками
                            decoration: BoxDecoration(
                              color: index == 5 ? Colors.purple : Colors.grey[800],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: index == 2
                                ? Icon(Icons.access_time, color: Colors.white, size: 16)
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Второй ряд ячеек
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start, // Выравнивание влево
                        children: List.generate(
                         3,
                              (index) => Container(
                            width: 32, // Ширина ячейки
                            height: 32, // Высота ячейки
                            margin: EdgeInsets.only(right: 8), // Промежуток между ячейками
                            decoration: BoxDecoration(
                              color: index == 3 ? Colors.green : Colors.grey[800],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: index == 3
                                ? Icon(Icons.access_time, color: Colors.white, size: 16)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Кнопка
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8A00D4), Color(0xFF0078FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {

                        Get.to(() => LevelsScreen());

                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Into the program view",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и описание
              Text(
                "0 Easy Game ",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "The world's first smart contract game with passive income in BNB directly to your wallet."
                    " All players are randomly placed on 16 levels with unlimited cycles. Rewards are distributed as follows:",
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                "- 74% of the level cost for each cycle of your level\n"
                    "- 13%-8%-5% of the level value from partners up to 3 deep whenever they earn",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              SizedBox(height: 16),
              // Раздел с видео и презентациями
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Видео-презентация
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "Easy Game \n[VIDEO PLACEHOLDER]",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Презентации и кнопка
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Easy Game  presentations",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              _presentationRow("English", Icons.flag),
                              _presentationRow("Hindi", Icons.language),
                              // _presentationRow("русский", Icons.flag_circle),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            minimumSize: Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text("Find out more about Express"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Информация о контрактах
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Easy Game  Contracts",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Express", style: TextStyle(color: Colors.grey[400])),
                        Row(
                          children: [
                            Text("0x4c9...d2B", style: TextStyle(color: Colors.white)),
                            SizedBox(width: 4),
                            Icon(Icons.copy, color: Colors.white, size: 16),
                          ],
                        ),
                      ],
                    ),
                    Divider(color: Colors.grey[600]),
                    _infoRow("Total participants", "2 280"),
                    _infoRow("The deals are done", "9 937"),
                    _infoRow("Turnover, ETH(base)", "11 785.48"),
                  ],
                ),
              ),
            ],
          ),
        ),
            SizedBox(height: 16),
            Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок раздела
              Row(
                children: [
                  Text(
                    "Easy Game  recent activity",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.info_outline, color: Colors.grey, size: 16),
                ],
              ),
              SizedBox(height: 16),
              // Список активности
              Column(
                children: List.generate(8, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Иконка и информация
                        Row(
                          children: [
                            Icon(
                              index % 2 == 0 ? Icons.person : Icons.monetization_on,
                              color: index % 2 == 0 ? Colors.green : Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "ID ${305521 + index}",
                                      style: TextStyle(color: Colors.blue, fontSize: 14),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      index % 2 == 0
                                          ? "activated"
                                          : "+ affiliate bonus 0.${(index + 1) * 7} ETH(base)",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Text(
                                  "${index % 2 == 0 ? "6 level" : "4 level"}  Express",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Время и кнопка
                        Row(
                          children: [
                            Text(
                              "1 minute",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.open_in_new, color: Colors.grey, size: 16),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ),
              SizedBox(height: 16),
              // Кнопка "Узнать больше"
              Center(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Find out more",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
            SizedBox(height: 16),




        ],
        ),
      ),

    );
  }

  // Виджет для отображения строки презентации
  Widget _presentationRow(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          Icon(Icons.download, color: Colors.white, size: 16),
        ],
      ),
    );
  }

// Виджет для строки информации
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}

class ReferralLinkWidget extends StatelessWidget {
  final String referralLink = "https://express.game/npalce";

  const ReferralLinkWidget({Key? key}) : super(key: key);

  void copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: referralLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Ссылка скопирована в буфер обмена!")),
    );
  }

  void shareLink(BuildContext context) async {
    final Uri url = Uri.parse(referralLink);

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Не удалось открыть ссылку!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My personal link",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Tooltip(
                message: "Read more",
                child: Icon(Icons.info_outline, color: Colors.grey),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                referralLink,
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => copyToClipboard(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("Copy"),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => shareLink(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("Share"),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}