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

bool get isBaseAccountBridgeAvailable => false;

Future<BaseAccountSignInResult> signInWithBaseAccount({
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
