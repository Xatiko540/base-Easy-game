import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/firebase_options.dart';

class AppConfigService extends GetxService {
  static const _region = 'us-central1';
  static const _useFirebaseEmulators =
      bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  static bool _emulatorsConfigured = false;
  static const _envEasyGameAddress =
      String.fromEnvironment('EASY_GAME_ADDRESS');
  static const _envEasyGameContractAddress =
      String.fromEnvironment('EASY_GAME_CONTRACT_ADDRESS');
  static const _envRoundManagerAddress =
      String.fromEnvironment('EASY_GAME_ROUND_MANAGER_ADDRESS');
  static const _envArenaSkillsAddress =
      String.fromEnvironment('EASY_GAME_ARENA_SKILLS_ADDRESS');
  static const _envRoundSettlementAddress =
      String.fromEnvironment('EASY_GAME_ROUND_SETTLEMENT_ADDRESS');
  static const _envEasyGameInviter =
      String.fromEnvironment('EASY_GAME_INVITER');
  static const _envPaymentReceiver = String.fromEnvironment('PAYMENT_RECEIVER');
  static const _envUsdcTokenAddress =
      String.fromEnvironment('USDC_TOKEN_ADDRESS');
  static const _envWeb3PublicRpcUrl =
      String.fromEnvironment('WEB3_PUBLIC_RPC_URL');
  static const _envBaseBuilderDataSuffix =
      String.fromEnvironment('BASE_BUILDER_DATA_SUFFIX');
  static const _envAllowLocalChains =
      String.fromEnvironment('EASY_GAME_ALLOW_LOCAL_CHAINS');
  static const _envAppPublicUrl = String.fromEnvironment('APP_PUBLIC_URL');
  static const _envTargetBaseChainId =
      int.fromEnvironment('EASY_GAME_CHAIN_ID', defaultValue: 0);

  final RxBool isLoaded = false.obs;
  final Map<String, String> _data = {};
  Future<void>? _fetchInProgress;

  Future<void> fetch() {
    if (isLoaded.value) return Future<void>.value();
    return _fetchInProgress ??=
        _fetchConfig().whenComplete(() => _fetchInProgress = null);
  }

  Future<void> _fetchConfig() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      if (_useFirebaseEmulators && !_emulatorsConfigured) {
        const host = '127.0.0.1';
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
        await FirebaseAuth.instance.useAuthEmulator(host, 9099);
        FirebaseFunctions.instanceFor(region: _region)
            .useFunctionsEmulator(host, 5001);
        _emulatorsConfigured = true;
      }
      final functions = FirebaseFunctions.instanceFor(region: _region);
      final result = await functions.httpsCallable('getAppConfig').call();
      final map = Map<String, dynamic>.from(result.data as Map);
      for (final entry in map.entries) {
        _data[entry.key] = entry.value?.toString() ?? '';
      }
      _copyAlias(from: 'chainId', to: 'targetBaseChainId');
      _copyAlias(from: 'contractAddress', to: 'easyGameContractAddress');
      _copyAlias(
          from: 'easyGameRoundManagerAddress', to: 'roundManagerAddress');
      _copyAlias(from: 'web3Rpc', to: 'web3PublicRpcUrl');
      _copyAlias(from: 'usdcTokenAddress', to: 'usdcContractAddress');
      isLoaded.value = true;
    } catch (e) {
      debugPrint('AppConfigService fetch failed: $e');
      rethrow;
    }
  }

  void _copyAlias({required String from, required String to}) {
    final source = _data[from];
    final target = _data[to];
    if ((target == null || target.isEmpty) && source != null) {
      _data[to] = source;
    }
  }

  String get(String key, [String defaultValue = '']) {
    final value = _data[key];
    if (value != null && value.isNotEmpty) return value;

    final env = _envValue(key);
    if (env.isNotEmpty) return env;

    return defaultValue;
  }

  int getInt(String key, [int defaultValue = 0]) =>
      int.tryParse(get(key)) ?? defaultValue;

  bool getBool(String key, [bool defaultValue = false]) {
    final val = get(key);
    if (val.isEmpty) return defaultValue;
    return val == 'true' || val == '1';
  }

  String _envValue(String key) {
    switch (key) {
      case 'contractAddress':
      case 'easyGameContractAddress':
        return _envEasyGameAddress.isNotEmpty
            ? _envEasyGameAddress
            : _envEasyGameContractAddress;
      case 'easyGameRoundManagerAddress':
      case 'roundManagerAddress':
        return _envRoundManagerAddress;
      case 'arenaSkillsAddress':
        return _envArenaSkillsAddress;
      case 'roundSettlementAddress':
        return _envRoundSettlementAddress;
      case 'easyGameInviter':
        return _envEasyGameInviter;
      case 'paymentReceiver':
        return _envPaymentReceiver;
      case 'usdcContractAddress':
      case 'usdcTokenAddress':
        return _envUsdcTokenAddress;
      case 'web3Rpc':
      case 'web3PublicRpcUrl':
        return _envWeb3PublicRpcUrl;
      case 'baseBuilderDataSuffix':
        return _envBaseBuilderDataSuffix;
      case 'allowLocalChains':
        return _envAllowLocalChains;
      case 'appPublicUrl':
        return _envAppPublicUrl;
      case 'chainId':
      case 'targetBaseChainId':
        return _envTargetBaseChainId == 0 ? '' : '$_envTargetBaseChainId';
      default:
        return '';
    }
  }
}
