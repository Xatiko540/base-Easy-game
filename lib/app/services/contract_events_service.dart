import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

import 'app_config_service.dart';
import 'wallet_connect_service.dart';
import 'notifications_service.dart';

class ContractEventsService extends GetxService {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final NotificationsService notifications = Get.find<NotificationsService>();
  Web3Client? _client;
  DeployedContract? _contract;

  ContractEventsService();

  Future<void> init({String? rpcUrl, String? wsUrl}) async {
    // Determine RPC URL - prefer provided, then Firebase config, then default
    final configRpc = _fromConfig('web3Rpc');
    final rpc = rpcUrl ??
        (configRpc.isNotEmpty ? configRpc : walletService.targetNetwork.rpcUrl);

    _client = Web3Client(rpc, Client());

    final artifact = jsonDecode(
      await rootBundle.loadString('src/artifacts/EasyGameAdvance.json'),
    ) as Map<String, dynamic>;
    final abi = artifact['abi'];

    // Resolve contract address via wallet service (falls back to artifact networks)
    String address;
    try {
      address = await walletService.resolveEasyGameAddress();
    } catch (e) {
      if (kDebugMode) {
        print('ContractEventsService init skipped: $e');
      }
      return;
    }

    _contract = DeployedContract(
        ContractAbi.fromJson(jsonEncode(abi), 'EasyGameAdvance'),
        EthereumAddress.fromHex(address.toString()));

    _eventSubscriptions = <String, StreamSubscription>{};

    const eventNames = <String>[
      'LevelActivated',
      'PaymentSplit',
      'ProjectFeeAccrued',
      'MatrixPlaced',
      'ReferralBonusAdded',
      'SecondLineBonusAdded',
      'ThirdLineBonusAdded',
      'WeightUpdated',
      'Recycled',
      'BoxTokenGranted',
      'PrizePositionReached',
      'ReferralBonusClaimed',
      'PrizeClaimed',
      'LevelFrozen',
      'LevelUnfrozen',
      'LevelPriceChanged',
      'WalletsChanged',
    ];

    for (final name in eventNames) {
      _subscribeToGenericEvent(name);
    }
  }

  void _subscribeToGenericEvent(String eventName) {
    try {
      final evt = _contract!.event(eventName);
      final filter = FilterOptions.events(contract: _contract!, event: evt);
      final sub = _client!.events(filter).listen((filterEvent) {
        final topics = filterEvent.topics ?? <String>[];
        final decoded = evt.decodeResults(topics, filterEvent.data ?? '');
        final payload = _prettyPrintEventPayload(eventName, decoded);
        final title = eventName
            .replaceAllMapped(
              RegExp(r'([A-Z])'),
              (match) => ' ${match.group(0)}',
            )
            .trim();
        final body = payload.isNotEmpty ? payload : 'Event fired';
        notifications.showNotification(title: title, body: body);
      });

      _eventSubscriptions![eventName] = sub;
    } catch (_) {
      // ignore if event not found in ABI
    }
  }

  String _prettyPrintEventPayload(String eventName, List<dynamic> decoded) {
    switch (eventName) {
      case 'LevelActivated':
        return _formatLevelActivated(decoded);
      case 'MatrixPlaced':
        return _formatMatrixPlaced(decoded);
      case 'PaymentSplit':
        return _formatPaymentSplit(decoded);
      case 'ReferralBonusAdded':
      case 'SecondLineBonusAdded':
      case 'ThirdLineBonusAdded':
        return _formatReferralPaid(decoded);
      case 'Recycled':
        return _formatRecycled(decoded);
      case 'PrizePositionReached':
        return _formatPrizePosition(decoded);
      case 'LevelFrozen':
      case 'LevelUnfrozen':
        return _formatStatusChange(decoded);
      case 'LevelPriceChanged':
        return _formatLevelPriceChanged(decoded);
      case 'ProjectFeeAccrued':
        return _formatProjectFeeAccrued(decoded);
      default:
        return decoded.map((item) => item.toString()).join(', ');
    }
  }

  String _formatLevelActivated(List<dynamic> decoded) {
    if (decoded.length < 4) return decoded.join(', ');
    final player = decoded[0].toString();
    final level = _asInt(decoded[1]);
    final amount = _weiToEth(_asBigInt(decoded[2]));
    final cellId = _asInt(decoded[3]);
    return 'Player $player activated level $level paying $amount ETH. Cell: $cellId';
  }

  String _formatMatrixPlaced(List<dynamic> decoded) {
    if (decoded.length < 4) return decoded.join(', ');
    final player = decoded[0].toString();
    final level = _asInt(decoded[1]);
    final positionId = _asInt(decoded[2]);
    final parentId = _asInt(decoded[3]);
    return 'Player $player placed in level $level at position $positionId under parent $parentId';
  }

  String _formatPaymentSplit(List<dynamic> decoded) {
    if (decoded.length < 7) return decoded.join(', ');
    final player = decoded[0].toString();
    final level = _asInt(decoded[1]);
    final pool = _weiToEth(_asBigInt(decoded[2]));
    final direct = _weiToEth(_asBigInt(decoded[3]));
    final second = _weiToEth(_asBigInt(decoded[4]));
    final third = _weiToEth(_asBigInt(decoded[5]));
    final fee = _weiToEth(_asBigInt(decoded[6]));
    return 'Payment split for $player level $level: pool $pool, refs $direct/$second/$third, fee $fee ETH';
  }

  String _formatReferralPaid(List<dynamic> decoded) {
    if (decoded.length < 5) return decoded.join(', ');
    final inviter = decoded[0].toString();
    final invitee = decoded[1].toString();
    final level = _asInt(decoded[2]);
    final amount = _weiToEth(_asBigInt(decoded[3]));
    final weight = _asBigInt(decoded[4]);
    return 'Referral bonus to $inviter from $invitee on level $level: $amount ETH, +$weight rating';
  }

  String _formatRecycled(List<dynamic> decoded) {
    if (decoded.length < 4) return decoded.join(', ');
    final player = decoded[0].toString();
    final level = _asInt(decoded[1]);
    final cycle = _asInt(decoded[2]);
    final newPositionId = _asInt(decoded[3]);
    return 'Player $player recycled on level $level, cycle $cycle, new position $newPositionId';
  }

  String _formatPrizePosition(List<dynamic> decoded) {
    if (decoded.length < 5) return decoded.join(', ');
    final player = decoded[0].toString();
    final level = _asInt(decoded[1]);
    final cellId = _asInt(decoded[2]);
    final amount = _weiToEth(_asBigInt(decoded[3]));
    final pending = decoded[4].toString();
    return 'Prize cell $cellId reached by $player on level $level: $amount ETH, pending: $pending';
  }

  String _formatProjectFeeAccrued(List<dynamic> decoded) {
    if (decoded.length < 3) return decoded.join(', ');
    final level = _asInt(decoded[0]);
    final amount = _weiToEth(_asBigInt(decoded[1]));
    final total = _weiToEth(_asBigInt(decoded[2]));
    return 'Project fee accrued on level $level: $amount ETH, total $total ETH';
  }

  String _formatStatusChange(List<dynamic> decoded) {
    if (decoded.length < 2) return decoded.join(', ');
    final player = decoded[0].toString();
    final level = _asInt(decoded[1]);
    return 'Player $player level $level';
  }

  String _formatLevelPriceChanged(List<dynamic> decoded) {
    if (decoded.length < 3) return decoded.join(', ');
    final level = _asInt(decoded[0]);
    final oldPrice = _weiToEth(_asBigInt(decoded[1]));
    final newPrice = _weiToEth(_asBigInt(decoded[2]));
    return 'Level $level price changed from $oldPrice ETH to $newPrice ETH';
  }

  BigInt _asBigInt(dynamic value) {
    if (value is BigInt) return value;
    if (value is int) return BigInt.from(value);
    return BigInt.parse(value.toString());
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is BigInt) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _weiToEth(BigInt value) {
    final decimals = BigInt.from(10).pow(18);
    final ethValue = value.toDouble() / decimals.toDouble();
    return ethValue.toStringAsFixed(6).replaceAll(RegExp(r'\.?0+$'), '');
  }

  Map<String, StreamSubscription>? _eventSubscriptions;

  @override
  void onClose() {
    if (_eventSubscriptions != null) {
      for (final sub in _eventSubscriptions!.values) {
        sub.cancel();
      }
      _eventSubscriptions = null;
    }
    _client?.dispose();
    super.onClose();
  }

  static String _fromConfig(String key) {
    try {
      return Get.find<AppConfigService>().get(key);
    } catch (_) {
      return '';
    }
  }
}
