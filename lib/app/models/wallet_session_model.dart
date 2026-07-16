enum WalletSessionProvider {
  baseAccount,
  injectedWallet,
}

extension WalletSessionProviderStorage on WalletSessionProvider {
  String get storageValue {
    switch (this) {
      case WalletSessionProvider.baseAccount:
        return 'base_account';
      case WalletSessionProvider.injectedWallet:
        return 'injected_wallet';
    }
  }

  static WalletSessionProvider? fromStorage(String? value) {
    switch (value) {
      case 'base_account':
        return WalletSessionProvider.baseAccount;
      case 'injected_wallet':
        return WalletSessionProvider.injectedWallet;
      default:
        return null;
    }
  }
}

class WalletSessionSnapshot {
  final WalletSessionProvider provider;
  final String address;
  final int chainId;

  const WalletSessionSnapshot({
    required this.provider,
    required this.address,
    required this.chainId,
  });

  factory WalletSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final provider = WalletSessionProviderStorage.fromStorage(
      json['provider']?.toString(),
    );
    if (provider == null) {
      throw const FormatException('Unknown wallet session provider.');
    }
    return WalletSessionSnapshot(
      provider: provider,
      address: json['address']?.toString() ?? '',
      chainId: (json['chainId'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'provider': provider.storageValue,
        'address': address,
        'chainId': chainId,
      };
}
