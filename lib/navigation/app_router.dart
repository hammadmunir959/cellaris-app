import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cellaris/shared/layouts/app_layout.dart';
import 'package:cellaris/features/dashboard/view/dashboard_screen.dart';
import 'package:cellaris/features/sales/view/sales_screen.dart';
import 'package:cellaris/features/inventory/view/inventory_hub_screen.dart';
import 'package:cellaris/features/repairs/view/repairs_screen.dart';
import 'package:cellaris/features/analytics/view/analytics_screen.dart';
import 'package:cellaris/features/customers/view/customers_screen.dart';
import 'package:cellaris/features/suppliers/view/suppliers_screen.dart';
import 'package:cellaris/features/settings/view/settings_screen.dart';
import 'package:cellaris/features/profile/view/profile_screen.dart';
import 'package:cellaris/features/pos/view/returns_screen.dart';
import 'package:cellaris/features/auth/view/login_screen.dart';
import 'package:cellaris/features/auth/view/registration_screen.dart';
import 'package:cellaris/features/auth/view/forgot_password_screen.dart';
import 'package:cellaris/features/auth/view/subscription_expired_screen.dart';
import 'package:cellaris/features/auth/view/connection_error_screen.dart';
import 'package:cellaris/features/auth/view/subscription_guard.dart';
import 'package:cellaris/features/auth/controller/auth_controller.dart';
import 'package:cellaris/features/accounts/view/accounts_screen.dart';
import 'package:cellaris/features/stock/view/stock_issuance_screen.dart';
import 'package:cellaris/features/stock/view/unit_tracking_view.dart';
import 'package:cellaris/features/purchase_return/view/purchase_return_screen.dart';
import 'package:cellaris/features/transactions/view/transactions_history_screen.dart';
import 'package:cellaris/main.dart';
import 'package:cellaris/core/models/user_model.dart';

/// Helper function to determine if user can access the main app
/// ONLY allow: active status OR trial status with valid (not expired) subscription
bool _canUserAccessApp(AppUser user) {
  // Active users can access
  if (user.status == UserStatus.active) {
    // Also check if subscription date is still valid
    return user.subscriptionExpiry.isAfter(DateTime.now());
  }
  
  // Trial users can access ONLY if trial hasn't expired
  if (user.status == UserStatus.trial) {
    return user.subscriptionExpiry.isAfter(DateTime.now());
  }
  
  // All other statuses (pending, pendingVerification, expired, canceled, blocked) -> NO ACCESS
  return false;
}

/// App router configuration with authentication guards
/// Handles both online (Firebase) and offline (demo) modes
final appRouterProvider = Provider<GoRouter>((ref) {
  final isFirebaseAvailable = ref.watch(firebaseAvailableProvider);
  
  // Only watch auth state if Firebase is available
  AuthState? authState;
  if (isFirebaseAvailable) {
    authState = ref.watch(authControllerProvider);
  }

  return GoRouter(
    // Start at login, or error screen if Firebase failed
    initialLocation: isFirebaseAvailable ? '/login' : '/connection-error',
    debugLogDiagnostics: false,
    
    // Authentication redirect logic (only when Firebase is available)
    redirect: (context, state) {
      final location = state.matchedLocation;

      // If Firebase failed to initialize, redirect to error screen
      // unless we are already there or user explicitly chose dashboard (demo mode)
      if (!isFirebaseAvailable) {
        if (location == '/dashboard') return null; // Allow demo mode access
        if (location == '/connection-error') return null;
        return '/connection-error';
      }
      
      final isAuthenticated = authState?.isAuthenticated ?? false;
      final isInitialized = authState?.isInitialized ?? false;
      final user = authState?.user;
      
      // Auth routes that don't require authentication
      final authRoutes = ['/login', '/register', '/forgot-password'];
      final isAuthRoute = authRoutes.contains(location);
      
      // Wait for auth initialization
      if (!isInitialized && !isAuthRoute) {
        return '/login';
      }
      
      // Not authenticated -> redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }
      
      // Authenticated but on auth route -> check if can access app
      if (isAuthenticated && isAuthRoute && user != null) {
        final canAccessApp = _canUserAccessApp(user);
        return canAccessApp ? '/dashboard' : '/subscription-expired';
      }
      
      // Authenticated user - check if they can access the app
      if (isAuthenticated && user != null && !isAuthRoute) {
        final canAccessApp = _canUserAccessApp(user);
        
        // Block users who cannot access app
        if (!canAccessApp && location != '/subscription-expired') {
          return '/subscription-expired';
        }
        
        // User can access but is on subscription page -> redirect to dashboard
        if (canAccessApp && location == '/subscription-expired') {
          return '/dashboard';
        }
      }
      
      return null; // No redirect needed
    },
    
    routes: [
      // ==========================================
      // AUTH ROUTES (No Layout) - Only show when Firebase is available
      // ==========================================
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/connection-error',
        name: 'connection-error',
        builder: (context, state) => const ConnectionErrorScreen(),
      ),
      GoRoute(
        path: '/subscription-expired',
        name: 'subscription-expired',
        builder: (context, state) => const SubscriptionExpiredScreen(),
      ),
      
      // ==========================================
      // PROTECTED ROUTES (With Layout)
      // ==========================================
      ShellRoute(
        builder: (context, state, child) {
          // Wrap with SubscriptionGuard to auto-redirect if status becomes invalid
          return SubscriptionGuard(
            child: AppLayout(child: child),
          );
        },
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          
          // Unified Sales Screen (replaces POS and Sale Order)
          GoRoute(
            path: '/sales',
            name: 'sales',
            builder: (context, state) => const SalesScreen(),
          ),
          
          // Legacy redirects for backward compatibility
          GoRoute(
            path: '/pos',
            redirect: (context, state) => '/sales',
          ),
          GoRoute(
            path: '/sale-order',
            redirect: (context, state) => '/sales',
          ),
          
          // Inventory Hub
          GoRoute(
            path: '/inventory',
            name: 'inventory',
            builder: (context, state) => const InventoryHubScreen(),
          ),
          
          // Legacy redirects for consolidated inventory hub
          GoRoute(
            path: '/low-stock',
            redirect: (context, state) => '/inventory',
          ),
          GoRoute(
            path: '/purchases',
            redirect: (context, state) => '/inventory',
          ),

          // Stock Management
          GoRoute(
            path: '/stock-issuance',
            name: 'stock-issuance',
            builder: (context, state) => const StockIssuanceScreen(),
          ),
          GoRoute(
            path: '/unit-tracking',
            name: 'unit-tracking',
            builder: (context, state) => const Scaffold(body: UnitTrackingView()),
          ),
          
          // Repairs
          GoRoute(
            path: '/repairs',
            name: 'repairs',
            builder: (context, state) => const RepairsScreen(),
          ),
          
          // Purchase Returns
          GoRoute(
            path: '/purchase-return',
            name: 'purchase-return',
            builder: (context, state) => const PurchaseReturnScreen(),
          ),
          
          // Transaction History
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionsHistoryScreen(),
          ),
          
          // Analytics
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          
          // Accounts
          GoRoute(
            path: '/accounts',
            name: 'accounts',
            builder: (context, state) => const AccountsScreen(),
          ),
          
          // Customers
          GoRoute(
            path: '/customers',
            name: 'customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          
          // Suppliers
          GoRoute(
            path: '/suppliers',
            name: 'suppliers',
            builder: (context, state) => const SuppliersScreen(),
          ),
          
          // Returns
          GoRoute(
            path: '/returns',
            name: 'returns',
            builder: (context, state) => const ReturnsScreen(),
          ),
          
          // Settings
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          
          // Profile
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
