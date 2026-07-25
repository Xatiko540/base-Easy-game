import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/services/wagmi_contract_result.dart';

void main() {
  group('WagmiContractResult', () {
    test('reads positional tuple values', () {
      final result = <dynamic>[true, BigInt.from(17), '0xabc'];

      expect(
        WagmiContractResult.boolean(result, index: 0, name: 'active'),
        isTrue,
      );
      expect(
        WagmiContractResult.bigInt(result, index: 1, name: 'level'),
        BigInt.from(17),
      );
      expect(
        WagmiContractResult.string(result, index: 2, name: 'wallet'),
        '0xabc',
      );
    });

    test('reads named struct values returned by wagmi_web', () {
      final result = <String, dynamic>{
        'initialized': true,
        'occupiedCells': BigInt.from(12),
        'configHash': '0x1234',
      };

      expect(
        WagmiContractResult.boolean(
          result,
          index: 4,
          name: 'initialized',
        ),
        isTrue,
      );
      expect(
        WagmiContractResult.bigInt(
          result,
          index: 2,
          name: 'occupiedCells',
        ),
        BigInt.from(12),
      );
      expect(
        WagmiContractResult.string(
          result,
          index: 0,
          name: 'configHash',
        ),
        '0x1234',
      );
    });

    test('supports numeric map keys and safe defaults', () {
      final result = <String, dynamic>{
        '0': 'true',
        '1': '84532',
      };

      expect(
        WagmiContractResult.boolean(result, index: 0, name: 'connected'),
        isTrue,
      );
      expect(
        WagmiContractResult.bigInt(result, index: 1, name: 'chainId'),
        BigInt.from(84532),
      );
      expect(
        WagmiContractResult.bigInt(result, index: 2, name: 'missing'),
        BigInt.zero,
      );
    });
  });
}
