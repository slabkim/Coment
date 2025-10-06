import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga.dart';

class AniListMangaService {
  static const String _baseUrl = 'https://graphql.anilist.co';
  static const int _perPage = 10;

  /// Fungsi reusable untuk fetch manga berdasarkan query parameters
  Future<List<Manga>> fetchMangaByQuery(Map<String, dynamic> queryParams) async {
    try {
      final query = _buildGraphQLQuery(queryParams);
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'query': query,
          'variables': queryParams,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['errors'] != null) {
          throw Exception('GraphQL Error: ${jsonData['errors']}');
        }
        final mangaResponse = MangaResponse.fromJson(jsonData);
        return mangaResponse.manga;
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch manga: $e');
    }
  }

  /// Featured Titles - menggunakan ID yang sudah ditentukan
  Future<List<Manga>> getFeaturedTitles() async {
    const featuredIds = [119257, 53390, 105398, 85934, 109957, 101517, 87216, 
                         169355, 120980, 137714, 187944, 97216, 173062, 108428];
    
    return fetchMangaByQuery({
      'ids': featuredIds,
      'perPage': _perPage,
    });
  }

  /// Categories - berdasarkan genre
  Future<List<Manga>> getMangaByGenres(List<String> genres) async {
    return fetchMangaByQuery({
      'genres': genres,
      'perPage': _perPage,
    });
  }

  /// Popular This Week - sort: TRENDING_DESC
  Future<List<Manga>> getPopularThisWeek() async {
    return fetchMangaByQuery({
      'sort': ['TRENDING_DESC'],
      'perPage': _perPage,
    });
  }

  /// New Releases - sort: START_DATE_DESC
  Future<List<Manga>> getNewReleases() async {
    return fetchMangaByQuery({
      'sort': ['START_DATE_DESC'],
      'perPage': _perPage,
    });
  }

  /// Top Rated - sort: SCORE_DESC
  Future<List<Manga>> getTopRated() async {
    return fetchMangaByQuery({
      'sort': ['SCORE_DESC'],
      'perPage': _perPage,
    });
  }

  /// Trending Now - kombinasi sort: [TRENDING_DESC, POPULARITY_DESC]
  Future<List<Manga>> getTrendingNow() async {
    return fetchMangaByQuery({
      'sort': ['TRENDING_DESC', 'POPULARITY_DESC'],
      'perPage': _perPage,
    });
  }

  /// Seasonal Manga - filter berdasarkan season dan seasonYear
  Future<List<Manga>> getSeasonalManga({String? season, int? seasonYear}) async {
    final currentDate = DateTime.now();
    final currentSeason = season ?? _getCurrentSeason(currentDate);
    final currentYear = seasonYear ?? currentDate.year;

    return fetchMangaByQuery({
      'season': currentSeason,
      'seasonYear': currentYear,
      'perPage': _perPage,
    });
  }

  /// Recently Added - sort: ID_DESC
  Future<List<Manga>> getRecentlyAdded() async {
    return fetchMangaByQuery({
      'sort': ['ID_DESC'],
      'perPage': _perPage,
    });
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

  /// Build GraphQL query berdasarkan parameters
  String _buildGraphQLQuery(Map<String, dynamic> params) {
    final hasIds = params.containsKey('ids') && params['ids'] != null;
    final hasGenres = params.containsKey('genres') && params['genres'] != null;
    final hasSort = params.containsKey('sort') && params['sort'] != null;
    final hasSeason = params.containsKey('season') && params['season'] != null;
    final hasSeasonYear = params.containsKey('seasonYear') && params['seasonYear'] != null;

    String whereClause = 'type: MANGA, format_not: NOVEL';
    
    if (hasIds) {
      final ids = params['ids'] as List<int>;
      whereClause += ', id_in: [${ids.join(',')}]';
    }
    
    if (hasGenres) {
      final genres = params['genres'] as List<String>;
      whereClause += ', genre_in: [${genres.map((g) => '"$g"').join(',')}]';
    }
    
    if (hasSeason) {
      whereClause += ', season: ${params['season']}';
    }
    
    if (hasSeasonYear) {
      whereClause += ', seasonYear: ${params['seasonYear']}';
    }

    String sortClause = '';
    if (hasSort) {
      final sorts = params['sort'] as List<String>;
      sortClause = ', sort: [${sorts.join(',')}]';
    }

    final perPage = params['perPage'] ?? _perPage;

    return '''
      query (\$page: Int) {
        Page(page: \$page, perPage: $perPage) {
          pageInfo {
            currentPage
            hasNextPage
            lastPage
            perPage
            total
          }
          media($whereClause$sortClause) {
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
            episodes
            duration
            source
            seasonYear
            season
            averageScore
            meanScore
            popularity
            favourites
            isAdult
            countryOfOrigin
            updatedAt
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
                  status
                }
              }
            }
            characters {
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
            staff {
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
      }
    ''';
  }

  /// Get current season berdasarkan tanggal
  String _getCurrentSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'SPRING';
    if (month >= 6 && month <= 8) return 'SUMMER';
    if (month >= 9 && month <= 11) return 'FALL';
    return 'WINTER';
  }
}
