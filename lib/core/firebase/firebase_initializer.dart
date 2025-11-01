import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../logger.dart';

/// Handles Firebase initialization
class FirebaseInitializer {
  /// Initialize Firebase with error handling for duplicate app
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      AppLogger.info('Firebase initialized successfully');
    } catch (e, stackTrace) {
      if (e.toString().contains('duplicate-app')) {
        AppLogger.debug('Firebase already initialized, skipping...');
      } else {
        AppLogger.firebaseError('Firebase initialization', e, stackTrace);
        rethrow;
      }
    }
  }
}

