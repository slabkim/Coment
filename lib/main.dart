import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'notifications/notification_service.dart';
import 'ui/screens/chat_screen.dart';
import 'ui/screens/detail_screen.dart';
import 'ui/screens/forum_chat_screen.dart';
import 'ui/screens/main_screen.dart';
import 'data/models/forum.dart';
import 'data/models/nandogami_item.dart';
import 'data/models/comic_item.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'data/repositories/comic_repository.dart';
import 'data/services/xp_service.dart';
import 'firebase_options.dart';
import 'state/item_provider.dart';
import 'state/theme_provider.dart';
import 'ui/screens/chat_list_screen.dart';
import 'ui/screens/splash_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
RemoteMessage? _pendingInitialMessage;

// Native notification tap channel
const MethodChannel _notificationChannel = MethodChannel('com.example.nandogami/notification');

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Show local notification for better control over tap handling
  // This ensures notification tap can navigate properly even when app is terminated
  try {
    await AppNotificationService.instance.initialize();
    await AppNotificationService.instance.showForegroundRemote(message);
  } catch (e) {
    debugPrint('Error showing background notification: $e');
  }
}

Future<void> _configureMessaging() async {
  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission();
  final token = await _getFcmToken(fcm);
  
  final user = FirebaseAuth.instance.currentUser;
  if (token != null && user != null) {
    await _persistUserFcmToken(user.uid, token);
  }
  // Persist token and update lastSeen when user logs in after app start
  FirebaseAuth.instance.authStateChanges().listen((u) async {
    if (u != null) {
      final t = await _getFcmToken(fcm);
      if (t != null) {
        await _persistUserFcmToken(u.uid, t);
      }
      // Update lastSeen on auth state change
      try {
        await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      } catch (e) {
        // Silently fail
      }
      // Award daily login bonus XP
      try {
        final xpService = XPService();
        await xpService.awardDailyLogin(u.uid);
        
        // Award MAX XP to developer accounts (SSS Class) 👑
        await xpService.awardDeveloperMaxXP(u.uid);
      } catch (e) {
        // Silently fail
      }
    }
  });
  FirebaseMessaging.instance.onTokenRefresh.listen(
    (newToken) async {
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser != null) {
        await _persistUserFcmToken(refreshedUser.uid, newToken);
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      unawaited(_handleAuthTokenFailure(error, stackTrace: stackTrace));
    },
  );

  // Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Foreground message: show in-app notification popup
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    // Show in-app notification popup
    _showInAppNotification(message);
    
    // Also show local notification as backup
    await AppNotificationService.instance.showForegroundRemote(message);
  });

  // Notification opened
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleMessageNavigation(message, initial: false);
  });

  // App launched from terminated by tapping notification
  try {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _pendingInitialMessage = initial;
    }
  } catch (_) {}
}

void _showInAppNotification(RemoteMessage message) {
  // Add small delay to ensure Scaffold is fully mounted
  Future.delayed(const Duration(milliseconds: 500), () {
    try {
      final context = appNavigatorKey.currentContext;
      if (context == null) {
        debugPrint('⚠️ In-app notification: context is null');
        return;
      }

      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      final notification = message.notification;
      
      if (scaffoldMessenger == null || notification == null) return;

      final title = notification.title ?? 'New Notification';
      final body = notification.body ?? '';
      final type = message.data['type'];

      // Choose emoji based on notification type
      final emoji = type == 'dm' ? '💬' : 
                    (type == 'like' ? '❤️' : 
                    (type == 'follow' ? '👤' : 
                    (type == 'mention' ? '📣' : '🔔')));

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$emoji $title',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Theme.of(context).colorScheme.primary,
            onPressed: () {
              _handleMessageNavigation(message, initial: false);
            },
          ),
        ),
      );
    } catch (e) {
      // Silently ignore in-app notification errors
    }
  });
}

Future<void> _handleMessageNavigation(RemoteMessage message, {required bool initial}) async {
  final type = message.data['type'];
  final navigator = appNavigatorKey.currentState;
  
  if (navigator == null) {
    _pendingInitialMessage = message;
    return;
  }

  // When app is launched from notification (closed state), just go to Home
  // Same behavior as clicking app icon - simple and has proper back stack
  if (initial) {
    debugPrint('📱 App launched from notification ($type), navigating to Home');
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainScreen(initialIndex: 0), // Home tab
      ),
      (route) => false, // Clear all routes including SplashScreen
    );
    return;
  }

  // When app is already running (foreground), navigate to specific page
  switch (type) {
    case 'dm':
      final senderId = message.data['senderId'];
      if (senderId == null || senderId.toString().isEmpty) return;
      
      final senderName = (message.data['senderName'] as String?)
          ?? message.notification?.title
          ?? 'Someone';
      
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            peerUserId: senderId,
            peerDisplayName: senderName,
          ),
        ),
      );
      break;

    case 'mention':
      final forumId = message.data['forumId'];
      if (forumId == null || forumId.toString().isEmpty) {
        debugPrint('⚠️ Mention notification missing forumId');
        return;
      }
      
      try {
        final forumDoc = await FirebaseFirestore.instance
            .collection('forums')
            .doc(forumId)
            .get();
        
        if (!forumDoc.exists) {
          debugPrint('⚠️ Forum not found: $forumId');
          if (navigator.mounted) {
            ScaffoldMessenger.of(navigator.context).showSnackBar(
              const SnackBar(content: Text('Forum not found or deleted')),
            );
          }
          return;
        }
        
        final forum = Forum.fromMap(forumDoc.id, forumDoc.data()!);
        
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ForumChatScreen(forum: forum),
          ),
        );
      } catch (e) {
        debugPrint('⚠️ Error navigating to forum: $e');
        if (navigator.mounted) {
          ScaffoldMessenger.of(navigator.context).showSnackBar(
            SnackBar(content: Text('Error opening forum: $e')),
          );
        }
      }
      break;

    case 'like':
      final itemId = message.data['itemId'];
      if (itemId == null || itemId.toString().isEmpty) {
        debugPrint('⚠️ Like notification missing itemId');
        return;
      }
      
      try {
        final itemProvider = Provider.of<ItemProvider>(
          navigator.context,
          listen: false,
        );
        
        var item = itemProvider.items.cast<NandogamiItem?>().firstWhere(
          (i) => i?.id == itemId,
          orElse: () => null,
        );
        
        if (item == null) {
          final anilistId = int.tryParse(itemId);
          if (anilistId != null) {
            final repo = ComicRepository();
            final comicItem = await repo.getDetail(anilistId);
            item = NandogamiItem(
              id: comicItem.id,
              title: comicItem.title,
              imageUrl: comicItem.imageUrl,
              description: comicItem.description,
              popularity: comicItem.popularity ?? 0,
              rating: comicItem.rating,
              genres: comicItem.categories,
              status: comicItem.status,
              type: comicItem.format,
            );
          }
        }
        
        if (item == null) {
          debugPrint('⚠️ Item not found: $itemId');
          return;
        }
        
        navigator.push(
          MaterialPageRoute(
            builder: (_) => DetailScreen(item: item!),
          ),
        );
      } catch (e) {
        debugPrint('⚠️ Error navigating to detail: $e');
      }
      break;

    case 'follow':
      navigator.push(
        MaterialPageRoute(
          builder: (_) => const MainScreen(initialIndex: 3), // Profile tab
        ),
      );
      break;
  }
}

Future<String?> _getFcmToken(FirebaseMessaging messaging) async {
  try {
    return await messaging.getToken();
  } on FirebaseException catch (error, stackTrace) {
    await _handleAuthTokenFailure(error, stackTrace: stackTrace);
    debugPrint('Failed to obtain FCM token: ${error.message}');
    return null;
  }
}

Future<void> _persistUserFcmToken(String uid, String token) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmUpdatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  } on FirebaseException catch (error, stackTrace) {
    await _handleAuthTokenFailure(error, stackTrace: stackTrace);
    debugPrint('Failed to persist FCM token: ${error.message}');
  }
}

bool _isInvalidRefreshTokenError(Object error) {
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

Future<void> _handleAuthTokenFailure(
  Object error, {
  StackTrace? stackTrace,
}) async {
  if (_isInvalidRefreshTokenError(error)) {
    debugPrint('[Auth] Invalid refresh token detected, signing out: $error');
    try {
      await FirebaseAuth.instance.signOut();
    } catch (signOutError) {
      debugPrint('[Auth] Sign-out after invalid token failed: $signOutError');
    }
  } else if (kDebugMode) {
    debugPrint('[Auth] Firebase operation error ignored: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}

Future<void> _ensureFreshUserSession() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;
  try {
    await currentUser.getIdToken(true);
  } on FirebaseAuthException catch (error, stackTrace) {
    await _handleAuthTokenFailure(error, stackTrace: stackTrace);
  }
}

Future<void> _configureFirebaseAuthLanguage() async {
  final override = dotenv.env['FIREBASE_AUTH_LANGUAGE']?.trim();
  final localeCode = (override != null && override.isNotEmpty)
      ? override
      : ui.PlatformDispatcher.instance.locale.languageCode;
  if (localeCode.isEmpty) return;
  try {
    await FirebaseAuth.instance.setLanguageCode(localeCode);
  } catch (error) {
    debugPrint('Unable to set Firebase Auth language ($localeCode): $error');
  }
}

Future<void> _activateAppCheck({
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
    } else {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    }
  } catch (error, stackTrace) {
    debugPrint('Primary App Check activation failed: $error');
    if (!useDebugProvider) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'App bootstrap',
          context: ErrorSummary('initializing Firebase App Check'),
        ),
      );
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    }
  }

  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

  if (useDebugProvider) {
    try {
      final debugToken = await FirebaseAppCheck.instance.getToken(true);
      debugPrint('Firebase App Check debug token: $debugToken');
    } catch (error) {
      debugPrint('Failed to fetch App Check debug token: $error');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Initialize Firebase with error handling for duplicate app
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized, skipping...');
    } else {
      rethrow;
    }
  }

  final appCheckDebugOverride =
      (dotenv.env['FIREBASE_APPCHECK_DEBUG'] ?? '').toLowerCase() == 'true';
  final webRecaptchaKey = dotenv.env['FIREBASE_RECAPTCHA_SITE_KEY'];

  await _configureFirebaseAuthLanguage();
  await _activateAppCheck(
    forceDebug: appCheckDebugOverride,
    webRecaptchaKey: webRecaptchaKey,
  );
  await _ensureFreshUserSession();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  try {
    await FirebaseAnalytics.instance.logAppOpen();
  } catch (_) {}

  try {
    await _configureMessaging();
  } catch (error, stackTrace) {
    await _handleAuthTokenFailure(error, stackTrace: stackTrace);
  }

  // Initialize local notifications
  try {
    AppNotificationService.instance.onNotificationTap = (message) {
      _handleMessageNavigation(message, initial: false);
    };
    await AppNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  // Setup native notification tap listener
  _notificationChannel.setMethodCallHandler((call) async {
    if (call.method == 'onNotificationTap') {
      try {
        final Map<dynamic, dynamic> data = call.arguments as Map<dynamic, dynamic>;
        final Map<String, dynamic> messageData = data.map((key, value) => 
          MapEntry(key.toString(), value));
        
        final message = RemoteMessage(data: messageData);
        
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleMessageNavigation(message, initial: false);
        });
      } catch (e) {
        debugPrint('Error handling native tap: $e');
      }
    }
  });

  runApp(const NandogamiBootstrap());

  // Handle any pending initial notification tap after app mount
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final msg = _pendingInitialMessage;
    if (msg != null) {
      _pendingInitialMessage = null;
      _handleMessageNavigation(msg, initial: true);
    }
  });
}

class NandogamiBootstrap extends StatelessWidget {
  const NandogamiBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ItemProvider(ComicRepository())),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        title: AppConst.appName,
        theme: NandogamiTheme.light,
        darkTheme: NandogamiTheme.dark,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
