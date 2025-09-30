import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
}
