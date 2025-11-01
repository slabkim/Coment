import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../logger.dart';

/// Handles Firebase App Check setup and configuration
class AppCheckService {
  /// Activate App Check with appropriate providers based on environment
  static Future<void> activate({
    required bool forceDebug,
    String? webRecaptchaKey,
  }) async {
    final useDebugProvider = forceDebug || kDebugMode;
    
    try {
      if (!useDebugProvider) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
          webProvider: (webRecaptchaKey != null && webRecaptchaKey.isNotEmpty)
              ? ReCaptchaV3Provider(webRecaptchaKey)
              : null,
        );
        AppLogger.info('App Check activated with production providers');
      } else {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        AppLogger.info('App Check activated with debug providers');
      }
    } catch (error, stackTrace) {
      AppLogger.error('Primary App Check activation failed', error, stackTrace);
      
      if (!useDebugProvider) {
        // Report error and fallback to debug provider
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'App bootstrap',
            context: ErrorSummary('initializing Firebase App Check'),
          ),
        );
        
        // Fallback to debug provider
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        AppLogger.warning('App Check fallback to debug providers');
      }
    }

    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

    if (useDebugProvider) {
      try {
        final debugToken = await FirebaseAppCheck.instance.getToken(true);
        AppLogger.debug('Firebase App Check debug token: $debugToken');
      } catch (error, stackTrace) {
        AppLogger.error('Failed to fetch App Check debug token', error, stackTrace);
      }
    }
  }
}

