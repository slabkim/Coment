import 'anilist_manga.dart';

/// Unified comic model using AniList API for comic data
class ComicItem {
  // Core identifiers
  final String id; // AniList ID as string
  final int anilistId;
  final String? mangadexId;

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

  // MangaDex specific data
  final String? mangadexCoverUrl;

  // UI flags (computed based on data)
  final bool? isFeatured;
  final bool? isNewRelease;
  final bool? isPopular;

  const ComicItem({
    required this.id,
    required this.anilistId,
    this.mangadexId,
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
    this.mangadexCoverUrl,
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

  /// Create ComicItem from raw JSON (Firebase or other sources)
  factory ComicItem.fromJson(Map<String, dynamic> json) {
    return ComicItem(
      id: json['id']?.toString() ?? '',
      anilistId: json['anilistId'] ?? int.tryParse(json['id'].toString()) ?? 0,
      mangadexId: json['mangadexId'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      alternativeTitles: (json['alternativeTitles'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      author: json['author'],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      chapters: json['chapters'] is int ? json['chapters'] : int.tryParse('${json['chapters']}'),
      format: json['format'],
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'] is int 
          ? json['ratingCount'] 
          : int.tryParse('${json['ratingCount']}'),
      releaseYear: json['releaseYear'] is int 
          ? json['releaseYear'] 
          : int.tryParse('${json['releaseYear']}'),
      synopsis: json['synopsis'],
      themes: (json['themes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      type: json['type'],
      status: json['status'],
      popularity: json['popularity'] is int 
          ? json['popularity'] 
          : int.tryParse('${json['popularity']}'),
      favourites: json['favourites'] is int 
          ? json['favourites'] 
          : int.tryParse('${json['favourites']}'),
      isCompleted: json['isCompleted'] == true,
      mangadexCoverUrl: json['mangadexCoverUrl'],
      isFeatured: json['isFeatured'],
      isNewRelease: json['isNewRelease'],
      isPopular: json['isPopular'],
    );
  }

  /// Merge existing comic with new data
  ComicItem copyWith({
    String? id,
    int? anilistId,
    String? mangadexId,
    String? title,
    String? description,
    String? imageUrl,
    List<String>? alternativeTitles,
    String? author,
    List<String>? categories,
    int? chapters,
    String? format,
    double? rating,
    int? ratingCount,
    int? releaseYear,
    String? synopsis,
    List<String>? themes,
    String? type,
    String? status,
    int? popularity,
    int? favourites,
    bool? isCompleted,
    String? mangadexCoverUrl,
    bool? isFeatured,
    bool? isNewRelease,
    bool? isPopular,
  }) {
    return ComicItem(
      id: id ?? this.id,
      anilistId: anilistId ?? this.anilistId,
      mangadexId: mangadexId ?? this.mangadexId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      alternativeTitles: alternativeTitles ?? this.alternativeTitles,
      author: author ?? this.author,
      categories: categories ?? this.categories,
      chapters: chapters ?? this.chapters,
      format: format ?? this.format,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      releaseYear: releaseYear ?? this.releaseYear,
      synopsis: synopsis ?? this.synopsis,
      themes: themes ?? this.themes,
      type: type ?? this.type,
      status: status ?? this.status,
      popularity: popularity ?? this.popularity,
      favourites: favourites ?? this.favourites,
      isCompleted: isCompleted ?? this.isCompleted,
      mangadexCoverUrl: mangadexCoverUrl ?? this.mangadexCoverUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      isNewRelease: isNewRelease ?? this.isNewRelease,
      isPopular: isPopular ?? this.isPopular,
    );
  }

  /// Convert ComicItem back to JSON (Firestore compatibility)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anilistId': anilistId,
      'mangadexId': mangadexId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      if (alternativeTitles != null) 'alternativeTitles': alternativeTitles,
      if (author != null) 'author': author,
      'categories': categories,
      if (chapters != null) 'chapters': chapters,
      if (format != null) 'format': format,
      if (rating != null) 'rating': rating,
      if (ratingCount != null) 'ratingCount': ratingCount,
      if (releaseYear != null) 'releaseYear': releaseYear,
      if (synopsis != null) 'synopsis': synopsis,
      if (themes != null) 'themes': themes,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (popularity != null) 'popularity': popularity,
      if (favourites != null) 'favourites': favourites,
      'isCompleted': isCompleted,
      if (mangadexCoverUrl != null) 'mangadexCoverUrl': mangadexCoverUrl,
      if (isFeatured != null) 'isFeatured': isFeatured,
      if (isNewRelease != null) 'isNewRelease': isNewRelease,
      if (isPopular != null) 'isPopular': isPopular,
    };
  }

  /// Create ComicItem from combined data sources
  factory ComicItem.merge({
    required AniListManga anilistManga,
    Map<String, dynamic>? firebaseData,
    Map<String, dynamic>? mangadexData,
  }) {
    var comic = ComicItem.fromAniList(anilistManga);

    if (firebaseData != null) {
      comic = comic.copyWith(
        title: firebaseData['title'] ?? comic.title,
        description: firebaseData['description'] ?? comic.description,
        imageUrl: firebaseData['imageUrl'] ?? comic.imageUrl,
        alternativeTitles: (firebaseData['alternativeTitles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            comic.alternativeTitles,
        author: firebaseData['author'] ?? comic.author,
        categories: (firebaseData['categories'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            comic.categories,
        chapters: firebaseData['chapters'] ?? comic.chapters,
        format: firebaseData['format'] ?? comic.format,
        rating: (firebaseData['rating'] as num?)?.toDouble() ?? comic.rating,
        ratingCount: firebaseData['ratingCount'] ?? comic.ratingCount,
        releaseYear: firebaseData['releaseYear'] ?? comic.releaseYear,
        synopsis: firebaseData['synopsis'] ?? comic.synopsis,
        themes: (firebaseData['themes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            comic.themes,
        type: firebaseData['type'] ?? comic.type,
        status: firebaseData['status'] ?? comic.status,
        popularity: firebaseData['popularity'] ?? comic.popularity,
        favourites: firebaseData['favourites'] ?? comic.favourites,
        isCompleted: firebaseData['isCompleted'] ?? comic.isCompleted,
        isFeatured: firebaseData['isFeatured'] ?? comic.isFeatured,
        isNewRelease: firebaseData['isNewRelease'] ?? comic.isNewRelease,
        isPopular: firebaseData['isPopular'] ?? comic.isPopular,
      );
    }

    if (mangadexData != null) {
      comic = comic.copyWith(
        mangadexId: mangadexData['id'],
        mangadexCoverUrl: mangadexData['attributes']?['fileName'],
      );
    }

    return comic;
  }

  /// Convert to Nandogami legacy model (for existing UI components)
  Map<String, dynamic> toLegacyJson() {
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
      'rating': rating,
      'ratingCount': ratingCount,
      'releaseYear': releaseYear,
      'synopsis': synopsis,
      'themes': themes,
      'type': type,
      'status': status,
      'popularity': popularity,
      'favourites': favourites,
      'isCompleted': isCompleted,
      'isFeatured': isFeatured,
      'isNewRelease': isNewRelease,
      'isPopular': isPopular,
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
      mangadexId: null,
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
      mangadexCoverUrl: null,
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
    // Popular jika nilai popularity tinggi
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
    return 'ComicItem(id: $id, title: $title, anilistId: $anilistId, mangadexId: $mangadexId)';
  }
}
