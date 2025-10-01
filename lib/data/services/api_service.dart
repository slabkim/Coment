import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nandogami_item.dart';

class ApiService {
  Future<List<NandogamiItem>> fetchItems() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('titles')
          .get();
      return snapshot.docs
          .map((doc) => NandogamiItem.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch items: $e');
    }
  }
}
