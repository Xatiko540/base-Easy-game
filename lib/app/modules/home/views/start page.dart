import 'package:flutter/material.dart';
import 'package:flutter_web3/ethereum.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/profilescreen.dart';
import 'package:lottery_advance/app/modules/home/views/registrationlevel.dart';

import 'PartnerBonusScreen.dart';
import 'home_view.dart';
import 'levels.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExpressGameScreen extends StatelessWidget {
    ExpressGameScreen({Key? key, this.walletAddress}) : super(key: key);

  final String? walletAddress;

   final WalletConnectService _walletService = WalletConnectService();

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
              "Easy game",
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
                walletAddress == null
                    ? "Not logged in" // Текст до логина
                    : walletAddress!, // Адрес кошелька после логина
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
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
        child: Padding(
          padding:  EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.10), // Боковые отступы
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20), // Отступ сверху
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF10CFCF), // Цвет фона
                  borderRadius: BorderRadius.circular(16), // Закругление углов
                ),
                padding: EdgeInsets.all(16), // Отступ внутри контейнера
                child: _headerSection(),
              ),
              SizedBox(height: 16),
              _timerSection(),
              SizedBox(height: 16),
              _previewModeSection(),
              SizedBox(height: 30),

            ],
          ),
        ),
      ),

    );
  }



  Widget _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _headerSection() {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10CFCF), Color(0xFF10CFCF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Easy game",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Join Forsage ETH(base) and Activate Express in one transaction with ETH(base)",
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF8A00D4), // Фиолетовый
                      Color(0xFF0078FF), // Синий
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_walletService.isConnected) {
                      // Если кошелек подключен, переходим на другую страницу
                      Get.to(() => LevelsScreen());
                    } else {
                      // Если кошелек не подключен, пробуем подключить
                      try {
                        await _walletService.connectWallet();
                        if (_walletService.isConnected) {
                          // После успешного подключения переходим на другую страницу
                          Get.to(() => LevelsScreen());
                        }
                      } catch (e) {
                        // Если произошла ошибка при подключении, показываем сообщение
                        Get.snackbar('Error', 'Failed to connect wallet');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // Прозрачный фон для градиента
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Login to your account",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

    Widget _timerSection() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF6A1B9A), // Цвет фона для таймера
            borderRadius: BorderRadius.circular(16), // Закругление углов
          ),
          padding:  EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Центрирование контента
            children: [
              Icon(Icons.timer, color: Colors.white, size: 16), // Иконка таймера
              SizedBox(width: 8),
              Text(
                "Level 3 available at: 00 D 07 H 32 M 54 S", // Текст таймера
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

  Widget _previewModeSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Preview Mode",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Look up any Express game member account in preview mode. Enter ID or ETH(base) address to preview.",
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    hintText: "Enter ID or Wallet",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Логика поиска
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text("Search"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



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

class WalletConnectService extends GetxController {
  final RxString _currentAddress = ''.obs;
  final RxBool _isConnected = false.obs;

  // Доступ к данным
  String get currentAddress => _currentAddress.value;
  bool get isConnected => _isConnected.value;

  // Проверка наличия кошелька
  bool get isWalletAvailable => ethereum != null;

  // Подключение кошелька
  Future<void> connectWallet() async {
    if (isWalletAvailable) {
      try {
        final accounts = await ethereum!.requestAccount();
        _currentAddress.value = accounts.first;
        _isConnected.value = true;
        print('Wallet connected: ${_currentAddress.value}');
      } catch (e) {
        _isConnected.value = false;
        print('Connection error: $e');
        rethrow;
      }
    } else {
      print('MetaMask or other Web3 wallet is not installed');
      throw Exception('Wallet not available');
    }
  }

  // Отключение кошелька
  void disconnectWallet() {
    _currentAddress.value = '';
    _isConnected.value = false;
    print('Wallet is disabled');
  }
}