/// Content filtering configuration for safe browsing
class ContentFilter {
  // AniList content filtering
  static const bool allowAdultContent = false;
  
  // MangaDex content rating filters
  static const List<String> allowedContentRatings = [
    'safe', // Konten yang aman untuk semua umur
    // 'suggestive', // Dihapus untuk filter lebih ketat
    // 'erotica',    // Tidak diizinkan
    // 'pornographic' // Tidak diizinkan
  ];
  
  // Genre blacklist untuk AniList
  static const List<String> blockedGenres = [
    'Hentai',
    'Yaoi', // Boys Love - banned
    'Yuri', // Girls Love - banned
    'Pure Ecchi', // Pure ecchi yang mesum - banned
    'Ecchi Hentai', // Ecchi yang terlalu explicit - banned
  ];
  
  // Genre yang diizinkan meskipun ada ecchi ringan
  static const List<String> allowedEcchiGenres = [
    'Ecchi', // Ecchi ringan diizinkan
    'Romance',
    'Comedy',
    'School',
    'Slice of Life',
  ];
  
  // Tag blacklist untuk AniList
  static const List<String> blockedTags = [
    'Nudity',
    'Sex',
    'Sexual Violence',
    'Borderline H',
    'Primarily Adult Cast',
    'Boys Love', // BL tags - banned
    'Girls Love', // GL tags - banned
    'Yaoi', // BL alternative - banned
    'Yuri', // GL alternative - banned
    'Explicit Sexual Content', // Pure ecchi yang mesum - banned
    'Hentai', // Explicit content - banned
  ];
  
  // Tag yang diizinkan untuk ecchi ringan
  static const List<String> allowedEcchiTags = [
    'Ecchi', // Ecchi ringan diizinkan
    'Fan Service', // Fan service ringan diizinkan
    'Romance',
    'Comedy',
    'School Life',
  ];
  
  /// Check if a manga is safe based on genres
  static bool isSafeByGenres(List<String> genres) {
    for (final genre in genres) {
      if (blockedGenres.contains(genre)) {
        return false;
      }
    }
    return true;
  }
  
  /// Check if a manga is safe based on tags with smart ecchi filtering
  static bool isSafeByTags(List<String> tags) {
    // Check for blocked tags first
    for (final tag in tags) {
      if (blockedTags.contains(tag)) {
        return false;
      }
    }
    
    // Smart ecchi filtering - allow ecchi only if it's combined with safe genres
    if (tags.contains('Ecchi')) {
      // Check if ecchi is combined with other safe content
      bool hasSafeContext = false;
      for (final tag in tags) {
        if (allowedEcchiTags.contains(tag) && tag != 'Ecchi') {
          hasSafeContext = true;
          break;
        }
      }
      
      // If ecchi is standalone or with explicit content, block it
      if (!hasSafeContext) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Check if ecchi content is acceptable (has safe context)
  static bool isEcchiAcceptable(List<String> genres, List<String> tags) {
    // Must have ecchi tag
    if (!tags.contains('Ecchi')) return false;
    
    // Check if it's combined with safe genres
    bool hasSafeGenre = false;
    for (final genre in genres) {
      if (allowedEcchiGenres.contains(genre)) {
        hasSafeGenre = true;
        break;
      }
    }
    
    // Check if it's combined with safe tags
    bool hasSafeTag = false;
    for (final tag in tags) {
      if (allowedEcchiTags.contains(tag) && tag != 'Ecchi') {
        hasSafeTag = true;
        break;
      }
    }
    
    return hasSafeGenre || hasSafeTag;
  }
  
  /// Check if content rating is allowed
  static bool isContentRatingAllowed(String contentRating) {
    return allowedContentRatings.contains(contentRating.toLowerCase());
  }
}
