import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/manga.dart';
import '../models/external_link.dart';

class SimpleAniListService {
  static const String _baseUrl = 'https://graphql.anilist.co';
  static const int _perPage = 20; // Increased for better data loading
  
  // Rate limiting
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(milliseconds: 1500); // Increased to 1.5 seconds to avoid rate limiting
  
  // Cache for external links to reduce API calls
  static final Map<int, List<ExternalLink>> _externalLinksCache = {};
  
  // Cache for mixed feed data
  static Map<String, List<Manga>> _mixedFeedCache = {};
  
  // Cache for search results
  static final Map<String, List<Manga>> _searchCache = {};

  /// Featured Titles - menggunakan ID yang sudah ditentukan
  Future<List<Manga>> getFeaturedTitles() async {
    const featuredIds = [119257, 53390, 105398, 85934, 109957, 101517, 87216, 
                         169355, 120980, 137714, 187944, 97216, 173062, 108428];
    
    final query = '''
      query {
        Page(perPage: $_perPage) {
          media(id_in: [${featuredIds.join(',')}], type: MANGA, isAdult: false) {
            id
            title {
              romaji
              english
              native
            }
            description
            coverImage {
              large
              medium
            }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
            seasonYear
            season
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// Popular This Week - sort: TRENDING_DESC
  Future<List<Manga>> getPopularThisWeek() async {
    final query = '''
      query {
        Page(perPage: $_perPage) {
          media(type: MANGA, sort: TRENDING_DESC, isAdult: false) {
            id
            title {
              romaji
              english
              native
            }
            description
            coverImage {
              large
              medium
            }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
            seasonYear
            season
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// New Releases - sort: START_DATE_DESC
  Future<List<Manga>> getNewReleases() async {
    final query = '''
      query {
        Page(perPage: $_perPage) {
          media(type: MANGA, sort: START_DATE_DESC, isAdult: false) {
            id
            title {
              romaji
              english
              native
            }
            description
            coverImage {
              large
              medium
            }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
            seasonYear
            season
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// Top Rated - sort: SCORE_DESC
  Future<List<Manga>> getTopRated() async {
    final query = '''
      query {
        Page(perPage: $_perPage) {
          media(type: MANGA, sort: SCORE_DESC, isAdult: false) {
            id
            title {
              romaji
              english
              native
            }
            description
            coverImage {
              large
              medium
            }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
            seasonYear
            season
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// Trending Now - kombinasi sort: [TRENDING_DESC, POPULARITY_DESC]
  Future<List<Manga>> getTrendingNow() async {
    final query = '''
      query {
        Page(perPage: $_perPage) {
          media(type: MANGA, sort: [TRENDING_DESC, POPULARITY_DESC], isAdult: false) {
            id
            title {
              romaji
              english
              native
            }
            description
            coverImage {
              large
              medium
            }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
            seasonYear
            season
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// Seasonal Manga - filter berdasarkan season dan seasonYear
  Future<List<Manga>> getSeasonalManga({String? season, int? seasonYear}) async {
    final currentDate = DateTime.now();
    final currentSeason = season ?? _getCurrentSeason(currentDate);
    final currentYear = seasonYear ?? currentDate.year;

    final query = '''
      query {
        Page(perPage: $_perPage) {
          media(type: MANGA, season: $currentSeason, seasonYear: $currentYear, isAdult: false) {
            id
            title {
              romaji
              english
              native
            }
            description
            coverImage {
              large
              medium
            }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
            seasonYear
            season
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// Recently Added - sort: ID_DESC
  Future<List<Manga>> getRecentlyAdded() async {
    final query = '''
      query {
        Page(perPage: $_perPage) {
          media(type: MANGA, sort: ID_DESC, isAdult: false) {
            id
            title {
              romaji
              english
              native
            }
            description
            coverImage {
              large
              medium
            }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
            seasonYear
            season
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// Categories - berdasarkan genre
  Future<List<Manga>> getMangaByGenres(List<String> genres) async {
    final genreString = genres.map((g) => '"$g"').join(',');
    
    final query = '''
      query {
        Page(perPage: $_perPage) {
          media(type: MANGA, genre_in: [$genreString], isAdult: false) {
            id
            title {
              romaji
              english
              native
            }
            description
            coverImage {
              large
              medium
            }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
            seasonYear
            season
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// Get all available genres
  Future<List<String>> getAvailableGenres() async {
    try {
      final query = '''
        query {
          GenreCollection
        }
      ''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'query': query}),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['errors'] != null) {
          throw Exception('GraphQL Error: ${jsonData['errors']}');
        }
        return List<String>.from(jsonData['data']['GenreCollection'] ?? []);
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch genres: $e');
    }
  }

  /// Execute GraphQL query with rate limiting and retry
  Future<List<Manga>> _executeQuery(String query) async {
    // Rate limiting
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        final waitTime = _minRequestInterval - timeSinceLastRequest;
        debugPrint('Rate limiting: waiting ${waitTime.inMilliseconds}ms');
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();

    // Retry mechanism
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({'query': query}),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          if (jsonData['errors'] != null) {
            debugPrint('GraphQL Error: ${jsonData['errors']}');
            if (attempt < 3) {
              await Future.delayed(Duration(seconds: attempt));
              continue;
            }
            throw Exception('GraphQL Error: ${jsonData['errors']}');
          }
          
          final media = jsonData['data']?['Page']?['media'] as List<dynamic>? ?? [];
          return media.map((item) => Manga.fromJson(item)).toList();
        } else if (response.statusCode == 429) {
          // Rate limited
          debugPrint('Rate limited (429), waiting ${attempt * 2} seconds');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          throw Exception('Rate limited');
        } else if (response.statusCode >= 500) {
          // Server error, retry
          debugPrint('Server error ${response.statusCode}, retrying...');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt));
            continue;
          }
          throw Exception('Server error: ${response.statusCode}');
        } else {
          debugPrint('HTTP Error: ${response.statusCode} - ${response.body}');
          throw Exception('HTTP Error: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Service Error attempt $attempt: $e');
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }
        throw Exception('Failed to fetch manga after 3 attempts: $e');
      }
    }
    
    throw Exception('Failed to fetch manga: Max retries exceeded');
  }

  /// Get current season berdasarkan tanggal
  String _getCurrentSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'SPRING';
    if (month >= 6 && month <= 8) return 'SUMMER';
    if (month >= 9 && month <= 11) return 'FALL';
    return 'WINTER';
  }

  /// Get manga by specific ID with basic details (faster)
  Future<Manga?> getMangaById(int id) async {
    final query = '''
      query {
        Media(id: $id, type: MANGA) {
          id
          title {
            romaji
            english
            native
          }
          description
          coverImage {
            large
            medium
          }
          bannerImage
          genres
          tags {
            name
          }
          format
          status
          chapters
          volumes
          averageScore
          meanScore
          popularity
          favourites
          seasonYear
          season
          source
          startDate {
            year
            month
            day
          }
          endDate {
            year
            month
            day
          }
          synonyms
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final media = data['data']?['Media'];
        if (media != null) {
          return Manga.fromJson(media);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching manga by ID: $e');
      return null;
    }
  }

  /// Get manga by specific ID with characters and relations (optimized)
  Future<Manga?> getMangaByIdFull(int id) async {
    // Try basic query first
    final basicQuery = '''
      query {
        Media(id: $id, type: MANGA) {
          id
          title {
            romaji
            english
            native
          }
          description
          coverImage {
            large
            medium
          }
          bannerImage
          genres
          tags {
            name
          }
          format
          status
          chapters
          volumes
          averageScore
          meanScore
          popularity
          favourites
          seasonYear
          season
          source
          startDate {
            year
            month
            day
          }
          endDate {
            year
            month
            day
          }
          synonyms
          externalLinks {
            site
            url
            type
          }
        }
      }
    ''';

    try {
      debugPrint('Fetching basic manga details for ID: $id');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': basicQuery}),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Response data keys: ${data.keys}');
        
        if (data['errors'] != null) {
          debugPrint('GraphQL errors: ${data['errors']}');
          return null;
        }
        
        final media = data['data']?['Media'];
        if (media != null) {
          return Manga.fromJson(media);
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching full manga by ID: $e');
      return null;
    }
  }

  /// Get external links for a specific manga
  Future<List<ExternalLink>> getMangaExternalLinks(int id) async {
    // Check cache first - use cache if available (even if empty, to avoid repeated API calls)
    if (_externalLinksCache.containsKey(id)) {
      return _externalLinksCache[id]!;
    }

    final query = '''
      query {
        Media(id: $id, type: MANGA) {
          externalLinks {
            site
            url
            type
            icon
          }
        }
      }
    ''';

    try {
      // Rate limiting
      if (_lastRequestTime != null) {
        final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
        if (timeSinceLastRequest < _minRequestInterval) {
          final waitTime = _minRequestInterval - timeSinceLastRequest;
          debugPrint('Rate limiting: waiting ${waitTime.inMilliseconds}ms');
          await Future.delayed(waitTime);
        }
      }
      _lastRequestTime = DateTime.now();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['errors'] != null) {
          debugPrint('GraphQL errors for external links: ${data['errors']}');
          return [];
        }
        
        final media = data['data']?['Media'];
        if (media != null) {
          final links = media['externalLinks'] as List<dynamic>? ?? [];
          final externalLinks = links.map((link) => ExternalLink.fromJson(link)).toList();
          _externalLinksCache[id] = externalLinks;
          return externalLinks;
        }
      } else if (response.statusCode == 429) {
        debugPrint('Rate limited by AniList API (429)');
        // Cache empty result to avoid repeated rate limit calls
        _externalLinksCache[id] = [];
        return [];
      }
      
      // Return empty list if no external links found
      debugPrint('No external links found');
      _externalLinksCache[id] = []; // Cache empty result
      return [];
    } catch (e) {
      debugPrint('Error fetching external links: $e');
      // Don't cache error responses, return empty list
      return [];
    }
  }

  /// Get fallback external links for testing
  List<ExternalLink> _getFallbackExternalLinks() {
    // Return empty list to avoid showing template data
    // This will make the "Where to Read" tab show "No external links available"
    return [];
  }

  /// Clear external links cache
  static void clearExternalLinksCache() {
    _externalLinksCache.clear();
    debugPrint('External links cache cleared');
  }

  /// Get external links with retry mechanism
  Future<List<ExternalLink>> getMangaExternalLinksWithRetry(int id, {int maxRetries = 2}) async {
    // Check cache first - if already cached, return immediately
    if (_externalLinksCache.containsKey(id)) {
      return _externalLinksCache[id]!;
    }
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final links = await getMangaExternalLinks(id);
        if (links.isNotEmpty) {
          return links;
        }
        
        // If no links found and not the last attempt, wait before retry
        if (attempt < maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        debugPrint('Error fetching external links for manga ID: $id, attempt ${attempt + 1}: $e');
        if (attempt < maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    
    debugPrint('No external links found after $maxRetries attempts for manga ID: $id');
    return [];
  }

  /// Get manga characters by ID
  Future<List<MangaCharacter>> getMangaCharacters(int id) async {
    final query = '''
      query {
        Media(id: $id, type: MANGA) {
          characters(sort: ROLE, perPage: 10) {
            edges {
              role
              node {
                id
                name {
                  full
                }
                image {
                  large
                  medium
                }
              }
            }
          }
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errors'] != null) {
          return [];
        }
        
        final media = data['data']?['Media'];
        if (media != null) {
          final charactersData = media['characters'];
          if (charactersData != null) {
            final edges = charactersData['edges'] as List?;
            if (edges != null && edges.isNotEmpty) {
              return edges.map((edge) => MangaCharacter.fromJson(edge)).toList();
            }
          }
        }
      } else {
        debugPrint('HTTP error for characters: ${response.statusCode} - ${response.body}');
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching characters: $e');
      return [];
    }
  }

  /// Get manga relations by ID
  Future<List<MangaRelation>> getMangaRelations(int id) async {
    final query = '''
      query {
        Media(id: $id, type: MANGA) {
          relations {
            edges {
              relationType
              node {
                id
                title {
                  romaji
                  english
                  native
                }
                coverImage {
                  large
                  medium
                }
                format
                type
              }
            }
          }
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errors'] != null) {
          return [];
        }
        
        final media = data['data']?['Media'];
        if (media != null) {
          final relationsData = media['relations'];
          if (relationsData != null) {
            final edges = relationsData['edges'] as List?;
            if (edges != null && edges.isNotEmpty) {
              return edges.map((edge) => MangaRelation.fromJson(edge)).toList();
            }
          }
        }
      } else {
        debugPrint('HTTP error for relations: ${response.statusCode} - ${response.body}');
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching relations: $e');
      return [];
    }
  }

  /// Get manga recommendations by ID
  Future<List<Manga>> getMangaRecommendations(int id) async {
    final query = '''
      query {
        Media(id: $id, type: MANGA) {
          recommendations(sort: RATING_DESC, perPage: 10) {
            edges {
              node {
                id
                mediaRecommendation {
                  id
                  title {
                    romaji
                    english
                    native
                  }
                  description
                  coverImage {
                    large
                    medium
                  }
                  bannerImage
                  genres
                  tags {
                    name
                  }
                  format
                  status
                  chapters
                  volumes
                  averageScore
                  meanScore
                  popularity
                  favourites
                  seasonYear
                  season
                  source
                  startDate {
                    year
                    month
                    day
                  }
                  endDate {
                    year
                    month
                    day
                  }
                  synonyms
                }
              }
            }
          }
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errors'] != null) {
          return [];
        }
        
        final media = data['data']?['Media'];
        if (media != null) {
          final recommendationsData = media['recommendations'];
          if (recommendationsData != null) {
            final edges = recommendationsData['edges'] as List?;
            if (edges != null && edges.isNotEmpty) {
              return edges
                  .map((edge) => edge['node']['mediaRecommendation'])
                  .where((rec) => rec != null)
                  .map((rec) => Manga.fromJson(rec))
                  .toList();
            }
          }
        }
      } else {
        debugPrint('HTTP error for recommendations: ${response.statusCode} - ${response.body}');
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching recommendations: $e');
      return [];
    }
  }

  /// Get popular manga
  Future<List<Manga>> getPopularManga() async {
    final query = '''
      query {
        Page(perPage: $_perPage) {
          media(type: MANGA, sort: POPULARITY_DESC, isAdult: false) {
            id
            title { romaji english native }
            description
            coverImage { large medium }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
            seasonYear
            season
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// Get trending manga
  Future<List<Manga>> getTrendingManga() async {
    final query = '''
      query {
        Page(perPage: $_perPage) {
          media(type: MANGA, sort: TRENDING_DESC, isAdult: false) {
            id
            title { romaji english native }
            description
            coverImage { large medium }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
            seasonYear
            season
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// Get top rated manga
  Future<List<Manga>> getTopRatedManga() async {
    final query = '''
      query {
        Page(perPage: $_perPage) {
          media(type: MANGA, sort: SCORE_DESC, isAdult: false) {
            id
            title { romaji english native }
            description
            coverImage { large medium }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
            seasonYear
            season
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// Search manga with caching
  Future<List<Manga>> searchManga(String query) async {
    // Check cache first
    final cacheKey = query.toLowerCase().trim();
    if (_searchCache.containsKey(cacheKey)) {
      debugPrint('Using cached search results for: $query');
      return _searchCache[cacheKey]!;
    }

    final searchQuery = '''
      query {
        Page(perPage: $_perPage) {
          media(type: MANGA, search: "$query", isAdult: false) {
            id
            title { romaji english native }
            description
            coverImage { large medium }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
            seasonYear
            season
          }
        }
      }
    ''';

    try {
      final results = await _executeQuery(searchQuery);
      // Cache the results
      _searchCache[cacheKey] = results;
      debugPrint('Cached search results for: $query (${results.length} items)');
      return results;
    } catch (e) {
      debugPrint('Error searching manga: $e');
      return [];
    }
  }

  /// Get mixed feed for home page sections using single GraphQL query
  Future<Map<String, List<Manga>>> getMixedFeed() async {
    // Check cache first
    if (_mixedFeedCache.isNotEmpty) {
      debugPrint('Using cached mixed feed data');
      return _mixedFeedCache;
    }

    final query = '''
      query {
        # Featured titles (predefined IDs)
        featured: Page(perPage: 4) {
          media(id_in: [119257, 53390, 105398, 85934], type: MANGA, isAdult: false) {
            id
            title { romaji english native }
            description
            coverImage { large medium }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
          }
        }
        
        # Popular manga
        popular: Page(perPage: 4) {
          media(type: MANGA, sort: POPULARITY_DESC, isAdult: false) {
            id
            title { romaji english native }
            description
            coverImage { large medium }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
          }
        }
        
        # New releases
        newReleases: Page(perPage: 4) {
          media(type: MANGA, sort: ID_DESC, isAdult: false) {
            id
            title { romaji english native }
            description
            coverImage { large medium }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
          }
        }
        
        # Top rated
        topRated: Page(perPage: 4) {
          media(type: MANGA, sort: SCORE_DESC, isAdult: false) {
            id
            title { romaji english native }
            description
            coverImage { large medium }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
          }
        }
        
        # Trending (recently popular)
        trending: Page(perPage: 4) {
          media(type: MANGA, sort: TRENDING_DESC, isAdult: false) {
            id
            title { romaji english native }
            description
            coverImage { large medium }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
          }
        }
        
        # Seasonal (current season)
        seasonal: Page(perPage: 4) {
          media(type: MANGA, season: ${_getCurrentSeason(DateTime.now())}, seasonYear: ${DateTime.now().year}, isAdult: false) {
            id
            title { romaji english native }
            description
            coverImage { large medium }
            bannerImage
            genres
            format
            status
            chapters
            averageScore
            meanScore
            popularity
            favourites
          }
        }
      }
    ''';

    try {
      // Rate limiting
      if (_lastRequestTime != null) {
        final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
        if (timeSinceLastRequest < _minRequestInterval) {
          final waitTime = _minRequestInterval - timeSinceLastRequest;
          debugPrint('Rate limiting: waiting ${waitTime.inMilliseconds}ms');
          await Future.delayed(waitTime);
        }
      }
      _lastRequestTime = DateTime.now();

      debugPrint('Fetching mixed feed with single query');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['errors'] != null) {
          debugPrint('GraphQL errors: ${data['errors']}');
          return _getEmptyMixedFeed();
        }
        
        final result = {
          'featured': _parseMangaList(data['data']['featured']['media']),
          'popular': _parseMangaList(data['data']['popular']['media']),
          'newReleases': _parseMangaList(data['data']['newReleases']['media']),
          'topRated': _parseMangaList(data['data']['topRated']['media']),
          'trending': _parseMangaList(data['data']['trending']['media']),
          'seasonal': _parseMangaList(data['data']['seasonal']['media']),
        };
        
        // Cache the result
        _mixedFeedCache = result;
        debugPrint('Mixed feed cached successfully');
        return result;
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        return _getEmptyMixedFeed();
      }
    } catch (e) {
      debugPrint('Error fetching mixed feed: $e');
      return _getEmptyMixedFeed();
    }
  }

  /// Parse manga list from GraphQL response
  List<Manga> _parseMangaList(List<dynamic> mediaList) {
    return mediaList.map((media) => Manga.fromJson(media)).toList();
  }

  /// Get empty mixed feed as fallback
  Map<String, List<Manga>> _getEmptyMixedFeed() {
    return {
      'featured': [],
      'popular': [],
      'newReleases': [],
      'topRated': [],
      'trending': [],
      'seasonal': [],
    };
  }

  /// Clear mixed feed cache
  static void clearMixedFeedCache() {
    _mixedFeedCache.clear();
    debugPrint('Mixed feed cache cleared');
  }

  /// Clear search cache
  static void clearSearchCache() {
    _searchCache.clear();
    debugPrint('Search cache cleared');
  }

  /// Clear all caches
  static void clearAllCaches() {
    _mixedFeedCache.clear();
    _searchCache.clear();
    _externalLinksCache.clear();
    debugPrint('All caches cleared');
  }
}
