class GameContractEvent {
  final String contract;
  final String eventName;
  final int logCount;
  final DateTime receivedAt;

  const GameContractEvent({
    required this.contract,
    required this.eventName,
    required this.logCount,
    required this.receivedAt,
  });
}
