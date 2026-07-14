import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  test('Base Sepolia deployment addresses are bundled with the app', () {
    const expected = <String, String>{
      'EasyGameAdvance': '0x99190EeBBF301d5f99D301E8819bF8C3eB835B89',
      'EasyGameRoundManager': '0x7f88408841b53f0219Ef2aa941f35aeB044f5340',
      'EasyGameRoundSettlement': '0x9502C447947482cC81Fe41488d7f782Bf13AB14E',
      'EasyGameArenaSkills': '0x6fb3aA2cc774CE55d2533c3e75B6932C8459F447',
      'EasyGameBasePayGateway': '0x5E772Fda40d58114D62251346fd73E54D9Ede398',
    };

    for (final entry in expected.entries) {
      final artifact = jsonDecode(
        File('src/artifacts/${entry.key}.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final networks = artifact['networks'] as Map<String, dynamic>;
      final baseSepolia = networks['84532'] as Map<String, dynamic>;
      expect(baseSepolia['address'], entry.value);
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
