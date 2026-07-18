import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/abi_test_utils.dart';

void main() {
  test('incompatible Base Sepolia deployment addresses are not bundled', () {
    const contracts = <String>[
      'EasyGameAdvance',
      'EasyGameRoundManager',
      'EasyGameRoundSettlement',
      'EasyGameArenaSkills',
    ];

    for (final contract in contracts) {
      final artifact = jsonDecode(
        File('src/artifacts/$contract.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final networks = artifact['networks'] as Map<String, dynamic>;
      expect(networks.containsKey('84532'), isFalse);
    }
  });

  test('settleRound ABI accepts wagmi nested Merkle proof arguments', () {
    final function = loadAbiFunction(
      'EasyGameRoundSettlement',
      'settleRound',
    );

    expect(function['stateMutability'], 'nonpayable');
    expect(
      abiInputTypes(function),
      const ['uint256', 'uint256[]', 'bytes32[][]'],
    );
    expect(function['outputs'], isEmpty);

    final proof = '0x${List.filled(32, '01').join()}';
    final wagmiArguments = <dynamic>[
      BigInt.one,
      [BigInt.one, BigInt.from(3)],
      [
        [proof],
        [proof],
      ],
    ];
    expect(wagmiArguments[0], isA<BigInt>());
    expect(wagmiArguments[1], isA<List<BigInt>>());
    expect(wagmiArguments[2], isA<List<List<String>>>());
  });
}
