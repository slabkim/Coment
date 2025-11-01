import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../logger.dart';

/// Handles showing in-app notification SnackBars
class InAppNotificationHandler {
  final GlobalKey<NavigatorState> navigatorKey;
  final Function(RemoteMessage) onNotificationTap;

  InAppNotificationHandler({
    required this.navigatorKey,
    required this.onNotificationTap,
  });

  /// Show in-app notification SnackBar
  void showNotification(RemoteMessage message) {
    // Add small delay to ensure Scaffold is fully mounted
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        final context = navigatorKey.currentContext;
        if (context == null || !context.mounted) {
          AppLogger.warning('In-app notification: context is null or not mounted');
          return;
        }

        final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
        final notification = message.notification;
        
        if (scaffoldMessenger == null || notification == null) {
          AppLogger.debug('Cannot show notification: scaffoldMessenger or notification is null');
          return;
        }

        final title = notification.title ?? 'New Notification';
        final body = notification.body ?? '';
        final type = message.data['type'];

        // Choose emoji based on notification type
        final emoji = _getNotificationEmoji(type);

        // Capture theme values after confirming context is still valid
        if (!context.mounted) return;
        final primaryContainer = Theme.of(context).colorScheme.primaryContainer;
        final primary = Theme.of(context).colorScheme.primary;

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
            backgroundColor: primaryContainer,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: primary,
              onPressed: () {
                onNotificationTap(message);
              },
            ),
          ),
        );
      } catch (e, stackTrace) {
        AppLogger.error('Error showing in-app notification', e, stackTrace);
      }
    });
  }

  /// Get emoji based on notification type
  String _getNotificationEmoji(String? type) {
    switch (type) {
      case 'dm':
        return '💬';
      case 'like':
        return '❤️';
      case 'follow':
        return '👤';
      case 'mention':
        return '📣';
      default:
        return '🔔';
    }
  }
}

