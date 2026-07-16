import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottery_advance/app/models/wallet_session_model.dart';

class WalletSessionStore extends GetxService {
  static const String _sessionKey = 'wallet_session_v1';

  final GetStorage _storage;
  final Rxn<WalletSessionSnapshot> session = Rxn<WalletSessionSnapshot>();

  WalletSessionStore({GetStorage? storage})
      : _storage = storage ?? GetStorage();

  @override
  void onInit() {
    super.onInit();
    session.value = read();
  }

  WalletSessionSnapshot? read() {
    final raw = _storage.read<dynamic>(_sessionKey);
    if (raw is! Map) return null;
    try {
      return WalletSessionSnapshot.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> save(WalletSessionSnapshot value) async {
    session.value = value;
    await _storage.write(_sessionKey, value.toJson());
  }

  Future<void> clear() async {
    session.value = null;
    await _storage.remove(_sessionKey);
  }
}
