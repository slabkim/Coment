import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/auth_helper.dart';
import '../../core/logger.dart';
import '../../data/models/manga.dart';
import '../../data/services/simple_anilist_service.dart';
import '../widgets/categories_section.dart';
import '../widgets/manga_section.dart';
import '../widgets/home/profile_badge.dart';
import '../widgets/home/home_helpers.dart';
import 'detail_screen.dart';
import 'chat_list_screen.dart';
import 'search_screen.dart';

/// Main home screen displaying featured manga, popular titles, new releases,
/// top rated, trending, and category-based sections.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SimpleAniListService _mangaService = SimpleAniListService();
  
  // Data untuk setiap section
  final Map<String, List<Manga>> _sectionData = {};
  final Map<String, bool> _sectionLoading = {};
  final Map<String, String?> _sectionErrors = {};
  List<String> _selectedGenres = [];

  @override
  void initState() {
    super.initState();
    _loadAllSections();
  }

  Future<void> _loadAllSections() async {
    // Use single API call for all sections to avoid rate limiting
    try {
      final mixedFeed = await _mangaService.getMixedFeed();
      
      setState(() {
        // Update all sections from single API response
        _sectionData['featured'] = mixedFeed['featured'] ?? [];
        _sectionData['popular'] = mixedFeed['popular'] ?? [];
        _sectionData['newReleases'] = mixedFeed['newReleases'] ?? [];
        _sectionData['topRated'] = mixedFeed['topRated'] ?? [];
        _sectionData['trending'] = mixedFeed['trending'] ?? [];
        _sectionData['completed'] = mixedFeed['completed'] ?? [];
        
        // Mark all sections as loaded
        _sectionLoading['featured'] = false;
        _sectionLoading['popular'] = false;
        _sectionLoading['newReleases'] = false;
        _sectionLoading['topRated'] = false;
        _sectionLoading['trending'] = false;
        _sectionLoading['completed'] = false;
      });
      
      // Load additional sections separately if needed (with delay)
      await Future.delayed(Duration(seconds: 3));
      await _loadHiddenGems();
    } catch (e) {
      AppLogger.apiError('loading mixed feed', e);
      // Fallback to individual loads with longer delays
      await _loadFeaturedTitles();
      await Future.delayed(Duration(seconds: 3));
      await _loadPopularThisWeek();
      await Future.delayed(Duration(seconds: 3));
      await _loadNewReleases();
    }
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
    } catch (e, stackTrace) {
      AppLogger.apiError('loading featured titles', e, stackTrace);
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
    } catch (e, stackTrace) {
      AppLogger.apiError('loading popular this week', e, stackTrace);
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
    } catch (e, stackTrace) {
      AppLogger.apiError('loading new releases', e, stackTrace);
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
    } catch (e, stackTrace) {
      AppLogger.apiError('loading top rated', e, stackTrace);
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
    } catch (e, stackTrace) {
      AppLogger.apiError('loading trending now', e, stackTrace);
      setState(() {
        _sectionErrors['trending'] = e.toString();
        _sectionLoading['trending'] = false;
      });
    }
  }

  Future<void> _loadHiddenGems() async {
    setState(() {
      _sectionLoading['hiddenGems'] = true;
      _sectionErrors['hiddenGems'] = null;
    });

    try {
      final manga = await _mangaService.getHiddenGems();
      setState(() {
        _sectionData['hiddenGems'] = manga;
        _sectionLoading['hiddenGems'] = false;
      });
    } catch (e, stackTrace) {
      AppLogger.apiError('loading hidden gems', e, stackTrace);
      setState(() {
        _sectionErrors['hiddenGems'] = e.toString();
        _sectionLoading['hiddenGems'] = false;
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
    } catch (e, stackTrace) {
      AppLogger.apiError('loading manga by genres', e, stackTrace);
      setState(() {
        _sectionErrors['categories'] = e.toString();
        _sectionLoading['categories'] = false;
      });
    }
  }

  void _onMangaTap(Manga manga) {
    // Open with basic data immediately for fast navigation
    // Preview pages will be loaded separately in PreviewTab
    _openWithBasicData(manga);
  }

  void _openWithBasicData(Manga manga) {
    // Convert basic Manga to NandogamiItem for DetailScreen
    final nandogamiItem = HomeHelpers.convertMangaToItem(manga);

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
          child: const ProfileBadge(),
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
            tooltip: 'Search',
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color, size: 22),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen())
              );
            },
          ),
          IconButton(
            tooltip: 'DM',
            icon: Icon(Icons.send, color: Theme.of(context).iconTheme.color, size: 22),
            onPressed: () async {
              // Capture context before async operation
              final stateContext = context;
              final success = await AuthHelper.requireAuthWithDialog(
                stateContext, 
                'use Direct Messages'
              );
              if (success && mounted && stateContext.mounted) {
                Navigator.of(stateContext).push(
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
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF3B82F6) // Blue for light mode
            : AppColors.purpleAccent, // Purple for dark mode
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
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

            // Completed Manga
            if (_sectionData['completed']?.isNotEmpty == true)
              MangaSection(
                title: 'Completed Manga',
                manga: _sectionData['completed']!,
                isLoading: _sectionLoading['completed'] ?? false,
                error: _sectionErrors['completed'],
                onRetry: _loadAllSections,
                onMangaTap: _onMangaTap,
              ),

            // Hidden Gems
            if (_sectionData['hiddenGems']?.isNotEmpty == true)
              MangaSection(
                title: 'Hidden Gems',
                manga: _sectionData['hiddenGems']!,
                isLoading: _sectionLoading['hiddenGems'] ?? false,
                error: _sectionErrors['hiddenGems'],
                onRetry: _loadHiddenGems,
                onMangaTap: _onMangaTap,
              ),

            const SizedBox(height: 16),
          ],
        ),
        ),
      ),
    );
  }
}
