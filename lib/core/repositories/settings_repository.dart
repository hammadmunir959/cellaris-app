import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static const _themeKey = 'theme_mode';
  static const _sidebarKey = 'sidebar_expanded';
  static const _lastScreenKey = 'last_active_screen';

  Future<void> setThemeMode(String mode) => _prefs.setString(_themeKey, mode);
  String getThemeMode() => _prefs.getString(_themeKey) ?? 'dark';

  Future<void> setSidebarState(bool expanded) => _prefs.setBool(_sidebarKey, expanded);
  bool getSidebarState() => _prefs.getBool(_sidebarKey) ?? true;

  Future<void> setLastScreen(String screen) => _prefs.setString(_lastScreenKey, screen);
  String getLastScreen() => _prefs.getString(_lastScreenKey) ?? '/dashboard';
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main.dart');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(sharedPrefsProvider));
});
