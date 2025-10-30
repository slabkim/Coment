import 'package:cloud_firestore/cloud_firestore.dart';

class UserStatsService {
  final FirebaseFirestore _db;
  UserStatsService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  /// Calculate and return user reading statistics
  Future<Map<String, dynamic>> calculateStats(String userId) async {
    try {
      // Get all reading statuses
      final readingStatusQuery = await _db
          .collection('reading_status')
          .where('userId', isEqualTo: userId)
          .get();

      final totalManga = readingStatusQuery.docs.length;
      
      // Count by status
      final statusCounts = <String, int>{
        'plan': 0,
        'reading': 0,
        'completed': 0,
        'dropped': 0,
        'on_hold': 0,
      };

      for (final doc in readingStatusQuery.docs) {
        final status = doc.data()['status'] as String?;
        if (status != null && statusCounts.containsKey(status)) {
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
      }

      // Get favorite genres from favorited manga
      final favoritesQuery = await _db
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      final totalFavorites = favoritesQuery.docs.length;

      // Get comments/reviews count
      final commentsQuery = await _db
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .get();

      final totalComments = commentsQuery.docs.length;

      // Get followers/following count
      final followersQuery = await _db
          .collection('follows')
          .where('followingId', isEqualTo: userId)
          .get();

      final followingQuery = await _db
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .get();

      final followerCount = followersQuery.docs.length;
      final followingCount = followingQuery.docs.length;

      final stats = {
        'totalManga': totalManga,
        'planToRead': statusCounts['plan'] ?? 0,
        'reading': statusCounts['reading'] ?? 0,
        'completed': statusCounts['completed'] ?? 0,
        'dropped': statusCounts['dropped'] ?? 0,
        'onHold': statusCounts['on_hold'] ?? 0,
        'totalFavorites': totalFavorites,
        'totalComments': totalComments,
        'followerCount': followerCount,
        'followingCount': followingCount,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };

      // Cache stats in user document
      await _db.collection('users').doc(userId).update({
        'stats': stats,
      });

      return stats;
    } catch (e) {
      return {
        'totalManga': 0,
        'planToRead': 0,
        'reading': 0,
        'completed': 0,
        'dropped': 0,
        'onHold': 0,
        'totalFavorites': 0,
        'totalComments': 0,
        'followerCount': 0,
        'followingCount': 0,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Get cached stats from user document
  Future<Map<String, dynamic>> getStats(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) return {};
      
      final stats = userDoc.data()?['stats'] as Map<String, dynamic>?;
      if (stats == null) {
        // Calculate if not cached
        return await calculateStats(userId);
      }
      
      // Check if cache is stale (older than 1 hour)
      final lastUpdated = stats['lastUpdated'] as num?;
      if (lastUpdated != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(lastUpdated.toInt());
        final now = DateTime.now();
        if (now.difference(cacheTime).inHours >= 1) {
          // Recalculate if stale
          return await calculateStats(userId);
        }
      }
      
      return stats;
    } catch (e) {
      return {};
    }
  }

  /// Stream stats (real-time updates)
  Stream<Map<String, dynamic>> watchStats(String userId) {
    return _db.collection('users').doc(userId).snapshots().asyncMap((doc) async {
      if (!doc.exists) return {};
      
      final stats = doc.data()?['stats'] as Map<String, dynamic>?;
      if (stats == null) {
        return await calculateStats(userId);
      }
      
      return stats;
    });
  }
}

