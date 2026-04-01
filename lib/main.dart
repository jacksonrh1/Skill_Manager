import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/root_page.dart';
import 'state/app_scope.dart';
import 'state/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SkillManagerBootstrap());
}

class SkillManagerBootstrap extends StatefulWidget {
  const SkillManagerBootstrap({super.key});

  @override
  State<SkillManagerBootstrap> createState() => _SkillManagerBootstrapState();
}

class _SkillManagerBootstrapState extends State<SkillManagerBootstrap> {
  late final Future<AppStore> _storeFuture = AppStore.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppStore>(
      future: _storeFuture,
      builder: (context, snapshot) {
        final app = MaterialApp(
          title: 'Skill Manager',
          debugShowCheckedModeBanner: false,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: snapshot.connectionState == ConnectionState.done &&
                  snapshot.requireData.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: snapshot.connectionState != ConnectionState.done
              ? const _LoadingScreen()
              : const RootPage(),
        );

        if (snapshot.connectionState != ConnectionState.done) {
          return app;
        }

        return AppScope(
          notifier: snapshot.requireData,
          child: ListenableBuilder(
            listenable: snapshot.requireData,
            builder: (context, _) {
              return MaterialApp(
                title: 'Skill Manager',
                debugShowCheckedModeBanner: false,
                theme: _buildLightTheme(),
                darkTheme: _buildDarkTheme(),
                themeMode: snapshot.requireData.isDarkMode
                    ? ThemeMode.dark
                    : ThemeMode.light,
                home: const RootPage(),
              );
            },
          ),
        );
      },
    );
  }
}

ThemeData _buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5D9EF8),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F5FB),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE5E8F2),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF263041),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF263041),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE7EAF2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE7EAF2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF6AA3FF),
          width: 1.5,
        ),
      ),
    ),
  );
}

ThemeData _buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5D9EF8),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121722),
    cardColor: const Color(0xFF1A2130),
    dividerColor: const Color(0xFF2C3548),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFF5F7FB),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFFF5F7FB),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1D2636),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2C3548)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2C3548)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF6AA3FF),
          width: 1.5,
        ),
      ),
    ),
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
