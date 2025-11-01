import '../../../data/models/manga.dart';
import '../../../data/models/nandogami_item.dart';

/// Helper functions for Home Screen
class HomeHelpers {
  /// Convert Manga to NandogamiItem for DetailScreen
  static NandogamiItem convertMangaToItem(Manga manga) {
    return NandogamiItem(
      id: manga.id.toString(),
      title: manga.bestTitle,
      description: manga.description ?? '',
      imageUrl: manga.coverImage ?? '',
      coverImage: manga.coverImage,
      bannerImage: manga.bannerImage,
      categories: manga.genres,
      chapters: manga.chapters,
      format: manga.format,
      rating: manga.rating,
      ratingCount: manga.ratingCount,
      releaseYear: manga.seasonYear,
      synopsis: manga.description,
      type: 'Manga',
      isFeatured: false,
      isNewRelease: false,
      isPopular: false,
      // AniList specific fields
      englishTitle: manga.englishTitle,
      nativeTitle: manga.nativeTitle,
      genres: manga.genres,
      tags: manga.tags,
      status: manga.status,
      volumes: manga.volumes,
      source: manga.source,
      seasonYear: manga.seasonYear,
      season: manga.season,
      averageScore: manga.averageScore,
      meanScore: manga.meanScore,
      popularity: manga.popularity,
      favourites: manga.favourites,
      startDate: manga.startDate,
      endDate: manga.endDate,
      synonyms: manga.synonyms,
      relations: manga.relations,
      characters: manga.characters,
      staff: manga.staff,
      externalLinks: null, // Will be loaded separately in AboutTab
      trailer: manga.trailer, // Include trailer data
    );
  }
}

