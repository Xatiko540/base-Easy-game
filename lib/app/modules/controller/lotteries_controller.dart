import 'dart:math';

import 'package:get/get.dart';
import 'package:lottery_advance/app/services/contract_linking.dart';

class LotteriesController extends GetxController
    with GetSingleTickerProviderStateMixin {



  List<List<T>> createMatrixWithFunction<T>(
      int rows,
      int columns,
      T Function(int row, int column) fillFunction,
      ) {
    return List.generate(
      rows,
          (row) => List.generate(columns, (column) => fillFunction(row, column)),
    );
  }

  List<List<int>> createRandomMatrix(int rows, int columns, int maxValue) {
    final random = Random();
    return createMatrixWithFunction<int>(
      rows,
      columns,
          (_, __) => random.nextInt(maxValue),
    );
  }

  final contractLink = Get.find<ContractLinking>();

  setup() async {
    // contractLink.isLoading.value = true;
    await contractLink.getAbi();
    await contractLink.getCredentials();
    await contractLink.getDeployedContractLotteryGenerator();
    // contractLink.isLoading.value = false;
  }

  @override
  Future<void> onInit() async {
    await setup();
    super.onInit();
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    contractLink.listenLotteryCreatedEvent().listen((event) async {
      print("Calling listenLotteryCreatedEvent");
      print(event);
      await contractLink.getLotteriesList();
    });
  }



}



class BinaryMatrix {

  final List<List<int?>> matrix = [];
  final Map<int, int> recycleCounts = {}; // Количество рециркуляций для каждого игрока
  int currentPlayerId = 1; // ID текущего игрока

  void fillMatrix(int levels) {
    for (int level = 0; level < levels; level++) {
      final int spotsInLevel = pow(2, level).toInt(); // Количество мест на уровне
      final List<int?> currentLevel = List.filled(spotsInLevel, null);

      for (int spot = 0; spot < spotsInLevel; spot++) {
        if (currentLevel[spot] == null) {
          // Если доступен игрок для рециркуляции, используем его
          int? recycledPlayer = findPlayerToRecycle();
          if (recycledPlayer != null) {
            currentLevel[spot] = recycledPlayer;
          } else {
            // Если нет доступного игрока для рециркуляции, добавляем нового
            currentLevel[spot] = currentPlayerId++;
          }
        }

        // Проверяем, нужно ли игроку добавлять рециркуляцию
        int player = currentLevel[spot]!;
        if (shouldRecycle(player)) {
          recycleCounts[player] = (recycleCounts[player] ?? 0) + 1;
        }
      }

      matrix.add(currentLevel);
    }
  }

  // Проверяем, нужно ли рециклировать игрока
  bool shouldRecycle(int playerId) {
    int completedSpots = 0;
    for (var row in matrix) {
      for (var spot in row) {
        if (spot == playerId) {
          completedSpots++;
        }
      }
    }
    return completedSpots % 2 == 0 && completedSpots > 0; // Рециркуляция при заполнении двух мест
  }

  // Находим игрока, которого нужно рециклировать
  int? findPlayerToRecycle() {
    for (var playerId in recycleCounts.keys) {
      if (recycleCounts[playerId]! > 0) {
        recycleCounts[playerId] = recycleCounts[playerId]! - 1;
        return playerId;
      }
    }
    return null; // Если нет доступных игроков для рециркуляции
  }

  // Вывод матрицы
  void printMatrix() {
    for (int i = 0; i < matrix.length; i++) {
      print("Level ${i + 1}: ${matrix[i]}");
    }
  }

}