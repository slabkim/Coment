import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nandogami_flutter/state/item_provider.dart';
import 'package:nandogami_flutter/data/models/comic_item.dart';
import 'package:nandogami_flutter/data/repositories/comic_repository.dart';
import 'package:nandogami_flutter/ui/screens/detail_screen.dart';
import 'package:nandogami_flutter/ui/screens/search_screen.dart';

final List<ComicItem> _testItems = [
  const ComicItem(
    id: '1',
    anilistId: 1,
    title: 'Attack on Titan',
    description: 'Shingeki no Kyojin',
    imageUrl: 'https://example.com/aot.jpg',
    categories: const ['Action', 'Drama'],
    isCompleted: false,
  ),
  const ComicItem(
    id: '2',
    anilistId: 2,
    title: 'One Piece',
    description: 'Pirates adventure',
    imageUrl: 'https://example.com/op.jpg',
    categories: const ['Adventure'],
    isCompleted: false,
  ),
];

class _TestRepo extends ComicRepository {
  _TestRepo() : super();

  List<ComicItem> get _items => _testItems;

  @override
  Future<Map<String, List<ComicItem>>> getMixedFeed() async {
    return {
      'featured': _items,
      'popular': _items,
      'newReleases': _items,
      'categories': _items,
      'seasonal': _items,
    };
  }

  @override
  Future<List<ComicItem>> getTopRated() async => _items;

  @override
  Future<List<ComicItem>> getTrending() async => _items;

  @override
  Future<List<ComicItem>> search(String query) async {
    final lower = query.toLowerCase();
    return _items
        .where((item) => item.title.toLowerCase().contains(lower))
        .toList();
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

    await tester.pump(); // settle initial build

    // Load fake data
    await provider.load();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    // Enter query
    final textField = find.byType(TextField).first;
    await tester.enterText(textField, 'Attack');
    await tester.pump(const Duration(milliseconds: 300));

    // Expect result appears
    expect(find.text('Attack on Titan'), findsWidgets);

    // Tap result
    await tester.tap(find.text('Attack on Titan').first);
    await tester.pump(const Duration(milliseconds: 300));

    // Navigated to DetailScreen
    expect(find.byType(DetailScreen), findsOneWidget);
  });
}
