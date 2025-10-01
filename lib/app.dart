import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'data/models/nandogami_item.dart';
import 'data/repositories/nandogami_repository.dart';
import 'data/services/api_service.dart';
import 'state/item_provider.dart';
import 'state/theme_provider.dart';
import 'ui/screens/detail_screen.dart';
import 'ui/screens/login_register_screen.dart';
import 'ui/screens/main_screen.dart';
import 'core/theme.dart';

class NandogamiApp extends StatelessWidget {
  const NandogamiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ItemProvider(NandogamiRepository(ApiService())),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..load(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, tp, _) => MaterialApp(
        title: AppConst.appName,
        theme: NandogamiTheme.light,
        darkTheme: NandogamiTheme.dark,
        themeMode: tp.mode,
        home: const _AuthGate(),
      ),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AppLinks? _appLinks;
  StreamSubscription<Uri?>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDynamicLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _appLinks = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

  Future<void> _initDynamicLinks() async {
    _appLinks = AppLinks();
    final initial = await _appLinks!.getInitialLink();
    _handleUri(initial);
    _linkSubscription = _appLinks!.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri? deepLink) {
    if (deepLink == null || !mounted) return;
    final segments = deepLink.pathSegments;
    if (segments.length >= 2 && segments.first == 'title') {
      final id = segments[1];
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
        if (!mounted) return;
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => DetailScreen(item: item)));
      });
    }
  }
}
