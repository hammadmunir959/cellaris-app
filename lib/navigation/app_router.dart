import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mbm_app/shared/layouts/app_layout.dart';
import 'package:mbm_app/features/dashboard/view/dashboard_screen.dart';
import 'package:mbm_app/features/sales/view/sales_screen.dart';
import 'package:mbm_app/features/inventory/view/inventory_hub_screen.dart';
import 'package:mbm_app/features/repairs/view/repairs_screen.dart';
import 'package:mbm_app/features/analytics/view/analytics_screen.dart';
import 'package:mbm_app/features/customers/view/customers_screen.dart';
import 'package:mbm_app/features/suppliers/view/suppliers_screen.dart';
import 'package:mbm_app/features/settings/view/settings_screen.dart';
import 'package:mbm_app/features/pos/view/returns_screen.dart';
import 'package:mbm_app/features/auth/view/login_screen.dart';
import 'package:mbm_app/features/accounts/view/accounts_screen.dart';
import 'package:mbm_app/features/stock/view/stock_issuance_screen.dart';
import 'package:mbm_app/features/stock/view/unit_tracking_view.dart';
import 'package:mbm_app/features/purchase_return/view/purchase_return_screen.dart';
import 'package:mbm_app/features/transactions/view/transactions_history_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppLayout(child: child);
        },
        routes: [
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
          GoRoute(
            path: '/repairs',
            name: 'repairs',
            builder: (context, state) => const RepairsScreen(),
          ),
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
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/accounts',
            name: 'accounts',
            builder: (context, state) => const AccountsScreen(),
          ),
          GoRoute(
            path: '/customers',
            name: 'customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/suppliers',
            name: 'suppliers',
            builder: (context, state) => const SuppliersScreen(),
          ),
          GoRoute(
            path: '/returns',
            name: 'returns',
            builder: (context, state) => const ReturnsScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
