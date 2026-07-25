class WagmiContractResult {
  const WagmiContractResult._();

  static dynamic unwrap(dynamic result) {
    if (result is Map && result.containsKey('result')) {
      return result['result'];
    }
    return result;
  }

  static bool hasField(
    dynamic result, {
    required int index,
    required String name,
  }) {
    if (result is List) return index < result.length;
    if (result is Map) {
      return result.containsKey(name) ||
          result.containsKey(index) ||
          result.containsKey('$index');
    }
    return false;
  }

  static dynamic field(
    dynamic result, {
    required int index,
    required String name,
  }) {
    if (result is List && index < result.length) return result[index];
    if (result is Map) {
      if (result.containsKey(name)) return result[name];
      if (result.containsKey(index)) return result[index];
      if (result.containsKey('$index')) return result['$index'];
    }
    return null;
  }

  static BigInt bigInt(
    dynamic result, {
    required int index,
    required String name,
  }) {
    final value = field(result, index: index, name: name);
    if (value is BigInt) return value;
    if (value is int) return BigInt.from(value);
    if (value is num) return BigInt.from(value.toInt());
    return BigInt.tryParse(value?.toString() ?? '') ?? BigInt.zero;
  }

  static BigInt scalarBigInt(dynamic value) {
    if (value is BigInt) return value;
    if (value is int) return BigInt.from(value);
    if (value is num) return BigInt.from(value.toInt());
    return BigInt.tryParse(value?.toString() ?? '') ?? BigInt.zero;
  }

  static bool boolean(
    dynamic result, {
    required int index,
    required String name,
  }) {
    final value = field(result, index: index, name: name);
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true';
  }

  static bool scalarBoolean(dynamic value) {
    if (value is bool) return value;
    if (value is BigInt) return value != BigInt.zero;
    if (value is num) return value != 0;
    final normalized = value?.toString().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return false;
  }

  static String string(
    dynamic result, {
    required int index,
    required String name,
    String fallback = '',
  }) {
    final value = field(result, index: index, name: name);
    return value?.toString() ?? fallback;
  }
}
