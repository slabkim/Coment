import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'core/constants.dart';
import 'firebase_options.dart';
import 'ui/screens/splash_screen.dart';
import 'core/theme.dart';
import 'ui/screens/chat_list_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: system shows notification from payload; keep handler to enable background delivery on Android
}

Future<void> _configureMessaging() async {
  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission();
  final token = await fcm.getToken();
  final user = FirebaseAuth.instance.currentUser;
  if (token != null && user != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'fcmUpdatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final refreshedUser = FirebaseAuth.instance.currentUser;
    if (refreshedUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(refreshedUser.uid)
          .set({
            'fcmToken': newToken,
            'fcmUpdatedAt': DateTime.now().millisecondsSinceEpoch,
          }, SetOptions(merge: true));
    }
  });

  // Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Foreground message: show lightweight snackbar banner
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    final title = message.notification?.title ?? 'New notification';
    final body = message.notification?.body ?? '';
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text([title, body].where((e) => e.isNotEmpty).join(' — ')),
        duration: const Duration(seconds: 2),
      ),
    );
  });

  // Notification opened
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    final type = message.data['type'];
    if (type == 'dm') {
      Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const ChatListScreen()),
      );
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Crashlytics
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // Analytics (optional event)
  try {
    await FirebaseAnalytics.instance.logAppOpen();
  } catch (_) {}
  try {
    await _configureMessaging();
  } catch (_) {
    // best effort; ignore FCM failures during bootstrap
  }
  runApp(const NandogamiBootstrap());
}

class NandogamiBootstrap extends StatelessWidget {
  const NandogamiBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: AppConst.appName,
      theme: NandogamiTheme.light,
      darkTheme: NandogamiTheme.dark,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
