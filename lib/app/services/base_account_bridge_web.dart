import 'dart:js_interop';
import 'dart:js_interop_unsafe';

class BaseAccountSignInResult {
  final String address;
  final String message;
  final String signature;
  final String nonce;
  final int chainId;

  const BaseAccountSignInResult({
    required this.address,
    required this.message,
    required this.signature,
    required this.nonce,
    required this.chainId,
  });
}

bool get isBaseAccountBridgeAvailable {
  final bridge = globalContext['easyGameBaseAccount'] as JSObject?;
  return bridge != null && bridge.has('signIn') && bridge.has('request');
}

Future<BaseAccountSignInResult> signInWithBaseAccount({
  required int chainId,
  required String appName,
  required String appLogoUrl,
}) async {
  final bridge = _bridge();
  final promise = bridge.callMethod<JSPromise<JSAny?>>(
    'signIn'.toJS,
    chainId.toJS,
    appName.toJS,
    appLogoUrl.toJS,
  );
  final raw = await promise.toDart;
  final data = raw?.dartify();
  if (data is! Map) {
    throw Exception('Invalid Base Account sign-in response');
  }

  return BaseAccountSignInResult(
    address: data['address']?.toString() ?? '',
    message: data['message']?.toString() ?? '',
    signature: data['signature']?.toString() ?? '',
    nonce: data['nonce']?.toString() ?? '',
    chainId: int.tryParse(data['chainId']?.toString() ?? '') ?? chainId,
  );
}

Future<dynamic> baseAccountRequest(String method, List<dynamic> params) async {
  final bridge = _bridge();
  final promise = bridge.callMethod<JSPromise<JSAny?>>(
    'request'.toJS,
    method.toJS,
    params.jsify(),
  );
  final raw = await promise.toDart;
  return raw?.dartify();
}

JSObject _bridge() {
  final bridge = globalContext['easyGameBaseAccount'] as JSObject?;
  if (bridge == null) {
    throw Exception('Base Account SDK bridge is not loaded.');
  }
  return bridge;
}
