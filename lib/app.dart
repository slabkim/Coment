import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'data/repositories/comic_repository.dart';
import 'data/services/api_service.dart';
import 'state/item_provider.dart';
import 'state/theme_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/main_screen.dart';

class ComentApp extends StatelessWidget {
  const ComentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ItemProvider(ComicRepository(ApiService())),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        title: AppConst.appName,
        theme: ComentTheme.light,
        darkTheme: ComentTheme.dark,
        themeMode: ThemeMode.system,
        home: const MainScreen(),
      ),
    );
  }
}
