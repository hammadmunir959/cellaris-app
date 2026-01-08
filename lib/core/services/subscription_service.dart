import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

// Platform-specific imports
import 'package:cloud_firestore/cloud_firestore.dart' as flutter_firestore;
import 'package:firebase_dart/firebase_dart.dart' as fb_dart;
import 'firestore_rest_client.dart';

/// Check if running on desktop platform
bool get _isDesktop {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}

/// Service for managing subscription status with secure local storage
/// Supports offline subscription validation with tamper-resistant storage
class SubscriptionService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // FlutterFire for web/mobile
  flutter_firestore.FirebaseFirestore? _flutterFirestore;
  
  // REST client for desktop
  FirestoreRestClient? _firestoreClient;

  // Encryption configuration
  static const String _encryptionKey = 'CELLARIS_SUBSCRIPTION_KEY_32Byte';
  static const String _ivString = '16CharactersIV!!';
  static const String _checksumSalt = 'CELLARIS_CHECKSUM_SALT_2024';
  static const String _storageKey = 'subscription_data';

  SubscriptionService() {
    if (_isDesktop) {
      _firestoreClient = FirestoreRestClient(projectId: 'cellaris-959');
      
      // Listen to auth state changes to update REST client token
      fb_dart.FirebaseAuth.instance.idTokenChanges().listen((user) async {
        if (user != null) {
          try {
            final token = await user.getIdToken();
            setAuthToken(token);
          } catch (e) {
            debugPrint('SubscriptionService: Failed to get auth token: $e');
          }
        } else {
          setAuthToken(null);
        }
      });
    } else {
      _flutterFirestore = flutter_firestore.FirebaseFirestore.instance;
    }
  }

  /// Set auth token for REST API (desktop only)
  void setAuthToken(String? token) {
    _firestoreClient?.setAuthToken(token);
  }

  encrypt.Encrypter get _encrypter {
    final key = encrypt.Key.fromUtf8(_encryptionKey);
    return encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  }

  encrypt.IV get _iv => encrypt.IV.fromUtf8(_ivString);

  /// Save subscription details to secure local storage
  Future<void> saveLocalData({
    required DateTime expiry, 
    required UserStatus status,
  }) async {
    try {
      final data = {
        'expiry': expiry.toIso8601String(),
        'status': status.name,
        'timestamp': DateTime.now().toIso8601String(),
        'checksum': _generateChecksum(expiry, status.name),
      };
      
      final jsonString = jsonEncode(data);
      final encrypted = _encrypter.encrypt(jsonString, iv: _iv);
      
      await _storage.write(key: _storageKey, value: encrypted.base64);
      debugPrint('SubscriptionService: Saved local data - Status: ${status.name}, Expiry: $expiry');
    } catch (e) {
      debugPrint('SubscriptionService: Error saving local data: $e');
    }
  }

  /// Supported for backward compatibility - assumes active status if saving just expiry
  Future<void> saveLocalExpiry(DateTime expiry) async {
    await saveLocalData(expiry: expiry, status: UserStatus.active);
  }

  /// Get local subscription data
  Future<({DateTime expiry, UserStatus status})?> getLocalData() async {
    try {
      final encryptedData = await _storage.read(key: _storageKey);
      if (encryptedData == null) return null;

      final decrypted = _encrypter.decrypt64(encryptedData, iv: _iv);
      final data = jsonDecode(decrypted) as Map<String, dynamic>;
      
      if (!data.containsKey('expiry')) return null;
      
      final expiry = DateTime.parse(data['expiry']);
      final storedChecksum = data['checksum'] as String;
      
      // Handle status (default to active for legacy data)
      final statusStr = data['status'] as String? ?? 'active';
      UserStatus status;
      try {
        status = UserStatus.values.firstWhere(
          (e) => e.name == statusStr, 
          orElse: () => UserStatus.expired
        );
      } catch (_) {
        status = UserStatus.expired;
      }
      
      // Verify checksum
      if (storedChecksum != _generateChecksum(expiry, statusStr)) {
        // Fallback for legacy checksums (expiry only)
         if (storedChecksum != _generateChecksumLegacy(expiry)) {
           debugPrint('SubscriptionService: Checksum mismatch - data may be tampered');
           await clearLocal();
           return null;
         }
      }
      
      return (expiry: expiry, status: status);
    } catch (e) {
      debugPrint('SubscriptionService: Error reading local data: $e');
      return null;
    }
  }

  /// Get subscription expiry from secure local storage
  Future<DateTime?> getLocalExpiry() async {
    final data = await getLocalData();
    return data?.expiry;
  }

  /// Generate checksum for tampering detection
  String _generateChecksum(DateTime expiry, String status) {
    final data = '${expiry.toIso8601String()}_${status}_$_checksumSalt';
    final bytes = utf8.encode(data);
    return base64Encode(bytes).substring(0, 24);
  }
  
  String _generateChecksumLegacy(DateTime expiry) {
    final data = '${expiry.toIso8601String()}_$_checksumSalt';
    final bytes = utf8.encode(data);
    return base64Encode(bytes).substring(0, 24);
  }

  /// Check if subscription is valid (works offline)
  Future<bool> isSubscriptionValid() async {
    final expiry = await getLocalExpiry();
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  /// Get days until subscription expires (negative if expired)
  Future<int> getDaysUntilExpiry() async {
    final expiry = await getLocalExpiry();
    if (expiry == null) return -999;
    return expiry.difference(DateTime.now()).inDays;
  }

  /// Sync subscription status from Firebase
  Future<DateTime?> syncFromFirebase(String userId) async {
    try {
      Map<String, dynamic>? data;
      
      if (_isDesktop) {
        // Use REST API for desktop
        data = await _firestoreClient!.getDocument('users', userId);
      } else {
        // Use FlutterFire for web/mobile
        final doc = await _flutterFirestore!.collection('users').doc(userId).get();
        if (!doc.exists) {
          debugPrint('SubscriptionService: User document not found');
          return null;
        }
        data = doc.data();
      }
      
      if (data == null) {
        debugPrint('SubscriptionService: User document not found');
        return null;
      }

      // Handle different expiry field formats
      DateTime? expiry;
      if (data['subscriptionExpiry'] != null) {
        final expiryVal = data['subscriptionExpiry'];
        if (expiryVal is DateTime) {
          expiry = expiryVal;
        } else if (expiryVal is flutter_firestore.Timestamp) {
          expiry = expiryVal.toDate();
        } else if (expiryVal is String) {
          expiry = DateTime.tryParse(expiryVal);
        }
      } else if (data['subscription']?['endDate'] != null) {
        final endDate = data['subscription']['endDate'];
        if (endDate is DateTime) {
          expiry = endDate;
        } else if (endDate is String) {
          expiry = DateTime.tryParse(endDate);
        }
      }
      
      if (expiry != null) {
        // Extract status
        final statusStr = data['status'] as String? ?? 'active';
        final status = UserStatus.values.firstWhere(
          (e) => e.firestoreValue == statusStr,
          orElse: () => UserStatus.values.firstWhere(
            (e) => e.name == statusStr,
            orElse: () => UserStatus.expired
          ),
        );

        await saveLocalData(expiry: expiry, status: status);
        debugPrint('SubscriptionService: Synced from Firebase: $status, Exp: $expiry');
      }
      
      return expiry;
    } catch (e) {
      debugPrint('SubscriptionService: Failed to sync from Firebase: $e');
      return await getLocalExpiry();
    }
  }

  /// Update subscription status to pending
  Future<void> updateStatusToPending(String userId) async {
    try {
      if (_isDesktop) {
        await _firestoreClient!.updateDocument('users', userId, {
          'status': 'pendingVerification',
        });
      } else {
        await _flutterFirestore!.collection('users').doc(userId).update({
          'status': 'pendingVerification',
        });
      }
    } catch (e) {
      debugPrint('SubscriptionService: Failed to update status: $e');
    }
  }

  /// Clear local subscription data (on logout)
  Future<void> clearLocal() async {
    await _storage.delete(key: _storageKey);
  }

  /// Check if any local subscription data exists
  Future<bool> hasLocalData() async {
    final data = await _storage.read(key: _storageKey);
    return data != null;
  }
}

/// Provider for SubscriptionService
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// Provider for subscription validity check
final subscriptionValidProvider = FutureProvider<bool>((ref) async {
  return ref.watch(subscriptionServiceProvider).isSubscriptionValid();
});

/// Provider for days until expiry
final daysUntilExpiryProvider = FutureProvider<int>((ref) async {
  return ref.watch(subscriptionServiceProvider).getDaysUntilExpiry();
});
