import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/logger.dart';
import '../models/forum.dart';
import '../models/user_profile.dart';

/// Service for managing user-created forums
/// Service for managing forums (Singleton)
class ForumService {
  // Singleton pattern
  static final ForumService _instance = ForumService._internal();
  factory ForumService() => _instance;
  
  final FirebaseFirestore _db;

  ForumService._internal() : _db = FirebaseFirestore.instance;

  /// Create a new custom forum (user-created)
  /// Creator is automatically added as first member
  Future<String> createForum({
    required String name,
    required String description,
    String? coverImage,
    required String creatorId,
    required String creatorName,
  }) async {
    try {
      final docRef = _db.collection('forums').doc();
      final forumId = docRef.id;
      
      // Get creator info to check if developer
      final userDoc = await _db.collection('users').doc(creatorId).get();
      final userData = userDoc.data();
      final email = userData?['email'] as String?;
      final handle = userData?['handle'] as String?;
      final isCreatorDeveloper = UserProfile.isDeveloperAccount(email, handle);
      
      // Always add THE developer as auto-moderator in ALL forums (absolute admin)
      // Also add creator if they are developer
      final moderatorIds = <String>[];
      if (isCreatorDeveloper) {
        moderatorIds.add(creatorId); // Creator is developer
      } else {
        moderatorIds.add(AppConst.developerUid); // Add THE developer account
      }
      
      final forum = Forum(
        id: forumId,
        name: name,
        description: description,
        coverImage: coverImage,
        memberCount: 1, // Creator is first member
        moderatorIds: moderatorIds,
        createdAt: DateTime.now(),
        createdBy: creatorId,
        createdByName: creatorName,
      );
      
      // Use batch to ensure atomicity
      final batch = _db.batch();
      
      // Create forum with memberCount = 1
      batch.set(docRef, forum.toMap());
      
      // Create member record for creator
      final memberDocId = '${forumId}_$creatorId';
      final role = isCreatorDeveloper ? 'moderator' : 'member';
      batch.set(_db.collection('forum_members').doc(memberDocId), {
        'forumId': forumId,
        'userId': creatorId,
        'role': role,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastReadAt': FieldValue.serverTimestamp(),
        'muted': false,
      });
      
      // Create user forum subscription for creator
      final subscriptionDocId = '${creatorId}_$forumId';
      batch.set(_db.collection('user_forums').doc(subscriptionDocId), {
        'userId': creatorId,
        'forumId': forumId,
        'unreadCount': 0,
        'lastReadAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      
      
      return forumId;
    } catch (e) {
      AppLogger.firebaseError('creating forum', e);
      rethrow;
    }
  }

  /// Get forum by ID
  Future<Forum?> getForum(String forumId) async {
    try {
      final doc = await _db.collection('forums').doc(forumId).get();
      
      if (!doc.exists) return null;
      
      return Forum.fromMap(doc.id, doc.data()!);
    } catch (e) {
      AppLogger.firebaseError('getting forum', e);
      return null;
    }
  }

  /// Watch forum in real-time
  Stream<Forum?> watchForum(String forumId) {
    return _db
        .collection('forums')
        .doc(forumId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return Forum.fromMap(doc.id, doc.data()!);
        });
  }

  /// Get all forums (sorted by member count - popular first)
  Future<List<Forum>> getAllForums({int limit = 50}) async {
    try {
      final querySnapshot = await _db
          .collection('forums')
          .orderBy('memberCount', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Forum.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      AppLogger.firebaseError('getting all forums', e);
      return [];
    }
  }

  /// Watch all forums in real-time (sorted by member count)
  Stream<List<Forum>> watchAllForums({int limit = 50}) {
    return _db
        .collection('forums')
        .orderBy('memberCount', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Forum.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<List<Forum>> searchForums(String query, {int limit = 50}) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return getAllForums(limit: limit);
    }

    try {
      final snapshot = await _db
          .collection('forums')
          .orderBy('memberCount', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      final matches = snapshot.docs
          .map((doc) => Forum.fromMap(doc.id, doc.data()))
          .where((forum) {
            final name = forum.name.toLowerCase();
            final desc = forum.description.toLowerCase();
            final creator = forum.createdByName.toLowerCase();
            return name.contains(normalized) ||
                desc.contains(normalized) ||
                creator.contains(normalized);
          })
          .take(limit)
          .toList();
      return matches;
    } catch (e) {
      AppLogger.firebaseError('searching forums', e);
      return [];
    }
  }

  /// Delete a forum (only creator or developer can delete)
  /// Cascade deletes all related messages, members, and subscriptions
  Future<void> deleteForum(String forumId, String userId) async {
    try {
      // Get forum to check permissions
      final forum = await getForum(forumId);
      if (forum == null) {
        throw Exception('Forum not found');
      }
      
      // Get user info to check if developer
      final userDoc = await _db.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final email = userData?['email'] as String?;
      final handle = userData?['handle'] as String?;
      
      // Check if user can delete
      if (!forum.canDelete(userId, email: email, handle: handle)) {
        throw Exception('You do not have permission to delete this forum');
      }
      
      
      // Delete all related data in batches (max 500 operations per batch)
      await _deleteCollectionInBatches('forum_messages', 'forumId', forumId);
      await _deleteCollectionInBatches('forum_members', 'forumId', forumId);
      await _deleteCollectionInBatches('user_forums', 'forumId', forumId);
      
      // Finally delete the forum document itself
      await _db.collection('forums').doc(forumId).delete();
      
    } catch (e) {
      AppLogger.firebaseError('deleting forum', e);
      rethrow;
    }
  }

  /// Update forum cover image
  Future<void> updateForumCover(String forumId, String coverImageUrl) async {
    try {
      await _db.collection('forums').doc(forumId).update({
        'coverImage': coverImageUrl,
      });
    } catch (e) {
      AppLogger.firebaseError('updating forum cover', e);
      rethrow;
    }
  }

  /// Helper method to delete a collection in batches
  Future<void> _deleteCollectionInBatches(
    String collectionName,
    String fieldName,
    String fieldValue,
  ) async {
    const batchSize = 500;
    
    while (true) {
      final snapshot = await _db
          .collection(collectionName)
          .where(fieldName, isEqualTo: fieldValue)
          .limit(batchSize)
          .get();
      
      if (snapshot.docs.isEmpty) break;
      
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // If less than batch size, we're done
      if (snapshot.docs.length < batchSize) break;
    }
  }

  /// Update forum details (name, description, cover)
  Future<void> updateForum({
    required String forumId,
    String? name,
    String? description,
    String? coverImage,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (coverImage != null) updates['coverImage'] = coverImage;
      
      if (updates.isEmpty) return;
      
      await _db.collection('forums').doc(forumId).update(updates);
      
    } catch (e) {
      AppLogger.firebaseError('updating forum', e);
      rethrow;
    }
  }

  /// Pin a message
  Future<void> pinMessage(String forumId, String messageId) async {
    try {
      await _db.collection('forums').doc(forumId).update({
        'pinnedMessageIds': FieldValue.arrayUnion([messageId]),
      });
      
      // Update message
      await _db.collection('forum_messages').doc(messageId).update({
        'isPinned': true,
      });
      
    } catch (e) {
      AppLogger.firebaseError('pinning message', e);
      rethrow;
    }
  }

  /// Unpin a message
  Future<void> unpinMessage(String forumId, String messageId) async {
    try {
      await _db.collection('forums').doc(forumId).update({
        'pinnedMessageIds': FieldValue.arrayRemove([messageId]),
      });
      
      // Update message
      await _db.collection('forum_messages').doc(messageId).update({
        'isPinned': false,
      });
      
    } catch (e) {
      AppLogger.firebaseError('unpinning message', e);
      rethrow;
    }
  }

  /// Add moderator to forum (developer only)
  Future<void> addModerator(String forumId, String userId) async {
    try {
      await _db.collection('forums').doc(forumId).update({
        'moderatorIds': FieldValue.arrayUnion([userId]),
      });
      
    } catch (e) {
      AppLogger.firebaseError('adding moderator', e);
      rethrow;
    }
  }

  /// Remove moderator from forum (developer only)
  Future<void> removeModerator(String forumId, String userId) async {
    try {
      await _db.collection('forums').doc(forumId).update({
        'moderatorIds': FieldValue.arrayRemove([userId]),
      });
      
    } catch (e) {
      AppLogger.firebaseError('removing moderator', e);
      rethrow;
    }
  }

  /// Check if user is moderator
  Future<bool> isModerator(String forumId, String userId) async {
    try {
      final forum = await getForum(forumId);
      if (forum == null) return false;
      
      return forum.isModerator(userId);
    } catch (e) {
      AppLogger.firebaseError('checking moderator status', e);
      return false;
    }
  }

  /// Check if user can delete forum
  Future<bool> canDeleteForum(String forumId, String userId) async {
    try {
      final forum = await getForum(forumId);
      if (forum == null) return false;
      
      final userDoc = await _db.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final email = userData?['email'] as String?;
      final handle = userData?['handle'] as String?;
      
      return forum.canDelete(userId, email: email, handle: handle);
    } catch (e) {
      AppLogger.firebaseError('checking delete permission', e);
      return false;
    }
  }
}
