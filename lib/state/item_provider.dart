import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/nandogami_item.dart';
import '../data/repositories/nandogami_repository.dart';

class ItemProvider extends ChangeNotifier {
  final NandogamiRepository repo;

  ItemProvider(this.repo);

  List<NandogamiItem> _all = [];
  List<NandogamiItem> _filtered = [];
  List<NandogamiItem> _featured = [];
  List<NandogamiItem> _categoryPicks = [];
  List<NandogamiItem> _popular = [];
  List<NandogamiItem> _newReleases = [];
  bool _loading = false;
  String _query = '';
  Set<String> _favoriteIds = {};

  List<NandogamiItem> get items => _filtered;
  bool get isLoading => _loading;
  String get query => _query;
  Set<String> get favorites => _favoriteIds;

  Future<void> init() async {
    await _loadFavs();
    await load();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _all = await repo.getAll();
      _rebuildSections();
      _applyFilter();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void search(String q) {
    _query = q;
    _applyFilter();
    notifyListeners();
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
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList('favorites', _favoriteIds.toList());
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  List<NandogamiItem> get getFeatured => _featured;

  List<NandogamiItem> get getCategories => _categoryPicks;

  List<NandogamiItem> get getPopular => _popular;

  List<NandogamiItem> get getNewReleases => _newReleases;

  Future<void> _loadFavs() async {
    final sp = await SharedPreferences.getInstance();
    _favoriteIds = (sp.getStringList('favorites') ?? []).toSet();
  }

  void _rebuildSections() {
    final used = <String>{};
    List<NandogamiItem> pick(Iterable<NandogamiItem> source, {int take = 8}) {
      final list = source.toList()..shuffle();
      final result = <NandogamiItem>[];
      for (final item in list) {
        if (used.contains(item.id)) continue;
        used.add(item.id);
        result.add(item);
        if (result.length >= take) break;
      }
      return result;
    }

    _featured = pick(_all.where((e) => e.isFeatured == true));
    _categoryPicks = pick(
      _all.where((e) => (e.categories ?? const <String>[]).isNotEmpty),
    );
    _popular = pick(_all.where((e) => e.isPopular == true));
    _newReleases = pick(_all.where((e) => e.isNewRelease == true));

    // If any section empty, fallback to remaining unused items so UI doesn't look blank.
    void fillIfEmpty(List<NandogamiItem> target) {
      if (target.isNotEmpty) return;
      target.addAll(pick(_all.where((e) => !used.contains(e.id))));
    }

    fillIfEmpty(_featured);
    fillIfEmpty(_categoryPicks);
    fillIfEmpty(_popular);
    fillIfEmpty(_newReleases);
  }
}
