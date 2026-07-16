import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/firebase_options.dart';

class GameScheduleRestDataSource {
  GameScheduleRestDataSource({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<GameRoundSchedule>> fetchRounds({required int chainId}) async {
    final options = DefaultFirebaseOptions.currentPlatform;
    final endpoint = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/${options.projectId}/databases/(default)/documents:runQuery',
      <String, String>{'key': options.apiKey},
    );
    final response = await _client.post(
      endpoint,
      headers: const <String, String>{'content-type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'structuredQuery': <String, dynamic>{
          'from': <Map<String, String>>[
            <String, String>{'collectionId': 'rounds'},
          ],
          'where': <String, dynamic>{
            'fieldFilter': <String, dynamic>{
              'field': <String, String>{'fieldPath': 'chainId'},
              'op': 'EQUAL',
              'value': <String, String>{'integerValue': '$chainId'},
            },
          },
          'limit': 100,
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Public round schedule request failed (${response.statusCode}).',
      );
    }

    final rows = jsonDecode(response.body);
    if (rows is! List) {
      throw const FormatException('Invalid Firestore runQuery response');
    }

    final rounds = <GameRoundSchedule>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final document = row['document'];
      if (document is! Map) continue;
      final name = '${document['name'] ?? ''}';
      final fields = document['fields'];
      if (name.isEmpty || fields is! Map) continue;

      final data = FirestoreRestValueDecoder.decodeFields(fields);
      rounds.add(GameRoundSchedule.fromMap(
        documentId: name.split('/').last,
        data: data,
      ));
    }
    return rounds;
  }

  void close() => _client.close();
}

class FirestoreRestValueDecoder {
  const FirestoreRestValueDecoder._();

  static Map<String, dynamic> decodeFields(Map<dynamic, dynamic> fields) {
    return fields.map<String, dynamic>(
      (key, value) => MapEntry('$key', decodeValue(value)),
    );
  }

  static dynamic decodeValue(dynamic value) {
    if (value is! Map) return null;
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('booleanValue')) {
      return value['booleanValue'] == true;
    }
    if (value.containsKey('integerValue')) {
      return int.tryParse('${value['integerValue']}') ?? 0;
    }
    if (value.containsKey('doubleValue')) {
      return double.tryParse('${value['doubleValue']}') ?? 0.0;
    }
    if (value.containsKey('timestampValue')) return value['timestampValue'];
    if (value.containsKey('stringValue')) return '${value['stringValue']}';
    if (value.containsKey('bytesValue')) return '${value['bytesValue']}';
    if (value.containsKey('referenceValue')) {
      return '${value['referenceValue']}';
    }
    if (value.containsKey('mapValue')) {
      final mapValue = value['mapValue'];
      if (mapValue is Map && mapValue['fields'] is Map) {
        return decodeFields(mapValue['fields'] as Map);
      }
      return <String, dynamic>{};
    }
    if (value.containsKey('arrayValue')) {
      final arrayValue = value['arrayValue'];
      if (arrayValue is Map && arrayValue['values'] is List) {
        return (arrayValue['values'] as List).map(decodeValue).toList();
      }
      return <dynamic>[];
    }
    return null;
  }
}
