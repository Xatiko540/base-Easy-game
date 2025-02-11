import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/profilescreen.dart';
import 'package:lottery_advance/app/modules/home/views/registrationlevel.dart';

import '../../../services/Notifications.dart';
import 'ActivateExpressGameScreen.dart';
import 'PartnerBonusScreen.dart';

class LevelsScreen extends StatefulWidget {
  final String? walletAddress;

   LevelsScreen({Key? key, this.walletAddress}) : super(key: key);

  @override
  _LevelsScreenState createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {

  Timer? liveTimer;
  List<Level> levels = [];

   String? walletAddress;

  LevelStatus getStatus(int level) {
    if (level <= 3) return LevelStatus.active;
    if (level <= 6) return LevelStatus.waiting;
    return LevelStatus.locked;
  }

  void initializeLevels() {
    // Базовые стоимости уровней и дни разблокировки
    Map<int, double> baseValues = {
      1: 0.01, 2: 0.015, 3: 0.02, 4: 0.03, 5: 0.04, 6: 0.06, 7: 0.09, 8: 0.13,
      9: 0.2, 10: 0.3, 11: 0.4, 12: 0.6, 13: 0.9, 14: 1.3, 15: 2.0, 16: 3.0, 17: 4.0
    };

    Map<int, int> unlockHours = {
      1: 0, 2: 0, 3: 0, 4: 12, 5: 12, 6: 12, 7: 24, 8: 24,
      9: 36, 10: 36, 11: 48, 12: 48, 13: 60, 14: 72, 15: 84, 16: 96, 17: 108
    };

    DateTime now = DateTime.now();

    for (int i = 1; i <= 17; i++) {
      levels.add(Level(
        levelNumber: i,
        status: getStatus(i),
        coin: baseValues[i]!,
        partnerBonus: baseValues[i]! * 0.5,
        levelProfit: baseValues[i]! * 4,
        fillPercent: i <= 3 ? 50 : 0,
        isVisible: i <= 6,
        unlockTime: i > 3 ? now.add(Duration(hours: unlockHours[i]!)) : null,
      ));
    }

    setState(() {});
    startLiveTimer();
  }

  void startLiveTimer() {
    liveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      bool allLevelsUnlocked = true;

      setState(() {
        for (var level in levels) {
          if (level.status == LevelStatus.locked && level.unlockTime != null) {
            final remainingTime = level.unlockTime!.difference(DateTime.now());
            if (remainingTime.isNegative) {
              level.status = LevelStatus.waiting;
              level.isVisible = true;
              print('Level ${level.levelNumber} is now waiting for activation.');
            } else {
              allLevelsUnlocked = false;
            }
          }
        }
      });

      if (allLevelsUnlocked) {
        timer.cancel();
      }
    });
  }

  void activateLevel(Level level) {
    setState(() {
      level.status = LevelStatus.active;
      print('Level ${level.levelNumber} activated');
    });
  }

  void completeLevel(Level level) {
    setState(() {
      level.status = LevelStatus.completed;
      print('Level ${level.levelNumber} completed');
    });

    // Unlock the next level if it exists
    final nextIndex = levels.indexOf(level) + 1;
    if (nextIndex < levels.length) {
      startWaiting(levels[nextIndex]);
    }
  }

  void startWaiting(Level level) {
    setState(() {
      level.status = LevelStatus.waiting;
      print('Level ${level.levelNumber} is waiting for activation');
    });

    // Simulate waiting period with a timer
    Timer(const Duration(seconds: 10), () {
      activateLevel(level);
    });
  }

  void startLevelProgression() {
    Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        updateLevels();
        startLiveTimer();
      });
    });
  }

  // void initializeLevels() {
  //   for (int i = 1; i <= 17; i++) {
  //     levels.add(Level(
  //       levelNumber: i,
  //       isVisible: i == 1, // Только первый уровень виден
  //       coin: 0.1 * i, // Пример стоимости
  //       partnerBonus: 0.05 * i, // Пример бонуса
  //       levelProfit: 0.4 * i, // Пример прибыли
  //       fillPercent: 0, // Уровни изначально пустые
  //     ));
  //   }
  // }

  void updateLevels() {
    setState(() {
      for (var level in levels) {
        if (level.isVisible && level.status == LevelStatus.active) {
          level.fillPercent += 5;
          if (level.fillPercent > 100) {
            level.fillPercent = 100;
            completeLevel(level);
          }
          print('Updated visible level: ${level.levelNumber} -> ${level.fillPercent}%');
        } else {
          int prevIndex = level.levelNumber - 2;
          if (prevIndex >= 0 && levels[prevIndex].fillPercent == 100) {
            level.isVisible = true;
            print('Level ${level.levelNumber} is now visible.');
          }
        }
      }
    });
  }

  void printLevels() {
    for (var level in levels) {
      print(level.toString());
    }
  }


  @override
  void initState() {
    super.initState();
    initializeLevels(); // Инициализация уровней
    updateLevels();
    printLevels();
    // startLevelProgression();
  }

  @override
  void dispose() {
    // Cancel the timer to prevent setState calls after dispose
    liveTimer?.cancel();
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
        title: const Row(
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
              //   child: const Row(
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
              // const SizedBox(width: 8),

              // "0.265 BNB"
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
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
              const SizedBox(width: 8),

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

      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;

          int crossAxisCount = width < 480
              ? 2
              : width < 800
              ? 2
              : width < 1200
              ? 3
              : 4;

          double childAspectRatio = width < 480 ? 1 : 0.85;

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.10, // Horizontal padding
                    vertical: 16, // Vertical padding
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Side: ID and Title
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ID 308435 / Easy game",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Easy game",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Right Side: Amount
                      Text(
                        "0.192 ETH(base)",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.10,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];

                      switch (level.status) {
                        case LevelStatus.locked:
                          return TimeCard(
                            level: level.levelNumber,
                            coin: level.coin,
                            availableTime: level.getRemainingTime(),
                          );
                        case LevelStatus.waiting:
                          return ActivateCard(
                            level: level.levelNumber,
                            onActivate: (Level status) => activateLevel(status),
                            coin: level.coin,
                            status: level.status,
                          );
                        case LevelStatus.active:
                          return LevelCard(
                            level: level.levelNumber,
                            coin: level.coin,
                            partnerBonus: level.partnerBonus,
                            levelProfit: level.levelProfit,
                            fillPercent: level.fillPercent,
                          );
                        case LevelStatus.completed:
                          return LevelCard(
                            level: level.levelNumber,
                            coin: level.coin,
                            partnerBonus: level.partnerBonus,
                            levelProfit: level.levelProfit,
                            fillPercent: 100, // Completed levels always show full progress
                          );
                      }
                    },
                  ),
                ),
                SizedBox(height: 16),
                // Bottom section with table
                BottomTableSection(),
              ],
            ),
          );
        },
      ),

    );
  }
}

class LevelCard extends StatelessWidget {
  final int level;
  final double coin, partnerBonus, levelProfit, fillPercent;

  const LevelCard({Key? key,
    required this.level,
    required this.coin,
    required this.partnerBonus,
    required this.levelProfit,
    required this.fillPercent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the detail screen

        Get.to(() =>  LevelDetailScreen(level: level));


      },
      child: AspectRatio(
        aspectRatio: 1 / 1.2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1A1F2E),
                Color(0xFF0F131A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFF6A4BFF),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A4BFF).withOpacity(0.7),
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
                      "Level $level",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const CircleAvatar(
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
                const Text(
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
                          gradient: const LinearGradient(
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
                const SizedBox(height: 8),
                const Text(
                  "Current line fill",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  "${fillPercent.toStringAsFixed(2)}%",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partnerBonus.toStringAsFixed(4) + " ETH(base)",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          levelProfit.toStringAsFixed(4) + " base",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActivateCard extends StatefulWidget {

  final int level;
  final double coin;
  final LevelStatus status;
  final Function(Level) onActivate;


  const ActivateCard
      ({Key? key,

    required this.level,
    required this.coin,
    required this.status,
    required this.onActivate

  }) : super(key: key);

  @override
  ActivateCardState createState() => ActivateCardState();
}

class ActivateCardState extends State<ActivateCard> {

  Timer? liveTimer;
  List<Level> levels = [];


  void activateLevel(Level level) {
    setState(() {
      level.status = LevelStatus.active;
      print('Level ${level.levelNumber} activated');
    });
  }

  void completeLevel(Level level) {
    setState(() {
      level.status = LevelStatus.completed;
      print('Level ${level.levelNumber} completed');
    });

    // Unlock the next level if it exists
    final nextIndex = levels.indexOf(level) + 1;
    if (nextIndex < levels.length) {
      startWaiting(levels[nextIndex]);
    }
  }

  void startWaiting(Level level) {
    setState(() {
      level.status = LevelStatus.waiting;
      print('Level ${level.levelNumber} is waiting for activation');
    });

    // Simulate waiting period with a timer
    Timer(const Duration(seconds: 10), () {
      activateLevel(level);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          // Navigate to the detail screen


          Get.to(() =>  ActivateCardDetailScreen(level: widget.level));

        },
        child: AspectRatio(
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
                    'Level ${widget.level}',
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
                        widget.coin.toStringAsFixed(2),
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
                        width: 160,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF6A4BFF),
                              Color(0xFF2AF598),
                            ],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Get.to(() => RegistrationScreen(widget.status));

                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, // Делает фон прозрачным
                            shadowColor: Colors.transparent, // Убирает тень
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Закругленные углы
                            ),
                          ),
                          child: Text(
                            "Activate",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
        ));
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
                "Level $level",
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

class BottomTableSection extends StatelessWidget {
  const BottomTableSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            "Marketing legend",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "All prices in ETH(base)",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 16),
          // Таблица
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[900]),
              dataRowColor: MaterialStateProperty.all(Colors.black),
              columns: [
                DataColumn(
                  label: Text(
                    "Type",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Date",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "ID",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Level",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Wallet",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "ETH(base)",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
              rows: [
                _buildRow(Icons.card_giftcard, "02.04.2022 11:14", "ID 310375",
                    4, "0xB634...8CA9C", "0.1036"),
                _buildRow(Icons.card_giftcard, "02.04.2022 10:23", "ID 310112",
                    4, "0x6E322...076E2", "+ gift"),
                _buildRow(Icons.card_giftcard, "02.04.2022 10:13", "ID 310112",
                    5, "0x6E322...076E2", "0.05"),
                _buildRow(Icons.card_giftcard, "02.04.2022 06:56", "ID 308783",
                    5, "0xBf3E...89708", "+ gift"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(IconData icon, String date, String id, int level,
      String wallet, String bnb) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Icon(icon, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(""),
            ],
          ),
        ),
        DataCell(Text(date, style: TextStyle(color: Colors.white))),
        DataCell(Text(id, style: TextStyle(color: Colors.blue))),
        DataCell(Text(level.toString(), style: TextStyle(color: Colors.white))),
        DataCell(
          Row(
            children: [
              Text(wallet, style: TextStyle(color: Colors.white)),
              Icon(Icons.copy, color: Colors.grey, size: 16),
            ],
          ),
        ),
        DataCell(
          Text(
            bnb,
            style: TextStyle(
              color: bnb.contains("gift") ? Colors.green : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class ActivateCardDetailScreen extends StatelessWidget {
  final int level;

  const ActivateCardDetailScreen({Key? key, required this.level}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Level $level",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.10, // 5% horizontal padding
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ID 308435 / Easy Game / Level $level",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 16),
            // Main Content Container
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1F2E), Color(0xFF0F131A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Navigation Arrows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Level Navigation
                      GestureDetector(
                        onTap: () {
                          // Navigate to Previous Level
                        },
                        child: Container(
                          height: 60,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Color(0xFF1A1F2E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                                Text(
                                  "Level ${level + 1}",
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Next Level Navigation
                      GestureDetector(
                        onTap: () {
                          // Navigate to Next Level
                        },
                        child: Container(
                          height: 60,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Color(0xFF1A1F2E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Level ${level - 1}",
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Level Info Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Lvl $level",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
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
                          SizedBox(width: 8),
                          Text(
                            "0.03 ETH(base)",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      "You",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 4),
                  Center(
                    child: Text(
                      "ID 308435",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Progress Bar with Coin
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.94, // 93.99% filled
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF6A4BFF),
                                Color(0xFF009EFD),
                                Color(0xFF2AF598),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        child: CircleAvatar(
                          backgroundColor: Colors.orangeAccent,
                          radius: 10,
                          child: Icon(
                            Icons.monetization_on,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Current line fill: 93.99%",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Stats Row
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           "Missed profit",
                  //           style: TextStyle(color: Colors.grey, fontSize: 14),
                  //         ),
                  //         Text(
                  //           "0 BNB",
                  //           style: TextStyle(color: Colors.white, fontSize: 14),
                  //         ),
                  //       ],
                  //     ),
                  //     Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           "Total level profit",
                  //           style: TextStyle(color: Colors.grey, fontSize: 14),
                  //         ),
                  //         Text(
                  //           "0.1036 BNB",
                  //           style: TextStyle(color: Colors.white, fontSize: 14),
                  //         ),
                  //       ],
                  //     ),
                  //     Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           "Total partner bonus",
                  //           style: TextStyle(color: Colors.grey, fontSize: 14),
                  //         ),
                  //         Text(
                  //           "0.0364 BNB",
                  //           style: TextStyle(color: Colors.white, fontSize: 14),
                  //         ),
                  //       ],
                  //     ),
                  //   ],
                  // ),
                  SizedBox(height: 16),
                  // Activate Button
                  Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 300), // Maximum width for the button
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF8A00D4),
                            Color(0xFF0078FF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle Activate Button
                          Get.to(() => ActivateExpressGameScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Activate",
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Transaction History Section
            Text(
              "Transaction History",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Center(child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DataTable(
                columns: const [
                  DataColumn(
                    label: Text(
                      "Type",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Date",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "ID",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Level",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Wallet",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "ETH(base)",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                rows: List<DataRow>.generate(
                  5,
                      (index) => DataRow(
                    cells: [
                      DataCell(Text("Gift", style: TextStyle(color: Colors.white))),
                      DataCell(Text("02.04.2022", style: TextStyle(color: Colors.white))),
                      DataCell(Text("ID $index", style: TextStyle(color: Colors.white))),
                      DataCell(Text("$level", style: TextStyle(color: Colors.white))),
                      DataCell(Text("0xB...9F", style: TextStyle(color: Colors.white))),
                      DataCell(Text("0.10 base", style: TextStyle(color: Colors.white))),
                    ],
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

class LevelDetailScreen extends StatelessWidget {
  final int level;

  const LevelDetailScreen({Key? key, required this.level}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Level $level",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05, // 5% horizontal padding
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ID 308435 / Easy Game / Level $level",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 16),
            // Main Content Container
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1F2E), Color(0xFF0F131A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Navigation Arrows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Level Navigation
                      GestureDetector(
                        onTap: () {
                          // Navigate to Previous Level
                        },
                        child: Container(
                          height: 60,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Color(0xFF1A1F2E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                                Text(
                                  "Level ${level + 1}",
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Next Level Navigation
                      GestureDetector(
                        onTap: () {
                          // Navigate to Next Level
                        },
                        child: Container(
                          height: 60,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Color(0xFF1A1F2E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Level ${level - 1}",
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Level Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Lvl $level",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
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
                          SizedBox(width: 8),
                          Text(
                            "0.02 ETH(base)",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      "You",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 4),
                  Center(
                    child: Text(
                      "ID 308435",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Progress Bar with Coin
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.94,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF6A4BFF),
                                Color(0xFF009EFD),
                                Color(0xFF2AF598),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        child: CircleAvatar(
                          backgroundColor: Colors.orangeAccent,
                          radius: 10,
                          child: Icon(
                            Icons.monetization_on,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Current line fill: 93.99%",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Missed profit", style: TextStyle(color: Colors.grey, fontSize: 14)),
                          Text("0 ETH(base)", style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Total level profit", style: TextStyle(color: Colors.grey, fontSize: 14)),
                          Text("0.1036 ETH(base)", style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Total partner bonus", style: TextStyle(color: Colors.grey, fontSize: 14)),
                          Text("0.0364 ETH(base)", style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Activate Button

                ],
              ),
            ),
            SizedBox(height: 16),
            // Transaction History Section
            Text(
              "Transaction History",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Center(child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DataTable(
                columns: const [
                  DataColumn(
                    label: Text("Type", style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label: Text("Date", style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label: Text("ID", style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label: Text("Level", style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label: Text("Wallet", style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label: Text("ETH(base)", style: TextStyle(color: Colors.white)),
                  ),
                ],
                rows: List<DataRow>.generate(
                  5,
                      (index) => DataRow(
                    cells: [
                      DataCell(Text("Gift", style: TextStyle(color: Colors.white))),
                      DataCell(Text("02.04.2022", style: TextStyle(color: Colors.white))),
                      DataCell(Text("ID $index", style: TextStyle(color: Colors.white))),
                      DataCell(Text("$level", style: TextStyle(color: Colors.white))),
                      DataCell(Text("0xB...9F", style: TextStyle(color: Colors.white))),
                      DataCell(Text("0.10 BNB", style: TextStyle(color: Colors.white))),
                    ],
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

enum LevelStatus { locked, active, waiting, completed }

class Level {
  final int levelNumber;
  LevelStatus status;
  final double coin;
  final double partnerBonus;
  final double levelProfit;
  double fillPercent;
  bool isVisible;
  DateTime? unlockTime; // Time when the level becomes available

  Level({
    required this.levelNumber,
    required this.status,
    required this.coin,
    required this.partnerBonus,
    required this.levelProfit,
    required this.fillPercent,
    required this.isVisible,
    this.unlockTime,
  });


  // Example for JSON serialization
  Map<String, dynamic> toJson() => {
    'levelNumber': levelNumber,
    'status': status.toString(),
    'coin': coin,
    'partnerBonus': partnerBonus,
    'levelProfit': levelProfit,
    'fillPercent': fillPercent,
    'isVisible': isVisible,
  };

  factory Level.fromJson(Map<String, dynamic> json) => Level(
    levelNumber: json['levelNumber'],
    status: LevelStatus.values.firstWhere((e) => e.toString() == json['status']),
    coin: json['coin'],
    partnerBonus: json['partnerBonus'],
    levelProfit: json['levelProfit'],
    fillPercent: json['fillPercent'],
    isVisible: json['isVisible'],
  );

  String getRemainingTime() {
    if (unlockTime == null) return '';
    final duration = unlockTime!.difference(DateTime.now());
    if (duration.isNegative) return 'Available now';

    if (duration.inHours < 1) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else if (duration.inDays < 1) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m';
    }
  }
}
