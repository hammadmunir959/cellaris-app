import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'tabs/all_products_tab.dart';
import 'tabs/low_stock_tab.dart';
import 'tabs/purchase_orders_tab.dart';

class InventoryHubScreen extends ConsumerStatefulWidget {
  const InventoryHubScreen({super.key});

  @override
  ConsumerState<InventoryHubScreen> createState() => _InventoryHubScreenState();
}

class _InventoryHubScreenState extends ConsumerState<InventoryHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory & Procurement',
                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage products, stock levels, and purchase orders.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(
                    child: Row(
                      children: [
                        Icon(LucideIcons.package, size: 16),
                        SizedBox(width: 8),
                        Text('All Products'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      children: [
                        Icon(LucideIcons.alertTriangle, size: 16),
                        SizedBox(width: 8),
                        Text('Low Stock'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      children: [
                        Icon(LucideIcons.shoppingCart, size: 16),
                        SizedBox(width: 8),
                        Text('Purchase Orders'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              AllProductsTab(),
              LowStockTab(),
              PurchaseOrdersTab(),
            ],
          ),
        ),
      ],
    );
  }
}
