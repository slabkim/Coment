import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants.dart';
import '../../core/auth_helper.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/nandogami_item.dart';
import '../../data/services/user_service.dart';
import '../../data/services/follow_service.dart';
import '../../data/services/reading_status_service.dart';
import '../../data/services/favorite_service.dart';
import '../../data/services/simple_anilist_service.dart';
import '../widgets/class_badge.dart';
import 'edit_profile_screen.dart';
import 'user_list_screen.dart';
import 'reading_list_screen.dart';
import 'recommendations_screen.dart';
import 'about_screen.dart';
import 'detail_screen.dart';
import 'package:provider/provider.dart';
import '../../state/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final uid = user?.uid;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            actions: uid != null ? [
              IconButton(
                tooltip: 'Settings',
                icon: Icon(
                  Icons.settings_outlined,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black87 // Dark icon for light mode
                      : Colors.white, // White icon for dark mode
                ),
                onPressed: () => _showSettingsSheet(context),
              ),
              const SizedBox(width: 8),
            ] : null,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: uid == null
              ? _LoginRequiredWidget()
              : StreamBuilder<UserProfile?>(
                  stream: userService.watchProfile(uid),
                  builder: (context, snapshot) {
                final profile = snapshot.data;
                return CustomScrollView(
                  slivers: [
                    // Cover Photo Header
                    SliverToBoxAdapter(
                      child: _EnhancedProfileHeader(profile: profile, uid: uid),
                    ),
                    
                    // XP & Class Section
                    if (profile != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: LargeClassBadge(
                            userClass: profile.userClass,
                            xp: profile.xp,
                          ),
                        ),
                      ),
                    
                    // Favorite Manga Showcase
                    SliverToBoxAdapter(
                      child: _FavoriteMangaShowcase(userId: uid),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                );
              },
            ),
        );
      },
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  final UserProfile? profile;
  const _AvatarHeader({this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.username ?? 'Your Name';
    final handle = profile?.handle ?? profile?.email;
    final photo = profile?.photoUrl;
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFF3B2A58),
          backgroundImage: (photo != null && photo.isNotEmpty)
              ? NetworkImage(photo)
              : null,
          child: (photo == null || photo.isEmpty)
              ? Text(
                  _initials(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (handle != null && handle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              handle.startsWith('@') ? handle : '@$handle',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  static String _initials(String value) {
    final parts = value.split(' ');
    final first = parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first[0]
        : 'U';
    final second = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0]
        : '';
    return (first + second).toUpperCase();
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final follow = FollowService();
    if (uid == null) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: follow.following(uid),
          builder: (_, s) => GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const UserListScreen(title: 'Following'),
              ),
            ),
            child: _StatItem(
              label: 'Following',
              value: (s.data?.length ?? 0).toString(),
            ),
          ),
        ),
        const SizedBox(width: 22),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: follow.followers(uid),
          builder: (_, s) => GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const UserListScreen(title: 'Followers'),
              ),
            ),
            child: _StatItem(
              label: 'Followers',
              value: (s.data?.length ?? 0).toString(),
            ),
          ),
        ),
        const SizedBox(width: 22),
        StreamBuilder<List<String>>(
          stream: ReadingStatusService().watchAllReadingTitles(uid),
          builder: (_, s) => GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ReadingListScreen(),
              ),
            ),
            child: _StatItem(
              label: 'Reads',
              value: (s.data?.length ?? 0).toString(),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

Widget _tile(
  BuildContext context, {
  required IconData icon,
  required String title,
  VoidCallback? onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
    title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
    trailing: Icon(
      Icons.chevron_right,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    onTap: onTap,
  );
}

void _showSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    builder: (_) => _SettingsSheet(),
  );
}

void _showThemeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    builder: (_) => const _ThemeSheet(),
  );
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Logout',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _logout(context);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> _logout(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    
    if (context.mounted) {
      // Navigate to login screen or show login required message
      Navigator.of(context).pushReplacementNamed('/login');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _SettingsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu items
            _settingsOption(
              context,
              icon: Icons.person_outline,
              label: 'Edit Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            _settingsOption(
              context,
              icon: Icons.palette_outlined,
              label: 'Change Theme',
              onTap: () {
                Navigator.pop(context);
                _showThemeSheet(context);
              },
            ),
            _settingsOption(
              context,
              icon: Icons.library_books_outlined,
              label: 'Reading List',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReadingListScreen()),
                );
              },
            ),
            _settingsOption(
              context,
              icon: Icons.info_outline,
              label: 'About',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
            
            const SizedBox(height: 8),
            
            // Logout button (different style)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _settingsOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet();

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    ThemeMode current = tp.mode;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Theme',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            _themeOption(context, 'System Default', ThemeMode.system, current),
            _themeOption(context, 'Light', ThemeMode.light, current),
            _themeOption(context, 'Dark', ThemeMode.dark, current),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext context, String label, ThemeMode mode, ThemeMode current) {
    final tp = context.read<ThemeProvider>();
    final selected = mode == current;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label, 
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () async {
        await tp.setMode(mode);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}

class _LoginRequiredWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Login Required',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please login to access your profile and personal features',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final success = await AuthHelper.requireAuth(context);
                if (success && context.mounted) {
                  // Refresh the screen to show profile
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF3B82F6) // Blue for light mode
                    : AppColors.purpleAccent, // Purple for dark mode
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Login Now'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced Profile Header with Cover Photo
class _EnhancedProfileHeader extends StatelessWidget {
  final UserProfile? profile;
  final String uid;
  
  const _EnhancedProfileHeader({required this.profile, required this.uid});

  @override
  Widget build(BuildContext context) {
    final name = profile?.username ?? 'Your Name';
    final handle = profile?.handle ?? profile?.email;
    final photo = profile?.photoUrl;
    final coverPhoto = profile?.coverPhotoUrl;
    
    return Column(
      children: [
        // Cover Photo
        Stack(
          clipBehavior: Clip.none,
          children: [
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
                            style: const TextStyle(
                              color: Colors.white,
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
        
        const SizedBox(height: 48),
        
        // Name & Handle (with Dev Badge)
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (profile?.isDeveloper ?? false) ...[
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
        if (handle != null && handle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              handle.startsWith('@') ? handle : '@$handle',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        
        // Bio
        if ((profile?.bio ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              profile!.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 18),
        
        // Stats Row
        _ProfileStats(),
        
        const SizedBox(height: 16),
      ],
    );
  }
  
  String _initials(String value) {
    final parts = value.split(' ');
    final first = parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first[0]
        : 'U';
    final second = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0]
        : '';
    return (first + second).toUpperCase();
  }
}

// Removed old _BadgesSection - now using XP & Class system

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
      // Get favorite IDs
      final favoriteIdsStream = _favoriteService.watchFavorites(widget.userId);
      final favoriteIds = await favoriteIdsStream.first;
      
      // Get manga details (limit to 10 for showcase)
      final showcaseIds = favoriteIds.take(10).toList();
      final manga = <NandogamiItem>[];
      
      for (final id in showcaseIds) {
        try {
          final mangaId = int.tryParse(id);
          if (mangaId == null) continue;
          
          final mangaData = await _mangaService.getMangaById(mangaId);
          if (mangaData != null) {
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
            manga.add(item);
          }
        } catch (e) {
          // Skip if manga not found
        }
      }
      
      if (mounted) {
        setState(() {
          _favoriteManga = manga;
          _loading = false;
        });
      }
    } catch (e) {
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
              if (_favoriteManga.length >= 10)
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full favorites page
                  },
                  child: const Text('See All'),
                ),
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
