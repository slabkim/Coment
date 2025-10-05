import '../models/comic_item.dart';
import '../services/comic_service.dart';

/// Repository that provides comic data from APIs
class ComicRepository {
  final ComicService _comicService;

  ComicRepository({ComicService? comicService})
      : _comicService = comicService ?? ComicService();

  /// Get all comics (mixed popular and trending)
  Future<List<ComicItem>> getAll() => _comicService.getAllComics();

  /// Get mixed feed for home page sections
  Future<Map<String, List<ComicItem>>> getMixedFeed() => 
      _comicService.getMixedFeed();

  /// Search comics
  Future<List<ComicItem>> search(String query) => 
      _comicService.searchComics(query);

  /// Get comic detail with preview pages
  Future<ComicItem> getDetail(int anilistId) => 
      _comicService.getComicDetail(anilistId);

  /// Get comics by genre
  Future<List<ComicItem>> getByGenre(String genre) => 
      _comicService.getComicsByGenre(genre);

  /// Get popular comics
  Future<List<ComicItem>> getPopular() => 
      _comicService.getPopularComics();

  /// Get trending comics
  Future<List<ComicItem>> getTrending() => 
      _comicService.getTrendingComics();

  /// Get new release comics
  Future<List<ComicItem>> getNewReleases() => 
      _comicService.getNewReleaseComics();

  /// Get top rated comics
  Future<List<ComicItem>> getTopRated() => 
      _comicService.getTopRatedComics();

  /// Get recommended comics
  Future<List<ComicItem>> getRecommended(ComicItem comic) => 
      _comicService.getRecommendedComics(comic);

  /// Get seasonal comics
  Future<List<ComicItem>> getSeasonal() => 
      _comicService.getSeasonalComics();

}
