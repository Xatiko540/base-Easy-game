import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/profilescreen.dart';
import 'package:lottery_advance/app/modules/home/views/registrationlevel.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

import '../../../services/Notifications.dart';
import 'PartnerBonusScreen.dart';

double levelPrice(int level) {
  const prices = {
    1: 0.01,
    2: 0.015,
    3: 0.02,
    4: 0.03,
    5: 0.04,
    6: 0.06,
    7: 0.09,
    8: 0.13,
    9: 0.2,
    10: 0.3,
    11: 0.4,
    12: 0.6,
    13: 0.9,
    14: 1.3,
    15: 2.0,
    16: 3.0,
    17: 4.0,
  };
  return prices[level] ?? 0.01;
}

String formatWeiToEth(BigInt wei, {int decimals = 4}) {
  final base = BigInt.from(10).pow(18);
  final whole = wei ~/ base;
  final fraction = (wei % base).toString().padLeft(18, '0');
  final clipped = fraction.substring(0, decimals);
  final trimmed = clipped.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.isEmpty ? whole.toString() : '$whole.$trimmed';
}

double weiToEthDouble(BigInt wei) {
  final base = BigInt.from(10).pow(18);
  final whole = wei ~/ base;
  final fraction = wei % base;
  return whole.toDouble() + fraction.toDouble() / base.toDouble();
}

class LevelsProvider extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();

  final RxList<Level> levels = <Level>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  String? playerAddress;

  BigInt get totalEarnedWei => levels.fold<BigInt>(
        BigInt.zero,
        (sum, level) => sum + level.earnedWei,
      );

  int get activeLevels => levels
      .where((level) =>
          level.status == LevelStatus.active ||
          level.status == LevelStatus.frozen)
      .length;

  void configure({String? playerAddress}) {
    this.playerAddress = playerAddress;
    if (levels.isEmpty) {
      levels.assignAll(_initialLevels());
    }
    refreshFromContract();
  }

  Future<void> refreshFromContract() async {
    if (!walletService.isConnected.value && playerAddress == null) {
      errorMessage.value = 'Connect wallet to read EasyGame level state.';
      levels.assignAll(_initialLevels());
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final nextLevels = <Level>[];
      for (var levelNumber = 1; levelNumber <= 17; levelNumber++) {
        nextLevels.add(await _loadLevel(levelNumber));
      }
      levels.assignAll(nextLevels);
    } catch (e) {
      errorMessage.value = 'Unable to refresh EasyGame levels: $e';
      if (kDebugMode) {
        print(errorMessage.value);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<Level> _loadLevel(int levelNumber) async {
    final priceWei = await walletService.getEasyGameLevelPriceWei(levelNumber);
    final state = await walletService.getEasyGameLevel(
      playerAddress: playerAddress,
      level: levelNumber,
    );
    final matrixStats = await walletService.getEasyGameMatrixStats(levelNumber);
    final previousActive = levelNumber == 1
        ? true
        : await walletService.isEasyGameLevelActive(
            playerAddress: playerAddress,
            level: levelNumber - 1,
          );

    final status = state.active
        ? state.frozen
            ? LevelStatus.frozen
            : LevelStatus.active
        : previousActive
            ? LevelStatus.waiting
            : LevelStatus.locked;

    return Level(
      levelNumber: levelNumber,
      status: status,
      coin: weiToEthDouble(priceWei),
      partnerBonus: weiToEthDouble(priceWei) * 0.095,
      levelProfit: weiToEthDouble(state.earnedWei),
      fillPercent: _fillPercent(state, matrixStats),
      isVisible: previousActive || state.active || levelNumber == 1,
      cycles: state.cycles,
      positionId: state.positionId,
      earnedWei: state.earnedWei,
      matrixSize: matrixStats.size,
    );
  }

  List<Level> _initialLevels() {
    return [
      for (var i = 1; i <= 17; i++)
        Level(
          levelNumber: i,
          status: i == 1 ? LevelStatus.waiting : LevelStatus.locked,
          coin: levelPrice(i),
          partnerBonus: levelPrice(i) * 0.095,
          levelProfit: 0,
          fillPercent: 0,
          isVisible: i == 1,
        ),
    ];
  }

  double _fillPercent(
    EasyGameLevelState state,
    EasyGameMatrixStats matrixStats,
  ) {
    if (!state.active || matrixStats.size == BigInt.zero) {
      return 0;
    }
    if (state.positionId == BigInt.zero) {
      return 0;
    }

    final filled = state.positionId.toDouble();
    final total = matrixStats.size.toDouble();
    if (total <= 0) {
      return 0;
    }
    return ((filled / total) * 100).clamp(0, 100).toDouble();
  }
}

class LevelsScreen extends StatefulWidget {
  final String? walletAddress;

  LevelsScreen({Key? key, this.walletAddress}) : super(key: key);

  @override
  _LevelsScreenState createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  late final String providerTag;
  late final LevelsProvider levelsProvider;

  @override
  void initState() {
    super.initState();
    providerTag = widget.walletAddress ?? 'connected-wallet';
    levelsProvider = Get.put(LevelsProvider(), tag: providerTag);
    levelsProvider.configure(playerAddress: widget.walletAddress);
  }

  @override
  void dispose() {
    if (Get.isRegistered<LevelsProvider>(tag: providerTag)) {
      Get.delete<LevelsProvider>(tag: providerTag);
    }
    super.dispose();
  }

  Widget _buildLevelCard(Level level) {
    switch (level.status) {
      case LevelStatus.locked:
        return StatusCard(
          level: level.levelNumber,
          coin: level.coin,
          title: 'Locked',
          subtitle: 'Activate previous level first',
          icon: Icons.lock,
          color: Colors.grey,
        );
      case LevelStatus.frozen:
        return StatusCard(
          level: level.levelNumber,
          coin: level.coin,
          title: 'Frozen',
          subtitle: 'Activate next level to unfreeze',
          icon: Icons.ac_unit,
          color: Colors.lightBlueAccent,
          onTap: () => Get.to(
            () => EasyGameLevelDetailScreen(level: level.levelNumber),
          ),
        );
      case LevelStatus.waiting:
        return ActivateCard(
          level: level.levelNumber,
          coin: level.coin,
          status: level.status,
        );
      case LevelStatus.active:
      case LevelStatus.completed:
        return LevelCard(
          level: level.levelNumber,
          coin: level.coin,
          partnerBonus: level.partnerBonus,
          levelProfit: level.levelProfit,
          fillPercent: level.fillPercent,
          cycles: level.cycles,
          positionId: level.positionId,
          earnedWei: level.earnedWei,
          matrixSize: level.matrixSize,
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

              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(
                  () => Row(
                    children: [
                      Icon(Icons.monetization_on,
                          color: Colors.yellow, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "${formatWeiToEth(levelsProvider.totalEarnedWei)} ETH(base)",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
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
                child: Obx(
                  () => Text(
                    walletService.isConnected.value
                        ? walletService.shortAddress
                        : "Not logged in",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
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
                onPressed: levelsProvider.refreshFromContract,
                icon: Icon(Icons.refresh, color: Colors.white),
              ),
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    backgroundColor: Colors.black,
                    builder: (context) => NotificationsBottomSheet(),
                  );
                },
                icon: Icon(Icons.notifications, color: Colors.white),
              ),
              IconButton(
                onPressed: () {
                  walletService.disconnectWallet();
                  Get.offAllNamed('/home');
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
                    title: Text("Instrument panel",
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
                    title: Text("Affiliate bonus",
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
                    title: Text("Telegram bots",
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
                    horizontal: MediaQuery.of(context).size.width *
                        0.10, // Horizontal padding
                    vertical: 16, // Vertical padding
                  ),
                  child: Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.walletAddress == null
                                    ? walletService.shortAddress
                                    : "Preview ${widget.walletAddress!.substring(0, 6)}...${widget.walletAddress!.substring(widget.walletAddress!.length - 4)}",
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
                          Text(
                            "${formatWeiToEth(levelsProvider.totalEarnedWei)} ETH(base)",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.10,
                  ),
                  child: Obx(
                    () => Column(
                      children: [
                        if (levelsProvider.errorMessage.value.isNotEmpty)
                          _LevelStateBanner(
                            message: levelsProvider.errorMessage.value,
                            onRefresh: levelsProvider.refreshFromContract,
                          ),
                        if (levelsProvider.isLoading.value)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: LinearProgressIndicator(),
                          ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemCount: levelsProvider.levels.length,
                          itemBuilder: (context, index) {
                            final level = levelsProvider.levels[index];
                            return _buildLevelCard(level);
                          },
                        ),
                      ],
                    ),
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
  final BigInt cycles, positionId, earnedWei, matrixSize;

  const LevelCard({
    Key? key,
    required this.level,
    required this.coin,
    required this.partnerBonus,
    required this.levelProfit,
    required this.fillPercent,
    required this.cycles,
    required this.positionId,
    required this.earnedWei,
    required this.matrixSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the detail screen

        Get.to(() => EasyGameLevelDetailScreen(level: level));
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
                  "Active matrix",
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
                  "Matrix progress",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  matrixSize == BigInt.zero
                      ? "No matrix data"
                      : "${fillPercent.toStringAsFixed(2)}%",
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
                          "Cycles ${cycles.toString()}",
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
                          "${formatWeiToEth(earnedWei)} ETH earned",
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
                const SizedBox(height: 4),
                Text(
                  "Position ${positionId.toString()} / matrix ${matrixSize.toString()}",
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActivateCard extends StatelessWidget {
  final int level;
  final double coin;
  final LevelStatus status;

  const ActivateCard({
    Key? key,
    required this.level,
    required this.coin,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          // Navigate to the detail screen

          Get.to(() => EasyGameLevelDetailScreen(level: level));
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
                    'Level $level',
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
                        coin.toStringAsFixed(3),
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
                            Get.to(() => RegistrationScreen(
                                  status,
                                  level: level,
                                  amount: coin,
                                  inviter: Get.find<WalletConnectService>()
                                      .activeInviter,
                                ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.transparent, // Делает фон прозрачным
                            shadowColor: Colors.transparent, // Убирает тень
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8), // Закругленные углы
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

class StatusCard extends StatelessWidget {
  final int level;
  final double coin;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatusCard({
    Key? key,
    required this.level,
    required this.coin,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1 / 1.2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF1A1F2E),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${coin.toStringAsFixed(3)} ETH',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              Icon(icon, size: 44, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelStateBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;

  const _LevelStateBanner({
    required this.message,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orangeAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRefresh,
            child: const Text('Refresh'),
          ),
        ],
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
          Text(
            "Level activity",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "On-chain events are emitted by EasyGame. A full activity table needs the event listener/indexer to persist history.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 16),
          _EventStatusRow(
            icon: Icons.account_tree,
            title: "MatrixPlaced",
            description: "Placement events for new level positions.",
          ),
          _EventStatusRow(
            icon: Icons.payments,
            title: "MatrixRewardPaid / ReferralPaid",
            description: "Reward events emitted after activation payment.",
          ),
          _EventStatusRow(
            icon: Icons.autorenew,
            title: "Recycled / LevelFrozen / LevelUnfrozen",
            description: "Cycle and freeze state changes emitted by contract.",
          ),
        ],
      ),
    );
  }
}

class _EventStatusRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EventStatusRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 3),
                Text(description,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EasyGameLevelDetailScreen extends StatelessWidget {
  final int level;

  EasyGameLevelDetailScreen({Key? key, required this.level}) : super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();

  Future<_LevelDetailSnapshot> _load() async {
    final state = await walletService.getEasyGameLevel(level: level);
    final stats = await walletService.getEasyGameMatrixStats(level);
    final priceWei = await walletService.getEasyGameLevelPriceWei(level);
    return _LevelDetailSnapshot(
      state: state,
      stats: stats,
      priceWei: priceWei,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Level $level",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: FutureBuilder<_LevelDetailSnapshot>(
        future: _load(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.08,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LevelNavButton(
                      label: "Level ${level <= 1 ? 1 : level - 1}",
                      icon: Icons.arrow_back_ios,
                      enabled: level > 1,
                      onTap: () => Get.off(
                        () => EasyGameLevelDetailScreen(level: level - 1),
                      ),
                    ),
                    _LevelNavButton(
                      label: "Level ${level >= 17 ? 17 : level + 1}",
                      icon: Icons.arrow_forward_ios,
                      trailing: true,
                      enabled: level < 17,
                      onTap: () => Get.off(
                        () => EasyGameLevelDetailScreen(level: level + 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),
                if (snapshot.hasError)
                  _LevelStateBanner(
                    message: 'Unable to load level details: ${snapshot.error}',
                    onRefresh: () => Get.off(
                      () => EasyGameLevelDetailScreen(level: level),
                    ),
                  ),
                if (data != null) ...[
                  _LevelDetailPanel(
                    title: 'Level status',
                    rows: [
                      _DetailRow('Price',
                          '${formatWeiToEth(data.priceWei)} ETH(base)'),
                      _DetailRow('Active', data.state.active ? 'Yes' : 'No'),
                      _DetailRow('Frozen', data.state.frozen ? 'Yes' : 'No'),
                      _DetailRow('Cycles', data.state.cycles.toString()),
                      _DetailRow(
                          'Position ID', data.state.positionId.toString()),
                      _DetailRow('Earned',
                          '${formatWeiToEth(data.state.earnedWei)} ETH(base)'),
                    ],
                  ),
                  _LevelDetailPanel(
                    title: 'Matrix',
                    rows: [
                      _DetailRow('Matrix size', data.stats.size.toString()),
                      _DetailRow(
                        'Next open parent',
                        data.stats.nextOpenParentId.toString(),
                      ),
                      _DetailRow(
                        'Fill indicator',
                        data.stats.size == BigInt.zero
                            ? 'No matrix data'
                            : '${_detailFillPercent(data).toStringAsFixed(2)}%',
                      ),
                    ],
                  ),
                  _LevelDetailPanel(
                    title: 'Activity',
                    rows: const [
                      _DetailRow(
                        'History source',
                        'On-chain event/indexer connection required',
                      ),
                      _DetailRow(
                        'Events',
                        'MatrixPlaced, Rewards, ReferralPaid, Recycle, Freeze',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!data.state.active)
                    ElevatedButton(
                      onPressed: () {
                        Get.to(() => RegistrationScreen(
                              LevelStatus.waiting,
                              level: level,
                              amount: weiToEthDouble(data.priceWei),
                              inviter: walletService.activeInviter,
                            ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Activate level',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  double _detailFillPercent(_LevelDetailSnapshot data) {
    if (data.stats.size == BigInt.zero ||
        data.state.positionId == BigInt.zero) {
      return 0;
    }
    return ((data.state.positionId.toDouble() / data.stats.size.toDouble()) *
            100)
        .clamp(0, 100)
        .toDouble();
  }
}

class _LevelDetailSnapshot {
  final EasyGameLevelState state;
  final EasyGameMatrixStats stats;
  final BigInt priceWei;

  const _LevelDetailSnapshot({
    required this.state,
    required this.stats,
    required this.priceWei,
  });
}

class _LevelDetailPanel extends StatelessWidget {
  final String title;
  final List<_DetailRow> rows;

  const _LevelDetailPanel({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.label,
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);
}

class _LevelNavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool trailing;
  final bool enabled;
  final VoidCallback onTap;

  const _LevelNavButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.trailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = [
      Icon(icon, color: enabled ? Colors.white : Colors.grey, size: 16),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.grey,
          fontSize: 14,
        ),
      ),
    ];
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: trailing ? content.reversed.toList() : content,
        ),
      ),
    );
  }
}

enum LevelStatus { locked, frozen, active, waiting, completed }

class Level {
  final int levelNumber;
  LevelStatus status;
  double coin;
  double partnerBonus;
  double levelProfit;
  double fillPercent;
  bool isVisible;
  DateTime? unlockTime; // Time when the level becomes available
  late BigInt cycles;
  late BigInt positionId;
  late BigInt earnedWei;
  late BigInt matrixSize;

  Level({
    required this.levelNumber,
    required this.status,
    required this.coin,
    required this.partnerBonus,
    required this.levelProfit,
    required this.fillPercent,
    required this.isVisible,
    this.unlockTime,
    BigInt? cycles,
    BigInt? positionId,
    BigInt? earnedWei,
    BigInt? matrixSize,
  }) {
    this.cycles = cycles ?? BigInt.zero;
    this.positionId = positionId ?? BigInt.zero;
    this.earnedWei = earnedWei ?? BigInt.zero;
    this.matrixSize = matrixSize ?? BigInt.zero;
  }

  // Example for JSON serialization
  Map<String, dynamic> toJson() => {
        'levelNumber': levelNumber,
        'status': status.toString(),
        'coin': coin,
        'partnerBonus': partnerBonus,
        'levelProfit': levelProfit,
        'fillPercent': fillPercent,
        'isVisible': isVisible,
        'cycles': cycles.toString(),
        'positionId': positionId.toString(),
        'earnedWei': earnedWei.toString(),
        'matrixSize': matrixSize.toString(),
      };

  factory Level.fromJson(Map<String, dynamic> json) => Level(
        levelNumber: json['levelNumber'],
        status: LevelStatus.values
            .firstWhere((e) => e.toString() == json['status']),
        coin: json['coin'],
        partnerBonus: json['partnerBonus'],
        levelProfit: json['levelProfit'],
        fillPercent: json['fillPercent'],
        isVisible: json['isVisible'],
        cycles: BigInt.tryParse('${json['cycles'] ?? 0}') ?? BigInt.zero,
        positionId:
            BigInt.tryParse('${json['positionId'] ?? 0}') ?? BigInt.zero,
        earnedWei: BigInt.tryParse('${json['earnedWei'] ?? 0}') ?? BigInt.zero,
        matrixSize:
            BigInt.tryParse('${json['matrixSize'] ?? 0}') ?? BigInt.zero,
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
