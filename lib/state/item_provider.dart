import 'package:flutter/foundation.dart';
import '../data/services/shared_prefs_service.dart';
import '../core/api_error_handler.dart';

import '../data/models/nandogami_item.dart';
import '../data/repositories/comic_repository.dart';
import '../data/adapters/comic_adapter.dart';

class ItemProvider extends ChangeNotifier {
  final ComicRepository repo;

  ItemProvider(this.repo);

  List<NandogamiItem> _all = [];
  List<NandogamiItem> _filtered = [];
  List<NandogamiItem> _featured = [];
  List<NandogamiItem> _categoryPicks = [];
  List<NandogamiItem> _popular = [];
  List<NandogamiItem> _newReleases = [];
  List<NandogamiItem> _topRated = [];
  List<NandogamiItem> _trending = [];
  List<NandogamiItem> _seasonal = [];
  bool _loading = false;
  String _query = '';
  String? _error;
  Set<String> _favoriteIds = {};

  List<NandogamiItem> get items => _filtered;
  List<NandogamiItem> get getFeatured => _featured;
  List<NandogamiItem> get getCategories => _categoryPicks;
  List<NandogamiItem> get getPopular => _popular;
  List<NandogamiItem> get getNewReleases => _newReleases;
  List<NandogamiItem> get getTopRated => _topRated;
  List<NandogamiItem> get getTrending => _trending;
  List<NandogamiItem> get getSeasonal => _seasonal;
  bool get isLoading => _loading;
  String get query => _query;
  String? get error => _error;
  bool get hasError => _error != null;
  Set<String> get favorites => _favoriteIds;

  Future<void> init() async {
    await _loadFavs();
    await load();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Get mixed feed from APIs with fallback
      final mixedFeed = await repo.getMixedFeed();
      
      // Convert to NandogamiItems for compatibility
      // All sections are now loaded from single mixedFeed API call
      _featured = ComicAdapter.toNandogamiItems(mixedFeed['featured'] ?? []);
      _popular = ComicAdapter.toNandogamiItems(mixedFeed['popular'] ?? []);
      _newReleases = ComicAdapter.toNandogamiItems(mixedFeed['newReleases'] ?? []);
      _topRated = ComicAdapter.toNandogamiItems(mixedFeed['topRated'] ?? []);
      _trending = ComicAdapter.toNandogamiItems(mixedFeed['trending'] ?? []);
      _categoryPicks = ComicAdapter.toNandogamiItems(mixedFeed['categories'] ?? []);
      _seasonal = ComicAdapter.toNandogamiItems(mixedFeed['seasonal'] ?? []);
      
      // Build _all from all sections
      final allComics = <String, NandogamiItem>{};
      for (final item in [..._featured, ..._popular, ..._newReleases, ..._categoryPicks, ..._seasonal, ..._topRated, ..._trending]) {
        allComics[item.id] = item;
      }
      _all = allComics.values.toList();
      _applyFilter();
    } catch (e, stackTrace) {
      ApiErrorHandler.logError(e, stackTrace);
      _error = ApiErrorHandler.getErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void search(String q) {
    _query = q;
    if (q.isEmpty) {
      _applyFilter();
    } else {
      _searchFromAPI(q);
    }
    notifyListeners();
  }

  Future<void> _searchFromAPI(String query) async {
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      final searchResults = await repo.search(query);
      _filtered = ComicAdapter.toNandogamiItems(searchResults);
    } catch (e, stackTrace) {
      ApiErrorHandler.logError(e, stackTrace);
      // Fallback to local search if API fails
      _applyFilter();
      // Don't set error for search failures, just fallback silently
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _filtered = _all;
    } else {
      final q = _query.toLowerCase();
      
      // Filter and score items by relevance
      final scoredItems = <MapEntry<NandogamiItem, double>>[];
      
      for (final e in _all) {
        double score = 0.0;
        final title = e.title.toLowerCase();
        final desc = e.description.toLowerCase();
        
        // Exact title match = highest score
        if (title == q) {
          score += 100.0;
        }
        // Title starts with query = very high score
        else if (title.startsWith(q)) {
          score += 50.0;
        }
        // Title contains query = high score
        else if (title.contains(q)) {
          score += 25.0;
        }
        
        // Alternative titles
        final inAlt = (e.alternativeTitles ?? const <String>[])
            .any((t) => t.toLowerCase().contains(q));
        if (inAlt) score += 20.0;
        
        // Description contains query
        if (desc.contains(q)) score += 5.0;
        
        // Categories/genres match
        final inCats = (e.categories ?? const <String>[])
            .any((t) => t.toLowerCase().contains(q));
        if (inCats) score += 3.0;
        
        // Themes match
        final inThemes = (e.themes ?? const <String>[])
            .any((t) => t.toLowerCase().contains(q));
        if (inThemes) score += 2.0;
        
        // Fuzzy matching for typos
        if (score == 0 && q.length > 3) {
          final fuzzyScore = _fuzzyMatchScore(q, title);
          if (fuzzyScore > 0.7) {
            score += fuzzyScore * 15.0; // Scale fuzzy score
          }
        }
        
        // Add popularity bonus (normalize popularity to 0-10 range)
        final popularity = e.popularity ?? 0;
        final popularityBonus = (popularity / 10000).clamp(0, 10);
        score += popularityBonus;
        
        if (score > 0) {
          scoredItems.add(MapEntry(e, score));
        }
      }
      
      // Sort by score (descending) and take results
      scoredItems.sort((a, b) => b.value.compareTo(a.value));
      _filtered = scoredItems.map((e) => e.key).toList();
    }
  }
  
  /// Calculate fuzzy match score between 0 and 1
  double _fuzzyMatchScore(String query, String target) {
    // Levenshtein distance ratio
    final distance = _levenshteinDistance(query, target);
    final maxLength = query.length > target.length ? query.length : target.length;
    if (maxLength == 0) return 1.0;
    return 1.0 - (distance / maxLength);
  }
  
  /// Calculate Levenshtein distance (edit distance)
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    final len1 = s1.length;
    final len2 = s2.length;
    final matrix = List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));
    
    for (var i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }
    
    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[len1][len2];
  }

  Future<void> toggleFavorite(String id) async {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
    final sp = SharedPrefsService();
    await sp.setStringList('favorites', _favoriteIds.toList());
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  NandogamiItem? findById(String id) {
    try {
      return _all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Find by AniList ID with fallback to API
  Future<NandogamiItem?> findByIdWithFallback(String id) async {
    // First try to find in cache
    final cached = findById(id);
    if (cached != null) {
      return cached;
    }

    // If not found, try to fetch from API
    try {
      final anilistId = int.tryParse(id);
      if (anilistId != null) {
        final comicItem = await repo.getDetail(anilistId);
        final comic = ComicAdapter.toNandogamiItem(comicItem);
        _all.add(comic);
        return comic;
      }
    } catch (e) {
      // Silently fail
    }
    
    return null;
  }

  Future<void> _loadFavs() async {
    final sp = SharedPrefsService();
    _favoriteIds = (await sp.getStringList('favorites')).toSet();
  }

  /// Refresh specific section
  Future<void> refreshSection(String sectionType) async {
    try {
      // Add delay before refresh to avoid rate limiting
      await Future.delayed(Duration(milliseconds: 1000));
      
      switch (sectionType) {
        case 'trending':
          _featured = ComicAdapter.toNandogamiItems(await repo.getTrending());
          break;
        case 'popular':
          _popular = ComicAdapter.toNandogamiItems(await repo.getPopular());
          break;
        case 'newReleases':
          _newReleases = ComicAdapter.toNandogamiItems(await repo.getNewReleases());
          break;
        case 'topRated':
          _topRated = ComicAdapter.toNandogamiItems(await repo.getTopRated());
          break;
        case 'seasonal':
          _seasonal = ComicAdapter.toNandogamiItems(await repo.getSeasonal());
          break;
        case 'recent':
          _newReleases = ComicAdapter.toNandogamiItems(await repo.getNewReleases());
          break;
        default:
          // Refresh all sections
          await load();
          return;
      }
      notifyListeners();
    } catch (e) {
      ApiErrorHandler.logError(e, StackTrace.current);
      // Show user-friendly error message
      _error = 'Failed to refresh data. Please try again later.';
      notifyListeners();
    }
  }

  // Sections are now built directly from API response in load() method
}
