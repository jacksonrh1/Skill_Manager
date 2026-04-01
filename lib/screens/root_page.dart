import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import 'auth_page.dart';
import 'home_page.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    if (!store.isReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!store.isAuthenticated) {
      return const AuthPage();
    }

    return const HomePage();
  }
}
