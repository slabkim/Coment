import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../firebase_options.dart';
import 'auth_token_manager.dart';
import '../logger.dart';
import '../../data/services/xp_service.dart';
import '../../notifications/notification_service.dart';

/// Handles Firebase Cloud Messaging (FCM) configuration and token management
class FCMService {
  static RemoteMessage? _pendingInitialMessage;
  static RemoteMessage? get pendingInitialMessage => _pendingInitialMessage;

  /// Background message handler (must be top-level function)
  @pragma('vm:entry-point')
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    // Initialize Firebase if needed
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Show local notification for better control over tap handling
    try {
      await AppNotificationService.instance.initialize();
      await AppNotificationService.instance.showForegroundRemote(message);
    } catch (e) {
      AppLogger.error('Error showing background notification', e);
    }
  }

  /// Get FCM token with error handling
  static Future<String?> getFcmToken(FirebaseMessaging messaging) async {
    try {
      final token = await messaging.getToken();
      AppLogger.debug('FCM token obtained');
      return token;
    } on FirebaseException catch (error, stackTrace) {
      await AuthTokenManager.handleAuthTokenFailure(error, stackTrace: stackTrace);
      AppLogger.firebaseError('Failed to obtain FCM token', error, stackTrace);
      return null;
    }
  }

  /// Persist FCM token to user document in Firestore
  static Future<void> persistUserFcmToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      AppLogger.debug('FCM token persisted for user: $uid');
    } on FirebaseException catch (error, stackTrace) {
      await AuthTokenManager.handleAuthTokenFailure(error, stackTrace: stackTrace);
      AppLogger.firebaseError('Failed to persist FCM token', error, stackTrace);
    }
  }

  /// Handle user login bonus and session updates
  static Future<void> _handleUserLogin(String uid) async {
    // Update lastSeen on auth state change
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      AppLogger.debug('LastSeen updated for user: $uid');
    } catch (e, stackTrace) {
      AppLogger.warning('Failed to update lastSeen', e, stackTrace);
    }

    // Award daily login bonus XP
    try {
      final xpService = XPService();
      await xpService.awardDailyLogin(uid);
      
      // Award MAX XP to developer accounts (SSS Class) 👑
      await xpService.awardDeveloperMaxXP(uid);
      AppLogger.debug('XP awarded to user: $uid');
    } catch (e, stackTrace) {
      AppLogger.warning('Failed to award XP', e, stackTrace);
    }
  }

  /// Configure FCM messaging with all handlers
  static Future<void> configure({
    required Function(RemoteMessage) onForegroundMessage,
    required Function(RemoteMessage) onMessageOpened,
  }) async {
    final fcm = FirebaseMessaging.instance;
    
    // Request notification permissions
    await fcm.requestPermission();
    AppLogger.info('FCM permissions requested');

    // Get initial token
    final token = await getFcmToken(fcm);
    final user = FirebaseAuth.instance.currentUser;
    if (token != null && user != null) {
      await persistUserFcmToken(user.uid, token);
    }

    // Listen for auth state changes to persist token and update session
    FirebaseAuth.instance.authStateChanges().listen((u) async {
      if (u != null) {
        final t = await getFcmToken(fcm);
        if (t != null) {
          await persistUserFcmToken(u.uid, t);
        }
        await _handleUserLogin(u.uid);
      }
    });

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        final refreshedUser = FirebaseAuth.instance.currentUser;
        if (refreshedUser != null) {
          await persistUserFcmToken(refreshedUser.uid, newToken);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        unawaited(AuthTokenManager.handleAuthTokenFailure(error, stackTrace: stackTrace));
      },
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      onForegroundMessage(message);
      // Also show local notification as backup
      await AppNotificationService.instance.showForegroundRemote(message);
    });

    // Notification opened handler
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpened);

    // Get initial message (app launched from terminated state)
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _pendingInitialMessage = initial;
        AppLogger.info('App launched from notification');
      }
    } catch (e, stackTrace) {
      AppLogger.warning('Failed to get initial message', e, stackTrace);
    }

    AppLogger.info('FCM configuration completed');
  }

  /// Clear pending initial message
  static void clearPendingMessage() {
    _pendingInitialMessage = null;
  }
}

