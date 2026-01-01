import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/shared/controller/shared_controller.dart';
import 'package:mbm_app/features/inventory/controller/inventory_controller.dart';

import '../controller/unified_sales_controller.dart';
import '../../pos/view/imei_selection_dialog.dart';

/// Unified Sales Screen with Tabs
class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        // Header Row (matches inventory hub style)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sales', style: theme.textTheme.displayMedium?.copyWith(fontSize: 28)),
                const SizedBox(height: 4),
                const Text('Point of Sale & Order Management', style: TextStyle(color: Colors.grey)),
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
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(child: Row(children: [Icon(LucideIcons.shoppingCart, size: 16), SizedBox(width: 8), Text('POS')])),
                  Tab(child: Row(children: [Icon(LucideIcons.history, size: 16), SizedBox(width: 8), Text('Sales History')])),
                  Tab(child: Row(children: [Icon(LucideIcons.globe, size: 16), SizedBox(width: 8), Text('Online Orders')])),
                  Tab(child: Row(children: [Icon(LucideIcons.pauseCircle, size: 16), SizedBox(width: 8), Text('On Hold')])),
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
            children: [
              _POSTab(),
              _SalesHistoryTab(),
              _OnlineOrdersTab(),
              _OnHoldTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TAB 1: POS
// ============================================================

class _POSTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unifiedSalesProvider);
    final products = ref.watch(salesFilteredProductsProvider);
    final allProducts = ref.watch(productProvider);
    final List<String> categories = ['All', ...allProducts.map((e) => e.category).toSet()];
    final currentCategory = ref.watch(salesCategoryFilterProvider);

    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.f1) ref.read(unifiedSalesProvider.notifier).setMode(SalesMode.directSale);
          else if (event.logicalKey == LogicalKeyboardKey.f2) ref.read(unifiedSalesProvider.notifier).setMode(SalesMode.createOrder);
          else if (event.logicalKey == LogicalKeyboardKey.f3) ref.read(unifiedSalesProvider.notifier).holdCurrentOrder();
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Products
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Search & Category Filter
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => ref.read(salesSearchQueryProvider.notifier).state = val,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: const Icon(LucideIcons.search, size: 18),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentCategory,
                          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) => ref.read(salesCategoryFilterProvider.notifier).state = v ?? 'All',
                          dropdownColor: AppTheme.darkBg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Product Grid
                Expanded(
                  child: products.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(LucideIcons.searchX, size: 48, color: Colors.grey.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text('No products found', style: TextStyle(color: Colors.grey[600])),
                        ]))
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _ProductCard(product: product, onTap: () => _addToCart(context, product, ref));
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Right: Cart
          SizedBox(
            width: 360,
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Cart Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          const Icon(LucideIcons.shoppingCart, size: 18),
                          const SizedBox(width: 8),
                          Text('Cart (${state.items.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                        // Mode Toggle
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              _ModeChip(label: 'Sale', isActive: state.isDirectSale, onTap: () => ref.read(unifiedSalesProvider.notifier).setMode(SalesMode.directSale)),
                              _ModeChip(label: 'Order', isActive: state.isCreateOrder, onTap: () => ref.read(unifiedSalesProvider.notifier).setMode(SalesMode.createOrder)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Customer Row
                  _CustomerRow(state: state, ref: ref),
                  const Divider(height: 1),
                  // Cart Items
                  Expanded(
                    child: state.items.isEmpty
                        ? Center(child: Text('Add products to cart', style: TextStyle(color: Colors.grey[600], fontSize: 13)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: state.items.length,
                            itemBuilder: (context, index) {
                              final item = state.items[index];
                              return _CartItem(item: item, ref: ref);
                            },
                          ),
                  ),
                  // Footer
                  _CartFooter(state: state, ref: ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context, Product product, WidgetRef ref) async {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} is out of stock'), backgroundColor: Colors.red));
      return;
    }
    if (product.requiresImei) {
      final imeis = await showImeiSelectionDialog(context, product);
      if (imeis != null && imeis.isNotEmpty) ref.read(unifiedSalesProvider.notifier).addToCartWithImeis(product, imeis);
    } else {
      ref.read(unifiedSalesProvider.notifier).addToCart(product);
    }
  }
}

// Mode Chip (Sale/Order toggle)
class _ModeChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ModeChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.white : Colors.grey)),
      ),
    );
  }
}

// Product Card (Compact)
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOut = product.stock <= 0;
    return InkWell(
      onTap: isOut ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Stack(
                  children: [
                    Center(child: Icon(product.isSerialized ? LucideIcons.smartphone : LucideIcons.package, size: 32, color: isOut ? Colors.grey : AppTheme.primaryColor)),
                    if (isOut) Positioned(top: 6, right: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: const Text('Out', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)))),
                    if (product.isSerialized && !isOut) Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)), child: const Text('IMEI', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(product.sku, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text('Rs. ${NumberFormat('#,###').format(product.sellingPrice)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isOut ? Colors.grey : AppTheme.primaryColor), overflow: TextOverflow.ellipsis)),
                if (!isOut) Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle), child: const Icon(LucideIcons.plus, size: 12, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Customer Row (Compact)
class _CustomerRow extends StatelessWidget {
  final UnifiedSalesState state;
  final WidgetRef ref;
  const _CustomerRow({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(hintText: 'Customer name', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), fillColor: Colors.white.withOpacity(0.05), filled: true),
              onChanged: (v) => ref.read(unifiedSalesProvider.notifier).setWalkInName(v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 12),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(hintText: 'Phone', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), fillColor: Colors.white.withOpacity(0.05), filled: true),
              onChanged: (v) => ref.read(unifiedSalesProvider.notifier).setWalkInPhone(v),
            ),
          ),
        ],
      ),
    );
  }
}

// Cart Item Row
class _CartItem extends StatelessWidget {
  final SalesCartItem item;
  final WidgetRef ref;
  const _CartItem({required this.item, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Rs. ${NumberFormat('#,###').format(item.product.sellingPrice)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          // Qty
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QtyBtn(icon: LucideIcons.minus, onTap: () => ref.read(unifiedSalesProvider.notifier).updateQuantity(item.product.id, -1)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold))),
              _QtyBtn(icon: LucideIcons.plus, onTap: () => ref.read(unifiedSalesProvider.notifier).updateQuantity(item.product.id, 1)),
            ],
          ),
          const SizedBox(width: 12),
          Text('Rs. ${NumberFormat('#,###').format(item.lineTotal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor)),
          IconButton(icon: const Icon(LucideIcons.x, size: 14, color: Colors.red), onPressed: () => ref.read(unifiedSalesProvider.notifier).removeFromCart(item.product.id), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(5)), child: Icon(icon, size: 12)),
    );
  }
}

// Cart Footer
class _CartFooter extends StatelessWidget {
  final UnifiedSalesState state;
  final WidgetRef ref;
  const _CartFooter({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final total = state.items.fold(0.0, (sum, i) => sum + i.lineTotal) - state.discountAmount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Rs. ${NumberFormat('#,###').format(total)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: state.items.isEmpty ? null : () => ref.read(unifiedSalesProvider.notifier).holdCurrentOrder(), child: const Text('Hold', style: TextStyle(fontSize: 12)))),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: ElevatedButton(
                onPressed: state.items.isEmpty ? null : () async {
                  final result = state.isDirectSale 
                    ? await ref.read(unifiedSalesProvider.notifier).processDirectSale()
                    : await ref.read(unifiedSalesProvider.notifier).saveOrder();
                  if (result != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${state.isDirectSale ? 'Sale' : 'Order'} completed: $result'), backgroundColor: Colors.green));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(state.isDirectSale ? 'Pay Now' : 'Save Order', style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 2: Sales History
// ============================================================

class _SalesHistoryTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SalesHistoryTab> createState() => _SalesHistoryTabState();
}

class _SalesHistoryTabState extends ConsumerState<_SalesHistoryTab> {
  String searchQuery = '';
  String? statusFilter;
  int currentPage = 0;
  static const int pageSize = 12;

  @override
  Widget build(BuildContext context) {
    final mockSales = _getMockSales();
    final filtered = _filterSales(mockSales);
    final paginated = _paginateSales(filtered);
    final totalRevenue = mockSales.fold(0.0, (sum, s) => sum + (s['total'] as double));

    return Column(
      children: [
        // Stats & Filters Row
        Row(
          children: [
            _StatBadge(icon: LucideIcons.receipt, label: 'Total', value: '${mockSales.length}', color: Colors.blue),
            const SizedBox(width: 12),
            _StatBadge(icon: LucideIcons.dollarSign, label: 'Revenue', value: 'Rs. ${NumberFormat.compact().format(totalRevenue)}', color: Colors.green),
            const Spacer(),
            // Search
            SizedBox(
              width: 200,
              child: TextField(
                onChanged: (v) => setState(() { searchQuery = v; currentPage = 0; }),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(LucideIcons.search, size: 16),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Status Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: statusFilter,
                  hint: const Text('Status', style: TextStyle(fontSize: 12)),
                  items: [null, 'Completed', 'Pending', 'Cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s ?? 'All', style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() { statusFilter = v; currentPage = 0; }),
                  dropdownColor: AppTheme.darkBg,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Table
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
                  child: const Row(children: [
                    Expanded(flex: 2, child: Text('Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 1, child: Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                  ]),
                ),
                // Rows
                Expanded(
                  child: ListView.builder(
                    itemCount: paginated.length,
                    itemBuilder: (context, index) {
                      final s = paginated[index];
                      final statusColor = s['status'] == 'Completed' ? Colors.green : (s['status'] == 'Pending' ? Colors.orange : Colors.red);
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
                        child: Row(children: [
                          Expanded(flex: 2, child: Text(s['invoice'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                          Expanded(flex: 2, child: Text(s['customer'], style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 2, child: Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(s['date'])), style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 1, child: Text('${s['items']}', style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 2, child: Text('Rs. ${NumberFormat('#,###').format(s['total'])}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor))),
                          Expanded(flex: 1, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(s['status'], style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)))),
                        ]),
                      );
                    },
                  ),
                ),
                // Pagination
                if (filtered.length > pageSize)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${currentPage * pageSize + 1}-${((currentPage + 1) * pageSize).clamp(0, filtered.length)} of ${filtered.length}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      Row(children: [
                        IconButton(icon: const Icon(LucideIcons.chevronLeft, size: 16), onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null),
                        Text('${currentPage + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(LucideIcons.chevronRight, size: 16), onPressed: currentPage < (filtered.length / pageSize).ceil() - 1 ? () => setState(() => currentPage++) : null),
                      ]),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filterSales(List<Map<String, dynamic>> sales) {
    return sales.where((s) {
      if (searchQuery.isNotEmpty && !s['invoice'].toLowerCase().contains(searchQuery.toLowerCase()) && !s['customer'].toLowerCase().contains(searchQuery.toLowerCase())) return false;
      if (statusFilter != null && s['status'] != statusFilter) return false;
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _paginateSales(List<Map<String, dynamic>> sales) {
    final start = currentPage * pageSize;
    return sales.sublist(start, (start + pageSize).clamp(0, sales.length));
  }

  List<Map<String, dynamic>> _getMockSales() {
    return List.generate(40, (i) => {
      'invoice': 'INV-${1000 + i}',
      'customer': ['Ali Khan', 'Sara Ahmed', 'Usman Ali', 'Fatima Noor', 'Hassan'][i % 5],
      'date': DateTime.now().subtract(Duration(days: i)).toIso8601String(),
      'items': (i % 5) + 1,
      'total': (15000 + (i * 1500)).toDouble(),
      'status': ['Completed', 'Completed', 'Pending', 'Completed', 'Cancelled'][i % 5],
    });
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatBadge({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ]),
      ]),
    );
  }
}

// ============================================================
// TAB 3: Online Orders
// ============================================================

class _OnlineOrdersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.globe, size: 56, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Online Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Connect your online store to manage orders', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 20),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.link, size: 14), label: const Text('Connect Store')),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 4: On Hold
// ============================================================

class _OnHoldTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heldOrders = ref.watch(unifiedSalesProvider).heldOrders;

    if (heldOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.pauseCircle, size: 56, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No Held Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Press F3 in POS to hold an order', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1.4, crossAxisSpacing: 16, mainAxisSpacing: 16),
      itemCount: heldOrders.length,
      itemBuilder: (context, index) {
        final order = heldOrders.values.elementAt(index);
        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Icon(LucideIcons.pauseCircle, color: Colors.orange, size: 16)),
                const SizedBox(width: 10),
                Expanded(child: Text(order.customerName ?? 'Walk-in', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
              ]),
              const Spacer(),
              Text('${order.itemCount} items • Rs. ${NumberFormat('#,###').format(order.total)}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => ref.read(unifiedSalesProvider.notifier).deleteHeldOrder(order.id), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)), child: const Text('Delete', style: TextStyle(fontSize: 11)))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: () => ref.read(unifiedSalesProvider.notifier).resumeHeldOrder(order.id), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor), child: const Text('Resume', style: TextStyle(fontSize: 11)))),
              ]),
            ],
          ),
        );
      },
    );
  }
}
