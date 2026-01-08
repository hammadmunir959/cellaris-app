import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/subscription_service.dart';

/// Authentication state for the app
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  final bool isSubscriptionValid;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isSubscriptionValid = false,
    this.isInitialized = false,
  });

  /// Check if user is authenticated
  bool get isAuthenticated => user != null;

  /// Check if subscription is expired
  bool get isExpired => isAuthenticated && !isSubscriptionValid;

  /// Create a copy with modified fields
  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool? isSubscriptionValid,
    bool? isInitialized,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSubscriptionValid: isSubscriptionValid ?? this.isSubscriptionValid,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  String toString() => 'AuthState(user: ${user?.email}, isAuthenticated: $isAuthenticated, isSubscriptionValid: $isSubscriptionValid)';
}

/// Controller for managing authentication state
class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;
  final SubscriptionService _subscriptionService;
  
  // Flag to prevent auth state listener from interfering during active login/register
  bool _isAuthenticating = false;
  
  // Real-time user stream subscription
  StreamSubscription<AppUser?>? _userSubscription;

  AuthController(this._authService, this._subscriptionService) : super(const AuthState()) {
    _initialize();
  }

  /// Initialize auth state on app startup
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    
    // Listen to Firebase auth state changes
    // Note: authStateChanges returns dynamic because it can be
    // either firebase_auth.User or firebase_dart.User depending on platform
    _authService.authStateChanges.listen((user) async {
      // Skip if we're actively authenticating (login/register in progress)
      if (_isAuthenticating) return;
      
      if (user != null) {
        // Get UID from either FlutterFire User or firebase_dart User
        final uid = user.uid as String?;
        if (uid != null) {
          await _loadUser(uid);
        } else {
          state = const AuthState(isInitialized: true);
        }
      } else {
        state = const AuthState(isInitialized: true);
      }
    });

    // Check if already logged in
    final currentUid = _authService.currentUserId;
    if (currentUid != null) {
      await _loadUser(currentUid);
    } else {
      state = const AuthState(isInitialized: true);
    }
  }

  /// Load user data and subscribe to real-time updates
  Future<void> _loadUser(String uid) async {
    // Cancel existing subscription if any
    await _userSubscription?.cancel();
    _userSubscription = null;
    
    try {
      // First try to get initial data
      final user = await _authService.getUser(uid);
      
      if (user != null) {
        _updateUserState(user);
        
        // Listen to real-time updates
        _userSubscription = _authService.getUserStream(uid).listen(
          (updatedUser) {
            if (updatedUser != null) {
              _updateUserState(updatedUser);
            } else {
              // User deleted or permission denied
              state = state.copyWith(error: 'User data not found');
            }
          },
          onError: (e) {
            debugPrint('AuthController: User stream error: $e');
            // Don't change state on stream error, keep last known good state
          },
        );
      } else {
        if (!_isAuthenticating) {
          state = state.copyWith(
            isLoading: false,
            isInitialized: true,
            error: 'User document not found',
          );
        }
      }

    } catch (e) {
      // Network error - try to recover using local storage
      if (!_isAuthenticating) {
        debugPrint('AuthController: Network error ($e), attempting offline recovery...');
        
        try {
          // Get secure local data (Status + Expiry)
          final localData = await _subscriptionService.getLocalData();
          
          if (localData != null) {
            // Reconstruct user from cached auth data + secure local storage
            final offlineUser = AppUser(
              id: uid,
              email: _authService.currentUserEmail ?? 'offline@cellaris.app',
              name: _authService.currentUserName ?? 'Offline User',
              role: UserRole.salesProfessional, // Default role for offline
              status: localData.status,
              subscriptionExpiry: localData.expiry,
              createdAt: DateTime.now(), // Placeholder
              lastLoginAt: DateTime.now(),
            );
            
            // Check access based on recovered data
            final canAccess = (offlineUser.status == UserStatus.active || 
                             offlineUser.status == UserStatus.trial) &&
                             offlineUser.subscriptionExpiry.isAfter(DateTime.now());
            
            state = state.copyWith(
              user: offlineUser,
              isSubscriptionValid: canAccess,
              isLoading: false,
              isInitialized: true,
              error: 'Offline Mode - Functionality may be limited',
            );
            
            debugPrint('AuthController: Recovered offline user - Status: ${offlineUser.status.name}, Access: $canAccess');
          } else {
            // No local data found
            state = state.copyWith(
              isLoading: false,
              isInitialized: true,
              error: 'Connection failed and no local data found',
            );
          }
        } catch (localError) {
          debugPrint('AuthController: Offline recovery failed: $localError');
          state = state.copyWith(
            isLoading: false,
            isInitialized: true,
            error: 'Connection error',
          );
        }
      }
    }
  }

  /// Helper to update state from user object
  Future<void> _updateUserState(AppUser user) async {
    // Sync subscription details
    await _subscriptionService.syncFromFirebase(user.id);
    
    // Check access rights
    final canAccess = (user.status == UserStatus.active || user.status == UserStatus.trial) &&
        user.subscriptionExpiry.isAfter(DateTime.now());
        
    state = state.copyWith(
      user: user,
      isSubscriptionValid: canAccess,
      isLoading: false,
      isInitialized: true,
      error: null,
    );
    
    debugPrint('AuthController: User updated - Status: ${user.status.name}, Access: $canAccess');
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _isAuthenticating = true;
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authService.login(email: email, password: password);
      
      // Save subscription expiry locally
      await _subscriptionService.saveLocalExpiry(user.subscriptionExpiry);
      
      state = state.copyWith(
        user: user,
        isSubscriptionValid: user.isSubscriptionValid,
        isLoading: false,
        error: null,
      );
      
      _isAuthenticating = false;
      return true;
    } catch (e) {
      _isAuthenticating = false;
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Register a new user
  Future<bool> register(String email, String password, String name) async {
    _isAuthenticating = true;
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authService.register(
        email: email,
        password: password,
        name: name,
      );
      
      // Save subscription expiry locally (7-day trial)
      await _subscriptionService.saveLocalExpiry(user.subscriptionExpiry);
      
      state = state.copyWith(
        user: user,
        isSubscriptionValid: user.isSubscriptionValid,
        isLoading: false,
        error: null,
      );
      
      _isAuthenticating = false;
      return true;
    } catch (e) {
      _isAuthenticating = false;
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Logout and clear local data
  Future<void> logout() async {
    await _userSubscription?.cancel();
    _userSubscription = null;
    await _authService.logout();
    await _subscriptionService.clearLocal();
    state = const AuthState(isInitialized: true);
  }
  
  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  /// Request password reset email
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authService.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Refresh user data and subscription status from Firebase
  /// This reloads the full user document including status changes
  Future<void> refreshSubscription() async {
    if (state.user == null) return;
    
    try {
      final uid = state.user!.id;
      
      // Reload full user data from Firebase
      final user = await _authService.getUser(uid);
      
      if (user != null) {
        // Sync subscription from Firebase
        await _subscriptionService.syncFromFirebase(uid);
        final isValid = await _subscriptionService.isSubscriptionValid();
        
        // Check if user can still access the app
        final canAccess = (user.status == UserStatus.active || user.status == UserStatus.trial) &&
            user.subscriptionExpiry.isAfter(DateTime.now());
        
        state = state.copyWith(
          user: user,
          isSubscriptionValid: canAccess,
        );
        
        debugPrint('AuthController: Refreshed user - Status: ${user.status.name}, CanAccess: $canAccess');
      }
    } catch (e) {
      debugPrint('AuthController: Failed to refresh subscription: $e');
    }
  }

  /// Check subscription validity (for startup)
  Future<void> checkSubscription() async {
    final isValid = await _subscriptionService.isSubscriptionValid();
    state = state.copyWith(isSubscriptionValid: isValid);
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authServiceProvider),
    ref.watch(subscriptionServiceProvider),
  );
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isAuthenticated;
});

/// Provider for checking if subscription is valid
final isSubscriptionValidProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isSubscriptionValid;
});

/// Provider for current user
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});
