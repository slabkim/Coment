import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comic_item.dart';

class ApiService {
  Future<List<ComicItem>> fetchItems() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('titles')
          .get();
      return snapshot.docs
          .map((doc) => ComicItem.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch items: $e');
    }
  }
}
