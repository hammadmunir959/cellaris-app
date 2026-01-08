import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'firestore_rest_client.dart';

// Firebase Dart SDK for desktop
import 'package:firebase_dart/firebase_dart.dart' as fb_dart;

// FlutterFire for web/mobile (compiled conditionally)
import 'package:firebase_auth/firebase_auth.dart' as flutter_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as flutter_firestore;

/// Check if running on desktop platform  
bool get _isDesktop {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}

/// Unified Auth Service that works on all platforms
/// - Desktop (Linux/Windows): Uses firebase_dart for auth + REST API for Firestore
/// - Web/Mobile: Uses FlutterFire packages
class AuthService {
  // Desktop components
  fb_dart.FirebaseAuth? _desktopAuth;
  FirestoreRestClient? _firestoreClient;
  
  // FlutterFire components
  flutter_auth.FirebaseAuth? _flutterAuth;
  flutter_firestore.FirebaseFirestore? _flutterFirestore;
  
  // Config
  final String projectId;
  
  AuthService({required this.projectId}) {
    if (_isDesktop) {
      _desktopAuth = fb_dart.FirebaseAuth.instance;
      _firestoreClient = FirestoreRestClient(projectId: projectId);
    } else {
      _flutterAuth = flutter_auth.FirebaseAuth.instance;
      _flutterFirestore = flutter_firestore.FirebaseFirestore.instance;
    }
  }

  /// Stream of authentication state changes
  Stream<dynamic> get authStateChanges {
    if (_isDesktop) {
      return _desktopAuth!.authStateChanges();
    } else {
      return _flutterAuth!.authStateChanges();
    }
  }



  /// Get current user ID
  String? get currentUserId {
    if (_isDesktop) {
      return _desktopAuth!.currentUser?.uid;
    } else {
      return _flutterAuth!.currentUser?.uid;
    }
  }

  /// Get current user email
  String? get currentUserEmail {
    if (_isDesktop) {
      return _desktopAuth!.currentUser?.email;
    } else {
      return _flutterAuth!.currentUser?.email;
    }
  }

  /// Get current user display name
  String? get currentUserName {
    if (_isDesktop) {
      return _desktopAuth!.currentUser?.displayName;
    } else {
      return _flutterAuth!.currentUser?.displayName;
    }
  }

  /// Check if signed in
  bool get isSignedIn => currentUserId != null;

  /// Register a new user
  Future<AppUser> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? companyName,
  }) async {
    try {
      String uid;
      
      if (_isDesktop) {
        final credential = await _desktopAuth!.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (credential.user == null) throw Exception('Failed to create user');
        uid = credential.user!.uid;
        
        // Update display name
        await credential.user!.updateProfile(displayName: name);
        
        // Get ID token for Firestore REST API
        final idToken = await credential.user!.getIdToken();
        _firestoreClient!.setAuthToken(idToken!);
        
        // Create user document via REST API
        final now = DateTime.now();
        await _firestoreClient!.setDocument('users', uid, {
          'email': email,
          'name': name,
          'phone': phone,
          'companyName': companyName,
          'status': 'pending',
          'approved': false,
          'role': 'salesProfessional',
          'subscription': {
            'plan': null,
            'startDate': null,
            'endDate': null,
          },
          'security': {
            'maxOfflineDays': 7,
          },
          'createdAt': now,
          'lastLoginAt': now,
        });
      } else {
        // FlutterFire path
        final credential = await _flutterAuth!.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (credential.user == null) throw Exception('Failed to create user');
        uid = credential.user!.uid;
        await credential.user!.updateDisplayName(name);
        
        await _flutterFirestore!.collection('users').doc(uid).set({
          'email': email,
          'name': name,
          'phone': phone,
          'companyName': companyName,
          'status': 'pending',
          'approved': false,
          'role': 'salesProfessional',
          'subscription': {
            'plan': null,
            'startDate': null,
            'endDate': null,
          },
          'security': {
            'maxOfflineDays': 7,
          },
          'createdAt': flutter_firestore.FieldValue.serverTimestamp(),
          'lastLoginAt': flutter_firestore.FieldValue.serverTimestamp(),
        });
      }

      final now = DateTime.now();
      return AppUser(
        id: uid,
        email: email,
        name: name,
        role: UserRole.salesProfessional,
        subscriptionExpiry: now,
        status: UserStatus.pendingVerification,
        createdAt: now,
        lastLoginAt: now,
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Sign in with email and password
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      String uid;
      
      if (_isDesktop) {
        final credential = await _desktopAuth!.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (credential.user == null) throw Exception('Failed to sign in');
        uid = credential.user!.uid;
        
        // Get ID token for Firestore REST API
        final idToken = await credential.user!.getIdToken();
        _firestoreClient!.setAuthToken(idToken!);
        
        // Update last login
        await _firestoreClient!.updateDocument('users', uid, {
          'lastLoginAt': DateTime.now(),
        });
      } else {
        final credential = await _flutterAuth!.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (credential.user == null) throw Exception('Failed to sign in');
        uid = credential.user!.uid;
        
        await _flutterFirestore!.collection('users').doc(uid).update({
          'lastLoginAt': flutter_firestore.FieldValue.serverTimestamp(),
        });
      }

      final user = await getUser(uid);
      if (user == null) throw Exception('User data not found');
      return user;
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Get user data by UID
  Future<AppUser?> getUser(String uid) async {
    try {
      if (_isDesktop) {
        final data = await _firestoreClient!.getDocument('users', uid);
        if (data == null) return null;
        return AppUser.fromMap(uid, data);
      } else {
        final doc = await _flutterFirestore!.collection('users').doc(uid).get();
        if (!doc.exists) return null;
        return AppUser.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Get user stream by UID (Real-time updates)
  Stream<AppUser?> getUserStream(String uid) {
    if (_isDesktop) {
      // Desktop uses REST, so we must poll for "real-time" updates
      // Poll every 5 seconds to simulate a stream
      return Stream.periodic(const Duration(seconds: 5))
          .asyncMap((_) => getUser(uid));
    } else {
      // Mobile/Web uses native Firestore streams
      return _flutterFirestore!
          .collection('users')
          .doc(uid)
          .snapshots()
          .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
    }
  }

  /// Get current app user
  Future<AppUser?> getCurrentAppUser() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return await getUser(uid);
  }

  /// Sign out
  Future<void> logout() async {
    if (_isDesktop) {
      await _desktopAuth!.signOut();
    } else {
      await _flutterAuth!.signOut();
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      if (_isDesktop) {
        await _desktopAuth!.sendPasswordResetEmail(email: email);
      } else {
        await _flutterAuth!.sendPasswordResetEmail(email: email);
      }
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Handle exceptions with user-friendly messages
  Exception _handleException(dynamic e) {
    final errorString = e.toString().toLowerCase();
    String message = 'An error occurred';
    
    if (errorString.contains('user-not-found') || errorString.contains('user not found')) {
      message = 'No account found with this email.';
    } else if (errorString.contains('wrong-password') || errorString.contains('incorrect')) {
      message = 'Incorrect password. Please try again.';
    } else if (errorString.contains('email-already-in-use') || errorString.contains('already in use')) {
      message = 'An account already exists with this email.';
    } else if (errorString.contains('weak-password') || errorString.contains('weak')) {
      message = 'Password is too weak. Use at least 6 characters.';
    } else if (errorString.contains('invalid-email') || errorString.contains('invalid email')) {
      message = 'Please enter a valid email address.';
    } else if (errorString.contains('too-many-requests')) {
      message = 'Too many attempts. Please try again later.';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      message = 'Network error. Please check your connection.';
    } else {
      message = 'Error: $e';
    }
    
    return Exception(message);
  }
}

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(projectId: 'cellaris-959');
});

/// Provider for auth state stream
final authStateProvider = StreamProvider<dynamic>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
