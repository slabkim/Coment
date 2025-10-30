import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/forum_member.dart';
import '../models/user_profile.dart';

/// Service for managing forum members (Singleton)
class ForumMemberService {
  // Singleton pattern
  static final ForumMemberService _instance = ForumMemberService._internal();
  factory ForumMemberService() => _instance;
  
  final FirebaseFirestore _db;
  
  // Track ongoing operations to prevent race conditions (shared across all instances)
  final Set<String> _ongoingOperations = {};
  
  // Track last operation time per forum to enforce cooldown
  final Map<String, DateTime> _lastOperationTime = {};
  static const _cooldownDuration = Duration(seconds: 1);

  ForumMemberService._internal() : _db = FirebaseFirestore.instance;

  /// Join a forum (with race condition protection)
  Future<void> joinForum(String forumId, String userId) async {
    final operationKey = 'join_${forumId}_$userId';
    final forumKey = forumId;
    
    // Check cooldown period
    final lastOperation = _lastOperationTime[forumKey];
    if (lastOperation != null) {
      final timeSinceLastOp = DateTime.now().difference(lastOperation);
      if (timeSinceLastOp < _cooldownDuration) {
        final remainingMs = (_cooldownDuration - timeSinceLastOp).inMilliseconds;
        debugPrint('⏳ Cooldown active for forum $forumId (${remainingMs}ms remaining)');
        return;
      }
    }
    
    // Prevent duplicate concurrent requests
    if (_ongoingOperations.contains(operationKey)) {
      debugPrint('Join operation already in progress for $operationKey');
      return;
    }
    
    _ongoingOperations.add(operationKey);
    _lastOperationTime[forumKey] = DateTime.now();
    
    try {
      final memberDocId = '${forumId}_$userId';
      
      // Use transaction for atomic check-and-set (reads always from server in transactions)
      await _db.runTransaction((transaction) async {
        // Read forum first to get latest member count
        final forumDoc = await transaction.get(_db.collection('forums').doc(forumId));
        final currentMemberCount = forumDoc.data()?['memberCount'] ?? 0;
        
        // Check if already a member (transaction reads from server, not cache)
        final memberDoc = await transaction.get(_db.collection('forum_members').doc(memberDocId));
        final memberData = memberDoc.data();
        
        // Check if document has VALID required fields (not just incomplete/corrupted data)
        final hasRequiredFields = memberData != null && 
                                   memberData.containsKey('forumId') && 
                                   memberData.containsKey('userId') && 
                                   memberData.containsKey('role');
        final memberExists = memberDoc.exists && hasRequiredFields;
        
        // If document truly exists with valid data, skip
        if (memberExists) {
          debugPrint('❌ User $userId already member of forum $forumId (memberCount: $currentMemberCount)');
          return; // Already joined, do nothing
        }
        
        // If corrupted/incomplete document exists, log and overwrite
        if (memberDoc.exists && !hasRequiredFields) {
          debugPrint('⚠️ Corrupted member document found for $userId in forum $forumId (fields: ${memberData?.keys}). Will overwrite.');
        }
        
        debugPrint('➕ Adding user $userId to forum $forumId (current memberCount: $currentMemberCount)');
        
        // Check if developer for auto-moderator
        final userDoc = await transaction.get(_db.collection('users').doc(userId));
        final userData = userDoc.data();
        final email = userData?['email'] as String?;
        final handle = userData?['handle'] as String?;
        final isDeveloper = UserProfile.isDeveloperAccount(email, handle);
        
        final role = isDeveloper ? ForumMemberRole.moderator : ForumMemberRole.member;
        
        final member = ForumMember(
          forumId: forumId,
          userId: userId,
          role: role,
          joinedAt: DateTime.now(),
        );
        
        // Add member
        transaction.set(_db.collection('forum_members').doc(memberDocId), member.toMap());
        
        // ONLY increment memberCount if we actually added a new member
        final forumRef = _db.collection('forums').doc(forumId);
        transaction.update(forumRef, {
          'memberCount': FieldValue.increment(1),
          if (isDeveloper) 'moderatorIds': FieldValue.arrayUnion([userId]),
        });
        
        // Create user forum subscription
        final subscriptionDocId = '${userId}_$forumId';
        final subscription = UserForumSubscription(
          userId: userId,
          forumId: forumId,
        );
        transaction.set(_db.collection('user_forums').doc(subscriptionDocId), subscription.toMap());
        
        debugPrint('✅ User $userId joined forum $forumId as ${role.name} (memberCount: $currentMemberCount → ${currentMemberCount + 1})');
      });
      
      // Don't wait here - cooldown will prevent next operation
    } catch (e) {
      debugPrint('Error joining forum: $e');
      rethrow;
    } finally {
      _ongoingOperations.remove(operationKey);
    }
  }

  /// Leave a forum (with race condition protection)
  Future<void> leaveForum(String forumId, String userId) async {
    final operationKey = 'leave_${forumId}_$userId';
    final forumKey = forumId;
    
    // Check cooldown period
    final lastOperation = _lastOperationTime[forumKey];
    if (lastOperation != null) {
      final timeSinceLastOp = DateTime.now().difference(lastOperation);
      if (timeSinceLastOp < _cooldownDuration) {
        final remainingMs = (_cooldownDuration - timeSinceLastOp).inMilliseconds;
        debugPrint('⏳ Cooldown active for forum $forumId (${remainingMs}ms remaining)');
        return;
      }
    }
    
    // Prevent duplicate concurrent requests
    if (_ongoingOperations.contains(operationKey)) {
      debugPrint('Leave operation already in progress for $operationKey');
      return;
    }
    
    _ongoingOperations.add(operationKey);
    _lastOperationTime[forumKey] = DateTime.now();
    
    try {
      final memberDocId = '${forumId}_$userId';
      
      // Use transaction for atomic check-and-delete (reads always from server in transactions)
      await _db.runTransaction((transaction) async {
        // Read forum first to get latest member count
        final forumDoc = await transaction.get(_db.collection('forums').doc(forumId));
        final currentMemberCount = forumDoc.data()?['memberCount'] ?? 0;
        
        // Check if actually a member (transaction reads from server, not cache)
        final memberDoc = await transaction.get(_db.collection('forum_members').doc(memberDocId));
        final memberData = memberDoc.data();
        
        // Document doesn't exist at all
        if (!memberDoc.exists) {
          debugPrint('❌ User $userId not a member of forum $forumId (memberCount: $currentMemberCount)');
          return; // Not a member, do nothing
        }
        
        // Check if document has VALID required fields
        final hasRequiredFields = memberData != null && 
                                   memberData.containsKey('forumId') && 
                                   memberData.containsKey('userId') && 
                                   memberData.containsKey('role');
        
        // If corrupted document, still allow delete (clean up) but don't decrement count
        if (!hasRequiredFields) {
          debugPrint('⚠️ Cleaning up corrupted member document for $userId in forum $forumId (fields: ${memberData?.keys})');
          transaction.delete(_db.collection('forum_members').doc(memberDocId));
          
          // Also clean up subscription if exists
          final subscriptionDocId = '${userId}_$forumId';
          transaction.delete(_db.collection('user_forums').doc(subscriptionDocId));
          return; // Don't decrement count as it's corrupted data
        }
        
        debugPrint('➖ Removing user $userId from forum $forumId (current memberCount: $currentMemberCount)');
        
        // Remove member
        transaction.delete(_db.collection('forum_members').doc(memberDocId));
        
        // ONLY decrement memberCount if we actually removed a member
        final forumRef = _db.collection('forums').doc(forumId);
        transaction.update(forumRef, {
          'memberCount': FieldValue.increment(-1),
          'moderatorIds': FieldValue.arrayRemove([userId]),
        });
        
        // Delete user forum subscription
        final subscriptionDocId = '${userId}_$forumId';
        transaction.delete(_db.collection('user_forums').doc(subscriptionDocId));
        
        debugPrint('✅ User $userId left forum $forumId (memberCount: $currentMemberCount → ${currentMemberCount - 1})');
      });
      
      // Don't wait here - cooldown will prevent next operation
    } catch (e) {
      debugPrint('Error leaving forum: $e');
      rethrow;
    } finally {
      _ongoingOperations.remove(operationKey);
    }
  }

  /// Check if user is member of forum
  Future<bool> isMember(String forumId, String userId) async {
    try {
      final memberDocId = '${forumId}_$userId';
      final doc = await _db.collection('forum_members').doc(memberDocId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking membership: $e');
      return false;
    }
  }

  /// Watch membership status
  Stream<bool> watchMembership(String forumId, String userId) {
    final memberDocId = '${forumId}_$userId';
    return _db
        .collection('forum_members')
        .doc(memberDocId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get forum members
  Future<List<ForumMember>> getMembers(String forumId, {int limit = 50}) async {
    try {
      final querySnapshot = await _db
          .collection('forum_members')
          .where('forumId', isEqualTo: forumId)
          .orderBy('joinedAt', descending: false)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ForumMember.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting members: $e');
      return [];
    }
  }

  /// Get user's forums
  Future<List<String>> getUserForums(String userId) async {
    try {
      final querySnapshot = await _db
          .collection('forum_members')
          .where('userId', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return data['forumId'] as String;
          })
          .toList();
    } catch (e) {
      debugPrint('Error getting user forums: $e');
      return [];
    }
  }

  /// Watch user's forums in real-time
  Stream<List<String>> watchUserForums(String userId) {
    return _db
        .collection('forum_members')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return data['forumId'] as String;
              })
              .toList();
        });
  }

  /// Update last read timestamp
  Future<void> markAsRead(String forumId, String userId) async {
    try {
      final memberDocId = '${forumId}_$userId';
      
      // Check if member exists first (don't create partial documents!)
      final memberDoc = await _db.collection('forum_members').doc(memberDocId).get();
      
      // Only update if member document exists with valid data
      if (memberDoc.exists && memberDoc.data() != null) {
        final data = memberDoc.data()!;
        // Check if it's a valid member document (has required fields)
        if (data.containsKey('forumId') && data.containsKey('userId') && data.containsKey('role')) {
          await _db.collection('forum_members').doc(memberDocId).update({
            'lastReadAt': FieldValue.serverTimestamp(),
          });
        }
        
        // Also reset unread count in subscription (only if member exists)
        final subscriptionDocId = '${userId}_$forumId';
        await _db.collection('user_forums').doc(subscriptionDocId).set({
          'userId': userId,
          'forumId': forumId,
          'unreadCount': 0,
          'lastReadAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  /// Get unread count
  Future<int> getUnreadCount(String forumId, String userId) async {
    try {
      final subscriptionDocId = '${userId}_$forumId';
      final doc = await _db.collection('user_forums').doc(subscriptionDocId).get();
      
      if (!doc.exists) return 0;
      
      final data = doc.data();
      return (data?['unreadCount'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mute/unmute forum notifications
  Future<void> toggleMute(String forumId, String userId, bool mute) async {
    try {
      final memberDocId = '${forumId}_$userId';
      await _db.collection('forum_members').doc(memberDocId).update({
        'muted': mute,
      });
      
      debugPrint('Forum $forumId ${mute ? "muted" : "unmuted"} for user $userId');
    } catch (e) {
      debugPrint('Error toggling mute: $e');
      rethrow;
    }
  }
}

