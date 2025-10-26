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
      _featured = ComicAdapter.toNandogamiItems(mixedFeed['featured'] ?? []);
      _popular = ComicAdapter.toNandogamiItems(mixedFeed['popular'] ?? []);
      _newReleases = ComicAdapter.toNandogamiItems(mixedFeed['newReleases'] ?? []);
      _categoryPicks = ComicAdapter.toNandogamiItems(mixedFeed['categories'] ?? []);
      _seasonal = ComicAdapter.toNandogamiItems(mixedFeed['seasonal'] ?? []);
      
      // Try to load additional sections, but don't fail if they don't work
      try {
        await Future.delayed(Duration(milliseconds: 500));
        _topRated = ComicAdapter.toNandogamiItems(await repo.getTopRated());
      } catch (e) {
        print('Failed to load top rated: $e');
        _topRated = _featured; // Use featured as fallback
      }
      
      try {
        await Future.delayed(Duration(milliseconds: 500));
        _trending = ComicAdapter.toNandogamiItems(await repo.getTrending());
      } catch (e) {
        print('Failed to load trending: $e');
        _trending = _featured; // Use featured as fallback
      }
      
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
      _filtered = _all.where((e) {
        final inTitle = e.title.toLowerCase().contains(q);
        final inDesc = e.description.toLowerCase().contains(q);
        final inAlt =
            (e.alternativeTitles ?? const <String>[]) // alt titles
                .any((t) => t.toLowerCase().contains(q));
        final inCats =
            (e.categories ?? const <String>[]) // categories/tags
                .any((t) => t.toLowerCase().contains(q));
        final inThemes =
            (e.themes ?? const <String>[]) // themes
                .any((t) => t.toLowerCase().contains(q));
        return inTitle || inDesc || inAlt || inCats || inThemes;
      }).toList();
    }
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
