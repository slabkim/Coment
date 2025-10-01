import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'firebase_options.dart';
import 'ui/screens/splash_screen.dart';

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
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      debugShowCheckedModeBanner: false,
      title: AppConst.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryDark,
          surface: AppColors.black,
          onSurface: AppColors.white,
        ),
        scaffoldBackgroundColor: AppColors.black,
      ),
      home: const SplashScreen(),
    );
  }
}
