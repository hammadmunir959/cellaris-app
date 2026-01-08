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

  /// Load user data and subscription status
  Future<void> _loadUser(String uid) async {
    try {
      // First try to get user from Firestore
      final user = await _authService.getUser(uid);
      
      if (user != null) {
        // Sync subscription from Firebase (updates local storage)
        await _subscriptionService.syncFromFirebase(uid);
        
        // Check subscription validity
        final isValid = await _subscriptionService.isSubscriptionValid();
        
        state = state.copyWith(
          user: user,
          isSubscriptionValid: isValid,
          isLoading: false,
          isInitialized: true,
          error: null,
        );
      } else {
        // User document not found - only show error if not actively authenticating
        if (!_isAuthenticating) {
          state = state.copyWith(
            isLoading: false,
            isInitialized: true,
            error: 'User data not found',
          );
        }
      }
    } catch (e) {
      // Network error - try local subscription check (only if not actively authenticating)
      if (!_isAuthenticating) {
        final isValid = await _subscriptionService.isSubscriptionValid();
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          isSubscriptionValid: isValid,
          error: 'Offline mode - using cached data',
        );
      }
    }
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
    await _authService.logout();
    await _subscriptionService.clearLocal();
    state = const AuthState(isInitialized: true);
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

  /// Refresh subscription status from Firebase
  Future<void> refreshSubscription() async {
    if (state.user == null) return;
    
    try {
      await _subscriptionService.syncFromFirebase(state.user!.id);
      final isValid = await _subscriptionService.isSubscriptionValid();
      
      state = state.copyWith(isSubscriptionValid: isValid);
    } catch (e) {
      print('AuthController: Failed to refresh subscription: $e');
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
