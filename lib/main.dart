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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'data/repositories/comic_repository.dart';
import 'firebase_options.dart';
import 'state/item_provider.dart';
import 'state/theme_provider.dart';
import 'ui/screens/chat_list_screen.dart';
import 'ui/screens/splash_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: system shows notification from payload; keep handler to enable background delivery on Android
}

Future<void> _configureMessaging() async {
  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission();
  final token = await _getFcmToken(fcm);
  final user = FirebaseAuth.instance.currentUser;
  if (token != null && user != null) {
    await _persistUserFcmToken(user.uid, token);
  }
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

  // Foreground message: show lightweight snackbar banner
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    final title = message.notification?.title ?? 'New notification';
    final body = message.notification?.body ?? '';

    // Use post-frame callback to avoid calling showSnackBar during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final text = [title, body].where((e) => e.isNotEmpty).join(' - ');
      if (text.isEmpty) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(text),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  });

  // Notification opened
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    final type = message.data['type'];
    if (type == 'dm') {
      Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const ChatListScreen()));
    }
  });
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  runApp(const NandogamiBootstrap());
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
