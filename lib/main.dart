import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/logger.dart';
import 'core/theme.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/firebase/firebase_auth_language_config.dart';
import 'core/firebase/app_check_service.dart';
import 'core/firebase/auth_token_manager.dart';
import 'core/firebase/fcm_service.dart';
import 'core/notifications/notification_navigator.dart';
import 'core/notifications/in_app_notification_handler.dart';
import 'core/ads/ad_service.dart';
import 'data/repositories/comic_repository.dart';
import 'notifications/notification_service.dart';
import 'state/item_provider.dart';
import 'state/theme_provider.dart';
import 'ui/screens/splash_screen.dart';

/// Global navigator key for app-wide navigation
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Native notification tap channel
const MethodChannel _notificationChannel = MethodChannel(
  'com.example.nandogami/notification',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (error, stackTrace) {
    final isMissingEnv = error.toString().contains('FileNotFoundError');
    if (isMissingEnv) {
      AppLogger.warning(
        '`.env` file not bundled; falling back to process environment.',
        error,
        stackTrace,
      );
    } else {
      rethrow;
    }
  }

  // Initialize Firebase
  await FirebaseInitializer.initialize();

  // Configure Firebase Auth language
  await FirebaseAuthLanguageConfig.configure();

  // Activate App Check
  final appCheckDebugOverride =
      (dotenv.env['FIREBASE_APPCHECK_DEBUG'] ?? '').toLowerCase() == 'true';
  final webRecaptchaKey = dotenv.env['FIREBASE_RECAPTCHA_SITE_KEY'];
  await AppCheckService.activate(
    forceDebug: appCheckDebugOverride,
    webRecaptchaKey: webRecaptchaKey,
  );

  // Ensure fresh user session
  await AuthTokenManager.ensureFreshUserSession();

  // Setup error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Log app open
  try {
    await FirebaseAnalytics.instance.logAppOpen();
  } catch (e, stackTrace) {
    AppLogger.warning('Failed to log app open', e, stackTrace);
  }

  // Setup notification services
  await _setupNotificationServices();

  // Initialize Google Mobile Ads
  await AdService.initialize();

  // Run app
  runApp(const NandogamiBootstrap());

  // Handle any pending initial notification tap after app mount
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final msg = FCMService.pendingInitialMessage;
    if (msg != null) {
      FCMService.clearPendingMessage();
      final navigator = NotificationNavigator(appNavigatorKey);
      navigator.handleNavigation(msg, initial: true);
    }
  });
}

/// Setup notification services (FCM, local notifications, native channel)
Future<void> _setupNotificationServices() async {
  // Initialize notification navigator and handler
  final notificationNavigator = NotificationNavigator(appNavigatorKey);
  final inAppNotificationHandler = InAppNotificationHandler(
    navigatorKey: appNavigatorKey,
    onNotificationTap: (message) {
      notificationNavigator.handleNavigation(message, initial: false);
    },
  );

  // Configure FCM
  try {
    await FCMService.configure(
      onForegroundMessage: (message) {
        inAppNotificationHandler.showNotification(message);
      },
      onMessageOpened: (message) {
        notificationNavigator.handleNavigation(message, initial: false);
      },
    );
  } catch (error, stackTrace) {
    await AuthTokenManager.handleAuthTokenFailure(
      error,
      stackTrace: stackTrace,
    );
  }

  // Initialize local notifications
  try {
    AppNotificationService.instance.onNotificationTap = (message) {
      notificationNavigator.handleNavigation(message, initial: false);
    };
    await AppNotificationService.instance.initialize();
  } catch (e, stackTrace) {
    AppLogger.error('Notification init error', e, stackTrace);
  }

  // Setup native notification tap listener
  _notificationChannel.setMethodCallHandler((call) async {
    if (call.method == 'onNotificationTap') {
      try {
        final Map<dynamic, dynamic> data =
            call.arguments as Map<dynamic, dynamic>;
        final Map<String, dynamic> messageData = data.map(
          (key, value) => MapEntry(key.toString(), value),
        );

        final message = RemoteMessage(data: messageData);

        Future.delayed(const Duration(milliseconds: 500), () {
          notificationNavigator.handleNavigation(message, initial: false);
        });
      } catch (e, stackTrace) {
        AppLogger.error('Error handling native tap', e, stackTrace);
      }
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
