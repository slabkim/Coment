import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';

class NewsService {
  static const String _baseUrl = 'https://newsapi.org/v2';
  static const String _apiKey = '92d2e11a492541ad8dd02b6fbdb27c17';

  /// Get latest manga/anime news
  Future<NewsResponse> getLatestNews({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/everything').replace(
        queryParameters: {
          'q': 'manga OR anime OR "japanese animation" OR "manga news" OR "anime news" OR "comic" OR "graphic novel" OR "shonen" OR "shoujo" OR "seinen" OR "josei" OR "manga artist" OR "anime studio" OR "shonen jump" OR "weekly shonen" OR "manga sales" OR "anime adaptation"',
          'language': 'en',
          'sortBy': 'publishedAt',
          'page': page.toString(),
          'pageSize': pageSize.toString(),
          'apiKey': _apiKey,
          'excludeDomains': 'facebook.com,twitter.com,instagram.com,reddit.com',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final newsResponse = NewsResponse.fromJson(jsonData);
        
        // Filter articles to ensure they are relevant to manga/anime
        final filteredArticles = newsResponse.articles.where((article) {
          final title = article.title.toLowerCase();
          final description = article.description.toLowerCase();
          final content = article.content.toLowerCase();
          
          // Keywords that indicate manga/anime relevance
          final relevantKeywords = [
          // Umum
          'manga', 'anime', 'japanese', 'shonen', 'shoujo', 'seinen', 'josei',
           'comic', 'graphic novel', 'animation', 'manhwa', 'manhua', 'webtoon', 'donghua', 'comic hiatus',

          // Studio
          'studio ghibli', 'toei', 'madhouse', 'bones', 'wit studio', 'ufotable',
          'mappa', 'trigger', 'kyoto animation', 'cloverworks', 'sunrise', 'gainax',

          // Judul populer
          'one piece', 'naruto', 'dragon ball', 'attack on titan', 'demon slayer',
          'my hero academia', 'jujutsu kaisen', 'tokyo ghoul', 'death note',
          'bleach', 'fairy tail', 'black clover', 'one punch man', 'fullmetal alchemist',
          'sword art online', 're:zero', 'chainsaw man', 'spy x family', 'blue lock',

          // Genre
          'isekai', 'mecha', 'slice of life', 'romcom', 'harem', 'fantasy anime', 'sci-fi anime', 'sports anime',

          // Platform & layanan
          'shonen jump', 'weekly shonen', 'manga plus', 'crunchyroll',
          'funimation', 'hidive', 'netflix anime', 'amazon prime anime', 'disney plus anime',
          'anime news network', 'manga sales', 'anime adaptation',

          // Event & industri
          'anime expo', 'comiket', 'jump festa', 'animejapan', 'manga award',
          'kodansha', 'shueisha', 'kadokawa',

          // Kreator
          'osamu tezuka', 'rumiko takahashi'
        ];

          
          // Check if title, description, or content contains relevant keywords
          return relevantKeywords.any((keyword) => 
            title.contains(keyword) || 
            description.contains(keyword) || 
            content.contains(keyword)
          );
        }).toList();
        
        return NewsResponse(
          status: newsResponse.status,
          totalResults: filteredArticles.length,
          articles: filteredArticles,
        );
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your NewsAPI key.');
      } else if (response.statusCode == 429) {
        throw Exception('API rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Failed to fetch news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('News Service Error: $e');
    }
  }

  /// Get trending manga/anime news
  Future<NewsResponse> getTrendingNews({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/everything').replace(
        queryParameters: {
          'q': 'manga OR anime OR "japanese animation" OR "manga news" OR "anime news" OR "comic" OR "graphic novel" OR "shonen" OR "shoujo" OR "seinen" OR "josei" OR "manga artist" OR "anime studio" OR "shonen jump" OR "weekly shonen" OR "manga sales" OR "anime adaptation"',
          'language': 'en',
          'sortBy': 'popularity',
          'page': page.toString(),
          'pageSize': pageSize.toString(),
          'apiKey': _apiKey,
          'excludeDomains': 'facebook.com,twitter.com,instagram.com,reddit.com',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return NewsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to fetch trending news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('News Service Error: $e');
    }
  }

  /// Get news by category
  Future<NewsResponse> getNewsByCategory(
    String category, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/everything').replace(
        queryParameters: {
          'q': 'manga OR anime OR "japanese animation" OR "manga news" OR "anime news" $category',
          'language': 'en',
          'sortBy': 'publishedAt',
          'page': page.toString(),
          'pageSize': pageSize.toString(),
          'apiKey': _apiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return NewsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to fetch news by category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('News Service Error: $e');
    }
  }

  /// Search news
  Future<NewsResponse> searchNews(
    String query, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/everything').replace(
        queryParameters: {
          'q': '$query manga OR anime OR "japanese animation"',
          'language': 'en',
          'sortBy': 'relevancy',
          'page': page.toString(),
          'pageSize': pageSize.toString(),
          'apiKey': _apiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return NewsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('News Service Error: $e');
    }
  }
}
