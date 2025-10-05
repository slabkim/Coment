import 'shared_prefs_service.dart';

class SearchService {
  static const _key = 'recent_searches';

  Future<List<String>> getRecent({int limit = 8}) async {
    final sp = SharedPrefsService();
    final list = await sp.getStringList(_key);
    return list.take(limit).toList();
  }

  Future<void> pushRecent(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final sp = SharedPrefsService();
    final list = List<String>.from(await sp.getStringList(_key));
    list.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    list.insert(0, q);
    while (list.length > 12) {
      list.removeLast();
    }
    await sp.setStringList(_key, list);
  }

  Future<void> clear() async {
    final sp = SharedPrefsService();
    await sp.remove(_key);
  }
}
