import 'package:cloud_firestore/cloud_firestore.dart';

class GameUser {
  final String id;
  final String wallet;
  final int chainId;
  final bool exists;
  final bool walletVerified;
  final int profileVersion;
  final DateTime? registeredAt;
  final DateTime? updatedAt;

  const GameUser({
    required this.id,
    required this.wallet,
    required this.chainId,
    required this.exists,
    required this.walletVerified,
    required this.profileVersion,
    required this.registeredAt,
    required this.updatedAt,
  });

  factory GameUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) throw const FormatException('User document is empty');
    return GameUser(
      id: document.id,
      wallet: '${data['wallet'] ?? ''}'.toLowerCase(),
      chainId: _int(data['chainId']),
      exists: data['exists'] == true,
      walletVerified: data['walletVerified'] == true,
      profileVersion: _int(data['profileVersion'], 1),
      registeredAt: _date(data['registeredAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  static int _int(dynamic value, [int fallback = 0]) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

  static DateTime? _date(dynamic value) =>
      value is Timestamp ? value.toDate().toUtc() : null;
}
