import 'anilist_manga.dart';

/// Unified comic model using AniList API for comic data
class ComicItem {
  // Core identifiers
  final String id; // AniList ID as string
  final int anilistId;

  // Basic info (primarily from AniList)
  final String title;
  final String description;
  final String imageUrl;
  final List<String>? alternativeTitles;
  final String? author;
  final List<String> categories; // genres
  final int? chapters;
  final String? format;
  final double? rating;
  final int? ratingCount;
  final int? releaseYear;
  final String? synopsis;
  final List<String>? themes;
  final String? type;
  final String? status;

  // Additional metadata
  final int? popularity;
  final int? favourites;
  final bool isCompleted;

  // UI flags (computed based on data)
  final bool? isFeatured;
  final bool? isNewRelease;
  final bool? isPopular;

  const ComicItem({
    required this.id,
    required this.anilistId,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.alternativeTitles,
    this.author,
    required this.categories,
    this.chapters,
    this.format,
    this.rating,
    this.ratingCount,
    this.releaseYear,
    this.synopsis,
    this.themes,
    this.type,
    this.status,
    this.popularity,
    this.favourites,
    required this.isCompleted,
    this.isFeatured,
    this.isNewRelease,
    this.isPopular,
  });

  /// Create ComicItem from AniList data only
  factory ComicItem.fromAniList(AniListManga anilistManga) {
    return ComicItem(
      id: anilistManga.id.toString(),
      anilistId: anilistManga.id,
      title: anilistManga.bestTitle,
      description: anilistManga.cleanDescription ?? '',
      imageUrl: anilistManga.coverImage.bestImage ?? '',
      alternativeTitles: _extractAlternativeTitles(anilistManga.title),
      author: anilistManga.author,
      categories: anilistManga.genres,
      chapters: anilistManga.chapters,
      format: 'MANGA',
      rating: anilistManga.formattedScore,
      ratingCount: anilistManga.favourites,
      releaseYear: anilistManga.publicationYear,
      synopsis: anilistManga.cleanDescription,
      themes: anilistManga.tagNames,
      type: 'MANGA',
      status: anilistManga.status,
      popularity: anilistManga.popularity,
      favourites: anilistManga.favourites,
      isCompleted: anilistManga.isCompleted,
      // Computed UI flags
      isFeatured: _computeIsFeatured(anilistManga),
      isNewRelease: _computeIsNewRelease(anilistManga),
      isPopular: _computeIsPopular(anilistManga),
    );
  }

  /// Create ComicItem from Manga model (SimpleAniListService)
  factory ComicItem.fromManga(dynamic manga) {
    return ComicItem(
      id: manga.id.toString(),
      anilistId: manga.id,
      title: manga.title ?? manga.englishTitle ?? manga.nativeTitle ?? 'Unknown',
      description: manga.description ?? '',
      imageUrl: manga.coverImage ?? '',
      alternativeTitles: [
        if (manga.englishTitle != null) manga.englishTitle!,
        if (manga.nativeTitle != null) manga.nativeTitle!,
      ],
      author: null, // Not available in Manga model
      categories: manga.genres ?? [],
      chapters: manga.chapters,
      format: manga.format ?? 'MANGA',
      rating: manga.averageScore?.toDouble(),
      ratingCount: manga.favourites,
      releaseYear: manga.seasonYear,
      synopsis: manga.description,
      themes: manga.tags,
      type: manga.format ?? 'MANGA',
      status: manga.status,
      popularity: manga.popularity,
      favourites: manga.favourites,
      isCompleted: manga.status == 'FINISHED',
      // Computed UI flags
      isFeatured: manga.favourites != null && manga.favourites! > 1000,
      isNewRelease: manga.seasonYear != null && manga.seasonYear! >= DateTime.now().year - 1,
      isPopular: manga.popularity != null && manga.popularity! > 5000,
    );
  }


  /// Convert to legacy NandogamiItem for compatibility
  Map<String, dynamic> toNandogamiJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'alternativeTitles': alternativeTitles,
      'author': author,
      'categories': categories,
      'chapters': chapters,
      'format': format,
      'isFeatured': isFeatured,
      'isNewRelease': isNewRelease,
      'isPopular': isPopular,
      'rating': rating,
      'ratingCount': ratingCount,
      'release_year': releaseYear,
      'synopsis': synopsis,
      'themes': themes,
      'type': type,
    };
  }

  /// Create ComicItem from Jikan API data
  factory ComicItem.fromJikan(dynamic jikanManga) {
    final genres = (jikanManga.genres as List<dynamic>?) ?? [];
    final genreNames = genres.map((g) => g.name as String).toList();
    
    final themes = (jikanManga.themes as List<dynamic>?) ?? [];
    final themeNames = themes.map((t) => t.name as String).toList();
    
    return ComicItem(
      id: 'jikan_${jikanManga.malId}',
      anilistId: jikanManga.malId,
      title: jikanManga.title ?? 'Unknown Title',
      description: jikanManga.synopsis ?? 'No description available',
      imageUrl: jikanManga.imageUrl ?? 'https://via.placeholder.com/300x400?text=No+Image',
      alternativeTitles: _getJikanAlternativeTitles(jikanManga),
      author: 'Unknown Author', // Jikan doesn't provide author in basic data
      categories: genreNames,
      chapters: jikanManga.chapters,
      format: jikanManga.type,
      rating: jikanManga.score?.toDouble(),
      ratingCount: jikanManga.scoredBy,
      releaseYear: _getJikanReleaseYear(jikanManga),
      synopsis: jikanManga.synopsis,
      themes: themeNames.isNotEmpty ? themeNames : null,
      type: jikanManga.type,
      status: jikanManga.status,
      popularity: jikanManga.popularity,
      favourites: jikanManga.favorites,
      isCompleted: jikanManga.status == 'Finished',
      isFeatured: jikanManga.rank != null && jikanManga.rank! <= 10,
      isNewRelease: _isJikanNewRelease(jikanManga),
      isPopular: jikanManga.popularity != null && jikanManga.popularity! <= 100,
    );
  }

  // Helper methods for extracting data

  static List<String>? _extractAlternativeTitles(AniListTitle title) {
    final titles = <String>[];
    
    if (title.english?.isNotEmpty == true) titles.add(title.english!);
    if (title.romaji?.isNotEmpty == true) titles.add(title.romaji!);
    if (title.native?.isNotEmpty == true) titles.add(title.native!);
    
    return titles.isNotEmpty ? titles : null;
  }

  static bool _computeIsFeatured(AniListManga manga) {
    // Featured if high score and high popularity
    return (manga.averageScore ?? 0) >= 80 && (manga.popularity ?? 0) >= 10000;
  }

  static bool _computeIsNewRelease(AniListManga manga) {
    // New release if started within last 2 years
    final now = DateTime.now();
    final startDate = manga.startDate?.toDateTime();
    
    if (startDate == null) return false;
    
    final difference = now.difference(startDate);
    return difference.inDays <= 730; // 2 years
  }

  static bool _computeIsPopular(AniListManga manga) {
    // Popular if high popularity score
    return (manga.popularity ?? 0) >= 5000;
  }

  // Helper methods for Jikan data

  static List<String>? _getJikanAlternativeTitles(dynamic jikanManga) {
    final titles = <String>[];
    
    if (jikanManga.titleEnglish?.isNotEmpty == true) {
      titles.add(jikanManga.titleEnglish);
    }
    
    if (jikanManga.titleSynonyms != null) {
      titles.addAll(jikanManga.titleSynonyms.cast<String>());
    }
    
    return titles.isNotEmpty ? titles : null;
  }

  static int? _getJikanReleaseYear(dynamic jikanManga) {
    if (jikanManga.published?.from == null) return null;
    
    try {
      return int.tryParse(jikanManga.published.from.split('-')[0]);
    } catch (e) {
      return null;
    }
  }

  static bool _isJikanNewRelease(dynamic jikanManga) {
    if (jikanManga.published?.from == null) return false;
    
    try {
      final publishedYear = int.tryParse(jikanManga.published.from.split('-')[0]);
      if (publishedYear == null) return false;
      
      final currentYear = DateTime.now().year;
      return currentYear - publishedYear <= 2;
    } catch (e) {
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComicItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ComicItem(id: $id, title: $title, anilistId: $anilistId)';
  }
}
