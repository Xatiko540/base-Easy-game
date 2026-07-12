import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/firebase_options.dart';

class FirebaseLevelData {
  final int level;
  final bool available;
  final BigInt ethPriceWei;
  final BigInt usdcPrice;
  final BigInt prizePoolWei;
  final BigInt totalWeight;
  final BigInt activeCells;
  final BigInt nextOpenParent;
  final BigInt nextCell;
  final BigInt usdcPrizePoolWei;
  final BigInt usdcTotalWeight;
  final BigInt usdcActiveCells;
  final BigInt usdcNextOpenParent;
  final BigInt usdcNextCell;
  final DateTime? syncedAt;

  FirebaseLevelData({
    required this.level,
    required this.available,
    required this.ethPriceWei,
    required this.usdcPrice,
    required this.prizePoolWei,
    required this.totalWeight,
    required this.activeCells,
    required this.nextOpenParent,
    required this.nextCell,
    required this.usdcPrizePoolWei,
    required this.usdcTotalWeight,
    required this.usdcActiveCells,
    required this.usdcNextOpenParent,
    required this.usdcNextCell,
    this.syncedAt,
  });

  factory FirebaseLevelData.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>?;
    if (d == null) throw FormatException('No level data');

    final stats = (d['stats'] as Map<String, dynamic>?) ?? {};
    final usdcStats = (d['usdcStats'] as Map<String, dynamic>?) ?? {};

    return FirebaseLevelData(
      level: (d['level'] as num?)?.toInt() ?? 0,
      available: d['available'] as bool? ?? false,
      ethPriceWei: _parseBigInt(d['ethPriceWei']),
      usdcPrice: _parseBigInt(d['usdcPrice']),
      prizePoolWei: _parseBigInt(stats['prizePool']),
      totalWeight: _parseBigInt(stats['totalWeight']),
      activeCells: _parseBigInt(stats['activeCells']),
      nextOpenParent: _parseBigInt(stats['nextOpenParent']),
      nextCell: _parseBigInt(stats['nextCell']),
      usdcPrizePoolWei: _parseBigInt(usdcStats['prizePool']),
      usdcTotalWeight: _parseBigInt(usdcStats['totalWeight']),
      usdcActiveCells: _parseBigInt(usdcStats['activeCells']),
      usdcNextOpenParent: _parseBigInt(usdcStats['nextOpenParent']),
      usdcNextCell: _parseBigInt(usdcStats['nextCell']),
      syncedAt: (d['syncedAt'] as Timestamp?)?.toDate(),
    );
  }

  static BigInt _parseBigInt(dynamic value) {
    if (value == null) return BigInt.zero;
    if (value is num) return BigInt.from(value);
    return BigInt.tryParse(value.toString()) ?? BigInt.zero;
  }
}

class FirebaseDataService extends GetxService {
  static const _region = 'us-central1';

  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final RxBool isReady = false.obs;

  FirebaseFunctions? _functions;
  StreamSubscription? _levelsSubscription;

  FirebaseDataService();

  Future<void> init() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _functions = FirebaseFunctions.instanceFor(region: _region);
    isReady.value = true;
  }

  String get _chainId =>
      (walletService.chainId.value ?? WalletConnectService.baseMainnetChainId)
          .toString();

  // ─── Level data from Firestore ───────────────────

  Stream<List<FirebaseLevelData>> watchAllLevels() {
    return FirebaseFirestore.instance
        .collection('levels')
        .where('chainId', isEqualTo: int.parse(_chainId))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FirebaseLevelData.fromFirestore(doc))
            .toList());
  }

  Future<FirebaseLevelData?> getLevel(int level) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('levels')
          .doc('${_chainId}_$level')
          .get();
      if (!doc.exists) return null;
      return FirebaseLevelData.fromFirestore(doc);
    } catch (e) {
      debugPrint('FirebaseDataService.getLevel error: $e');
      return null;
    }
  }

  Stream<FirebaseLevelData?> watchLevel(int level) {
    return FirebaseFirestore.instance
        .collection('levels')
        .doc('${_chainId}_$level')
        .snapshots()
        .map((doc) =>
            doc.exists ? FirebaseLevelData.fromFirestore(doc) : null);
  }

  // ─── Fallback: read from contract ───────────────

  Future<List<FirebaseLevelData>> fetchLevelsFromContract() async {
    final results = <FirebaseLevelData>[];
    for (var level = 1; level <= 17; level++) {
      try {
        final priceWei =
            await walletService.getEasyGameLevelPriceWei(level);
        final stats =
            await walletService.getEasyGameAdvanceLevelStats(level);
        final usdcStats =
            await walletService.getEasyGameAdvanceLevelStatsUsdc(level);
        final usdcPrice =
            await walletService.getEasyGameLevelPriceUsdc(level);
        final available =
            await walletService.isEasyGameLevelAvailable(level);

        results.add(FirebaseLevelData(
          level: level,
          available: available,
          ethPriceWei: priceWei,
          usdcPrice: usdcPrice,
          prizePoolWei: stats.prizePoolWei,
          totalWeight: stats.totalWeight,
          activeCells: stats.activeCells,
          nextOpenParent: stats.nextOpenParentId,
          nextCell: stats.nextCellId,
          usdcPrizePoolWei: usdcStats.prizePoolWei,
          usdcTotalWeight: usdcStats.totalWeight,
          usdcActiveCells: usdcStats.activeCells,
          usdcNextOpenParent: usdcStats.nextOpenParentId,
          usdcNextCell: usdcStats.nextCellId,
        ));
      } catch (e) {
        final message = e.toString();
        if (message.contains('EasyGameAdvance contract is not deployed')) {
          debugPrint('FirebaseDataService: contract fallback skipped: $message');
          break;
        }
        debugPrint('FirebaseDataService: contract fallback level $level: $e');
      }
    }
    return results;
  }

  // ─── Admin sync functions ───────────────────────

  Future<Map<String, dynamic>> syncLevel(int level) async {
    if (_functions == null) throw StateError('FirebaseDataService not ready');
    final result = await _functions!
        .httpsCallable('syncLevel')
        .call(<String, dynamic>{'level': level});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> syncAllLevels() async {
    if (_functions == null) throw StateError('FirebaseDataService not ready');
    final result = await _functions!
        .httpsCallable('syncAllLevels')
        .call(<String, dynamic>{});
    return Map<String, dynamic>.from(result.data as Map);
  }

  @override
  void onClose() {
    _levelsSubscription?.cancel();
    super.onClose();
  }
}
