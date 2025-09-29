import '../models/nandogami_item.dart';
import '../services/api_service.dart';

class NandogamiRepository {
  final ApiService api;
  NandogamiRepository(this.api);

  Future<List<NandogamiItem>> getAll() => api.fetchItems();
}
