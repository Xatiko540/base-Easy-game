import 'dart:math';

import 'package:flutter/foundation.dart';

class BinaryMatrix {
  final List<List<int?>> matrix = [];
  final Map<int, int> recycleCounts = {};
  int currentPlayerId = 1;

  void fillMatrix(int levels) {
    for (int level = 0; level < levels; level++) {
      final int spotsInLevel = pow(2, level).toInt();
      final List<int?> currentLevel = List.filled(spotsInLevel, null);

      for (int spot = 0; spot < spotsInLevel; spot++) {
        if (currentLevel[spot] == null) {
          int? recycledPlayer = findPlayerToRecycle();
          if (recycledPlayer != null) {
            currentLevel[spot] = recycledPlayer;
          } else {
            currentLevel[spot] = currentPlayerId++;
          }
        }

        int player = currentLevel[spot]!;
        if (shouldRecycle(player)) {
          recycleCounts[player] = (recycleCounts[player] ?? 0) + 1;
        }
      }

      matrix.add(currentLevel);
    }
  }

  bool shouldRecycle(int playerId) {
    int completedSpots = 0;
    for (var row in matrix) {
      for (var spot in row) {
        if (spot == playerId) {
          completedSpots++;
        }
      }
    }
    return completedSpots % 2 == 0 && completedSpots > 0;
  }

  int? findPlayerToRecycle() {
    for (var playerId in recycleCounts.keys) {
      if (recycleCounts[playerId]! > 0) {
        recycleCounts[playerId] = recycleCounts[playerId]! - 1;
        return playerId;
      }
    }
    return null;
  }

  void printMatrix() {
    for (int i = 0; i < matrix.length; i++) {
      if (kDebugMode) {
        print("Level ${i + 1}: ${matrix[i]}");
      }
    }
  }
}
