import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/tile_cache_service.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await TileCacheService.instance.initialize();
  } catch (_) {
    // The UI and GPS experience should still start if local storage is unavailable.
  }
  runApp(const ProviderScope(child: FlightExperienceApp()));
}

class FlightExperienceApp extends StatelessWidget {
  const FlightExperienceApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0B5FFF);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flight Experience',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      ),
      home: const HomeScreen(),
    );
  }
}
