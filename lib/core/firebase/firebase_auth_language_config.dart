import 'dart:ui' as ui;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logger.dart';

/// Handles Firebase Auth language configuration
class FirebaseAuthLanguageConfig {
  /// Configure Firebase Auth language based on device locale or .env override
  static Future<void> configure() async {
    final override = dotenv.env['FIREBASE_AUTH_LANGUAGE']?.trim();
    final localeCode = (override != null && override.isNotEmpty)
        ? override
        : ui.PlatformDispatcher.instance.locale.languageCode;
    
    if (localeCode.isEmpty) {
      AppLogger.debug('Skipping Firebase Auth language config: empty locale');
      return;
    }
    
    try {
      await FirebaseAuth.instance.setLanguageCode(localeCode);
      AppLogger.info('Firebase Auth language set to: $localeCode');
    } catch (error, stackTrace) {
      AppLogger.authError('Setting Firebase Auth language', error, stackTrace);
    }
  }
}

