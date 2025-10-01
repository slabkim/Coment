import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nandogami_flutter/state/item_provider.dart';
import 'package:nandogami_flutter/data/repositories/nandogami_repository.dart';
import 'package:nandogami_flutter/data/models/nandogami_item.dart';
import 'package:nandogami_flutter/ui/screens/search_screen.dart';
import 'package:nandogami_flutter/ui/screens/detail_screen.dart';
import 'package:nandogami_flutter/data/services/api_service.dart';

class _TestRepo extends NandogamiRepository {
  _TestRepo() : super(ApiService());

  @override
  Future<List<NandogamiItem>> getAll() async {
    return [
      NandogamiItem(
        id: '1',
        title: 'Attack on Titan',
        description: 'Shingeki no Kyojin',
        imageUrl: 'https://example.com/aot.jpg',
        categories: const ['Action', 'Drama'],
      ),
      NandogamiItem(
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


