class AniListResponse {
  final PageInfo pageInfo;
  final List<AniListManga> media;

  const AniListResponse({
    required this.pageInfo,
    required this.media,
  });

  factory AniListResponse.fromJson(Map<String, dynamic> json) {
    return AniListResponse(
      pageInfo: PageInfo.fromJson(json['pageInfo'] ?? {}),
      media: (json['media'] as List<dynamic>? ?? [])
          .where((e) => e != null)
          .map((e) => AniListManga.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PageInfo {
  final int total;
  final int currentPage;
  final int lastPage;
  final bool hasNextPage;

  const PageInfo({
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.hasNextPage,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) {
    return PageInfo(
      total: json['total'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 1,
      lastPage: json['lastPage'] as int? ?? 1,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
    );
  }
}

class AniListManga {
  final int id;
  final AniListTitle title;
  final String? description;
  final AniListCoverImage coverImage;
  final String? bannerImage;
  final List<String> genres;
  final List<AniListTag> tags;
  final String? status;
  final int? chapters;
  final int? volumes;
  final int? averageScore;
  final int? popularity;
  final int? favourites;
  final AniListDate? startDate;
  final AniListDate? endDate;
  final List<AniListStaffEdge> staff;
  final List<AniListStudio> studios;
  final List<AniListRelationEdge>? relations;
  final List<AniListRecommendationNode>? recommendations;

  const AniListManga({
    required this.id,
    required this.title,
    this.description,
    required this.coverImage,
    this.bannerImage,
    required this.genres,
    required this.tags,
    this.status,
    this.chapters,
    this.volumes,
    this.averageScore,
    this.popularity,
    this.favourites,
    this.startDate,
    this.endDate,
    required this.staff,
    required this.studios,
    this.relations,
    this.recommendations,
  });

  factory AniListManga.fromJson(Map<String, dynamic> json) {
    return AniListManga(
      id: json['id'] as int,
      title: AniListTitle.fromJson(json['title'] ?? {}),
      description: json['description'] as String?,
      coverImage: AniListCoverImage.fromJson(json['coverImage'] ?? {}),
      bannerImage: json['bannerImage'] as String?,
      genres: (json['genres'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => AniListTag.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String?,
      chapters: json['chapters'] as int?,
      volumes: json['volumes'] as int?,
      averageScore: json['averageScore'] as int?,
      popularity: json['popularity'] as int?,
      favourites: json['favourites'] as int?,
      startDate: json['startDate'] != null
          ? AniListDate.fromJson(json['startDate'] as Map<String, dynamic>)
          : null,
      endDate: json['endDate'] != null
          ? AniListDate.fromJson(json['endDate'] as Map<String, dynamic>)
          : null,
      staff: (json['staff']?['edges'] as List<dynamic>? ?? [])
          .map((e) => AniListStaffEdge.fromJson(e as Map<String, dynamic>))
          .toList(),
      studios: (json['studios']?['nodes'] as List<dynamic>? ?? [])
          .map((e) => AniListStudio.fromJson(e as Map<String, dynamic>))
          .toList(),
      relations: json['relations'] != null
          ? (json['relations']['edges'] as List<dynamic>? ?? [])
              .map((e) => AniListRelationEdge.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      recommendations: json['recommendations'] != null
          ? (json['recommendations']['nodes'] as List<dynamic>? ?? [])
              .map((e) => AniListRecommendationNode.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  /// Get best available title
  String get bestTitle {
    if (title.english?.isNotEmpty == true) return title.english!;
    if (title.romaji?.isNotEmpty == true) return title.romaji!;
    if (title.native?.isNotEmpty == true) return title.native!;
    return 'Unknown Title';
  }

  /// Get author name
  String? get author {
    try {
      final authorEdge = staff.firstWhere(
        (edge) => edge.role?.toLowerCase().contains('story') == true ||
                  edge.role?.toLowerCase().contains('original creator') == true,
      );
      return authorEdge.node.name.full;
    } catch (e) {
      return null;
    }
  }

  /// Get formatted description without HTML tags
  String? get cleanDescription {
    if (description == null) return null;
    
    return description!
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'\s+'), ' ')    // Normalize whitespace
        .trim();
  }

  /// Get formatted score
  double? get formattedScore {
    if (averageScore == null) return null;
    return averageScore! / 10.0; // Convert from 0-100 to 0-10
  }

  /// Get publication year
  int? get publicationYear => startDate?.year;

  /// Check if manga is completed
  bool get isCompleted => status?.toLowerCase() == 'finished';

  /// Get tag names
  List<String> get tagNames => tags.map((tag) => tag.name).toList();
}

class AniListTitle {
  final String? romaji;
  final String? english;
  final String? native;

  const AniListTitle({
    this.romaji,
    this.english,
    this.native,
  });

  factory AniListTitle.fromJson(Map<String, dynamic> json) {
    return AniListTitle(
      romaji: json['romaji'] as String?,
      english: json['english'] as String?,
      native: json['native'] as String?,
    );
  }
}

class AniListCoverImage {
  final String? large;
  final String? medium;

  const AniListCoverImage({
    this.large,
    this.medium,
  });

  factory AniListCoverImage.fromJson(Map<String, dynamic> json) {
    return AniListCoverImage(
      large: json['large'] as String?,
      medium: json['medium'] as String?,
    );
  }

  /// Get best available cover image
  String? get bestImage => large ?? medium;
}

class AniListTag {
  final String name;
  final String? description;

  const AniListTag({
    required this.name,
    this.description,
  });

  factory AniListTag.fromJson(Map<String, dynamic> json) {
    return AniListTag(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

class AniListDate {
  final int? year;
  final int? month;
  final int? day;

  const AniListDate({
    this.year,
    this.month,
    this.day,
  });

  factory AniListDate.fromJson(Map<String, dynamic> json) {
    return AniListDate(
      year: json['year'] as int?,
      month: json['month'] as int?,
      day: json['day'] as int?,
    );
  }

  /// Convert to DateTime if possible
  DateTime? toDateTime() {
    if (year == null) return null;
    return DateTime(year!, month ?? 1, day ?? 1);
  }
}

class AniListStaffEdge {
  final String? role;
  final AniListStaffNode node;

  const AniListStaffEdge({
    this.role,
    required this.node,
  });

  factory AniListStaffEdge.fromJson(Map<String, dynamic> json) {
    return AniListStaffEdge(
      role: json['role'] as String?,
      node: AniListStaffNode.fromJson(json['node'] ?? {}),
    );
  }
}

class AniListStaffNode {
  final AniListName name;

  const AniListStaffNode({
    required this.name,
  });

  factory AniListStaffNode.fromJson(Map<String, dynamic> json) {
    return AniListStaffNode(
      name: AniListName.fromJson(json['name'] ?? {}),
    );
  }
}

class AniListName {
  final String? full;

  const AniListName({
    this.full,
  });

  factory AniListName.fromJson(Map<String, dynamic> json) {
    return AniListName(
      full: json['full'] as String?,
    );
  }
}

class AniListStudio {
  final String name;

  const AniListStudio({
    required this.name,
  });

  factory AniListStudio.fromJson(Map<String, dynamic> json) {
    return AniListStudio(
      name: json['name'] as String? ?? '',
    );
  }
}

class AniListRelationEdge {
  final String? relationType;
  final AniListRelationNode node;

  const AniListRelationEdge({
    this.relationType,
    required this.node,
  });

  factory AniListRelationEdge.fromJson(Map<String, dynamic> json) {
    return AniListRelationEdge(
      relationType: json['relationType'] as String?,
      node: AniListRelationNode.fromJson(json['node'] ?? {}),
    );
  }
}

class AniListRelationNode {
  final int id;
  final AniListTitle title;
  final AniListCoverImage coverImage;

  const AniListRelationNode({
    required this.id,
    required this.title,
    required this.coverImage,
  });

  factory AniListRelationNode.fromJson(Map<String, dynamic> json) {
    return AniListRelationNode(
      id: json['id'] as int? ?? 0,
      title: AniListTitle.fromJson(json['title'] ?? {}),
      coverImage: AniListCoverImage.fromJson(json['coverImage'] ?? {}),
    );
  }
}

class AniListRecommendationNode {
  final AniListRelationNode mediaRecommendation;

  const AniListRecommendationNode({
    required this.mediaRecommendation,
  });

  factory AniListRecommendationNode.fromJson(Map<String, dynamic> json) {
    return AniListRecommendationNode(
      mediaRecommendation: AniListRelationNode.fromJson(
        json['mediaRecommendation'] ?? {},
      ),
    );
  }
}
