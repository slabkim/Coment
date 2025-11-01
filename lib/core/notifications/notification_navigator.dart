import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/forum.dart';
import '../../data/models/nandogami_item.dart';
import '../../data/repositories/comic_repository.dart';
import '../../state/item_provider.dart';
import '../../ui/screens/chat_screen.dart';
import '../../ui/screens/detail_screen.dart';
import '../../ui/screens/forum_chat_screen.dart';
import '../../ui/screens/main_screen.dart';
import '../logger.dart';

/// Handles navigation based on notification types
class NotificationNavigator {
  final GlobalKey<NavigatorState> navigatorKey;

  NotificationNavigator(this.navigatorKey);

  /// Handle navigation based on notification message
  Future<void> handleNavigation(RemoteMessage message, {required bool initial}) async {
    final type = message.data['type'];
    final navigator = navigatorKey.currentState;
    
    if (navigator == null) {
      AppLogger.warning('Navigator not available, navigation deferred');
      return;
    }

    // When app is launched from notification (closed state), just go to Home
    if (initial) {
      AppLogger.info('App launched from notification ($type), navigating to Home');
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
        await _handleDmNotification(message, navigator);
        break;

      case 'mention':
        await _handleMentionNotification(message, navigator);
        break;

      case 'like':
        await _handleLikeNotification(message, navigator);
        break;

      case 'follow':
        _handleFollowNotification(navigator);
        break;

      default:
        AppLogger.warning('Unknown notification type: $type');
    }
  }

  /// Handle DM (Direct Message) notification
  Future<void> _handleDmNotification(
    RemoteMessage message,
    NavigatorState navigator,
  ) async {
    final senderId = message.data['senderId'];
    if (senderId == null || senderId.toString().isEmpty) {
      AppLogger.warning('DM notification missing senderId');
      return;
    }
    
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
  }

  /// Handle mention notification
  Future<void> _handleMentionNotification(
    RemoteMessage message,
    NavigatorState navigator,
  ) async {
    final forumId = message.data['forumId'];
    if (forumId == null || forumId.toString().isEmpty) {
      AppLogger.warning('Mention notification missing forumId');
      return;
    }
    
    try {
      final forumDoc = await FirebaseFirestore.instance
          .collection('forums')
          .doc(forumId)
          .get();
      
      if (!forumDoc.exists) {
        AppLogger.warning('Forum not found: $forumId');
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
    } catch (e, stackTrace) {
      AppLogger.error('Error navigating to forum', e, stackTrace);
      if (navigator.mounted) {
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(content: Text('Error opening forum: $e')),
        );
      }
    }
  }

  /// Handle like notification
  Future<void> _handleLikeNotification(
    RemoteMessage message,
    NavigatorState navigator,
  ) async {
    final itemId = message.data['itemId'];
    if (itemId == null || itemId.toString().isEmpty) {
      AppLogger.warning('Like notification missing itemId');
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
        // Try to fetch from repository
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
        AppLogger.warning('Item not found: $itemId');
        return;
      }
      
      navigator.push(
        MaterialPageRoute(
          builder: (_) => DetailScreen(item: item!),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error navigating to detail', e, stackTrace);
    }
  }

  /// Handle follow notification
  void _handleFollowNotification(NavigatorState navigator) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => const MainScreen(initialIndex: 3), // Profile tab
      ),
    );
  }
}

