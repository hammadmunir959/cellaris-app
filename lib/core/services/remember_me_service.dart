import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for handling "Remember Me" functionality
/// Securely stores email for auto-fill on login
class RememberMeService {
  static const _emailKey = 'remembered_email';
  static const _rememberKey = 'remember_me_enabled';
  
  final FlutterSecureStorage _storage;
  
  RememberMeService() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Check if "Remember Me" is enabled
  Future<bool> isRememberMeEnabled() async {
    try {
      final value = await _storage.read(key: _rememberKey);
      return value == 'true';
    } catch (e) {
      debugPrint('RememberMeService: Error reading remember me status: $e');
      return false;
    }
  }

  /// Get remembered email (if any)
  Future<String?> getRememberedEmail() async {
    try {
      final isEnabled = await isRememberMeEnabled();
      if (!isEnabled) return null;
      
      return await _storage.read(key: _emailKey);
    } catch (e) {
      debugPrint('RememberMeService: Error reading remembered email: $e');
      return null;
    }
  }

  /// Save email and enable "Remember Me"
  Future<void> rememberUser(String email) async {
    try {
      await _storage.write(key: _emailKey, value: email);
      await _storage.write(key: _rememberKey, value: 'true');
      debugPrint('RememberMeService: Saved email for remember me');
    } catch (e) {
      debugPrint('RememberMeService: Error saving remember me data: $e');
    }
  }

  /// Clear remembered data
  Future<void> forgetUser() async {
    try {
      await _storage.delete(key: _emailKey);
      await _storage.write(key: _rememberKey, value: 'false');
      debugPrint('RememberMeService: Cleared remember me data');
    } catch (e) {
      debugPrint('RememberMeService: Error clearing remember me data: $e');
    }
  }

  /// Clear all auth-related data (for logout)
  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _rememberKey);
    } catch (e) {
      debugPrint('RememberMeService: Error clearing all data: $e');
    }
  }
}

/// Provider for RememberMeService
final rememberMeServiceProvider = Provider<RememberMeService>((ref) {
  return RememberMeService();
});

/// Provider for remembered email
final rememberedEmailProvider = FutureProvider<String?>((ref) async {
  return ref.watch(rememberMeServiceProvider).getRememberedEmail();
});

/// Provider for remember me status
final rememberMeEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(rememberMeServiceProvider).isRememberMeEnabled();
});
