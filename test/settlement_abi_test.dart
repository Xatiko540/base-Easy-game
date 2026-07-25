import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/abi_test_utils.dart';

void main() {
  test('incompatible Base Sepolia deployment addresses are not bundled',
      () async {
    if (kIsWeb) return;
    const incompatibleAddresses = <String>{
      '0x99190eebbf301d5f99d301e8819bf8c3eb835b89',
      '0x7f88408841b53f0219ef2aa941f35aeb044f5340',
      '0x5e772fda40d58114d62251346fd73e54d9ede398',
      '0x6fb3aa2cc774ce55d2533c3e75b6932c8459f447',
      '0x9502c447947482cc81fe41488d7f782bf13ab14e',
    };
    const contracts = <String>{
      'EasyGameAdvance',
      'EasyGameRoundManager',
      'EasyGameRoundSettlement',
      'EasyGameArenaSkills',
    };

    for (final contract in contracts) {
      final artifact = await loadArtifact(contract);
      final networks = artifact['networks'] as Map<String, dynamic>;
      final baseSepolia = networks['84532'] as Map<String, dynamic>?;
      final address = baseSepolia?['address']?.toString().toLowerCase();
      expect(incompatibleAddresses, isNot(contains(address)));
    }
  });

  test('settleRound ABI accepts wagmi nested Merkle proof arguments', () async {
    if (kIsWeb) return;
    final function = await loadAbiFunction(
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
