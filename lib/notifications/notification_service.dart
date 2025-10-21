import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AppNotificationService {
  AppNotificationService._();
  static final AppNotificationService instance = AppNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String chatChannelId = 'chat_channel';
  static const String chatChannelName = 'Chat Notifications';
  static const String chatChannelDesc = 'Direct message notifications';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: iOS);
    await _plugin.initialize(initSettings);

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          chatChannelId,
          chatChannelName,
          description: chatChannelDesc,
          importance: Importance.max,
          playSound: true,
          showBadge: true,
        ),
      );

      // Android 13+ requires runtime notification permission.
      // Ask permission if not already granted.
      try {
        final enabled = await androidPlugin?.areNotificationsEnabled() ?? true;
        if (!enabled) {
          await androidPlugin?.requestNotificationsPermission();
        }
      } catch (_) {
        // Silently ignore if method not available on older plugin versions/SDKs.
      }
    }

    _initialized = true;
  }

  Future<void> showForegroundRemote(RemoteMessage message) async {
    if (!_initialized) {
      await initialize();
    }

    final title = message.notification?.title ?? 'New message';
    final body = message.notification?.body ?? '';

    const androidDetails = AndroidNotificationDetails(
      chatChannelId,
      chatChannelName,
      channelDescription: chatChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    const iOSDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _plugin.show(
      0,
      title,
      body,
      details,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }
}
