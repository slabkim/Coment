import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Log levels for filtering output
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Centralized logging service for the application
/// 
/// Provides consistent logging across the app with:
/// - Log level filtering (debug/info only in debug mode)
/// - Firebase Crashlytics integration for errors
/// - Clean, readable output format
class AppLogger {
  /// Minimum log level to display
  /// In production, only warning and error are shown
  static LogLevel get _minLevel => kDebugMode ? LogLevel.debug : LogLevel.warning;

  /// Log a debug message (only in debug mode)
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.debug)) {
      debugPrint('[DEBUG] $message');
      if (error != null) {
        debugPrint('  Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('  Stack: $stackTrace');
      }
    }
  }

  /// Log an info message (only in debug mode)
  static void info(String message) {
    if (_shouldLog(LogLevel.info)) {
      debugPrint('[INFO] $message');
    }
  }

  /// Log a warning message (always shown)
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.warning)) {
      debugPrint('[WARNING] $message');
      if (error != null) {
        debugPrint('  Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('  Stack: $stackTrace');
      }
    }
  }

  /// Log an error message (always shown, sent to Crashlytics)
  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    bool fatal = false,
  ]) {
    if (_shouldLog(LogLevel.error)) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('  Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('  Stack: $stackTrace');
      }
    }

    // Send to Crashlytics in production
    if (!kDebugMode) {
      try {
        if (error != null && stackTrace != null) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            fatal: fatal,
            reason: message,
          );
        } else {
          FirebaseCrashlytics.instance.log('[ERROR] $message');
        }
      } catch (_) {
        // Fail silently if Crashlytics is not initialized
      }
    }
  }

  /// Check if a log level should be displayed
  static bool _shouldLog(LogLevel level) {
    return level.index >= _minLevel.index;
  }

  /// Log API errors with context
  static void apiError(
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    AppLogger.error('API Error in $operation', error, stackTrace);
  }

  /// Log Firebase errors with context
  static void firebaseError(
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    AppLogger.error('Firebase Error in $operation', error, stackTrace);
  }

  /// Log auth errors with context
  static void authError(
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    AppLogger.warning('Auth Error in $operation', error, stackTrace);
  }
}

