import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:nandogami_flutter/ui/screens/splash_screen.dart';

void main() {
  testWidgets('App boots splash', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(enableAutoNavigate: false)),
    );
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
