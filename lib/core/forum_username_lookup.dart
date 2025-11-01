import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/logger.dart';

/// Helper class untuk mencari user ID berdasarkan username dengan caching
class ForumUsernameLookup {
  // Shared cache untuk username -> userId mapping
  static final Map<String, String?> _usernameCache = {};
  static final Set<String> _fetchingUsernames = {};

  /// Find user ID by username and validate they're a forum member
  static Future<String?> getUserIdByUsername(String username, String forumId) async {
    // Create cache key with forumId to ensure forum-specific validation
    final cacheKey = '${forumId}_$username';
    
    // Check cache first
    if (_usernameCache.containsKey(cacheKey)) {
      return _usernameCache[cacheKey];
    }
    
    // If already fetching, wait a bit and check cache again
    if (_fetchingUsernames.contains(cacheKey)) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _usernameCache[cacheKey];
    }
    
    // Mark as fetching
    _fetchingUsernames.add(cacheKey);
    
    try {
      // Try querying by 'handle' field first (most common)
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('handle', isEqualTo: username)
          .limit(1)
          .get();
      
      // If not found, try 'username' field
      if (querySnapshot.docs.isEmpty) {
        querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
      }
      
      String? userId;
      if (querySnapshot.docs.isNotEmpty) {
        userId = querySnapshot.docs.first.id;
        
        // ✅ VALIDATION: Check if user is a member of this forum
        final memberDocId = '${forumId}_$userId';
        final memberDoc = await FirebaseFirestore.instance
            .collection('forum_members')
            .doc(memberDocId)
            .get();
        
        if (!memberDoc.exists) {
          userId = null; // Not a member, treat as invalid
        }
      }
      
      // Cache the result (even if null)
      _usernameCache[cacheKey] = userId;
      return userId;
    } catch (e, stackTrace) {
      AppLogger.warning('Error finding user by username: $username', e, stackTrace);
      _usernameCache[cacheKey] = null; // Cache the failure too
      return null;
    } finally {
      // Remove from fetching set
      _fetchingUsernames.remove(cacheKey);
    }
  }
}

