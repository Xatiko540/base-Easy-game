import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  test('incompatible Base Sepolia deployment addresses are not bundled', () {
    const contracts = <String>[
      'EasyGameAdvance',
      'EasyGameRoundManager',
      'EasyGameRoundSettlement',
      'EasyGameArenaSkills',
      'EasyGameBasePayGateway',
    ];

    for (final contract in contracts) {
      final artifact = jsonDecode(
        File('src/artifacts/$contract.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final networks = artifact['networks'] as Map<String, dynamic>;
      expect(networks.containsKey('84532'), isFalse);
    }
  });

  test('web3dart encodes the nested Merkle proof settlement call', () {
    final artifact = jsonDecode(
      File('src/artifacts/EasyGameRoundSettlement.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final abi = ContractAbi.fromJson(jsonEncode(artifact['abi']), 'Settlement');
    final function = abi.functions.singleWhere(
      (candidate) => candidate.name == 'settleRound',
    );
    final proofWord = Uint8List.fromList(List<int>.filled(32, 1));
    final encoded = function.encodeCall([
      BigInt.one,
      [BigInt.one, BigInt.from(3)],
      [
        [proofWord],
        [proofWord],
      ],
    ]);

    expect(encoded.length, greaterThan(4));
  });
}
