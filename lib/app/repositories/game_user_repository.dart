import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_user.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class GameUserRepository extends GetxService {
  final WalletConnectService _wallet = Get.find<WalletConnectService>();

  final Rxn<GameUser> currentUser = Rxn<GameUser>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  Worker? _walletWorker;
  Worker? _chainWorker;

  GameUserRepository bind() {
    _walletWorker ??= ever<String>(_wallet.currentAddress, (_) => _watch());
    _chainWorker ??= ever<int?>(_wallet.chainId, (_) => _watch());
    _watch();
    return this;
  }

  Future<void> _watch() async {
    await _subscription?.cancel();
    currentUser.value = null;
    final address = _wallet.currentAddress.value.trim().toLowerCase();
    final chainId = _wallet.chainId.value;
    if (address.isEmpty || chainId == null) return;

    isLoading.value = true;
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc('${chainId}_$address')
        .snapshots()
        .listen((document) {
      currentUser.value = document.exists
          ? GameUser.fromFirestore(document)
          : null;
      errorMessage.value = '';
      isLoading.value = false;
    }, onError: (Object error) {
      currentUser.value = null;
      errorMessage.value = '$error';
      isLoading.value = false;
    });
  }

  @override
  void onClose() {
    _walletWorker?.dispose();
    _chainWorker?.dispose();
    _subscription?.cancel();
    super.onClose();
  }
}
