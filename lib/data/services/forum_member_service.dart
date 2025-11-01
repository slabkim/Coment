import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';
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
        return;
      }
    }
    
    // Prevent duplicate concurrent requests
    if (_ongoingOperations.contains(operationKey)) {
      return;
    }
    
    _ongoingOperations.add(operationKey);
    _lastOperationTime[forumKey] = DateTime.now();
    
    try {
      final memberDocId = '${forumId}_$userId';
      
      // Use transaction for atomic check-and-set (reads always from server in transactions)
      await _db.runTransaction((transaction) async {
        // Read forum first to get latest member count
        await transaction.get(_db.collection('forums').doc(forumId));
        
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
          return; // Already joined, do nothing
        }
        
        // If corrupted/incomplete document exists, log and overwrite
        if (memberDoc.exists && !hasRequiredFields) {
          AppLogger.warning('Corrupted member document found for $userId in forum $forumId (fields: ${memberData?.keys}). Will overwrite.');
        }
        
        
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
        
      });
      
      // Don't wait here - cooldown will prevent next operation
    } catch (e) {
      AppLogger.firebaseError('joining forum', e);
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
        return;
      }
    }
    
    // Prevent duplicate concurrent requests
    if (_ongoingOperations.contains(operationKey)) {
      return;
    }
    
    _ongoingOperations.add(operationKey);
    _lastOperationTime[forumKey] = DateTime.now();
    
    try {
      final memberDocId = '${forumId}_$userId';
      
      // Use transaction for atomic check-and-delete (reads always from server in transactions)
      await _db.runTransaction((transaction) async {
        // Read forum first to get latest member count
        await transaction.get(_db.collection('forums').doc(forumId));
        
        // Check if actually a member (transaction reads from server, not cache)
        final memberDoc = await transaction.get(_db.collection('forum_members').doc(memberDocId));
        final memberData = memberDoc.data();
        
        // Document doesn't exist at all
        if (!memberDoc.exists) {
          return; // Not a member, do nothing
        }
        
        // Check if document has VALID required fields
        final hasRequiredFields = memberData != null && 
                                   memberData.containsKey('forumId') && 
                                   memberData.containsKey('userId') && 
                                   memberData.containsKey('role');
        
        // If corrupted document, still allow delete (clean up) but don't decrement count
        if (!hasRequiredFields) {
          AppLogger.warning('Cleaning up corrupted member document for $userId in forum $forumId (fields: ${memberData?.keys})');
          transaction.delete(_db.collection('forum_members').doc(memberDocId));
          
          // Also clean up subscription if exists
          final subscriptionDocId = '${userId}_$forumId';
          transaction.delete(_db.collection('user_forums').doc(subscriptionDocId));
          return; // Don't decrement count as it's corrupted data
        }
        
        
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
        
      });
      
      // Don't wait here - cooldown will prevent next operation
    } catch (e) {
      AppLogger.firebaseError('leaving forum', e);
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
      AppLogger.firebaseError('checking membership', e);
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
      AppLogger.firebaseError('getting members', e);
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
      AppLogger.firebaseError('getting user forums', e);
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
      AppLogger.firebaseError('marking as read', e);
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
      AppLogger.firebaseError('getting unread count', e);
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
      
    } catch (e) {
      AppLogger.firebaseError('toggling mute', e);
      rethrow;
    }
  }
}

