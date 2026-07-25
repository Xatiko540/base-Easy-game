import 'dart:convert';
import 'dart:io';

Future<Map<String, dynamic>> loadArtifactJson(String contractName) async {
  return jsonDecode(
    await File('src/artifacts/$contractName.json').readAsString(),
  ) as Map<String, dynamic>;
}
