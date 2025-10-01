import 'package:shared_preferences/shared_preferences.dart';

class SearchService {
  static const _key = 'recent_searches';

  Future<List<String>> getRecent({int limit = 8}) async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_key) ?? const [];
    return list.take(limit).toList();
  }

  Future<void> pushRecent(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_key) ?? <String>[];
    list.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    list.insert(0, q);
    while (list.length > 12) list.removeLast();
    await sp.setStringList(_key, list);
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}


