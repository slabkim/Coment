import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedSampleTitles() async {
  final db = FirebaseFirestore.instance;
  final col = db.collection('titles');
  final samples = [
    {
      'title': 'Sword of Dawn',
      'description': 'A hero rises to face ancient darkness.',
      'imageUrl': 'https://picsum.photos/seed/sword/600/400',
      'categories': ['Action', 'Fantasy'],
      'themes': ['Adventure', 'Hero'],
      'isFeatured': true,
      'isPopular': true,
      'isNewRelease': false,
      'rating': 4.6,
      'ratingCount': 320,
      'release_year': 2022,
    },
    {
      'title': 'Campus Days',
      'description': 'Slice of life with heartwarming moments.',
      'imageUrl': 'https://picsum.photos/seed/campus/600/400',
      'categories': ['Slice of Life', 'Comedy'],
      'themes': ['School', 'Friendship'],
      'isFeatured': false,
      'isPopular': true,
      'isNewRelease': true,
      'rating': 4.2,
      'ratingCount': 150,
      'release_year': 2025,
    },
  ];
  for (final s in samples) {
    await col.add(s);
  }
}


