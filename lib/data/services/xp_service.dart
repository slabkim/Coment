import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';
import '../models/user_class.dart';
import '../models/user_profile.dart';

/// Service for managing user XP and class progression
class XPService {
  final FirebaseFirestore _db;

  XPService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  /// Award XP to a user
  /// 
  /// [userId] - The user receiving XP
  /// [amount] - Amount of XP to award (can be negative for penalties)
  /// [reason] - Reason for XP award (for logging/analytics)
  Future<void> awardXP(String userId, int amount, String reason) async {
    try {
      final userRef = _db.collection('users').doc(userId);
      
      await _db.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          return;
        }
        
        final currentXP = (userDoc.data()?['xp'] as num?)?.toInt() ?? 0;
        final newXP = (currentXP + amount).clamp(0, 999999); // Max XP cap
        
        final oldClass = UserClass.fromXP(currentXP);
        final newClass = UserClass.fromXP(newXP);
        
        transaction.update(userRef, {
          'xp': newXP,
          'lastXPUpdate': FieldValue.serverTimestamp(),
        });
        
        // Log class upgrade
        if (newClass.name != oldClass.name) {
          AppLogger.debug('User $userId ranked up: ${oldClass.name} → ${newClass.name}!');
          
          // Optionally send notification (implement later if needed)
          // _sendClassUpgradeNotification(userId, newClass);
        }
        
      });
    } catch (e, stackTrace) {
      AppLogger.firebaseError('awarding XP', e, stackTrace);
    }
  }

  /// Award XP for completing a comic
  Future<void> awardCompleteComic(String userId, String comicId) async {
    await awardXP(userId, XPReward.completeComic, 'Completed comic $comicId');
  }

  /// Award XP for adding a favorite
  Future<void> awardAddFavorite(String userId, String comicId) async {
    await awardXP(userId, XPReward.addFavorite, 'Added favorite $comicId');
  }

  /// Penalize XP for removing a favorite
  Future<void> penalizeRemoveFavorite(String userId, String comicId) async {
    await awardXP(userId, XPReward.removeFavorite, 'Removed favorite $comicId');
  }

  /// Award XP for writing a comment
  Future<void> awardWriteComment(String userId, String comicId) async {
    await awardXP(userId, XPReward.writeComment, 'Wrote comment on $comicId');
  }

  /// Award XP for replying to a comment
  Future<void> awardReplyComment(String userId, String parentCommentId) async {
    await awardXP(userId, XPReward.replyComment, 'Replied to comment $parentCommentId');
  }

  /// Award XP for gaining a follower
  Future<void> awardGainFollower(String userId, String followerId) async {
    await awardXP(userId, XPReward.getFollower, 'Gained follower $followerId');
  }

  /// Penalize XP for losing a follower
  Future<void> penalizeLoseFollower(String userId, String followerId) async {
    await awardXP(userId, XPReward.loseFollower, 'Lost follower $followerId');
  }

  /// Award XP for updating reading status
  Future<void> awardUpdateReadingStatus(String userId, String comicId) async {
    await awardXP(userId, XPReward.updateReadingStatus, 'Updated reading status for $comicId');
  }

  /// Award XP for sharing a comic
  Future<void> awardShareComic(String userId, String comicId) async {
    await awardXP(userId, XPReward.shareComic, 'Shared comic $comicId');
  }

  /// Award daily login bonus (call once per day per user)
  Future<void> awardDailyLogin(String userId) async {
    try {
      final userRef = _db.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) return;
      
      final lastLogin = userDoc.data()?['lastDailyLogin'] as Timestamp?;
      final now = DateTime.now();
      
      // Check if already claimed today
      if (lastLogin != null) {
        final lastLoginDate = lastLogin.toDate();
        if (now.difference(lastLoginDate).inHours < 24) {
          return;
        }
      }
      
      // Award daily bonus
      await awardXP(userId, XPReward.dailyLogin, 'Daily login bonus');
      
      // Update last daily login
      await userRef.update({
        'lastDailyLogin': FieldValue.serverTimestamp(),
      });
      
    } catch (e, stackTrace) {
      AppLogger.firebaseError('awarding daily login', e, stackTrace);
    }
  }

  /// Get user's current XP and class
  Future<Map<String, dynamic>> getUserXPInfo(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return {
          'xp': 0,
          'class': UserClass.allClasses.first,
        };
      }
      
      final xp = (userDoc.data()?['xp'] as num?)?.toInt() ?? 0;
      final userClass = UserClass.fromXP(xp);
      
      return {
        'xp': xp,
        'class': userClass,
        'nextClassXP': userClass.getXPToNextClass(xp),
        'progress': userClass.getProgressPercentage(xp),
      };
    } catch (e, stackTrace) {
      AppLogger.firebaseError('getting user XP info', e, stackTrace);
      return {
        'xp': 0,
        'class': UserClass.allClasses.first,
      };
    }
  }

  /// Watch user's XP in real-time
  Stream<int> watchUserXP(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => (doc.data()?['xp'] as num?)?.toInt() ?? 0);
  }

  /// Get leaderboard (top users by XP)
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .orderBy('xp', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final xp = (data['xp'] as num?)?.toInt() ?? 0;
        final userClass = UserClass.fromXP(xp);
        
        return {
          'userId': doc.id,
          'username': data['username'],
          'photoUrl': data['photoUrl'],
          'xp': xp,
          'class': userClass,
        };
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.firebaseError('fetching leaderboard', e, stackTrace);
      return [];
    }
  }

  /// Award MAX XP to developer accounts (Developer Privilege! 👑)
  /// Automatically grants SSS Class to developers
  Future<void> awardDeveloperMaxXP(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) return;
      
      final userData = userDoc.data();
      if (userData == null) return;
      
      // Check if user is a developer
      final email = userData['email'] as String?;
      final handle = userData['handle'] as String?;
      final isDev = UserProfile.isDeveloperAccount(email, handle);
      
      if (!isDev) return; // Only developers get max XP!
      
      // Award MAX XP for SSS Class (Developer Privilege!)
      const maxXP = 999999; // Max XP cap
      
      await _db.collection('users').doc(userId).update({
        'xp': maxXP,
        'lastXPUpdate': FieldValue.serverTimestamp(),
      });
      
      AppLogger.debug('Developer Privilege: MAX XP awarded to $userId! SSS Class unlocked!');
    } catch (e, stackTrace) {
      AppLogger.firebaseError('awarding developer max XP', e, stackTrace);
      // Log warning instead of silently failing
      // This is a bonus feature, but we should track failures
      AppLogger.warning('Failed to award developer max XP to $userId', e, stackTrace);
    }
  }
}

