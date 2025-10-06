import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nandogami_flutter/state/item_provider.dart';
import 'package:nandogami_flutter/data/repositories/comic_repository.dart';
import 'package:nandogami_flutter/data/models/comic_item.dart';
import 'package:nandogami_flutter/ui/screens/search_screen.dart';
import 'package:nandogami_flutter/ui/screens/detail_screen.dart';

class _TestRepo extends ComicRepository {
  @override
  Future<Map<String, List<ComicItem>>> getMixedFeed() async {
    final testItems = [
      ComicItem(
        id: '1',
        anilistId: 1,
        title: 'Attack on Titan',
        description: 'Shingeki no Kyojin',
        imageUrl: 'https://example.com/aot.jpg',
        categories: const ['Action', 'Drama'],
        isCompleted: false,
      ),
      ComicItem(
        id: '2',
        anilistId: 2,
        title: 'One Piece',
        description: 'Pirates adventure',
        imageUrl: 'https://example.com/op.jpg',
        categories: const ['Adventure'],
        isCompleted: false,
      ),
    ];
    
    return {
      'featured': testItems,
      'popular': testItems,
      'newReleases': testItems,
      'categories': testItems,
    };
  }

  @override
  Future<List<ComicItem>> search(String query) async {
    final allItems = [
      ComicItem(
        id: '1',
        anilistId: 1,
        title: 'Attack on Titan',
        description: 'Shingeki no Kyojin',
        imageUrl: 'https://example.com/aot.jpg',
        categories: const ['Action', 'Drama'],
        isCompleted: false,
      ),
      ComicItem(
        id: '2',
        anilistId: 2,
        title: 'One Piece',
        description: 'Pirates adventure',
        imageUrl: 'https://example.com/op.jpg',
        categories: const ['Adventure'],
        isCompleted: false,
      ),
    ];
    
    return allItems.where((item) => 
      item.title.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}

void main() {
  testWidgets('Search then open detail', (tester) async {
    final provider = ItemProvider(_TestRepo());

    await tester.pumpWidget(
      ChangeNotifierProvider<ItemProvider>.value(
        value: provider,
        child: const MaterialApp(home: SearchScreen()),
      ),
    );

    // load fake items
    await provider.load();
    await tester.pumpAndSettle();

    // enter query
    final textField = find.byType(TextField).first;
    await tester.enterText(textField, 'Attack');
    await tester.pumpAndSettle();

    // expect result appears
    expect(find.text('Attack on Titan'), findsWidgets);

    // tap result
    await tester.tap(find.text('Attack on Titan').first);
    await tester.pumpAndSettle();

    // navigated to DetailScreen
    expect(find.byType(DetailScreen), findsOneWidget);
  });
}


