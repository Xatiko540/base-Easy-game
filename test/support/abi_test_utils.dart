import 'dart:convert';
import 'dart:io';

Map<String, dynamic> loadArtifact(String contractName) {
  return jsonDecode(
    File('src/artifacts/$contractName.json').readAsStringSync(),
  ) as Map<String, dynamic>;
}

Map<String, dynamic> loadAbiFunction(
  String contractName,
  String functionName,
) {
  final abi = loadArtifact(contractName)['abi'] as List<dynamic>;
  return abi.cast<Map<String, dynamic>>().singleWhere(
        (entry) => entry['type'] == 'function' && entry['name'] == functionName,
      );
}

List<String> abiInputTypes(Map<String, dynamic> function) {
  return (function['inputs'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map((input) => input['type'] as String)
      .toList(growable: false);
}
