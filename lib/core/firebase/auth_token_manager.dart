import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../logger.dart';

/// Handles Firebase Auth token refresh and validation
class AuthTokenManager {
  /// Check if an error indicates an invalid refresh token
  static bool _isInvalidRefreshTokenError(Object error) {
    if (error is FirebaseAuthException) {
      final message = error.message ?? '';
      return error.code == 'user-token-expired' ||
          message.contains('INVALID_REFRESH_TOKEN');
    }
    if (error is FirebaseException) {
      final message = error.message ?? '';
      return message.contains('INVALID_REFRESH_TOKEN') ||
          error.code.toLowerCase() == 'unauthenticated';
    }
    return false;
  }

  /// Handle auth token failures, signing out if token is invalid
  static Future<void> handleAuthTokenFailure(
    Object error, {
    StackTrace? stackTrace,
  }) async {
    if (_isInvalidRefreshTokenError(error)) {
      AppLogger.authError('Invalid refresh token detected, signing out', error, stackTrace);
      try {
        await FirebaseAuth.instance.signOut();
        AppLogger.info('User signed out due to invalid token');
      } catch (signOutError, stackTrace) {
        AppLogger.authError('Sign-out after invalid token failed', signOutError, stackTrace);
      }
    } else if (kDebugMode) {
      AppLogger.debug('Firebase operation error ignored', error, stackTrace);
    }
  }

  /// Ensure user session is fresh by refreshing ID token
  static Future<void> ensureFreshUserSession() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppLogger.debug('No current user, skipping token refresh');
      return;
    }
    
    try {
      await currentUser.getIdToken(true);
      AppLogger.debug('User session refreshed');
    } on FirebaseAuthException catch (error, stackTrace) {
      await handleAuthTokenFailure(error, stackTrace: stackTrace);
    }
  }
}

