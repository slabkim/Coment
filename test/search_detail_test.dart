import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:coment/state/item_provider.dart';
import 'package:coment/data/repositories/comic_repository.dart';
import 'package:coment/data/models/comic_item.dart';
import 'package:coment/ui/screens/search_screen.dart';
import 'package:coment/ui/screens/detail_screen.dart';
import 'package:coment/data/services/api_service.dart';

class _TestRepo extends ComicRepository {
  _TestRepo() : super(ApiService());

  @override
  Future<List<ComicItem>> getAll() async {
    return [
      ComicItem(
        id: '1',
        title: 'Attack on Titan',
        description: 'Shingeki no Kyojin',
        imageUrl: 'https://example.com/aot.jpg',
        categories: const ['Action', 'Drama'],
      ),
      ComicItem(
        id: '2',
        title: 'One Piece',
        description: 'Pirates adventure',
        imageUrl: 'https://example.com/op.jpg',
        categories: const ['Adventure'],
      ),
    ];
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
