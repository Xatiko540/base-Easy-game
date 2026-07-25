import 'abi_artifact_loader_web.dart'
    if (dart.library.io) 'abi_artifact_loader_io.dart';

Future<Map<String, dynamic>> loadArtifact(String contractName) async {
  return loadArtifactJson(contractName);
}

Future<Map<String, dynamic>> loadAbiFunction(
  String contractName,
  String functionName,
) async {
  final abi = (await loadArtifact(contractName))['abi'] as List<dynamic>;
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
