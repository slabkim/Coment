class ExternalLink {
  final String site;
  final String url;
  final String? type;
  final String? icon;

  const ExternalLink({
    required this.site,
    required this.url,
    this.type,
    this.icon,
  });

  factory ExternalLink.fromJson(Map<String, dynamic> json) {
    return ExternalLink(
      site: json['site'] ?? '',
      url: json['url'] ?? '',
      type: json['type'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'site': site,
      'url': url,
      if (type != null) 'type': type,
      if (icon != null) 'icon': icon,
    };
  }

  /// Get display name for the site
  String get displayName {
    switch (site.toLowerCase()) {
      case 'crunchyroll':
        return 'Crunchyroll';
      case 'funimation':
        return 'Funimation';
      case 'hulu':
        return 'Hulu';
      case 'netflix':
        return 'Netflix';
      case 'amazon prime':
        return 'Amazon Prime';
      case 'disney+':
        return 'Disney+';
      case 'hbo max':
        return 'HBO Max';
      case 'vrv':
        return 'VRV';
      case 'hidive':
        return 'HIDIVE';
      case 'retrocrush':
        return 'RetroCrush';
      case 'tubi':
        return 'Tubi';
      case 'concrunchyroll':
        return 'Crunchyroll';
      case 'confunimation':
        return 'Funimation';
      case 'conhulu':
        return 'Hulu';
      case 'connetflix':
        return 'Netflix';
      case 'conamazon prime':
        return 'Amazon Prime';
      case 'condisney+':
        return 'Disney+';
      case 'conhbo max':
        return 'HBO Max';
      case 'convrv':
        return 'VRV';
      case 'conhidive':
        return 'HIDIVE';
      case 'conretrocrush':
        return 'RetroCrush';
      case 'contubi':
        return 'Tubi';
      case 'manga':
        return 'Manga';
      case 'novel':
        return 'Novel';
      case 'anime':
        return 'Anime';
      case 'game':
        return 'Game';
      case 'music':
        return 'Music';
      case 'book':
        return 'Book';
      case 'dvd':
        return 'DVD';
      case 'blu-ray':
        return 'Blu-ray';
      case 'cd':
        return 'CD';
      case 'vinyl':
        return 'Vinyl';
      case 'cassette':
        return 'Cassette';
      case 'other':
        return 'Other';
      default:
        return site;
    }
  }

  /// Get icon URL from AniList or fallback to local icon
  String get iconUrl {
    // If AniList provides an icon URL, use it
    if (icon != null && icon!.isNotEmpty) {
      return icon!;
    }
    
    // Fallback to local icon based on site name
    return _getLocalIconUrl();
  }

  /// Get local icon URL based on site name
  String _getLocalIconUrl() {
    switch (site.toLowerCase()) {
      case 'webtoon':
        return 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1-1.jpg'; // Placeholder
      case 'tapas':
        return 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1-2.jpg'; // Placeholder
      case 'kakaopage':
        return 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1-3.jpg'; // Placeholder
      case 'naver':
        return 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1-4.jpg'; // Placeholder
      case 'crunchyroll':
      case 'concrunchyroll':
        return 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1-5.jpg'; // Placeholder
      case 'netflix':
      case 'connetflix':
        return 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1-6.jpg'; // Placeholder
      case 'manga plus':
        return 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1-7.jpg'; // Placeholder
      case 'viz media':
        return 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1-8.jpg'; // Placeholder
      default:
        return 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1-9.jpg'; // Default placeholder
    }
  }

  /// Get Material icon name for fallback
  String get iconName {
    switch (site.toLowerCase()) {
      case 'webtoon':
        return 'auto_stories';
      case 'tapas':
        return 'menu_book';
      case 'kakaopage':
        return 'library_books';
      case 'naver':
        return 'web';
      case 'crunchyroll':
      case 'concrunchyroll':
        return 'play_circle';
      case 'funimation':
      case 'confunimation':
        return 'play_circle';
      case 'hulu':
      case 'conhulu':
        return 'play_circle';
      case 'netflix':
      case 'connetflix':
        return 'play_circle';
      case 'amazon prime':
      case 'conamazon prime':
        return 'play_circle';
      case 'disney+':
      case 'condisney+':
        return 'play_circle';
      case 'hbo max':
      case 'conhbo max':
        return 'play_circle';
      case 'vrv':
      case 'convrv':
        return 'play_circle';
      case 'hidive':
      case 'conhidive':
        return 'play_circle';
      case 'retrocrush':
      case 'conretrocrush':
        return 'play_circle';
      case 'tubi':
      case 'contubi':
        return 'play_circle';
      case 'manga plus':
        return 'auto_stories';
      case 'viz media':
        return 'library_books';
      case 'manga':
        return 'book';
      case 'novel':
        return 'book';
      case 'anime':
        return 'play_circle';
      case 'game':
        return 'sports_esports';
      case 'music':
        return 'music_note';
      case 'book':
        return 'book';
      case 'dvd':
        return 'movie';
      case 'blu-ray':
        return 'movie';
      case 'cd':
        return 'album';
      case 'vinyl':
        return 'album';
      case 'cassette':
        return 'album';
      case 'other':
        return 'link';
      default:
        return 'link';
    }
  }

  /// Check if this is a streaming service
  bool get isStreaming {
    final streamingSites = [
      'crunchyroll', 'concrunchyroll',
      'funimation', 'confunimation',
      'hulu', 'conhulu',
      'netflix', 'connetflix',
      'amazon prime', 'conamazon prime',
      'disney+', 'condisney+',
      'hbo max', 'conhbo max',
      'vrv', 'convrv',
      'hidive', 'conhidive',
      'retrocrush', 'conretrocrush',
      'tubi', 'contubi',
    ];
    return streamingSites.contains(site.toLowerCase());
  }

  /// Check if this is a manga/novel reading site
  bool get isReading {
    final readingSites = ['manga', 'novel', 'book'];
    return readingSites.contains(site.toLowerCase());
  }

  /// Check if this is a merchandise site
  bool get isMerchandise {
    final merchSites = ['dvd', 'blu-ray', 'cd', 'vinyl', 'cassette'];
    return merchSites.contains(site.toLowerCase());
  }

  @override
  String toString() {
    return 'ExternalLink(site: $site, url: $url, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExternalLink && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
