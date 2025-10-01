import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'data/models/nandogami_item.dart';
import 'ui/screens/detail_screen.dart';
import 'core/constants.dart';
import 'data/repositories/nandogami_repository.dart';
import 'data/services/api_service.dart';
import 'state/item_provider.dart';
import 'ui/screens/login_register_screen.dart';
import 'ui/screens/main_screen.dart';

class NandogamiApp extends StatelessWidget {
  const NandogamiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ItemProvider(NandogamiRepository(ApiService())),
        ),
      ],
      child: MaterialApp(
        title: AppConst.appName,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.dark(
            primary: AppColors.primaryDark,
            surface: AppColors.black,
            onSurface: AppColors.white,
          ),
          scaffoldBackgroundColor: AppColors.black,
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    _initDynamicLinks(context);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const MainScreen();
        }

        return const LoginRegisterScreen();
      },
    );
  }

  void _initDynamicLinks(BuildContext context) {
    final appLinks = AppLinks();
    appLinks.getInitialLink().then((uri) {
      if (!context.mounted) return;
      _handleUri(context, uri);
    });
    appLinks.uriLinkStream.listen((uri) {
      if (!context.mounted) return;
      _handleUri(context, uri);
    });
  }

  void _handleUri(BuildContext context, Uri? deepLink) {
    if (deepLink == null) return;
    final segments = deepLink.pathSegments;
    if (segments.isNotEmpty && segments.first == 'title' && segments.length >= 2) {
      final id = segments[1];
      // Navigate to detail using provider items if available
      final prov = Provider.of<ItemProvider>(context, listen: false);
      final item = prov.items.firstWhere(
        (e) => e.id == id,
        orElse: () => NandogamiItem(
          id: id,
          title: 'Loading...',
          description: '',
          imageUrl: '',
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
        );
      });
    }
  }
}
