import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anilist_manga.dart';

class AniListService {
  static const String _baseUrl = 'https://graphql.anilist.co';
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // GraphQL query untuk mendapatkan daftar manga populer
  static const String _popularMangaQuery = '''
    query (\$page: Int, \$perPage: Int, \$sort: [MediaSort]) {
      Page(page: \$page, perPage: \$perPage) {
        pageInfo {
          total
          currentPage
          lastPage
          hasNextPage
        }
        media(type: MANGA, sort: \$sort, format: MANGA, isAdult: false) {
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
          status
          chapters
          volumes
          averageScore
          popularity
          favourites
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
          staff {
            edges {
              role
              node {
                name {
                  full
                }
              }
            }
          }
          studios {
            nodes {
              name
            }
          }
        }
      }
    }
  ''';

  // GraphQL query untuk mencari manga
  static const String _searchMangaQuery = '''
    query (\$search: String, \$page: Int, \$perPage: Int) {
      Page(page: \$page, perPage: \$perPage) {
        pageInfo {
          total
          currentPage
          lastPage
          hasNextPage
        }
        media(type: MANGA, search: \$search, format: MANGA, isAdult: false) {
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
          status
          chapters
          volumes
          averageScore
          popularity
          favourites
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
          staff {
            edges {
              role
              node {
                name {
                  full
                }
              }
            }
          }
        }
      }
    }
  ''';

  // GraphQL query untuk mendapatkan detail manga berdasarkan ID
  static const String _mangaDetailQuery = '''
    query (\$id: Int) {
      Media(id: \$id, type: MANGA, isAdult: false) {
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
          description
        }
        status
        chapters
        volumes
        averageScore
        popularity
        favourites
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
        staff {
          edges {
            role
            node {
              name {
                full
              }
            }
          }
        }
        studios {
          nodes {
            name
          }
        }
        relations {
          edges {
            relationType
            node {
              id
              title {
                romaji
                english
              }
              coverImage {
                medium
              }
            }
          }
        }
        recommendations {
          nodes {
            mediaRecommendation {
              id
              title {
                romaji
                english
              }
              coverImage {
                medium
              }
            }
          }
        }
      }
    }
  ''';

  /// Mengambil daftar manga populer
  Future<AniListResponse> getPopularManga({
    int page = 1,
    int perPage = 20,
  }) async {
    return _executeQuery(
      _popularMangaQuery,
      variables: {
        'page': page,
        'perPage': perPage,
        'sort': ['POPULARITY_DESC'],
      },
    );
  }

  /// Mengambil daftar manga trending
  Future<AniListResponse> getTrendingManga({
    int page = 1,
    int perPage = 20,
  }) async {
    return _executeQuery(
      _popularMangaQuery,
      variables: {
        'page': page,
        'perPage': perPage,
        'sort': ['TRENDING_DESC'],
      },
    );
  }

  /// Mengambil daftar manga berdasarkan rating tertinggi
  Future<AniListResponse> getTopRatedManga({
    int page = 1,
    int perPage = 20,
  }) async {
    return _executeQuery(
      _popularMangaQuery,
      variables: {
        'page': page,
        'perPage': perPage,
        'sort': ['SCORE_DESC'],
      },
    );
  }

  /// Mengambil daftar manga terbaru
  Future<AniListResponse> getNewManga({
    int page = 1,
    int perPage = 20,
  }) async {
    return _executeQuery(
      _popularMangaQuery,
      variables: {
        'page': page,
        'perPage': perPage,
        'sort': ['START_DATE_DESC'],
      },
    );
  }

  /// Mencari manga berdasarkan query
  Future<AniListResponse> searchManga(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    return _executeQuery(
      _searchMangaQuery,
      variables: {
        'search': query,
        'page': page,
        'perPage': perPage,
      },
    );
  }

  /// Mengambil detail manga berdasarkan ID
  Future<AniListManga> getMangaDetail(int id) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'query': _mangaDetailQuery,
          'variables': {'id': id},
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['errors'] != null) {
          throw Exception('AniList API Error: ${jsonData['errors']}');
        }

        // Pastikan data tidak null
        final data = jsonData['data'];
        if (data == null) {
          throw Exception('AniList API returned null data');
        }
        
        final media = data['Media'];
        if (media == null) {
          throw Exception('Manga with ID $id not found');
        }

        return AniListManga.fromJson(media);
      } else {
        throw Exception(
          'Failed to fetch manga detail from AniList: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch comic detail: $e');
    }
  }

  /// Mengambil manga berdasarkan genre
  Future<AniListResponse> getMangaByGenre(
    String genre, {
    int page = 1,
    int perPage = 20,
  }) async {
    const query = '''
      query (\$genre: String, \$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo {
            total
            currentPage
            lastPage
            hasNextPage
          }
          media(type: MANGA, genre: \$genre, format: MANGA, isAdult: false) {
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
            genres
            averageScore
            popularity
            status
            chapters
          }
        }
      }
    ''';

    return _executeQuery(
      query,
      variables: {
        'genre': genre,
        'page': page,
        'perPage': perPage,
      },
    );
  }

  /// Method internal untuk mengeksekusi GraphQL query
  Future<AniListResponse> _executeQuery(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'query': query,
          'variables': variables ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['errors'] != null) {
          throw Exception('AniList API Error: ${jsonData['errors']}');
        }

        // Pastikan data tidak null
        final data = jsonData['data'];
        if (data == null) {
          throw Exception('AniList API returned null data');
        }
        
        final page = data['Page'];
        if (page == null) {
          throw Exception('AniList API returned null Page data');
        }

        return AniListResponse.fromJson(page);
      } else {
        throw Exception(
          'Failed to fetch data from AniList: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('AniList Service Error: $e');
    }
  }
}
