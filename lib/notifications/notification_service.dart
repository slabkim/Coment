import 'dart:io' show Platform;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotificationService {
  AppNotificationService._();
  static final AppNotificationService instance = AppNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String chatChannelId = 'chat_channel';
  static const String chatChannelName = 'Chat Notifications';
  static const String chatChannelDesc = 'Direct message notifications';
  static const String _messageCacheKey = 'notification_message_cache_v2'; // v2 for new format with timestamp

  bool _initialized = false;
  
  // Cache for inbox-style notifications (max 5 messages per chat)
  // Format: {chatId: [{text: "message", timestamp: milliseconds}, ...]}
  final Map<String, List<Map<String, dynamic>>> _messageCache = {};
  
  // Callback for notification tap
  void Function(RemoteMessage)? onNotificationTap;

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: iOS);
    
    // Initialize with tap callback
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response);
      },
    );

    // Check if app was launched from a notification tap (terminated state)
    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      
      if (launchDetails?.didNotificationLaunchApp == true) {
        final response = launchDetails!.notificationResponse;
        if (response != null) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            _handleNotificationTap(response);
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking launch details: $e');
    }

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

    // Load cache first to ensure we have previous messages
    await _loadMessageCache();

    // Get title and body from data payload (Cloud Function sends data-only)
    final title = message.data['title'] ?? message.notification?.title ?? 'New message';
    final body = message.data['body'] ?? message.notification?.body ?? '';
    final type = message.data['type'] ?? '';
    final chatId = message.data['chatId'] ?? 'default';

    // For DM notifications, use inbox style with message caching
    if (type == 'dm') {
      final senderName = message.data['senderName'] ?? 'Someone';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Add message to cache with timestamp (max 5 messages)
      _messageCache.putIfAbsent(chatId, () => []);
      _messageCache[chatId]!.add({
        'text': body,
        'timestamp': timestamp,
        'sender': senderName,
      });
      
      // Keep only last 5 messages
      if (_messageCache[chatId]!.length > 5) {
        _messageCache[chatId]!.removeAt(0);
      }

      // Save cache for persistence
      await _saveMessageCache();

      final messages = _messageCache[chatId]!;

      // Create notification title and body based on message count
      String notificationTitle;
      String notificationBody;
      
      if (messages.length == 1) {
        notificationTitle = 'Pesan baru dari $senderName';
        notificationBody = messages[0]['text'] as String? ?? '';
      } else {
        notificationTitle = '$senderName';
        // Build body with all messages (max 5)
        final messageTexts = messages.map((msg) => msg['text'] as String? ?? '').toList();
        notificationBody = messageTexts.join('\n');
      }

      // Create BigText style notification for multiple messages
      final styleInfo = messages.length > 1 
          ? BigTextStyleInformation(
              notificationBody,
              htmlFormatBigText: false,
              contentTitle: notificationTitle,
              htmlFormatContentTitle: false,
              summaryText: '${messages.length} messages',
              htmlFormatSummaryText: false,
            )
          : null;

      // Create inbox-style notification
      final androidDetails = AndroidNotificationDetails(
        chatChannelId,
        chatChannelName,
        channelDescription: chatChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        ticker: messages.last['text'] as String? ?? '', // Last message in status bar
        styleInformation: styleInfo,
        tag: chatId, // Group by chatId
        groupKey: chatId, // Group notifications
        setAsGroupSummary: false,
        autoCancel: true, // Dismiss when tapped
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.private,
        onlyAlertOnce: false, // Alert every time
      );
      
      const iOSDetails = DarwinNotificationDetails();
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      // Use chatId hash as notification ID to replace/update same notification
      final notificationId = chatId.hashCode;

      await _plugin.show(
        notificationId,
        notificationTitle,
        notificationBody,
        details,
        payload: jsonEncode(message.data),
      );
    } else {
      // For non-DM notifications (like, follow), use simple notification
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
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        details,
        payload: jsonEncode(message.data),
      );
    }
  }
  
  /// Handle notification tap (both foreground and terminated state)
  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = jsonDecode(response.payload!);
        final message = RemoteMessage(data: Map<String, dynamic>.from(data));
        onNotificationTap?.call(message);
      } catch (e) {
        debugPrint('Error handling notification tap: $e');
      }
    }
  }

  /// Load message cache from SharedPreferences
  Future<void> _loadMessageCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_messageCacheKey);
      if (cacheJson != null) {
        final decoded = jsonDecode(cacheJson) as Map<String, dynamic>;
        _messageCache.clear();
        decoded.forEach((key, value) {
          if (value is List) {
            // Handle both old format (List<String>) and new format (List<Map>)
            final messages = value.map((item) {
              if (item is Map) {
                // New format with timestamp
                return Map<String, dynamic>.from(item);
              } else if (item is String) {
                // Old format - migrate to new format
                return {
                  'text': item,
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                  'sender': 'Someone',
                };
              }
              return {
                'text': '',
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'sender': 'Someone',
              };
            }).toList();
            _messageCache[key] = messages;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading message cache: $e');
    }
  }
  
  /// Save message cache to SharedPreferences
  Future<void> _saveMessageCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = jsonEncode(_messageCache);
      await prefs.setString(_messageCacheKey, cacheJson);
    } catch (e) {
      debugPrint('Error saving message cache: $e');
    }
  }
  
  /// Clear message cache for a specific chat
  Future<void> clearChatCache(String chatId) async {
    _messageCache.remove(chatId);
    await _saveMessageCache();
  }
  
  /// Clear all message caches
  Future<void> clearAllCaches() async {
    _messageCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messageCacheKey);
  }
}
