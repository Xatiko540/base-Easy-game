import 'package:get/get.dart';
import 'app_config_service.dart';

class ReferralLinkService {
  static const String referralPath = 'npalce';
  static String get publicBaseUrl {
    try {
      final fromConfig = Get.find<AppConfigService>().get('appPublicUrl');
      if (fromConfig.isNotEmpty) return fromConfig;
    } catch (_) {}
    return 'https://express.game';
  }

  static final RegExp _addressPattern = RegExp(r'^0x[a-fA-F0-9]{40}$');

  static String buildReferralLink(String walletAddress) {
    final inviter = normalizeAddress(walletAddress);
    final base = publicBaseUrl.endsWith('/')
        ? publicBaseUrl.substring(0, publicBaseUrl.length - 1)
        : publicBaseUrl;

    if (inviter.isEmpty) {
      return '$base/$referralPath';
    }

    return '$base/$referralPath?inviter=$inviter';
  }

  static String inviterFromCurrentUrl() => inviterFromUri(Uri.base);

  static String inviterFromParams(Map<String, String?> params) {
    for (final key in const ['inviter', 'ref', 'upline']) {
      final value = normalizeAddress(params[key] ?? '');
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static String inviterFromUri(Uri uri) {
    final fromQuery = inviterFromParams(uri.queryParameters);
    if (fromQuery.isNotEmpty) {
      return fromQuery;
    }

    final segments = uri.pathSegments;
    final referralIndex = segments.indexOf(referralPath);
    if (referralIndex >= 0 && referralIndex + 1 < segments.length) {
      final fromPath = normalizeAddress(segments[referralIndex + 1]);
      if (fromPath.isNotEmpty) {
        return fromPath;
      }
    }

    if (uri.fragment.isNotEmpty) {
      final fragment = uri.fragment.startsWith('/')
          ? Uri.parse('https://express.game${uri.fragment}')
          : Uri.parse('https://express.game/${uri.fragment}');
      final fromFragment = inviterFromUri(fragment);
      if (fromFragment.isNotEmpty) {
        return fromFragment;
      }
    }

    return '';
  }

  static bool isReferralEntryUri(Uri uri) {
    if (inviterFromUri(uri).isNotEmpty) {
      return true;
    }

    if (uri.pathSegments.contains(referralPath)) {
      return true;
    }

    if (uri.fragment.isNotEmpty) {
      return uri.fragment.contains(referralPath) ||
          uri.fragment.contains('inviter=');
    }

    return false;
  }

  static String normalizeAddress(String value) {
    final trimmed = value.trim();
    if (!_addressPattern.hasMatch(trimmed)) {
      return '';
    }
    return trimmed.toLowerCase();
  }
}
