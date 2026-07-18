import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:wagmi_web/wagmi_web.dart' as wagmi;

class GameClockService extends GetxService with WidgetsBindingObserver {
  static const Duration chainResyncInterval = Duration(minutes: 2);
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
      chainResyncInterval,
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
    final block = await wagmi.Core.getBlock(
      wagmi.GetBlockParameters(blockTag: const wagmi.BlockTag.latest()),
    );
    final timestamp = block.timestamp;
    if (timestamp == null) {
      throw const FormatException('Latest block has no timestamp');
    }
    return DateTime.fromMillisecondsSinceEpoch(
      timestamp.toInt() * 1000,
      isUtc: true,
    );
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
