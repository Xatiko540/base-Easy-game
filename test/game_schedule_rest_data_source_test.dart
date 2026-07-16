import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/services/game_schedule_rest_data_source.dart';

void main() {
  test('decodes Firestore REST typed values recursively', () {
    final decoded = FirestoreRestValueDecoder.decodeFields(
      <String, dynamic>{
        'chainId': <String, dynamic>{'integerValue': '84532'},
        'startsAt': <String, dynamic>{
          'timestampValue': '2026-07-13T20:44:37Z',
        },
        'enabled': <String, dynamic>{'booleanValue': true},
        'config': <String, dynamic>{
          'mapValue': <String, dynamic>{
            'fields': <String, dynamic>{
              'level': <String, dynamic>{'integerValue': '1'},
            },
          },
        },
        'cells': <String, dynamic>{
          'arrayValue': <String, dynamic>{
            'values': <Map<String, dynamic>>[
              <String, dynamic>{'integerValue': '7'},
              <String, dynamic>{'integerValue': '15'},
            ],
          },
        },
      },
    );

    expect(decoded['chainId'], 84532);
    expect(decoded['startsAt'], '2026-07-13T20:44:37Z');
    expect(decoded['enabled'], isTrue);
    expect(decoded['config'], <String, dynamic>{'level': 1});
    expect(decoded['cells'], <int>[7, 15]);
  });

  test('parses the published Base Sepolia round schema', () {
    final round = GameRoundSchedule.fromMap(
      documentId: '178397517701',
      data: <String, dynamic>{
        'chainId': 84532,
        'contractAddress': '0x99190eebbf301d5f99d301e8819bf8c3eb835b89',
        'roundManagerAddress': '0x7f88408841b53f0219ef2aa941f35aeb044f5340',
        'configHash':
            '0x5a32574b3d18b42f958443606af257a6a227e9aabf8079c7a00fb37de92289ae',
        'operatorSignature':
            '0x1e1086cfc6964b873a97eff8bbe871304b5184e5acf5edc025311e4f1b1d381f6e0287756d885ec55b6aac805af909bdf0a86d6b08938f6a067ea0edc88f32711c',
        'schemaVersion': 2,
        'config': <String, dynamic>{
          'seasonId': '1783975177',
          'roundId': '178397517701',
          'level': 1,
          'startsAt': '2026-07-13T20:44:37Z',
          'entriesCloseAt': '2026-07-14T20:44:37Z',
          'endsAt': '2026-07-15T20:44:37Z',
          'freezeClosesAt': '2026-07-15T20:44:37Z',
          'maxPlayers': 1024,
          'maxWinners': 6,
          'winningCellsRoot':
              '0xe22faf76a45456829d5e9ba833be627845284781998bcec4c871f8f777cb9ab4',
          'ethPriceWei': '50000000000000000',
          'usdcPrice': '50000',
          'freezeLimit': 10,
          'paymentSplitVersion': 1,
        },
      },
    );

    expect(round.level, 1);
    expect(round.chainId, 84532);
    expect(round.phaseAt(DateTime.utc(2026, 7, 13, 23)), GameRoundPhase.open);
  });
}
