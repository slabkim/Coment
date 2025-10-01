import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/nandogami_item.dart';
import '../data/repositories/nandogami_repository.dart';

class ItemProvider extends ChangeNotifier {
  final NandogamiRepository repo;

  ItemProvider(this.repo);

  List<NandogamiItem> _all = [];
  List<NandogamiItem> _filtered = [];
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
      _all.shuffle();
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
        final inAlt = (e.alternativeTitles ?? const <String>[]) // alt titles
            .any((t) => t.toLowerCase().contains(q));
        final inCats = (e.categories ?? const <String>[]) // categories/tags
            .any((t) => t.toLowerCase().contains(q));
        final inThemes = (e.themes ?? const <String>[]) // themes
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

  List<NandogamiItem> get getFeatured =>
      _all.where((e) => e.isFeatured == true).toList();

  List<NandogamiItem> get getCategories =>
      _all.where((e) => (e.categories ?? const []).isNotEmpty).toList();

  List<NandogamiItem> get getPopular =>
      _all.where((e) => e.isPopular == true).toList();

  List<NandogamiItem> get getNewReleases =>
      _all.where((e) => e.isNewRelease == true).toList();

  Future<void> _loadFavs() async {
    final sp = await SharedPreferences.getInstance();
    _favoriteIds = (sp.getStringList('favorites') ?? []).toSet();
  }
}
