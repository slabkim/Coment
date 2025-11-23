import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/logger.dart';

class GiphyService {
  static const _apiBase = 'https://api.giphy.com/v1/gifs';
  static const List<String> _fallbackGifs = [
    'https://media.giphy.com/media/ICOgUNjpvO0PC/giphy.gif',
    'https://media.giphy.com/media/l0HlSNOxJB956qwfK/giphy.gif',
    'https://media.giphy.com/media/3oriO0OEd9QIDdllqo/giphy.gif',
    'https://media.giphy.com/media/xT1XGSq4cPIHW8xTEs/giphy.gif',
    'https://media.giphy.com/media/JIX9t2j0ZTN9S/giphy.gif',
  ];

  Future<List<String>> searchGifs({
    required String query,
    int limit = 24,
    int offset = 0,
  }) async {
    final apiKey = AppConst.optionalGiphyApiKey;
    if (apiKey == null) {
      AppLogger.warning(
        'GIPHY_API_KEY missing. Returning fallback GIFs. Add one in .env to enable live search.',
      );
      return _fallbackGifs;
    }
    final cleanedQuery = query.trim().isEmpty ? 'reaction' : query.trim();
    try {
      final uri = Uri.parse('$_apiBase/search').replace(
        queryParameters: {
          'api_key': apiKey,
          'q': cleanedQuery,
          'limit': '$limit',
          'offset': '$offset',
          'rating': 'pg-13',
          'lang': 'en',
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        AppLogger.apiError(
          'Giphy search failed (${res.statusCode})',
          res.body,
          StackTrace.current,
        );
        return _fallbackGifs;
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final List data = json['data'] as List? ?? const [];
      if (data.isEmpty) {
        return _fallbackGifs;
      }
      // prefer mp4 or gif url; use original or downsized
      return data
          .map((e) {
            final images = (e['images'] as Map<String, dynamic>?);
            final original = images?['original'] as Map<String, dynamic>?;
            final downsized =
                images?['downsized_medium'] as Map<String, dynamic>?;
            return (downsized?['url'] ?? original?['url'] ?? e['url'] ?? '')
                .toString();
          })
          .where((url) => url.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (e, stackTrace) {
      AppLogger.apiError('Giphy search crashed', e, stackTrace);
      return _fallbackGifs;
    }
  }
}
