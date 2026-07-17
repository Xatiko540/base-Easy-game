import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  test('Matrix Arena ABI exposes every function used by Flutter', () {
    final artifact = jsonDecode(
      File('src/artifacts/EasyGameArenaSkills.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final abi = ContractAbi.fromJson(
      jsonEncode(artifact['abi']),
      'EasyGameArenaSkills',
    );

    final functionsByName = <String, ContractFunction>{
      for (final function in abi.functions) function.name: function,
    };

    for (final name in <String>[
      'FREEZE_TOKEN_PRICE_USDC',
      'getArenaStatus',
      'getUnfreezePriceUsdc',
      'buyFreezeToken',
      'freezePlayer',
      'buyUnfreeze',
    ]) {
      expect(functionsByName, contains(name));
    }

    expect(
      functionsByName['FREEZE_TOKEN_PRICE_USDC']!.isConstant,
      isTrue,
    );
    expect(functionsByName['getArenaStatus']!.isConstant, isTrue);
    expect(functionsByName['getUnfreezePriceUsdc']!.isConstant, isTrue);
    expect(functionsByName['buyFreezeToken']!.isConstant, isFalse);
    expect(functionsByName['freezePlayer']!.isConstant, isFalse);
    expect(functionsByName['buyUnfreeze']!.isConstant, isFalse);
  });
}
