import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'data/models/nandogami_item.dart';
import 'data/repositories/comic_repository.dart';
import 'data/services/user_service.dart';
import 'state/item_provider.dart';
import 'state/theme_provider.dart';
import 'ui/screens/detail_screen.dart';
import 'ui/screens/main_screen.dart';
import 'core/theme.dart';

class NandogamiApp extends StatefulWidget {
  const NandogamiApp({super.key});

  @override
  State<NandogamiApp> createState() => _NandogamiAppState();
}

class _NandogamiAppState extends State<NandogamiApp> with WidgetsBindingObserver {
  final _userService = UserService();
  Timer? _lastSeenTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLastSeenUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lastSeenTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App is active/foreground
      _updateLastSeen();
      _startLastSeenUpdates();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background
      _updateLastSeen();
      _lastSeenTimer?.cancel();
    }
  }

  void _startLastSeenUpdates() {
    _lastSeenTimer?.cancel();
    _updateLastSeen(); // Update immediately
    // Update every 2 minutes while app is active
    _lastSeenTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _updateLastSeen();
    });
  }

  void _updateLastSeen() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userService.updateLastSeen(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ItemProvider(ComicRepository()),
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
    // Langsung ke MainScreen tanpa cek autentikasi
    return const MainScreen();
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
