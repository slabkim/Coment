import '../models/comic_item.dart';
import '../models/nandogami_item.dart';

/// Adapter to convert between ComicItem and NandogamiItem for compatibility
class ComicAdapter {
  /// Convert ComicItem to NandogamiItem for backward compatibility
  static NandogamiItem toNandogamiItem(ComicItem comic) {
    return NandogamiItem(
      id: comic.id,
      title: comic.title,
      description: comic.description,
      imageUrl: comic.imageUrl,
      alternativeTitles: comic.alternativeTitles,
      author: comic.author,
      categories: comic.categories,
      chapters: comic.chapters,
      format: comic.format,
      isFeatured: comic.isFeatured,
      isNewRelease: comic.isNewRelease,
      isPopular: comic.isPopular,
      rating: comic.rating,
      ratingCount: comic.ratingCount,
      releaseYear: comic.releaseYear,
      synopsis: comic.synopsis,
      themes: comic.themes,
      type: comic.type,
      // AniList specific fields - only use available fields
      status: comic.status,
      popularity: comic.popularity,
      favourites: comic.favourites,
      // Additional fields that might be available
      englishTitle: comic.alternativeTitles?.isNotEmpty == true 
          ? comic.alternativeTitles!.first 
          : null,
      nativeTitle: (comic.alternativeTitles?.length ?? 0) > 1 
          ? comic.alternativeTitles![1] 
          : null,
      genres: comic.categories,
      tags: comic.themes,
      volumes: null, // Not available in ComicItem
      source: null, // Not available in ComicItem
      seasonYear: comic.releaseYear,
      season: null, // Not available in ComicItem
      averageScore: comic.rating,
      meanScore: comic.rating?.toInt(),
      startDate: null, // Not available in ComicItem
      endDate: null, // Not available in ComicItem
      synonyms: comic.alternativeTitles,
      relations: null, // Not available in ComicItem
      characters: null, // Not available in ComicItem
      staff: null, // Not available in ComicItem
      externalLinks: null, // Not available in ComicItem
    );
  }

  /// Convert list of ComicItems to NandogamiItems
  static List<NandogamiItem> toNandogamiItems(List<ComicItem> comics) {
    return comics.map(toNandogamiItem).toList();
  }

  /// Convert NandogamiItem to ComicItem (for reverse compatibility if needed)
  static ComicItem fromNandogamiItem(NandogamiItem item) {
    return ComicItem(
      id: item.id,
      anilistId: int.tryParse(item.id) ?? 0,
      title: item.title,
      description: item.description,
      imageUrl: item.imageUrl,
      alternativeTitles: item.alternativeTitles,
      author: item.author,
      categories: item.categories ?? [],
      chapters: item.chapters,
      format: item.format,
      rating: item.rating,
      ratingCount: item.ratingCount,
      releaseYear: item.releaseYear,
      synopsis: item.synopsis,
      themes: item.themes,
      type: item.type,
      isCompleted: false, // Default value
      isFeatured: item.isFeatured,
      isNewRelease: item.isNewRelease,
      isPopular: item.isPopular,
    );
  }
}
