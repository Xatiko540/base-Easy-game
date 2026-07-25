enum WalletAuthPhase {
  initializing,
  disconnected,
  connecting,
  connected,
  authenticating,
  authenticated,
  error,
}

class WalletAuthSession {
  final String wallet;
  final int chainId;
  final String firebaseUid;

  const WalletAuthSession({
    required this.wallet,
    required this.chainId,
    required this.firebaseUid,
  });

  bool matches(String address, int? activeChainId) {
    if (activeChainId == null) {
      return wallet.toLowerCase() == address.toLowerCase();
    }
    return wallet.toLowerCase() == address.toLowerCase() &&
        chainId == activeChainId;
  }
}
