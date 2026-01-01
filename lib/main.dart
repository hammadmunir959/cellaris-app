import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/navigation/app_router.dart';

import 'package:mbm_app/core/database/isar_service.dart';
import 'package:mbm_app/core/repositories/settings_repository.dart';
import 'package:mbm_app/core/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Production Error Handling: Catch Flutter-level errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // TODO: Send to Sentry/Crashlytics in real production
    print('PRODUCTION ERROR: ${details.exception}');
  };

  // Custom Error UI: Prevent "Grey Screen of Death"
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Something went wrong', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(details.exception.toString(), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  };
  
  // Initialize Local Database (Isar)
  final isarService = IsarService();
  await isarService.init();

  // Initialize App Settings (SharedPreferences)
  final sharedPrefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      isarServiceProvider.overrideWithValue(isarService),
      sharedPrefsProvider.overrideWithValue(sharedPrefs),
    ],
  );

  // Start Background Sync Service
  container.read(syncServiceProvider).start();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MBMApp(),
    ),
  );
}

class MBMApp extends ConsumerWidget {
  const MBMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'MBM – Mobile Business Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

// Global provider for theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
