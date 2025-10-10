import '../models/comic_item.dart';
import '../services/api_service.dart';

class ComicRepository {
  final ApiService api;
  ComicRepository(this.api);

  Future<List<ComicItem>> getAll() => api.fetchItems();
}
