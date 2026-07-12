import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lottery_advance/app/services/app_config_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class GameClockService extends GetxService with WidgetsBindingObserver {
  final WalletConnectService _walletService = Get.find<WalletConnectService>();

  final Rx<DateTime> chainTime = DateTime.now().toUtc().obs;
  final RxBool isSynchronized = false.obs;
  final RxString errorMessage = ''.obs;

  Timer? _ticker;
  Timer? _resyncTimer;
  Stopwatch? _anchorWatch;
  DateTime? _chainAnchor;
  int _requestId = 0;

  Future<GameClockService> init() async {
    WidgetsBinding.instance.addObserver(this);
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _resyncTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => synchronize(),
    );
    await synchronize();
    return this;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      synchronize();
    }
  }

  Future<void> synchronize() async {
    final requestId = ++_requestId;
    try {
      final timestamp = await _fetchLatestBlockTimestamp();
      if (requestId != _requestId) return;
      _chainAnchor = timestamp;
      _anchorWatch = Stopwatch()..start();
      chainTime.value = timestamp;
      isSynchronized.value = true;
      errorMessage.value = '';
    } catch (error) {
      if (requestId != _requestId) return;
      isSynchronized.value = false;
      errorMessage.value = '$error';
      if (kDebugMode) {
        debugPrint('GameClockService synchronization failed: $error');
      }
    }
  }

  void _tick() {
    final anchor = _chainAnchor;
    final watch = _anchorWatch;
    chainTime.value = anchor != null && watch != null
        ? anchor.add(watch.elapsed)
        : DateTime.now().toUtc();
  }

  Future<DateTime> _fetchLatestBlockTimestamp() async {
    final response = await http.post(
      Uri.parse(_rpcUrl),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'eth_getBlockByNumber',
        'params': ['latest', false],
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('RPC clock request failed: HTTP ${response.statusCode}');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (payload['error'] != null) {
      throw Exception('RPC clock request failed: ${payload['error']}');
    }
    final result = payload['result'] as Map<String, dynamic>?;
    final timestampHex = result?['timestamp'] as String?;
    if (timestampHex == null) {
      throw const FormatException('Latest block has no timestamp');
    }
    final seconds = int.parse(timestampHex.substring(2), radix: 16);
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  String get _rpcUrl {
    final configured = Get.find<AppConfigService>().get('web3PublicRpcUrl');
    return configured.isNotEmpty
        ? configured
        : _walletService.currentNetwork.rpcUrl;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _resyncTimer?.cancel();
    _anchorWatch?.stop();
    super.onClose();
  }
}
