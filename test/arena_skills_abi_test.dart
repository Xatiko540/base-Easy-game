import 'package:flutter_test/flutter_test.dart';

import 'support/abi_test_utils.dart';

void main() {
  test('Matrix Arena ABI exposes every function used by Flutter', () {
    final expected = <String, ({String mutability, List<String> inputs})>{
      'FREEZE_TOKEN_PRICE_USDC': (
        mutability: 'view',
        inputs: const [],
      ),
      'getArenaStatus': (
        mutability: 'view',
        inputs: const ['uint256', 'address'],
      ),
      'getUnfreezePriceUsdc': (
        mutability: 'view',
        inputs: const ['uint256', 'address'],
      ),
      'buyFreezeToken': (
        mutability: 'nonpayable',
        inputs: const ['uint256'],
      ),
      'freezePlayer': (
        mutability: 'nonpayable',
        inputs: const ['uint256', 'address'],
      ),
      'buyUnfreeze': (
        mutability: 'nonpayable',
        inputs: const ['uint256'],
      ),
    };

    for (final entry in expected.entries) {
      final function = loadAbiFunction('EasyGameArenaSkills', entry.key);
      expect(function['stateMutability'], entry.value.mutability);
      expect(abiInputTypes(function), entry.value.inputs);
    }
  });
}
