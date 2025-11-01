import '../models/comic_item.dart';
import '../../core/content_filter.dart';
import '../../core/logger.dart';
import 'simple_anilist_service.dart';

/// Service that uses AniList API for comic data
class ComicService {
  final SimpleAniListService _anilistService;

  ComicService({
    SimpleAniListService? anilistService,
  })  : _anilistService = anilistService ?? SimpleAniListService();

  /// Check if manga content is safe for general audience
  bool _isContentSafe(dynamic manga) {
    // Check genres
    final genres = (manga.genres as List<String>?) ?? [];
    if (!ContentFilter.isSafeByGenres(genres)) {
      return false;
    }

    // Check tags with smart ecchi filtering
    // Handle both Manga model (tags) and AniListManga model (tagNames)
    final tags = manga is Map 
        ? (manga['tags'] as List<String>?) ?? []
        : (manga.tags as List<String>?) ?? [];
    
    if (!ContentFilter.isSafeByTags(tags)) {
      return false;
    }

    // Additional check for ecchi content - must have safe context
    if (tags.contains('Ecchi')) {
      if (!ContentFilter.isEcchiAcceptable(genres, tags)) {
        return false;
      }
    }

    return true;
  }

  /// Get popular comics
  Future<List<ComicItem>> getPopularComics({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final mangaList = await _anilistService.getPopularManga();

      return mangaList
          .where((manga) => _isContentSafe(manga))
          .map((manga) => ComicItem.fromManga(manga))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.apiError('fetching popular comics', e, stackTrace);
      rethrow;
    }
  }

  /// Get trending comics
  Future<List<ComicItem>> getTrendingComics({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final mangaList = await _anilistService.getTrendingManga();

      return mangaList
          .where((manga) => _isContentSafe(manga))
          .map((manga) => ComicItem.fromManga(manga))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.apiError('fetching trending comics', e, stackTrace);
      rethrow;
    }
  }

  /// Get top rated comics
  Future<List<ComicItem>> getTopRatedComics({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final mangaList = await _anilistService.getTopRatedManga();

      return mangaList
          .where((manga) => _isContentSafe(manga))
          .map((manga) => ComicItem.fromManga(manga))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.apiError('fetching top rated comics', e, stackTrace);
      rethrow;
    }
  }

  /// Get seasonal comics using AniList API
  Future<List<ComicItem>> getSeasonalComics({int perPage = 20}) async {
    try {
      final mangaList = await _anilistService.getRecentlyAdded();

      return mangaList
          .where((manga) => _isContentSafe(manga))
          .map((manga) => ComicItem.fromManga(manga))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.apiError('fetching seasonal comics', e, stackTrace);
      rethrow;
    }
  }

  /// Get new release comics
  Future<List<ComicItem>> getNewReleaseComics({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final mangaList = await _anilistService.getRecentlyAdded();

      return mangaList
          .where((manga) => _isContentSafe(manga))
          .map((manga) => ComicItem.fromManga(manga))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.apiError('fetching new release comics', e, stackTrace);
      rethrow;
    }
  }

  /// Search comics
  Future<List<ComicItem>> searchComics(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final mangaList = await _anilistService.searchManga(query);

      return mangaList
          .where((manga) => _isContentSafe(manga))
          .map((manga) => ComicItem.fromManga(manga))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.apiError('searching comics', e, stackTrace);
      rethrow;
    }
  }

  /// Get comics by genre
  Future<List<ComicItem>> getComicsByGenre(
    String genre, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final mangaList = await _anilistService.getMangaByGenres([genre]);

      return mangaList
          .where((manga) => _isContentSafe(manga))
          .map((manga) => ComicItem.fromManga(manga))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.apiError('fetching comics by genre', e, stackTrace);
      rethrow;
    }
  }

  /// Get comic detail with preview pages
  Future<ComicItem> getComicDetail(int anilistId) async {
    try {
      // Get detailed info from AniList
      final anilistManga = await _anilistService.getMangaById(anilistId);
      
      if (anilistManga == null) {
        throw Exception('Manga not found');
      }
      
      // Create comic item from AniList data
      final comicItem = ComicItem.fromManga(anilistManga);

      return comicItem;
    } catch (e, stackTrace) {
      AppLogger.apiError('fetching comic detail', e, stackTrace);
      rethrow;
    }
  }

  /// Get comic detail with full AniList data (relations, characters, external links)
  Future<ComicItem> getComicDetailFull(int anilistId) async {
    try {
      // Get detailed info from AniList with full data
      final anilistManga = await _anilistService.getMangaById(anilistId);
      
      if (anilistManga == null) {
        throw Exception('Manga not found');
      }
      
      // Create comic item from AniList data with full details
      final comicItem = ComicItem.fromManga(anilistManga);

      return comicItem;
    } catch (e, stackTrace) {
      AppLogger.apiError('fetching comic detail (full)', e, stackTrace);
      rethrow;
    }
  }

  /// Get mixed feed of comics using single GraphQL query
  Future<Map<String, List<ComicItem>>> getMixedFeed() async {
    try {
      // Use single GraphQL query to get all sections at once
      final mixedFeed = await _anilistService.getMixedFeed();
      
      // Convert Manga to ComicItem and apply content filtering
      return {
        'featured': (mixedFeed['featured'] ?? [])
            .where((manga) => _isContentSafe(manga))
            .map((manga) => ComicItem.fromManga(manga))
            .toList(),
        'popular': (mixedFeed['popular'] ?? [])
            .where((manga) => _isContentSafe(manga))
            .map((manga) => ComicItem.fromManga(manga))
            .toList(),
        'newReleases': (mixedFeed['newReleases'] ?? [])
            .where((manga) => _isContentSafe(manga))
            .map((manga) => ComicItem.fromManga(manga))
            .toList(),
        'topRated': (mixedFeed['topRated'] ?? [])
            .where((manga) => _isContentSafe(manga))
            .map((manga) => ComicItem.fromManga(manga))
            .toList(),
        'trending': (mixedFeed['trending'] ?? [])
            .where((manga) => _isContentSafe(manga))
            .map((manga) => ComicItem.fromManga(manga))
            .toList(),
        'completed': (mixedFeed['completed'] ?? [])
            .where((manga) => _isContentSafe(manga))
            .map((manga) => ComicItem.fromManga(manga))
            .toList(),
      };
    } catch (e) {
      // Fallback to minimal data
      AppLogger.apiError('AniList API (using minimal fallback)', e);
      return _getMinimalFallback();
    }
  }

  /// Minimal fallback data when API fails
  Map<String, List<ComicItem>> _getMinimalFallback() {
    return {
      'featured': _getMinimalManga(2),
      'popular': _getMinimalManga(2),
      'newReleases': _getMinimalManga(2),
      'topRated': _getMinimalManga(2),
      'trending': _getMinimalManga(2),
      'completed': _getMinimalManga(2),
    };
  }

  /// Generate minimal manga data for fallback
  List<ComicItem> _getMinimalManga(int count) {
    final titles = ['One Piece', 'Naruto', 'Attack on Titan', 'Demon Slayer', 'Jujutsu Kaisen'];
    final colors = ['FF6B6B', '4ECDC4', '45B7D1', 'FF6B6B', '667eea'];
    
    return List.generate(count, (index) {
      final title = titles[index % titles.length];
      final color = colors[index % colors.length];
      
      return ComicItem(
        id: 'minimal_$index',
        anilistId: index + 1,
        title: title,
        description: 'Popular manga series',
        imageUrl: 'https://via.placeholder.com/300x400/$color/FFFFFF?text=$title',
        categories: ['Action', 'Adventure'],
        chapters: 100 + (index * 50),
        format: 'Manga',
        rating: 9.0 + (index * 0.1),
        ratingCount: 10000 + (index * 5000),
        releaseYear: 2000 + (index * 5),
        synopsis: 'Popular manga series',
        type: 'Manga',
        status: 'Ongoing',
        popularity: index + 1,
        favourites: 50000 + (index * 10000),
        isCompleted: false,
        isFeatured: index < 2,
        isNewRelease: index < 2,
        isPopular: true,
      );
    });
  }

  /// Get all comics (for compatibility with existing code)
  Future<List<ComicItem>> getAllComics() async {
    try {
      // Get a mix of popular and trending comics
      final popularComics = await getPopularComics(perPage: 50);
      final trendingComics = await getTrendingComics(perPage: 50);
      
      // Combine and remove duplicates
      final allComics = <String, ComicItem>{};
      
      for (final comic in popularComics) {
        allComics[comic.id] = comic;
      }
      
      for (final comic in trendingComics) {
        allComics[comic.id] = comic;
      }
      
      return allComics.values.toList();
    } catch (e, stackTrace) {
      AppLogger.apiError('fetching all comics', e, stackTrace);
      rethrow;
    }
  }


  /// Get recommended comics based on a comic
  Future<List<ComicItem>> getRecommendedComics(ComicItem comic) async {
    try {
      // Get recommendations from AniList service
      final recommendations = await _anilistService.getMangaRecommendations(comic.anilistId);
      
      if (recommendations.isNotEmpty) {
        // Convert recommendations to ComicItems
        return recommendations
            .where((manga) => _isContentSafe(manga))
            .map((manga) => ComicItem.fromManga(manga))
            .toList();
      }

      // Fallback: get comics with similar genres
      if (comic.categories.isNotEmpty) {
        final genre = comic.categories.first;
        final similarComics = await getComicsByGenre(genre, perPage: 10);
        
        // Remove the original comic from results
        return similarComics.where((c) => c.id != comic.id).toList();
      }

      return [];
    } catch (e, stackTrace) {
      AppLogger.apiError('fetching recommended comics', e, stackTrace);
      rethrow;
    }
  }
}
