import 'manga.dart';
import 'external_link.dart';

class NandogamiItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? coverImage;
  final String? bannerImage;
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
  
  // AniList specific fields
  final String? englishTitle;
  final String? nativeTitle;
  final List<String>? genres;
  final List<String>? tags;
  final String? status;
  final int? volumes;
  final String? source;
  final int? seasonYear;
  final String? season;
  final double? averageScore;
  final int? meanScore;
  final int? popularity;
  final int? favourites;
  final String? startDate;
  final String? endDate;
  final List<String>? synonyms;
  final List<MangaRelation>? relations;
  final List<MangaCharacter>? characters;
  final List<MangaStaff>? staff;
  final List<ExternalLink>? externalLinks;
  

  const NandogamiItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.coverImage,
    this.bannerImage,
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
    // AniList specific fields
    this.englishTitle,
    this.nativeTitle,
    this.genres,
    this.tags,
    this.status,
    this.volumes,
    this.source,
    this.seasonYear,
    this.season,
    this.averageScore,
    this.meanScore,
    this.popularity,
    this.favourites,
    this.startDate,
    this.endDate,
    this.synonyms,
    this.relations,
    this.characters,
    this.staff,
    this.externalLinks,
  });

  factory NandogamiItem.fromJson(Map<String, dynamic> j, [String? docId]) =>
      NandogamiItem(
        id: docId ?? j['id'].toString(),
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        imageUrl: j['imageUrl'] ?? '',
        coverImage: j['coverImage'],
        bannerImage: j['bannerImage'],
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
        // AniList specific fields
        englishTitle: j['englishTitle'],
        nativeTitle: j['nativeTitle'],
        genres: (j['genres'] as List<dynamic>?)?.cast<String>(),
        tags: (j['tags'] as List<dynamic>?)?.cast<String>(),
        status: j['status'],
        volumes: j['volumes'],
        source: j['source'],
        seasonYear: j['seasonYear'],
        season: j['season'],
        averageScore: j['averageScore']?.toDouble(),
        meanScore: j['meanScore'],
        popularity: j['popularity'],
        favourites: j['favourites'],
        startDate: j['startDate'],
        endDate: j['endDate'],
        synonyms: (j['synonyms'] as List<dynamic>?)?.cast<String>(),
        relations: (j['relations'] as List<dynamic>?)?.map((r) => MangaRelation.fromJson(r)).toList(),
        characters: (j['characters'] as List<dynamic>?)?.map((c) => MangaCharacter.fromJson(c)).toList(),
        staff: (j['staff'] as List<dynamic>?)?.map((s) => MangaStaff.fromJson(s)).toList(),
        externalLinks: (j['externalLinks'] as List<dynamic>?)?.map((l) => ExternalLink.fromJson(l)).toList(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    if (coverImage != null) 'coverImage': coverImage,
    if (bannerImage != null) 'bannerImage': bannerImage,
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
    // AniList specific fields
    if (englishTitle != null) 'englishTitle': englishTitle,
    if (nativeTitle != null) 'nativeTitle': nativeTitle,
    if (genres != null) 'genres': genres,
    if (tags != null) 'tags': tags,
    if (status != null) 'status': status,
    if (volumes != null) 'volumes': volumes,
    if (source != null) 'source': source,
    if (seasonYear != null) 'seasonYear': seasonYear,
    if (season != null) 'season': season,
    if (averageScore != null) 'averageScore': averageScore,
    if (meanScore != null) 'meanScore': meanScore,
    if (popularity != null) 'popularity': popularity,
    if (favourites != null) 'favourites': favourites,
    if (startDate != null) 'startDate': startDate,
    if (endDate != null) 'endDate': endDate,
    if (synonyms != null) 'synonyms': synonyms,
    if (relations != null) 'relations': relations?.map((r) => r.toJson()).toList(),
    if (characters != null) 'characters': characters?.map((c) => c.toJson()).toList(),
    if (staff != null) 'staff': staff?.map((s) => s.toJson()).toList(),
    if (externalLinks != null) 'externalLinks': externalLinks?.map((l) => l.toJson()).toList(),
  };
}
