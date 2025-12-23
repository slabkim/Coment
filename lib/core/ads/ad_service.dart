import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../logger.dart';
import 'ad_config.dart';

/// Thin wrapper around Google Mobile Ads initialization so we only
/// bootstrap the SDK once per app session.
class AdService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final config = RequestConfiguration(
        testDeviceIds: AdConfig.testDeviceIds,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
      );
      await MobileAds.instance.updateRequestConfiguration(config);
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (error, stackTrace) {
      AppLogger.warning('Failed to initialize Google Mobile Ads', error, stackTrace);
    }
  }
}
