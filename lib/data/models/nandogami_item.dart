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

  factory NandogamiItem.fromJson(Map<String, dynamic> json, [String? docId]) =>
      NandogamiItem(
        id: docId ?? json['id'].toString(),
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        coverImage: json['coverImage'],
        bannerImage: json['bannerImage'],
        alternativeTitles:
            (json['alternativeTitles'] as List<dynamic>?)?.cast<String>(),
        author: json['author'],
        categories: (json['categories'] as List<dynamic>?)?.cast<String>(),
        chapters: json['chapters'],
        format: json['format'],
        isFeatured: json['isFeatured'],
        isNewRelease: json['isNewRelease'],
        isPopular: json['isPopular'],
        rating: json['rating']?.toDouble(),
        ratingCount: json['ratingCount'],
        releaseYear: json['release_year'],
        synopsis: json['synopsis'],
        themes: (json['themes'] as List<dynamic>?)?.cast<String>(),
        type: json['type'],
        // AniList specific fields
        englishTitle: json['englishTitle'],
        nativeTitle: json['nativeTitle'],
        genres: (json['genres'] as List<dynamic>?)?.cast<String>(),
        tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
        status: json['status'],
        volumes: json['volumes'],
        source: json['source'],
        seasonYear: json['seasonYear'],
        season: json['season'],
        averageScore: json['averageScore']?.toDouble(),
        meanScore: json['meanScore'],
        popularity: json['popularity'],
        favourites: json['favourites'],
        startDate: json['startDate'],
        endDate: json['endDate'],
        synonyms: (json['synonyms'] as List<dynamic>?)?.cast<String>(),
        relations: (json['relations'] as List<dynamic>?)
            ?.map((relation) => MangaRelation.fromJson(relation))
            .toList(),
        characters: (json['characters'] as List<dynamic>?)
            ?.map((character) => MangaCharacter.fromJson(character))
            .toList(),
        staff: (json['staff'] as List<dynamic>?)
            ?.map((staffMember) => MangaStaff.fromJson(staffMember))
            .toList(),
        externalLinks: (json['externalLinks'] as List<dynamic>?)
            ?.map((link) => ExternalLink.fromJson(link))
            .toList(),
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
        if (relations != null)
          'relations': relations?.map((relation) => relation.toJson()).toList(),
        if (characters != null)
          'characters': characters?.map((character) => character.toJson()).toList(),
        if (staff != null)
          'staff': staff?.map((staffMember) => staffMember.toJson()).toList(),
        if (externalLinks != null)
          'externalLinks': externalLinks?.map((link) => link.toJson()).toList(),
      };
}
