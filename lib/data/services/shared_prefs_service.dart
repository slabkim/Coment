import 'package:shared_preferences/shared_preferences.dart';

/// A thin wrapper around SharedPreferences with namespaced keys
class SharedPrefsService {
  final String namespace;
  SharedPrefsService({this.namespace = 'nandogami'});

  String _k(String key) => '$namespace::$key';

  Future<List<String>> getStringList(String key) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(_k(key)) ?? const <String>[];
  }

  Future<void> setStringList(String key, List<String> value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_k(key), value);
  }

  Future<void> remove(String key) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_k(key));
  }
}


