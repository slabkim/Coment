import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../../core/auth_helper.dart';
import '../../data/models/manga.dart';
import '../../data/models/nandogami_item.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/simple_anilist_service.dart';
import '../../data/services/user_service.dart';
import '../../data/repositories/comic_repository.dart';
import '../widgets/categories_section.dart';
import '../widgets/manga_section.dart';
import 'detail_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';

class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({super.key});

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> {
  final SimpleAniListService _mangaService = SimpleAniListService();
  
  // Data untuk setiap section
  Map<String, List<Manga>> _sectionData = {};
  Map<String, bool> _sectionLoading = {};
  Map<String, String?> _sectionErrors = {};
  List<String> _selectedGenres = [];

  @override
  void initState() {
    super.initState();
    _loadAllSections();
  }

  Future<void> _loadAllSections() async {
    // Load semua section secara parallel
    await Future.wait([
      _loadFeaturedTitles(),
      _loadPopularThisWeek(),
      _loadNewReleases(),
      _loadTopRated(),
      _loadTrendingNow(),
      _loadSeasonalManga(),
      _loadRecentlyAdded(),
    ]);
  }

  Future<void> _loadFeaturedTitles() async {
    setState(() {
      _sectionLoading['featured'] = true;
      _sectionErrors['featured'] = null;
    });

    try {
      final manga = await _mangaService.getFeaturedTitles();
      setState(() {
        _sectionData['featured'] = manga;
        _sectionLoading['featured'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionErrors['featured'] = e.toString();
        _sectionLoading['featured'] = false;
      });
    }
  }

  Future<void> _loadPopularThisWeek() async {
    setState(() {
      _sectionLoading['popular'] = true;
      _sectionErrors['popular'] = null;
    });

    try {
      final manga = await _mangaService.getPopularThisWeek();
      setState(() {
        _sectionData['popular'] = manga;
        _sectionLoading['popular'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionErrors['popular'] = e.toString();
        _sectionLoading['popular'] = false;
      });
    }
  }

  Future<void> _loadNewReleases() async {
    setState(() {
      _sectionLoading['newReleases'] = true;
      _sectionErrors['newReleases'] = null;
    });

    try {
      final manga = await _mangaService.getNewReleases();
      setState(() {
        _sectionData['newReleases'] = manga;
        _sectionLoading['newReleases'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionErrors['newReleases'] = e.toString();
        _sectionLoading['newReleases'] = false;
      });
    }
  }

  Future<void> _loadTopRated() async {
    setState(() {
      _sectionLoading['topRated'] = true;
      _sectionErrors['topRated'] = null;
    });

    try {
      final manga = await _mangaService.getTopRated();
      setState(() {
        _sectionData['topRated'] = manga;
        _sectionLoading['topRated'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionErrors['topRated'] = e.toString();
        _sectionLoading['topRated'] = false;
      });
    }
  }

  Future<void> _loadTrendingNow() async {
    setState(() {
      _sectionLoading['trending'] = true;
      _sectionErrors['trending'] = null;
    });

    try {
      final manga = await _mangaService.getTrendingNow();
      setState(() {
        _sectionData['trending'] = manga;
        _sectionLoading['trending'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionErrors['trending'] = e.toString();
        _sectionLoading['trending'] = false;
      });
    }
  }

  Future<void> _loadSeasonalManga() async {
    setState(() {
      _sectionLoading['seasonal'] = true;
      _sectionErrors['seasonal'] = null;
    });

    try {
      final manga = await _mangaService.getSeasonalManga();
      setState(() {
        _sectionData['seasonal'] = manga;
        _sectionLoading['seasonal'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionErrors['seasonal'] = e.toString();
        _sectionLoading['seasonal'] = false;
      });
    }
  }

  Future<void> _loadRecentlyAdded() async {
    setState(() {
      _sectionLoading['recent'] = true;
      _sectionErrors['recent'] = null;
    });

    try {
      final manga = await _mangaService.getRecentlyAdded();
      setState(() {
        _sectionData['recent'] = manga;
        _sectionLoading['recent'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionErrors['recent'] = e.toString();
        _sectionLoading['recent'] = false;
      });
    }
  }

  Future<void> _loadMangaByGenres(List<String> genres) async {
    if (genres.isEmpty) return;

    setState(() {
      _sectionLoading['categories'] = true;
      _sectionErrors['categories'] = null;
    });

    try {
      final manga = await _mangaService.getMangaByGenres(genres);
      setState(() {
        _sectionData['categories'] = manga;
        _sectionLoading['categories'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionErrors['categories'] = e.toString();
        _sectionLoading['categories'] = false;
      });
    }
  }

  void _onMangaTap(Manga manga) {
    // Open with basic data immediately for fast navigation
    // Preview pages will be loaded separately in PreviewTab
    debugPrint('Opening manga: ${manga.bestTitle}');
    _openWithBasicData(manga);
  }

  void _openWithBasicData(Manga manga) {
    // Convert basic Manga to NandogamiItem for DetailScreen
    final nandogamiItem = NandogamiItem(
      id: manga.id.toString(),
      title: manga.bestTitle,
      description: manga.description ?? '',
      imageUrl: manga.coverImage ?? '',
      coverImage: manga.coverImage,
      bannerImage: manga.bannerImage,
      categories: manga.genres,
      chapters: manga.chapters,
      format: manga.format,
      rating: manga.rating,
      ratingCount: manga.ratingCount,
      releaseYear: manga.seasonYear,
      synopsis: manga.description,
      type: 'Manga',
      isFeatured: false,
      isNewRelease: false,
      isPopular: false,
      // AniList specific fields
      englishTitle: manga.englishTitle,
      nativeTitle: manga.nativeTitle,
      genres: manga.genres,
      tags: manga.tags,
      status: manga.status,
      volumes: manga.volumes,
      source: manga.source,
      seasonYear: manga.seasonYear,
      season: manga.season,
      averageScore: manga.averageScore,
      meanScore: manga.meanScore,
      popularity: manga.popularity,
      favourites: manga.favourites,
      startDate: manga.startDate,
      endDate: manga.endDate,
      synonyms: manga.synonyms,
      relations: manga.relations,
      characters: manga.characters,
      staff: manga.staff,
      externalLinks: null, // Will be loaded separately in AboutTabNew
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(item: nandogamiItem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 8,
        leadingWidth: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _ProfileBadge(),
        ),
        title: Text(
          AppConst.appName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'DM',
            icon: Icon(Icons.send, color: Theme.of(context).iconTheme.color, size: 22),
            onPressed: () async {
              final success = await AuthHelper.requireAuthWithDialog(
                context, 
                'use Direct Messages'
              );
              if (success) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatListScreen())
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllSections,
        color: AppColors.purpleAccent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Featured Titles
            if (_sectionData['featured']?.isNotEmpty == true)
              MangaSection(
                title: 'Featured Titles',
                manga: _sectionData['featured']!,
                isLoading: _sectionLoading['featured'] ?? false,
                error: _sectionErrors['featured'],
                onRetry: _loadFeaturedTitles,
                onMangaTap: _onMangaTap,
              ),

            // Categories Section
            CategoriesSection(
              onGenreSelected: (genres) {
                setState(() {
                  _selectedGenres = genres;
                });
                if (genres.isNotEmpty) {
                  _loadMangaByGenres(genres);
                }
              },
              selectedGenres: _selectedGenres,
            ),

            // Categories Results
            if (_selectedGenres.isNotEmpty)
              MangaSection(
                title: '${_selectedGenres.join(", ")} Manga',
                manga: _sectionData['categories'] ?? [],
                isLoading: _sectionLoading['categories'] ?? false,
                error: _sectionErrors['categories'],
                onRetry: () => _loadMangaByGenres(_selectedGenres),
                onMangaTap: _onMangaTap,
              ),

            // Popular This Week
            if (_sectionData['popular']?.isNotEmpty == true)
              MangaSection(
                title: 'Popular This Week',
                manga: _sectionData['popular']!,
                isLoading: _sectionLoading['popular'] ?? false,
                error: _sectionErrors['popular'],
                onRetry: _loadPopularThisWeek,
                onMangaTap: _onMangaTap,
              ),

            // New Releases
            if (_sectionData['newReleases']?.isNotEmpty == true)
              MangaSection(
                title: 'New Releases',
                manga: _sectionData['newReleases']!,
                isLoading: _sectionLoading['newReleases'] ?? false,
                error: _sectionErrors['newReleases'],
                onRetry: _loadNewReleases,
                onMangaTap: _onMangaTap,
              ),

            // Top Rated
            if (_sectionData['topRated']?.isNotEmpty == true)
              MangaSection(
                title: 'Top Rated',
                manga: _sectionData['topRated']!,
                isLoading: _sectionLoading['topRated'] ?? false,
                error: _sectionErrors['topRated'],
                onRetry: _loadTopRated,
                onMangaTap: _onMangaTap,
              ),

            // Trending Now
            if (_sectionData['trending']?.isNotEmpty == true)
              MangaSection(
                title: 'Trending Now',
                manga: _sectionData['trending']!,
                isLoading: _sectionLoading['trending'] ?? false,
                error: _sectionErrors['trending'],
                onRetry: _loadTrendingNow,
                onMangaTap: _onMangaTap,
              ),

            // Seasonal Manga
            if (_sectionData['seasonal']?.isNotEmpty == true)
              MangaSection(
                title: 'Seasonal Manga',
                manga: _sectionData['seasonal']!,
                isLoading: _sectionLoading['seasonal'] ?? false,
                error: _sectionErrors['seasonal'],
                onRetry: _loadSeasonalManga,
                onMangaTap: _onMangaTap,
              ),

            // Recently Added
            if (_sectionData['recent']?.isNotEmpty == true)
              MangaSection(
                title: 'Recently Added',
                manga: _sectionData['recent']!,
                isLoading: _sectionLoading['recent'] ?? false,
                error: _sectionErrors['recent'],
                onRetry: _loadRecentlyAdded,
                onMangaTap: _onMangaTap,
              ),

            const SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );
  }
}

class _ProfileBadge extends StatefulWidget {
  @override
  State<_ProfileBadge> createState() => _ProfileBadgeState();
}

class _ProfileBadgeState extends State<_ProfileBadge> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final userService = UserService();
      final profile = await userService.fetchProfile(user.uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile for badge: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photo = _profile?.photoUrl ?? user?.photoURL ?? '';
    
    // Debug info
    debugPrint('Profile Badge - User: ${user?.uid}');
    debugPrint('Profile Badge - Profile Photo URL: ${_profile?.photoUrl}');
    debugPrint('Profile Badge - Auth Photo URL: ${user?.photoURL}');
    debugPrint('Profile Badge - Final Photo URL: $photo');
    debugPrint('Profile Badge - Loading: $_loading');
    
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen())
        );
      },
      child: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.purpleAccent.withValues(alpha: 0.2),
        backgroundImage: (photo.isNotEmpty)
            ? NetworkImage(photo)
            : null,
        child: (photo.isEmpty)
            ? (_loading 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 16,
                  ))
            : null,
      ),
    );
  }
}
