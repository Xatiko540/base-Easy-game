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

class BaseAccountSessionResult {
  final String address;
  final int chainId;

  const BaseAccountSessionResult({
    required this.address,
    required this.chainId,
  });
}

class BasePayResult {
  final String id;
  final String amount;
  final String recipient;

  const BasePayResult({
    required this.id,
    required this.amount,
    required this.recipient,
  });
}

class BasePayStatusResult {
  final String status;
  final String sender;
  final String amount;
  final String recipient;

  const BasePayStatusResult({
    required this.status,
    required this.sender,
    required this.amount,
    required this.recipient,
  });
}

bool get isBaseAccountBridgeAvailable {
  final bridge = globalContext['easyGameBaseAccount'] as JSObject?;
  return bridge != null && bridge.has('signIn') && bridge.has('request');
}

bool get isBasePayBridgeAvailable {
  final bridge = globalContext['easyGameBaseAccount'] as JSObject?;
  return bridge != null && bridge.has('pay') && bridge.has('getPaymentStatus');
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

Future<BaseAccountSessionResult> restoreBaseAccountSession({
  required int chainId,
  required String appName,
  required String appLogoUrl,
}) async {
  final bridge = _bridge();
  final raw = await bridge
      .callMethod<JSPromise<JSAny?>>(
        'restore'.toJS,
        chainId.toJS,
        appName.toJS,
        appLogoUrl.toJS,
      )
      .toDart;
  final data = raw?.dartify();
  if (data is! Map) {
    throw Exception('Invalid Base Account session response');
  }
  return BaseAccountSessionResult(
    address: data['address']?.toString() ?? '',
    chainId: int.tryParse(data['chainId']?.toString() ?? '') ?? chainId,
  );
}

Future<void> disconnectBaseAccount({
  required int chainId,
  required String appName,
  required String appLogoUrl,
}) async {
  final bridge = _bridge();
  await bridge
      .callMethod<JSPromise<JSAny?>>(
        'disconnect'.toJS,
        chainId.toJS,
        appName.toJS,
        appLogoUrl.toJS,
      )
      .toDart;
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

Future<BasePayResult> sendBasePay({
  required String amount,
  required String recipient,
  required bool testnet,
  required String dataSuffix,
}) async {
  final bridge = _bridge();
  final raw = await bridge
      .callMethod<JSPromise<JSAny?>>(
        'pay'.toJS,
        amount.toJS,
        recipient.toJS,
        testnet.toJS,
        dataSuffix.toJS,
      )
      .toDart;
  final data = raw?.dartify();
  if (data is! Map) throw Exception('Invalid Base Pay response');
  return BasePayResult(
    id: data['id']?.toString() ?? '',
    amount: data['amount']?.toString() ?? '',
    recipient: data['to']?.toString() ?? '',
  );
}

Future<BasePayStatusResult> readBasePayStatus({
  required String paymentId,
  required bool testnet,
}) async {
  final bridge = _bridge();
  final raw = await bridge
      .callMethod<JSPromise<JSAny?>>(
        'getPaymentStatus'.toJS,
        paymentId.toJS,
        testnet.toJS,
      )
      .toDart;
  final data = raw?.dartify();
  if (data is! Map) throw Exception('Invalid Base Pay status response');
  return BasePayStatusResult(
    status: data['status']?.toString() ?? '',
    sender: data['sender']?.toString() ?? '',
    amount: data['amount']?.toString() ?? '',
    recipient: data['recipient']?.toString() ?? '',
  );
}

JSObject _bridge() {
  final bridge = globalContext['easyGameBaseAccount'] as JSObject?;
  if (bridge == null) {
    throw Exception('Base Account SDK bridge is not loaded.');
  }
  return bridge;
}
