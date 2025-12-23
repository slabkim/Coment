import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place to read AdMob IDs and IAP product IDs.
/// Falls back to Google test IDs so the app still runs while real IDs are
/// being provisioned.
class AdConfig {
  // Google test IDs (safe for development)
  static const _testAppIdAndroid = 'ca-app-pub-3940256099942544~3347511713';
  static const _testAppIdIos = 'ca-app-pub-3940256099942544~1458002511';
  static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  static String get appIdAndroid =>
      _readEnv('ADMOB_APP_ID_ANDROID', _testAppIdAndroid);

  static String get appIdIos =>
      _readEnv('ADMOB_APP_ID_IOS', _testAppIdIos);

  static String get bannerAdUnitId =>
      _readEnv('ADMOB_BANNER_UNIT_ID', _testBannerId);

  static String get interstitialAdUnitId =>
      _readEnv('ADMOB_INTERSTITIAL_UNIT_ID', _testInterstitialId);

  static String get rewardedAdUnitId =>
      _readEnv('ADMOB_REWARDED_UNIT_ID', _testRewardedId);

  /// Non-consumable product ID to unlock an ad-free experience.
  static const removeAdsProductId = 'remove_ads';

  /// Optional list of test device IDs for cleaner QA.
  static List<String> get testDeviceIds {
    final raw = dotenv.env['ADMOB_TEST_DEVICES'];
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static bool get usingTestIds =>
      bannerAdUnitId == _testBannerId ||
      interstitialAdUnitId == _testInterstitialId ||
      rewardedAdUnitId == _testRewardedId;

  static String _readEnv(String key, String fallback) {
    final value = dotenv.env[key];
    if (value == null) return fallback;
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
