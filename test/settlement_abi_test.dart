import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  test('Base Sepolia deployment addresses are bundled with the app', () {
    const expected = <String, String>{
      'EasyGameAdvance': '0x6d878b377e6CCE9B0134bF306A6c85880EF5B139',
      'EasyGameRoundManager': '0x856C4E5cb4C5EFcFdC533B651B9B8724d290512F',
      'EasyGameRoundSettlement': '0x8437F6aE3e7e56d707d66b316383630B501B7Aa5',
      'EasyGameArenaSkills': '0xF0706314ec9b060796897f2A9FB34266D08f595c',
      'EasyGameBasePayGateway': '0xB4FEC3E440321a751FB7f117b4Bb2BD38Fbc6709',
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
