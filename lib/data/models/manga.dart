import 'package:flutter/foundation.dart';
import 'external_link.dart';

class Manga {
  final int id;
  final String title;
  final String? englishTitle;
  final String? nativeTitle;
  final String? description;
  final String? coverImage;
  final String? bannerImage;
  final List<String> genres;
  final List<String> tags;
  final String? format;
  final String? status;
  final int? chapters;
  final int? volumes;
  final int? episodes;
  final int? duration;
  final String? source;
  final int? seasonYear;
  final String? season;
  final double? averageScore;
  final int? meanScore;
  final int? popularity;
  final int? favourites;
  final bool? isAdult;
  final String? countryOfOrigin;
  final String? updatedAt;
  final String? startDate;
  final String? endDate;
  final List<String>? synonyms;
  final List<MangaRelation>? relations;
  final List<MangaCharacter>? characters;
  final List<MangaStaff>? staff;
  final List<ExternalLink>? externalLinks;

  Manga({
    required this.id,
    required this.title,
    this.englishTitle,
    this.nativeTitle,
    this.description,
    this.coverImage,
    this.bannerImage,
    this.genres = const [],
    this.tags = const [],
    this.format,
    this.status,
    this.chapters,
    this.volumes,
    this.episodes,
    this.duration,
    this.source,
    this.seasonYear,
    this.season,
    this.averageScore,
    this.meanScore,
    this.popularity,
    this.favourites,
    this.isAdult,
    this.countryOfOrigin,
    this.updatedAt,
    this.startDate,
    this.endDate,
    this.synonyms,
    this.relations,
    this.characters,
    this.staff,
    this.externalLinks,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    return Manga(
      id: json['id'] ?? 0,
      title: json['title']?['romaji'] ?? json['title']?['english'] ?? 'Unknown Title',
      englishTitle: json['title']?['english'],
      nativeTitle: json['title']?['native'],
      description: json['description'],
      coverImage: json['coverImage']?['large'] ?? json['coverImage']?['medium'],
      bannerImage: json['bannerImage'],
      genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.map((tag) => tag['name'] as String).toList() ?? [],
      format: json['format'],
      status: json['status'],
      chapters: json['chapters'],
      volumes: json['volumes'],
      episodes: json['episodes'],
      duration: json['duration'],
      source: json['source'],
      seasonYear: json['seasonYear'],
      season: json['season'],
      averageScore: json['averageScore']?.toDouble(),
      meanScore: json['meanScore'],
      popularity: json['popularity'],
      favourites: json['favourites'],
      isAdult: json['isAdult'],
      countryOfOrigin: json['countryOfOrigin'],
      updatedAt: json['updatedAt'],
      startDate: json['startDate']?['year'] != null 
          ? '${json['startDate']['year']}-${json['startDate']['month']?.toString().padLeft(2, '0') ?? '01'}-${json['startDate']['day']?.toString().padLeft(2, '0') ?? '01'}'
          : null,
      endDate: json['endDate']?['year'] != null 
          ? '${json['endDate']['year']}-${json['endDate']['month']?.toString().padLeft(2, '0') ?? '01'}-${json['endDate']['day']?.toString().padLeft(2, '0') ?? '01'}'
          : null,
      synonyms: (json['synonyms'] as List<dynamic>?)?.cast<String>(),
      relations: (json['relations']?['edges'] as List<dynamic>?)?.map((edge) => MangaRelation.fromJson(edge)).toList(),
      characters: (json['characters']?['edges'] as List<dynamic>?)?.map((edge) => MangaCharacter.fromJson(edge)).toList(),
      staff: (json['staff']?['edges'] as List<dynamic>?)?.map((edge) => MangaStaff.fromJson(edge)).toList(),
      externalLinks: () {
        final links = json['externalLinks'] as List<dynamic>?;
        if (links != null) {
          return links.map((link) => ExternalLink.fromJson(link)).toList();
        }
        return null;
      }(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'englishTitle': englishTitle,
      'nativeTitle': nativeTitle,
      'description': description,
      'coverImage': coverImage,
      'bannerImage': bannerImage,
      'genres': genres,
      'tags': tags,
      'format': format,
      'status': status,
      'chapters': chapters,
      'volumes': volumes,
      'episodes': episodes,
      'duration': duration,
      'source': source,
      'seasonYear': seasonYear,
      'season': season,
      'averageScore': averageScore,
      'meanScore': meanScore,
      'popularity': popularity,
      'favourites': favourites,
      'isAdult': isAdult,
      'countryOfOrigin': countryOfOrigin,
      'updatedAt': updatedAt,
      'startDate': startDate,
      'endDate': endDate,
      'synonyms': synonyms,
      'relations': relations?.map((r) => r.toJson()).toList(),
      'characters': characters?.map((c) => c.toJson()).toList(),
      'staff': staff?.map((s) => s.toJson()).toList(),
      'externalLinks': externalLinks?.map((l) => l.toJson()).toList(),
    };
  }

  String get bestTitle => englishTitle ?? title;
  String get displayTitle => nativeTitle ?? englishTitle ?? title;
  double get rating => averageScore ?? 0.0;
  int get ratingCount => meanScore ?? 0;
  bool get isCompleted => status == 'FINISHED';
  bool get isOngoing => status == 'RELEASING';
  bool get isNotYetReleased => status == 'NOT_YET_RELEASED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isHiatus => status == 'HIATUS';

  @override
  String toString() {
    return 'Manga(id: $id, title: $title, format: $format, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Manga && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class MangaRelation {
  final String relationType;
  final Manga manga;

  MangaRelation({
    required this.relationType,
    required this.manga,
  });

  factory MangaRelation.fromJson(Map<String, dynamic> json) {
    return MangaRelation(
      relationType: json['relationType'] ?? '',
      manga: Manga.fromJson(json['node'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relationType': relationType,
      'manga': manga.toJson(),
    };
  }
}

class MangaCharacter {
  final String role;
  final MangaCharacterNode character;

  MangaCharacter({
    required this.role,
    required this.character,
  });

  factory MangaCharacter.fromJson(Map<String, dynamic> json) {
    return MangaCharacter(
      role: json['role'] ?? '',
      character: MangaCharacterNode.fromJson(json['node'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'character': character.toJson(),
    };
  }
}

class MangaCharacterNode {
  final int id;
  final String name;
  final String? image;

  MangaCharacterNode({
    required this.id,
    required this.name,
    this.image,
  });

  factory MangaCharacterNode.fromJson(Map<String, dynamic> json) {
    return MangaCharacterNode(
      id: json['id'] ?? 0,
      name: json['name']?['full'] ?? 'Unknown',
      image: json['image']?['large'] ?? json['image']?['medium'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
    };
  }
}

class MangaStaff {
  final String role;
  final MangaStaffNode staff;

  MangaStaff({
    required this.role,
    required this.staff,
  });

  factory MangaStaff.fromJson(Map<String, dynamic> json) {
    return MangaStaff(
      role: json['role'] ?? '',
      staff: MangaStaffNode.fromJson(json['node'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'staff': staff.toJson(),
    };
  }
}

class MangaStaffNode {
  final int id;
  final String name;
  final String? image;

  MangaStaffNode({
    required this.id,
    required this.name,
    this.image,
  });

  factory MangaStaffNode.fromJson(Map<String, dynamic> json) {
    return MangaStaffNode(
      id: json['id'] ?? 0,
      name: json['name']?['full'] ?? 'Unknown',
      image: json['image']?['large'] ?? json['image']?['medium'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
    };
  }
}

class MangaResponse {
  final List<Manga> manga;
  final PageInfo pageInfo;

  MangaResponse({
    required this.manga,
    required this.pageInfo,
  });

  factory MangaResponse.fromJson(Map<String, dynamic> json) {
    final media = json['data']?['Page']?['media'] as List<dynamic>? ?? [];
    return MangaResponse(
      manga: media.map((item) => Manga.fromJson(item)).toList(),
      pageInfo: PageInfo.fromJson(json['data']?['Page']?['pageInfo'] ?? {}),
    );
  }
}

class PageInfo {
  final int currentPage;
  final bool hasNextPage;
  final int lastPage;
  final int perPage;
  final int total;

  PageInfo({
    required this.currentPage,
    required this.hasNextPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) {
    return PageInfo(
      currentPage: json['currentPage'] ?? 1,
      hasNextPage: json['hasNextPage'] ?? false,
      lastPage: json['lastPage'] ?? 1,
      perPage: json['perPage'] ?? 10,
      total: json['total'] ?? 0,
    );
  }
}
