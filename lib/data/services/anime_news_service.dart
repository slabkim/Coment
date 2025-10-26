import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';

/// Service untuk fetch berita anime/manga dari berbagai sumber spesifik
class AnimeNewsService {
  // NewsAPI key
  static const String _newsApiKey = '92d2e11a492541ad8dd02b6fbdb27c17';

  /// Get latest anime/manga news dari NewsAPI dengan domain whitelist
  Future<NewsResponse> getLatestNews({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Domain yang HANYA berita anime/manga (lebih banyak + aktif update)
      final trustedDomains = [
        // Dedicated anime/manga sites (paling aktif)
        'animenewsnetwork.com',
        'crunchyroll.com',
        'myanimelist.net',
        'animelab.com',
        'funimation.com',
        
        // Gaming/Entertainment sites dengan section anime
        'ign.com',
        'polygon.com',
        'kotaku.com',
        'gamespot.com',
        'gamesradar.com',
        
        // Comic/Pop culture sites
        'comicbook.com',
        'cbr.com',
        'screenrant.com',
        'collider.com',
        'denofgeek.com',
        
        // Tech/Entertainment
        'theverge.com',
        'engadget.com',
        'techcrunch.com',
        
        // General entertainment (sering update anime news)
        'variety.com',
        'hollywoodreporter.com',
        'deadline.com',
        
        // Niche sites
        'animehunch.com',
        'otakukart.com',
        'epicstream.com',
        'sportskeeda.com',
        'gamerant.com',
      ].join(',');

      final uri = Uri.parse('https://newsapi.org/v2/everything').replace(
        queryParameters: {
          'q': 'anime OR manga OR "one piece" OR "demon slayer" OR "jujutsu kaisen" OR "attack on titan" OR crunchyroll OR "studio ghibli"',
          'domains': trustedDomains,
          'language': 'en',
          'sortBy': 'publishedAt',
          'page': page.toString(),
          'pageSize': pageSize.toString(),
          'apiKey': _newsApiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final newsResponse = NewsResponse.fromJson(jsonData);
        
        // Filter untuk memastikan relevan
        final filtered = newsResponse.articles.where((article) {
          final title = article.title.toLowerCase();
          final desc = article.description.toLowerCase();
          
          // Harus mengandung kata kunci anime/manga
          final hasAnimeKeyword = title.contains('anime') || 
                                  title.contains('manga') ||
                                  desc.contains('anime') ||
                                  desc.contains('manga');
          
          // Exclude berita yang tidak relevan
          final isIrrelevant = title.contains('football') ||
                              title.contains('soccer') ||
                              title.contains('politics') ||
                              title.contains('election');
                              
          return hasAnimeKeyword && !isIrrelevant;
        }).toList();
        
        return NewsResponse(
          status: newsResponse.status,
          totalResults: filtered.length,
          articles: filtered,
        );
      } else if (response.statusCode == 426) {
        throw Exception('NewsAPI: Please upgrade your plan');
      } else if (response.statusCode == 429) {
        throw Exception('NewsAPI: Rate limit exceeded');
      } else {
        throw Exception('NewsAPI error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }
  
  /// Get trending anime/manga news
  Future<NewsResponse> getTrendingNews({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Domain fokus anime/manga saja
      final trustedDomains = [
        'animenewsnetwork.com',
        'crunchyroll.com',
        'myanimelist.net',
        'comicbook.com',
        'cbr.com',
        'screenrant.com',
      ].join(',');

      final uri = Uri.parse('https://newsapi.org/v2/everything').replace(
        queryParameters: {
          // Query fokus anime populer
          'q': '"one piece" OR "demon slayer" OR "jujutsu kaisen" OR "attack on titan" OR "my hero academia" OR "chainsaw man"',
          'domains': trustedDomains,
          'language': 'en',
          'sortBy': 'popularity',
          'page': page.toString(),
          'pageSize': pageSize.toString(),
          'apiKey': _newsApiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return NewsResponse.fromJson(jsonData);
      } else {
        throw Exception('NewsAPI error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch trending news: $e');
    }
  }

}


