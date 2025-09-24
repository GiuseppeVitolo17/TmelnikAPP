import 'package:flutter/material.dart';
import 'screens/main_navigation_screen_local.dart';

void main() {
  runApp(const TmelnikAppLocal());
}

class TmelnikAppLocal extends StatelessWidget {
  const TmelnikAppLocal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tmelnik - Project Management (Local)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
        ),
      ),
      home: const MainNavigationScreenLocal(),
    );
  }
}
