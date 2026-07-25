import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class MatrixArenaRepository {
  MatrixArenaRepository({WalletConnectService? walletService})
      : _wallet = walletService ?? Get.find<WalletConnectService>();

  final WalletConnectService _wallet;
  final Map<String, Future<EasyGamePlayerSummary?>> _playerCache = {};
  final Map<String, Future<ArenaSkillStatus?>> _skillCache = {};

  Future<MatrixArenaRosterPage> loadRosterPage({
    required BigInt roundId,
    required BigInt activeCells,
    required BigInt currentPlayerCellId,
    required int page,
    int pageSize = 15,
  }) async {
    final total = activeCells.toInt();
    if (total <= 0) {
      return MatrixArenaRosterPage(
        participants: const [],
        page: page,
        hasMore: false,
      );
    }

    final start = page * pageSize + 1;
    final end = math.min(total, start + pageSize - 1);
    final cellIds = <int>{
      if (start <= total) ...[for (var cell = start; cell <= end; cell++) cell],
      if (page == 0 &&
          currentPlayerCellId > BigInt.zero &&
          currentPlayerCellId <= activeCells)
        currentPlayerCellId.toInt(),
    }.toList()
      ..sort();

    final nodes = (await Future.wait([
      for (final cellId in cellIds) _safeNode(roundId, cellId),
    ]))
        .whereType<RoundMatrixNode>()
        .where((node) => node.cellId > BigInt.zero && node.player.isNotEmpty)
        .toList(growable: false);

    final currentWallet = _wallet.currentAddress.value.toLowerCase();
    final participants = await Future.wait([
      for (final node in nodes) _buildParticipant(roundId, node, currentWallet),
    ]);

    return MatrixArenaRosterPage(
      participants: participants,
      page: page,
      hasMore: end < total,
    );
  }

  void invalidateRound(BigInt roundId) {
    final prefix = '${roundId.toString()}/';
    _skillCache.removeWhere((key, _) => key.startsWith(prefix));
  }

  void clear() {
    _playerCache.clear();
    _skillCache.clear();
  }

  Future<MatrixParticipant> _buildParticipant(
    BigInt roundId,
    RoundMatrixNode node,
    String currentWallet,
  ) async {
    final values = await Future.wait<Object?>([
      _playerSummary(node.player),
      _skillStatus(roundId, node.player),
    ]);
    final summary = values[0] as EasyGamePlayerSummary?;
    final skill = values[1] as ArenaSkillStatus?;
    final normalizedWallet = node.player.toLowerCase();
    return MatrixParticipant(
      cellId: node.cellId,
      wallet: node.player,
      isCurrentPlayer:
          currentWallet.isNotEmpty && normalizedWallet == currentWallet,
      isInvited: currentWallet.isNotEmpty &&
          summary?.inviter.toLowerCase() == currentWallet,
      skillStatus: skill,
    );
  }

  Future<RoundMatrixNode?> _safeNode(BigInt roundId, int cellId) async {
    try {
      return await _wallet.getRoundMatrixNode(roundId, cellId);
    } catch (_) {
      return null;
    }
  }

  Future<EasyGamePlayerSummary?> _playerSummary(String wallet) {
    final key = wallet.toLowerCase();
    return _playerCache.putIfAbsent(key, () async {
      try {
        return await _wallet.getEasyGamePlayerSummary(address: wallet);
      } catch (_) {
        return null;
      }
    });
  }

  Future<ArenaSkillStatus?> _skillStatus(BigInt roundId, String wallet) {
    final key = '$roundId/${wallet.toLowerCase()}';
    return _skillCache.putIfAbsent(key, () async {
      try {
        return await _wallet.getArenaSkillStatus(
          roundId,
          playerAddress: wallet,
        );
      } catch (_) {
        return null;
      }
    });
  }
}
