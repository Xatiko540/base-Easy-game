import 'package:flutter_test/flutter_test.dart';

import 'support/abi_test_utils.dart';

typedef _ExpectedFunction = ({String mutability, List<String> inputs});

void main() {
  test('active Wagmi contract calls match bundled Solidity artifacts', () {
    final expectedByContract = <String, Map<String, _ExpectedFunction>>{
      'EasyGameAdvance': {
        'getPlayer': (mutability: 'view', inputs: const ['address']),
        'levelAvailable': (mutability: 'view', inputs: const ['uint8']),
        'getPlayerRound': (
          mutability: 'view',
          inputs: const ['address', 'uint256'],
        ),
        'getRoundGameStats': (
          mutability: 'view',
          inputs: const ['uint256'],
        ),
        'getRoundMatrixNode': (
          mutability: 'view',
          inputs: const ['uint256', 'uint256'],
        ),
        'claimReferralBonus': (
          mutability: 'nonpayable',
          inputs: const [],
        ),
        'claimReferralBonusUSDC': (
          mutability: 'nonpayable',
          inputs: const [],
        ),
        'activateRound': (
          mutability: 'payable',
          inputs: const ['tuple', 'bytes', 'address'],
        ),
        'activateRoundWithUSDC': (
          mutability: 'nonpayable',
          inputs: const ['tuple', 'bytes', 'address'],
        ),
      },
      'EasyGameRoundManager': {
        'getEntryEligibility': (
          mutability: 'view',
          inputs: const ['uint256', 'uint8', 'address'],
        ),
        'getPlayerSeasonProgress': (
          mutability: 'view',
          inputs: const ['uint256', 'address'],
        ),
        'getRoundState': (
          mutability: 'view',
          inputs: const ['uint256'],
        ),
        'getRoundConfig': (
          mutability: 'view',
          inputs: const ['uint256'],
        ),
        'getRoundPhase': (
          mutability: 'view',
          inputs: const ['uint256'],
        ),
      },
      'EasyGameRoundSettlement': {
        'settleRound': (
          mutability: 'nonpayable',
          inputs: const ['uint256', 'uint256[]', 'bytes32[][]'],
        ),
        'claimPrize': (mutability: 'nonpayable', inputs: const []),
      },
      'EasyGameArenaSkills': {
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
      },
    };

    for (final contractEntry in expectedByContract.entries) {
      for (final functionEntry in contractEntry.value.entries) {
        final function = loadAbiFunction(
          contractEntry.key,
          functionEntry.key,
        );
        expect(
          function['stateMutability'],
          functionEntry.value.mutability,
          reason: '${contractEntry.key}.${functionEntry.key} mutability',
        );
        expect(
          abiInputTypes(function),
          functionEntry.value.inputs,
          reason: '${contractEntry.key}.${functionEntry.key} inputs',
        );
      }
    }
  });
}
