part of '../views/utility_screens.dart';

Map<String, CellState> _buildCellStates(
  _MatrixArenaSnapshot data,
  String selectedOpponent,
) {
  final states = <String, CellState>{};
  for (int cellId = 1; cellId <= 15; cellId++) {
    final coord = kAxialMap[cellId]!;
    final key = '${coord[0]}:${coord[1]}';
    final id = BigInt.from(cellId);
    final participant = data.participantAt(cellId);
    CellState state;
    if (participant == null) {
      if (data.nextOpenParentId == id) {
        state = CellState.cyanGlow;
      } else if (id <= data.activeCells) {
        state = CellState.greenGlow;
      } else {
        state = CellState.inactive;
      }
    } else if (participant.wallet.toLowerCase() ==
        selectedOpponent.toLowerCase()) {
      state = CellState.purpleStar;
    } else if (participant.skillStatus?.frozen == true) {
      state = CellState.blueUser;
    } else if (participant.isCurrentPlayer) {
      state = CellState.cyanUser;
    } else if (cellId == 7 || cellId == 15) {
      state = CellState.goldUser;
    } else {
      state = CellState.greenUser;
    }
    states[key] = state;
  }
  return states;
}
