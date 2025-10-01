import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app.dart';
import 'ui/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // FCM token registration (best-effort)
  try {
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
    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) {
        await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
          'fcmToken': t,
          'fcmUpdatedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }
    });
  } catch (_) {}
  runApp(const SplashScreen());
}
