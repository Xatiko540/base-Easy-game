import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

import 'wallet_connect_service.dart';
import 'notifications_service.dart';

class ContractEventsService extends GetxController {
  final WalletConnectService walletService;
  final NotificationsService notifications;
  Web3Client? _client;
  DeployedContract? _contract;

  ContractEventsService(
      {required this.walletService, required this.notifications});

  Future<void> init({String? rpcUrl, String? wsUrl}) async {
    // Determine RPC URL - prefer provided, then env, then default
    final envRpc = const String.fromEnvironment('WEB3_RPC');
    final rpc =
        rpcUrl ?? (envRpc.isNotEmpty ? envRpc : 'http://127.0.0.1:7545');

    _client = Web3Client(rpc, Client());

    final artifact =
        jsonDecode(await rootBundle.loadString('src/artifacts/EasyGame.json'))
            as Map<String, dynamic>;
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
        ContractAbi.fromJson(jsonEncode(abi), 'EasyGame'),
        EthereumAddress.fromHex(address.toString()));

    _eventSubscriptions = <String, StreamSubscription>{};

    const eventNames = <String>[
      'LevelActivated',
      'MatrixPlaced',
      'MatrixRewardPaid',
      'ReferralPaid',
      'Recycled',
      'LevelFrozen',
      'LevelUnfrozen',
      'LevelPriceChanged',
      'TreasuryChanged',
      'OperatorWalletChanged',
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
      case 'MatrixRewardPaid':
        return _formatMatrixRewardPaid(decoded);
      case 'ReferralPaid':
        return _formatReferralPaid(decoded);
      case 'Recycled':
        return _formatRecycled(decoded);
      case 'LevelFrozen':
      case 'LevelUnfrozen':
        return _formatStatusChange(decoded);
      case 'LevelPriceChanged':
        return _formatLevelPriceChanged(decoded);
      case 'TreasuryChanged':
        return _formatTreasuryChanged(decoded);
      case 'OperatorWalletChanged':
        return _formatOperatorWalletChanged(decoded);
      default:
        return decoded.map((item) => item.toString()).join(', ');
    }
  }

  String _formatLevelActivated(List<dynamic> decoded) {
    if (decoded.length < 4) return decoded.join(', ');
    final player = decoded[0].toString();
    final level = _asInt(decoded[1]);
    final amount = _weiToEth(_asBigInt(decoded[2]));
    final inviter = decoded[3].toString();
    return 'Player $player activated level $level paying $amount ETH. Inviter: ${inviter.isNotEmpty ? inviter : 'none'}';
  }

  String _formatMatrixPlaced(List<dynamic> decoded) {
    if (decoded.length < 4) return decoded.join(', ');
    final player = decoded[0].toString();
    final level = _asInt(decoded[1]);
    final positionId = _asInt(decoded[2]);
    final parentId = _asInt(decoded[3]);
    return 'Player $player placed in level $level at position $positionId under parent $parentId';
  }

  String _formatMatrixRewardPaid(List<dynamic> decoded) {
    if (decoded.length < 4) return decoded.join(', ');
    final from = decoded[0].toString();
    final to = decoded[1].toString();
    final level = _asInt(decoded[2]);
    final amount = _weiToEth(_asBigInt(decoded[3]));
    return 'Reward from $from to $to for level $level: $amount ETH';
  }

  String _formatReferralPaid(List<dynamic> decoded) {
    if (decoded.length < 4) return decoded.join(', ');
    final player = decoded[0].toString();
    final receiver = decoded[1].toString();
    final line = _asInt(decoded[2]);
    final amount = _weiToEth(_asBigInt(decoded[3]));
    return 'Referral payment for $player to $receiver line $line: $amount ETH';
  }

  String _formatRecycled(List<dynamic> decoded) {
    if (decoded.length < 4) return decoded.join(', ');
    final player = decoded[0].toString();
    final level = _asInt(decoded[1]);
    final cycle = _asInt(decoded[2]);
    final newPositionId = _asInt(decoded[3]);
    return 'Player $player recycled on level $level, cycle $cycle, new position $newPositionId';
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

  String _formatTreasuryChanged(List<dynamic> decoded) {
    if (decoded.length < 2) return decoded.join(', ');
    final oldTreasury = decoded[0].toString();
    final newTreasury = decoded[1].toString();
    return 'Treasury changed from $oldTreasury to $newTreasury';
  }

  String _formatOperatorWalletChanged(List<dynamic> decoded) {
    if (decoded.length < 2) return decoded.join(', ');
    final oldOperatorWallet = decoded[0].toString();
    final newOperatorWallet = decoded[1].toString();
    return 'Operator wallet changed from $oldOperatorWallet to $newOperatorWallet';
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
}
