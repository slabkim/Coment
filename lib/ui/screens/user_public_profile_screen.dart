import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/nandogami_item.dart';
import '../../data/services/follow_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/favorite_service.dart';
import '../../data/services/simple_anilist_service.dart';
import '../widgets/class_badge.dart';
import 'chat_screen.dart';
import 'detail_screen.dart';

class UserPublicProfileScreen extends StatelessWidget {
  final String userId;
  const UserPublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final userService = UserService();
    final followService = FollowService();
    final isSelf = currentUid == userId;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: const Text('Profile'),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: userService.watchProfile(userId),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          if (profile == null) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: Text(
                'User not found',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            );
          }
          final name =
              profile.username ?? profile.handle ?? profile.email ?? 'User';
          final handle = profile.handle ?? profile.email ?? '';
          final photo = profile.photoUrl;
          final coverPhoto = profile.coverPhotoUrl;
          final bio = profile.bio ?? '';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // Cover Photo & Profile Photo Header
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cover Photo
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: coverPhoto != null && coverPhoto.isNotEmpty
                        ? Image.network(
                            coverPhoto,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback gradient when image fails to load
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          ),
                  ),
                  
                  // Avatar (positioned at bottom of cover)
                  Positioned(
                    bottom: -40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 4,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          backgroundImage: (photo != null && photo.isNotEmpty)
                              ? NetworkImage(photo)
                              : null,
                          child: (photo == null || photo.isEmpty)
                              ? Text(
                                  _initials(name),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 52),
              
              // Name & Handle (with Dev Badge)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (profile.isDeveloper) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 12, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'DEV',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (handle.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      handle.startsWith('@') ? handle : '@$handle',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              
              // Bio
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: !isSelf
                    ? StreamBuilder<bool>(
                  stream: currentUid == null
                      ? const Stream<bool>.empty()
                      : followService.isFollowing(currentUid, userId),
                  builder: (context, followSnap) {
                    final isFollowing = followSnap.data ?? false;
                    return Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: currentUid == null
                                ? () => _requireLogin(context)
                                : () => followService.toggleFollow(
                                    followerId: currentUid,
                                    followingId: userId,
                                  ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF3B82F6) // Blue for light mode
                                  : AppColors.purpleAccent, // Purple for dark mode
                              foregroundColor: Theme.of(context).brightness == Brightness.light
                                  ? Colors.black87 // Black text for light mode
                                  : Colors.white, // White text for dark mode
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              elevation: 0, // Flat design
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30), // More rounded (pill-shaped)
                              ),
                            ),
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: currentUid == null
                                ? () => _requireLogin(context)
                                : () {
                                    final displayName =
                                        profile.username ??
                                        profile.handle ??
                                        'User';
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          peerUserId: userId,
                                          peerDisplayName: displayName,
                                          peerPhotoUrl: photo,
                                        ),
                                      ),
                                    );
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF3B82F6) // Blue for light mode
                                  : AppColors.purpleAccent, // Purple for dark mode
                              foregroundColor: Theme.of(context).brightness == Brightness.light
                                  ? Colors.black87 // Black text for light mode
                                  : Colors.white, // White text for dark mode
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              elevation: 0, // Flat design
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30), // More rounded (pill-shaped)
                              ),
                            ),
                            child: const Text(
                              'Message',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
                    : const Center(
                        child: Text(
                          'This is you!',
                          style: TextStyle(color: AppColors.whiteSecondary),
                        ),
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Class Section (Simple - no XP details for public profile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SimpleClassBadge(
                  userClass: profile.userClass,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Favorite Manga Showcase
              _FavoriteMangaShowcase(userId: userId),
            ],
          );
        },
      ),
    );
  }
  
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _requireLogin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to use this feature')),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(' ');
    final first = parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first[0]
        : 'U';
    final second = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0]
        : '';
    return (first + second).toUpperCase();
  }
}

/// Favorite Manga Showcase
class _FavoriteMangaShowcase extends StatefulWidget {
  final String userId;
  
  const _FavoriteMangaShowcase({required this.userId});

  @override
  State<_FavoriteMangaShowcase> createState() => _FavoriteMangaShowcaseState();
}

class _FavoriteMangaShowcaseState extends State<_FavoriteMangaShowcase> {
  final _favoriteService = FavoriteService();
  final _mangaService = SimpleAniListService();
  List<NandogamiItem> _favoriteManga = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      debugPrint('🔍 Loading favorites for user ${widget.userId}');
      
      // Get favorite IDs
      final favoriteIdsStream = _favoriteService.watchFavorites(widget.userId);
      final favoriteIds = await favoriteIdsStream.first;
      
      debugPrint('📚 Found ${favoriteIds.length} favorite IDs');
      
      // Limit to 5 for showcase to reduce API calls
      final showcaseIds = favoriteIds.take(5).toList();
      
      // Fetch all manga in parallel using Future.wait for better performance
      debugPrint('📖 Fetching ${showcaseIds.length} manga in parallel...');
      final fetchFutures = showcaseIds.map((id) async {
        try {
          final mangaId = int.tryParse(id);
          if (mangaId == null) {
            debugPrint('⚠️ Invalid manga ID: $id');
            return null;
          }
          
          final mangaData = await _mangaService.getMangaById(mangaId);
          if (mangaData != null) {
            debugPrint('✅ Successfully fetched: ${mangaData.title}');
            // Get author from staff (first author/story role)
            String? authorName;
            if (mangaData.staff != null && mangaData.staff!.isNotEmpty) {
              final author = mangaData.staff!.firstWhere(
                (s) => s.role.toLowerCase().contains('author') || 
                       s.role.toLowerCase().contains('story'),
                orElse: () => mangaData.staff!.first,
              );
              authorName = author.staff.name;
            }
            
            // Get year from seasonYear or startDate
            int? year = mangaData.seasonYear;
            if (year == null && mangaData.startDate != null) {
              try {
                year = int.tryParse(mangaData.startDate!.split('-').first);
              } catch (e) {
                year = null;
              }
            }
            
            // Convert Manga to NandogamiItem
            final item = NandogamiItem(
              id: mangaData.id.toString(),
              title: mangaData.title,
              description: mangaData.description ?? '',
              imageUrl: mangaData.coverImage ?? '',
              coverImage: mangaData.coverImage,
              bannerImage: mangaData.bannerImage,
              rating: mangaData.rating,
              categories: mangaData.genres,
              genres: mangaData.genres,
              chapters: mangaData.chapters,
              volumes: mangaData.volumes,
              author: authorName,
              type: mangaData.format,
              format: mangaData.format,
              status: mangaData.status,
              releaseYear: year,
              seasonYear: mangaData.seasonYear,
              season: mangaData.season,
              startDate: mangaData.startDate,
              endDate: mangaData.endDate,
              averageScore: mangaData.averageScore,
              meanScore: mangaData.meanScore,
              popularity: mangaData.popularity,
              favourites: mangaData.favourites,
              source: mangaData.source,
              englishTitle: mangaData.englishTitle,
              nativeTitle: mangaData.nativeTitle,
              synonyms: mangaData.synonyms,
              tags: mangaData.tags,
              relations: mangaData.relations,
              characters: mangaData.characters,
              staff: mangaData.staff,
              externalLinks: mangaData.externalLinks,
              trailer: mangaData.trailer,
            );
            return item;
          } else {
            debugPrint('⚠️ Manga data is null for ID: $mangaId');
            return null;
          }
        } catch (e) {
          debugPrint('❌ Error fetching manga $id: $e');
          return null;
        }
      }).toList();
      
      // Wait for all fetches to complete
      final results = await Future.wait(fetchFutures);
      
      // Filter out null values
      final manga = results.whereType<NandogamiItem>().toList();
      
      debugPrint('✨ Total manga loaded: ${manga.length}');
      
      if (mounted) {
        setState(() {
          _favoriteManga = manga;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error in _loadFavorites: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_favoriteManga.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favorite Manga',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Removed "See All" button since we only show top 5
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _favoriteManga.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final manga = _favoriteManga[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(item: manga),
                      ),
                    );
                  },
                  child: Container(
                    width: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            manga.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 32,
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                              child: Text(
                                manga.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
