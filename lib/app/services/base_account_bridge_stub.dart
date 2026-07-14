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

bool get isBaseAccountBridgeAvailable => false;
bool get isBasePayBridgeAvailable => false;

Future<BaseAccountSignInResult> signInWithBaseAccount({
  required int chainId,
  required String appName,
  required String appLogoUrl,
}) {
  throw UnsupportedError('Base Account SDK is only available on Flutter Web.');
}

Future<BaseAccountSessionResult> restoreBaseAccountSession({
  required int chainId,
  required String appName,
  required String appLogoUrl,
}) {
  throw UnsupportedError('Base Account SDK is only available on Flutter Web.');
}

Future<void> disconnectBaseAccount({
  required int chainId,
  required String appName,
  required String appLogoUrl,
}) {
  throw UnsupportedError('Base Account SDK is only available on Flutter Web.');
}

Future<dynamic> baseAccountRequest(String method, List<dynamic> params) {
  throw UnsupportedError(
      'Base Account provider is only available on Flutter Web.');
}

Future<BasePayResult> sendBasePay({
  required String amount,
  required String recipient,
  required bool testnet,
  required String dataSuffix,
}) {
  throw UnsupportedError('Base Pay is only available on Flutter Web.');
}

Future<BasePayStatusResult> readBasePayStatus({
  required String paymentId,
  required bool testnet,
}) {
  throw UnsupportedError('Base Pay is only available on Flutter Web.');
}
