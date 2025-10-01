import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class GiphyService {
  static const _apiBase = 'https://api.giphy.com/v1/gifs';

  Future<List<String>> searchGifs({required String query, int limit = 24, int offset = 0}) async {
    final uri = Uri.parse('$_apiBase/search').replace(queryParameters: {
      'api_key': AppConst.giphyApiKey,
      'q': query,
      'limit': '$limit',
      'offset': '$offset',
      'rating': 'pg',
      'lang': 'en',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Giphy search failed: ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final List data = json['data'] as List? ?? const [];
    // prefer mp4 or gif url; use original or downsized
    return data.map((e) {
      final images = (e['images'] as Map<String, dynamic>?);
      final original = images?['original'] as Map<String, dynamic>?;
      final downsized = images?['downsized_medium'] as Map<String, dynamic>?;
      return (downsized?['url'] ?? original?['url'] ?? e['url'] ?? '').toString();
    }).where((url) => url.isNotEmpty).cast<String>().toList();
  }
}


