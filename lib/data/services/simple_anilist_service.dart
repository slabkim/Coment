import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/manga.dart';
import '../models/external_link.dart';

class SimpleAniListService {
  static const String _baseUrl = 'https://graphql.anilist.co';
  static const int _perPage = 20; // Increased for better data loading
  
  // Rate limiting (increased to avoid 429 errors)
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(milliseconds: 4000); // 4 seconds between requests to avoid rate limiting
  
  // Cache for genre queries to reduce API calls
  static final Map<String, List<Manga>> _genreCache = {};
  static final Map<String, DateTime> _genreCacheTime = {};
  static const Duration _genreCacheDuration = Duration(minutes: 15); // Cache for 15 minutes
  
  // Cache for external links to reduce API calls
  static final Map<int, List<ExternalLink>> _externalLinksCache = {};
  
  // Cache for mixed feed data with timestamp
  static Map<String, List<Manga>> _mixedFeedCache = {};
  static DateTime? _mixedFeedCacheTime;
  static const Duration _mixedFeedCacheDuration = Duration(minutes: 30); // Cache for 30 minutes
  
  // Cache for search results with expiry
  static final Map<String, List<Manga>> _searchCache = {};
  static final Map<String, DateTime> _searchCacheTime = {};
  static const Duration _searchCacheDuration = Duration(minutes: 10); // Cache for 10 minutes

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
            trailer {
              id
              site
              thumbnail
            }
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
            trailer {
              id
              site
              thumbnail
            }
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
            trailer {
              id
              site
              thumbnail
            }
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
            trailer {
              id
              site
              thumbnail
            }
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// Trending Now - sort: FAVOURITES_DESC (most favorited manga)
  Future<List<Manga>> getTrendingNow() async {
    final query = '''
      query {
        Page(perPage: $_perPage) {
          media(type: MANGA, sort: FAVOURITES_DESC, isAdult: false) {
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
            trailer {
              id
              site
              thumbnail
            }
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
            trailer {
              id
              site
              thumbnail
            }
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// Hidden Gems - high rated but underrated manga (score >= 75, popularity < 50000)
  Future<List<Manga>> getHiddenGems() async {
    final query = '''
      query {
        Page(perPage: $_perPage) {
          media(
            type: MANGA, 
            sort: SCORE_DESC, 
            averageScore_greater: 75,
            popularity_lesser: 50000,
            isAdult: false
          ) {
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
            trailer {
              id
              site
              thumbnail
            }
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
            trailer {
              id
              site
              thumbnail
            }
          }
        }
      }
    ''';

    return _executeQuery(query);
  }

  /// Categories - berdasarkan genre/tag (ALL comic types: manga, manhwa, manhua, etc.)
  Future<List<Manga>> getMangaByGenres(List<String> genres) async {
    // Limit to max 3 genres to avoid overly specific queries returning 0 results
    final limitedGenres = genres.length > 3 ? genres.sublist(0, 3) : genres;
    
    if (limitedGenres.isEmpty) {
      debugPrint('No genres provided');
      return [];
    }
    
    // Check cache first
    final cacheKey = limitedGenres.join('|');
    if (_genreCache.containsKey(cacheKey) && _genreCacheTime.containsKey(cacheKey)) {
      final cacheAge = DateTime.now().difference(_genreCacheTime[cacheKey]!);
      if (cacheAge < _genreCacheDuration) {
        debugPrint('Using cached results for ${limitedGenres.join(", ")} (age: ${cacheAge.inMinutes}m)');
        return _genreCache[cacheKey]!;
      } else {
        // Cache expired
        _genreCache.remove(cacheKey);
        _genreCacheTime.remove(cacheKey);
      }
    }
    
    final genreString = limitedGenres.map((g) => '"$g"').join(',');
    
    // Official AniList genres
    final officialGenres = ['Action', 'Adventure', 'Comedy', 'Drama', 'Ecchi', 'Fantasy', 
                            'Horror', 'Mahou Shoujo', 'Mecha', 'Music', 'Mystery', 
                            'Psychological', 'Romance', 'Sci-Fi', 'Slice of Life', 
                            'Sports', 'Supernatural', 'Thriller'];
    
    // Determine if input contains genres or tags
    final hasGenre = limitedGenres.any((g) => officialGenres.contains(g));
    final hasTag = limitedGenres.any((g) => !officialGenres.contains(g));
    
    // Build filter parameters (simplified - single query for better performance)
    String genreTagFilter = '';
    if (hasGenre && !hasTag) {
      // Only genres
      genreTagFilter = 'genre_in: [$genreString],';
    } else if (!hasGenre && hasTag) {
      // Only tags
      genreTagFilter = 'tag_in: [$genreString],';
    } else if (hasGenre && hasTag) {
      // Mixed - separate them
      final genreList = limitedGenres.where((g) => officialGenres.contains(g)).toList();
      final tagList = limitedGenres.where((g) => !officialGenres.contains(g)).toList();
      final genreStr = genreList.map((g) => '"$g"').join(',');
      final tagStr = tagList.map((g) => '"$g"').join(',');
      genreTagFilter = 'genre_in: [$genreStr], tag_in: [$tagStr],';
    }
    
    // Simplified single query (no country filter to avoid timeout)
    final query = '''
      query {
        Page(perPage: 40) {
          media($genreTagFilter sort: POPULARITY_DESC, isAdult: false) {
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
            countryOfOrigin
            trailer { id site thumbnail }
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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'query': query}),
      ).timeout(const Duration(seconds: 15));  // Increased timeout

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['errors'] != null) {
          debugPrint('GraphQL Error for ${limitedGenres.join(", ")}: ${jsonData['errors']}');
          return [];
        }
        
        final media = jsonData['data']?['Page']?['media'] as List<dynamic>? ?? [];
        final comics = media.map((item) => Manga.fromJson(item)).toList();
        
        // Cache the results
        _genreCache[cacheKey] = comics;
        _genreCacheTime[cacheKey] = DateTime.now();
        
        final genreText = limitedGenres.join(", ");
        if (genres.length > 3) {
          debugPrint('Fetched ${comics.length} comics for $genreText (limited from ${genres.length} genres)');
        } else {
          debugPrint('Fetched ${comics.length} comics for $genreText');
        }
        return comics;
      } else if (response.statusCode == 429) {
        // Rate limited - wait and retry once
        debugPrint('Rate limited for ${limitedGenres.join(", ")}, waiting 5s before retry...');
        await Future.delayed(const Duration(seconds: 5));
        _lastRequestTime = DateTime.now();
        
        // Retry once
        final retryResponse = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({'query': query}),
        ).timeout(const Duration(seconds: 15));
        
        if (retryResponse.statusCode == 200) {
          final jsonData = json.decode(retryResponse.body);
          if (jsonData['errors'] == null) {
            final media = jsonData['data']?['Page']?['media'] as List<dynamic>? ?? [];
            final comics = media.map((item) => Manga.fromJson(item)).toList();
            
            // Cache the results
            _genreCache[cacheKey] = comics;
            _genreCacheTime[cacheKey] = DateTime.now();
            
            debugPrint('Retry successful: Fetched ${comics.length} comics for ${limitedGenres.join(", ")}');
            return comics;
          }
        }
        debugPrint('Retry failed for ${limitedGenres.join(", ")}');
        return [];
      } else {
        debugPrint('HTTP Error ${response.statusCode} for ${limitedGenres.join(", ")}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching comics for ${limitedGenres.join(", ")}: $e');
      return [];
    }
  }

  /// Get curated common genres only (simplified for better UX)
  Future<List<String>> getAvailableGenres() async {
    // Curated list of common and popular genres/tags
    final commonCategories = [
      // Official Genres (popular ones)
      'Action',
      'Adventure',
      'Comedy',
      'Drama',
      'Ecchi',
      'Fantasy',
      'Horror',
      'Mecha',
      'Music',
      'Mystery',
      'Psychological',
      'Romance',
      'Sci-Fi',
      'Slice of Life',
      'Sports',
      'Supernatural',
      'Thriller',
      
      // Popular Tags (commonly used)
      'Isekai',
      'Reincarnation',
      'Magic',
      'School',
      'Historical',
      'Military',
      'Martial Arts',
      'Demons',
      'Vampire',
      'Zombie',
      'Post-Apocalyptic',
      'Time Travel',
      'Survival',
      'Gore',
    ];
    
    // Sort alphabetically for better UX
    commonCategories.sort((a, b) => a.compareTo(b));
    
    debugPrint('Loaded ${commonCategories.length} common categories');
    return commonCategories;
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
          // Rate limited - use exponential backoff with longer delays
          final waitSeconds = attempt * 4; // 4, 8, 12 seconds
          debugPrint('Rate limited (429), waiting $waitSeconds seconds');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: waitSeconds));
            // Reset last request time to prevent immediate next request
            _lastRequestTime = DateTime.now();
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
        Media(id: $id) {
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
          trailer {
            id
            site
            thumbnail
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
        Media(id: $id) {
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
          trailer {
            id
            site
            thumbnail
          }
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
        Media(id: $id) {
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
        Media(id: $id) {
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
        Media(id: $id) {
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
        Media(id: $id) {
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

  /// Search manga with caching and popularity sorting
  /// Fuzzy matching is handled client-side in ItemProvider to avoid rate limiting
  Future<List<Manga>> searchManga(String query) async {
    // Check cache first with expiry
    final cacheKey = query.toLowerCase().trim();
    if (_searchCache.containsKey(cacheKey) && _searchCacheTime.containsKey(cacheKey)) {
      final cacheAge = DateTime.now().difference(_searchCacheTime[cacheKey]!);
      if (cacheAge < _searchCacheDuration) {
        debugPrint('Using cached search results for: $query (age: ${cacheAge.inMinutes}m)');
        return _searchCache[cacheKey]!;
      } else {
        // Cache expired, remove it
        _searchCache.remove(cacheKey);
        _searchCacheTime.remove(cacheKey);
      }
    }

    // Single API call with popularity sorting
    final searchQuery = '''
      query {
        Page(perPage: $_perPage) {
          media(type: MANGA, search: "$query", sort: POPULARITY_DESC, isAdult: false) {
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
            trailer {
              id
              site
              thumbnail
            }
          }
        }
      }
    ''';

    try {
      final results = await _executeQuery(searchQuery);
      
      // Cache the results with timestamp
      _searchCache[cacheKey] = results;
      _searchCacheTime[cacheKey] = DateTime.now();
      debugPrint('Cached search results for: $query (${results.length} items)');
      return results;
    } catch (e) {
      debugPrint('Error searching manga: $e');
      return [];
    }
  }

  /// Get mixed feed for home page sections using single GraphQL query
  Future<Map<String, List<Manga>>> getMixedFeed() async {
    // Check cache first with expiry
    if (_mixedFeedCache.isNotEmpty && _mixedFeedCacheTime != null) {
      final cacheAge = DateTime.now().difference(_mixedFeedCacheTime!);
      if (cacheAge < _mixedFeedCacheDuration) {
        debugPrint('Using cached mixed feed data (age: ${cacheAge.inMinutes}m)');
        return _mixedFeedCache;
      } else {
        // Cache expired
        debugPrint('Mixed feed cache expired, refreshing...');
        _mixedFeedCache.clear();
        _mixedFeedCacheTime = null;
      }
    }

    final query = '''
      query {
        # Featured titles (predefined IDs - 14 high-quality manga - show ALL)
        featured: Page(perPage: 20) {
          media(id_in: [119257, 53390, 105398, 85934, 109957, 101517, 87216, 169355, 120980, 137714, 187944, 97216, 173062, 108428], type: MANGA, isAdult: false) {
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
            trailer { id site thumbnail }
          }
        }
        
        # Popular manga
        popular: Page(perPage: 20) {
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
            trailer { id site thumbnail }
          }
        }
        
        # New releases
        newReleases: Page(perPage: 20) {
          media(type: MANGA, sort: START_DATE_DESC, isAdult: false) {
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
            trailer { id site thumbnail }
          }
        }
        
        # Top rated
        topRated: Page(perPage: 20) {
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
            trailer { id site thumbnail }
          }
        }
        
        # Trending (recently popular)
        trending: Page(perPage: 20) {
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
            trailer { id site thumbnail }
          }
        }
        
        # Completed Manga (high-rated finished series)
        completed: Page(perPage: 20) {
          media(type: MANGA, status: FINISHED, sort: SCORE_DESC, averageScore_greater: 75, isAdult: false) {
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
            trailer { id site thumbnail }
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
          'completed': _parseMangaList(data['data']['completed']['media']),
        };
        
        // Cache the result with timestamp
        _mixedFeedCache = result;
        _mixedFeedCacheTime = DateTime.now();
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
      'completed': [],
    };
  }

  /// Clear mixed feed cache
  static void clearMixedFeedCache() {
    _mixedFeedCache.clear();
    _mixedFeedCacheTime = null;
    debugPrint('Mixed feed cache cleared');
  }

  /// Clear search cache
  static void clearSearchCache() {
    _searchCache.clear();
    _searchCacheTime.clear();
    debugPrint('Search cache cleared');
  }

  /// Clear genre cache
  static void clearGenreCache() {
    _genreCache.clear();
    _genreCacheTime.clear();
    debugPrint('Genre cache cleared');
  }
  
  /// Clear all caches
  static void clearAllCaches() {
    _mixedFeedCache.clear();
    _mixedFeedCacheTime = null;
    _searchCache.clear();
    _searchCacheTime.clear();
    _externalLinksCache.clear();
    _genreCache.clear();
    _genreCacheTime.clear();
    debugPrint('All caches cleared');
  }
}
