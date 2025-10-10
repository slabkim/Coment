class ComicItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String>? alternativeTitles;
  final String? author;
  final List<String>? categories;
  final int? chapters;
  final String? format;
  final bool? isFeatured;
  final bool? isNewRelease;
  final bool? isPopular;
  final double? rating;
  final int? ratingCount;
  final int? releaseYear;
  final String? synopsis;
  final List<String>? themes;
  final String? type;

  const ComicItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.alternativeTitles,
    this.author,
    this.categories,
    this.chapters,
    this.format,
    this.isFeatured,
    this.isNewRelease,
    this.isPopular,
    this.rating,
    this.ratingCount,
    this.releaseYear,
    this.synopsis,
    this.themes,
    this.type,
  });

  factory ComicItem.fromJson(Map<String, dynamic> j, [String? docId]) =>
      ComicItem(
        id: docId ?? j['id'].toString(),
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        imageUrl: j['imageUrl'] ?? '',
        alternativeTitles: (j['alternativeTitles'] as List<dynamic>?)
            ?.cast<String>(),
        author: j['author'],
        categories: (j['categories'] as List<dynamic>?)?.cast<String>(),
        chapters: j['chapters'],
        format: j['format'],
        isFeatured: j['isFeatured'],
        isNewRelease: j['isNewRelease'],
        isPopular: j['isPopular'],
        rating: j['rating']?.toDouble(),
        ratingCount: j['ratingCount'],
        releaseYear: j['release_year'],
        synopsis: j['synopsis'],
        themes: (j['themes'] as List<dynamic>?)?.cast<String>(),
        type: j['type'],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    if (alternativeTitles != null) 'alternativeTitles': alternativeTitles,
    if (author != null) 'author': author,
    if (categories != null) 'categories': categories,
    if (chapters != null) 'chapters': chapters,
    if (format != null) 'format': format,
    if (isFeatured != null) 'isFeatured': isFeatured,
    if (isNewRelease != null) 'isNewRelease': isNewRelease,
    if (isPopular != null) 'isPopular': isPopular,
    if (rating != null) 'rating': rating,
    if (ratingCount != null) 'ratingCount': ratingCount,
    if (releaseYear != null) 'release_year': releaseYear,
    if (synopsis != null) 'synopsis': synopsis,
    if (themes != null) 'themes': themes,
    if (type != null) 'type': type,
  };
}
