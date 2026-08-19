import 'package:flutter/material.dart';

import 'auth/auth_store.dart';
import 'screens/business_workspace_screen.dart';
import 'screens/first_product_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';

class KisimbaApp extends StatelessWidget {
  const KisimbaApp({super.key, required this.authStore});
  final AuthStore authStore;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xff176b45));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kisimba POS',
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xfff7faf8),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 56),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: FutureBuilder<LocalAccount?>(
        future: authStore.account,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final account = snapshot.data;
          return account == null
              ? OnboardingScreen(authStore: authStore)
              : LoginScreen(authStore: authStore, account: account);
        },
      ),
    );
  }
}

void openFirstProduct(BuildContext context, LocalAccount account) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => FirstProductScreen(account: account)),
    (_) => false,
  );
}

void openWorkspace(BuildContext context, LocalAccount account) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => BusinessWorkspaceScreen(account: account)),
    (_) => false,
  );
}
