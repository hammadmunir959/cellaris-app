import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/features/inventory/controller/inventory_controller.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/shared/controller/shared_controller.dart';
import 'package:mbm_app/features/inventory/controller/purchase_order_controller.dart';
import 'purchase_order_dialog.dart';
import 'add_product_modal.dart';

import 'dart:io';

class LowStockScreen extends ConsumerStatefulWidget {
  const LowStockScreen({super.key});

  @override
  ConsumerState<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends ConsumerState<LowStockScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = ref.watch(productProvider);
    
    // Logic for filtering
    final lowStockProducts = products.where((p) {
      final isLow = p.stock <= p.lowStockThreshold;
      if (!isLow) return false;

      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;

      if (_selectedStatus == 'Out of Stock') return p.stock == 0;
      if (_selectedStatus == 'Critical') return p.stock > 0 && p.stock <= (p.lowStockThreshold / 2);
      
      return true;
    }).toList();

    final outOfStockCount = products.where((p) => p.stock == 0).length;
    final criticalCount = products.where((p) => p.stock > 0 && p.stock <= (p.lowStockThreshold / 2)).length;

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, lowStockProducts.length, products),
          const SizedBox(height: 24),
          _buildSummaryCards(context, lowStockProducts.length, outOfStockCount, criticalCount),
          const SizedBox(height: 32),
          _buildFilters(context),
          const SizedBox(height: 20),
          Expanded(
            child: lowStockProducts.isEmpty 
            ? _buildEmptyState(context)
            : _buildProductList(context, lowStockProducts),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int total, List<Product> products) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock Intelligence', style: theme.textTheme.displayMedium?.copyWith(fontSize: 28)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
                  ),
                  child: const Text('LIVE ALERTS', style: TextStyle(color: AppTheme.errorColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text('Monitor and replenish high-risk inventory items.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            PrimaryButton(
              label: 'Export List',
              onPressed: () => _exportLowStockData(context, products),
              icon: LucideIcons.download,
              width: 140,
              color: Colors.blueGrey,
            ),
            const SizedBox(width: 12),
            PrimaryButton(
              label: 'View Active POs',
              onPressed: () => _showActivePOsDialog(context),
              icon: LucideIcons.list,
              width: 160,
              color: Colors.indigo,
            ),
            const SizedBox(width: 12),
            PrimaryButton(
              label: 'Create Bulk PO',
              onPressed: () => _showBulkOrderDialog(context, total),
              icon: LucideIcons.shoppingCart,
              width: 180,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, int total, int out, int critical) {
    return Row(
      children: [
        Expanded(child: _buildKPI(context, 'Total Alerts', total.toString(), LucideIcons.alertTriangle, Colors.orange)),
        const SizedBox(width: 16),
        Expanded(child: _buildKPI(context, 'Out of Stock', out.toString(), LucideIcons.package, Colors.red)),
        const SizedBox(width: 16),
        Expanded(child: _buildKPI(context, 'Critical Level', critical.toString(), LucideIcons.zap, Colors.amber)),
        const SizedBox(width: 16),
        Expanded(child: _buildKPI(context, 'Ready to Order', '0', LucideIcons.shoppingBag, AppTheme.primaryColor)),
      ],
    );
  }

  Widget _buildKPI(BuildContext context, String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by product name or SKU...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              filled: true,
              fillColor: Theme.of(context).cardColor.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              items: ['All', 'Out of Stock', 'Critical', 'Low Stock'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.checkCircle2, size: 64, color: AppTheme.accentColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('Inventory Secured', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('All products are currently above the safety threshold.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProductList(BuildContext context, List<Product> products) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        itemCount: products.length,
        separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
        itemBuilder: (context, index) {
          final p = products[index];
          final bool isOut = p.stock == 0;
          final bool isCritical = p.stock <= (p.lowStockThreshold / 2);
          final double progress = (p.stock / p.lowStockThreshold).clamp(0.0, 1.0);
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isOut ? Colors.red : (isCritical ? Colors.orange : Colors.blue)).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOut ? LucideIcons.packageX : (isCritical ? LucideIcons.alertCircle : LucideIcons.trendingDown),
                    color: isOut ? Colors.red : (isCritical ? Colors.orange : Colors.blue),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('SKU: ${p.sku}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontFeatures: [FontFeature.tabularFigures()])),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${p.stock} Units', style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isOut ? Colors.red : (isCritical ? Colors.orange : Colors.white),
                          )),
                          Text('Target: ${p.lowStockThreshold}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOut ? Colors.red : (isCritical ? Colors.orange : AppTheme.primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                _buildStatusBadge(isOut, isCritical),
                const SizedBox(width: 40),
                PrimaryButton(
                  label: 'Create PO',
                  onPressed: () => _showReplenishDialog(context, [p]),
                  width: 100,
                  height: 36,
                  fontSize: 12,
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreHorizontal, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddProductDialog(context, product: p);
                    } else if (value == 'history') {
                      _showProductHistoryDialog(context, p);
                    } else if (value == 'adjust') {
                      _showStockAdjustmentDialog(context, p);
                    } else if (value == 'delete') {
                      _confirmDelete(context, p);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(LucideIcons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'adjust', child: Row(children: [Icon(LucideIcons.sliders, size: 16), SizedBox(width: 8), Text('Adjust Stock')])),
                    const PopupMenuItem(value: 'history', child: Row(children: [Icon(LucideIcons.history, size: 16), SizedBox(width: 8), Text('History')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(LucideIcons.trash2, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showReplenishDialog(BuildContext context, List<Product> products, {bool isBulk = false}) {
    final items = products.map((p) => PurchaseOrderItem(
      productId: p.id,
      productName: p.name,
      quantity: isBulk ? (p.lowStockThreshold * 2) : 10,
      costPrice: p.purchasePrice,
    )).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PurchaseOrderDialog(initialItems: items),
    );
  }


  Widget _buildStatusBadge(bool isOut, bool isCritical) {
    final String label = isOut ? 'Out of Stock' : (isCritical ? 'Critical' : 'Low Stock');
    final Color color = isOut ? Colors.red : (isCritical ? Colors.orange : Colors.blue);

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }


  // Deprecated _showOrderDialog replaced by _showReplenishDialog

  void _showActivePOsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.darkSurface,
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Purchase Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
                ],
              ),
              const SizedBox(height: 16),
              Consumer(builder: (context, ref, _) {
                final pos = ref.watch(purchaseOrderProvider).where((p) => 
                  p.status == PurchaseOrderStatus.draft || 
                  p.status == PurchaseOrderStatus.sent || 
                  p.status == PurchaseOrderStatus.confirmed
                ).toList();
                if (pos.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No active purchase orders.')));
                }

                return SizedBox(
                  height: 400,
                  child: ListView.separated(
                    itemCount: pos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (context, index) {
                      final po = pos[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(LucideIcons.fileText, color: Colors.blue),
                        ),
                        title: Text('PO #${po.id.length > 8 ? po.id.substring(0, 8) : po.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${po.supplierName} • ${po.items.length} items • ${po.status.name.toUpperCase()}'),
                        trailing: const Icon(LucideIcons.chevronRight, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => PurchaseOrderDialog(purchaseOrder: po),
                          );
                        },

                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }


  void _showBulkOrderDialog(BuildContext context, int count) {
    // Collect items from all DRAFT POs
    final draftPOs = ref.read(purchaseOrderProvider).where((p) => p.status == PurchaseOrderStatus.draft).toList();
    final draftItems = <PurchaseOrderItem>[];
    for (final po in draftPOs) {
      draftItems.addAll(po.items);
    }

    // Collect low stock products
    final lowStockProducts = ref.read(productProvider).where((p) => p.stock <= p.lowStockThreshold).toList();
    final lowStockItems = lowStockProducts.map((p) => PurchaseOrderItem(
      productId: p.id,
      productName: p.name,
      quantity: p.lowStockThreshold * 2,
      costPrice: p.purchasePrice,
    )).toList();

    // Merge: draft items + low stock items (avoiding duplicates by productId)
    final Map<String, PurchaseOrderItem> itemMap = {};
    for (final item in draftItems) {
      if (itemMap.containsKey(item.productId)) {
        final existing = itemMap[item.productId]!;
        itemMap[item.productId] = existing.copyWith(quantity: existing.quantity + item.quantity);
      } else {
        itemMap[item.productId] = item;
      }
    }
    for (final item in lowStockItems) {
      if (itemMap.containsKey(item.productId)) {
        final existing = itemMap[item.productId]!;
        itemMap[item.productId] = existing.copyWith(quantity: existing.quantity + item.quantity);
      } else {
        itemMap[item.productId] = item;
      }
    }

    final mergedItems = itemMap.values.toList();

    if (mergedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to order (no drafts or low stock).'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PurchaseOrderDialog(initialItems: mergedItems),
    );
  }


  // Implementation of parity methods and export
  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(productProvider.notifier).deleteProduct(product.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStockAdjustmentDialog(BuildContext context, Product product) {
    final quantityController = TextEditingController();
    String adjustmentType = 'add';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: Row(
            children: [
              const Icon(LucideIcons.sliders, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              const Text('Adjust Stock'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product: ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Current Stock: ${product.stock} units', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => adjustmentType = 'add'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: adjustmentType == 'add' ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: adjustmentType == 'add' ? Colors.green : Colors.transparent),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.plus, size: 18, color: adjustmentType == 'add' ? Colors.green : Colors.grey),
                            const SizedBox(width: 8),
                            Text('Add Stock', style: TextStyle(color: adjustmentType == 'add' ? Colors.green : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => adjustmentType = 'remove'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: adjustmentType == 'remove' ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: adjustmentType == 'remove' ? Colors.red : Colors.transparent),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.minus, size: 18, color: adjustmentType == 'remove' ? Colors.red : Colors.grey),
                            const SizedBox(width: 8),
                            Text('Remove Stock', style: TextStyle(color: adjustmentType == 'remove' ? Colors.red : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'Enter quantity',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            PrimaryButton(
              label: 'Apply',
              onPressed: () {
                final qty = int.tryParse(quantityController.text);
                if (qty == null || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid quantity'), backgroundColor: Colors.red),
                  );
                  return;
                }
                final change = adjustmentType == 'add' ? qty : -qty;
                ref.read(productProvider.notifier).updateStock(product.id, change);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Stock ${adjustmentType == 'add' ? 'increased' : 'decreased'} by $qty units'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              width: 100,
            ),
          ],
        ),
      ),
    );
  }

  void _showProductHistoryDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.darkSurface,
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Product History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(product.name, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Stock', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('${product.stock} units', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total Value', style: TextStyle(color: Colors.grey, fontSize: 12)), Text('Rs. ${(product.stock * product.sellingPrice).toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))]))
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.inbox, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No transaction history available', style: TextStyle(color: Colors.grey)),
                      Text('Transactions will appear here as they occur.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportLowStockData(BuildContext context, List<Product> products) async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No low stock items to export'), backgroundColor: Colors.orange),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Name,SKU,Current Stock,Threshold,Status');
    
    for (final p in products) {
      final bool isOut = p.stock == 0;
      final bool isCritical = p.stock <= (p.lowStockThreshold / 2);
      final status = isOut ? 'Out of Stock' : (isCritical ? 'Critical' : 'Low Stock');
      buffer.writeln('"${p.name}","${p.sku}",${p.stock},${p.lowStockThreshold},"$status"');
    }

    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final filename = 'low_stock_report_$timestamp.csv';
      
      final homeDir = Platform.environment['HOME'] ?? '/tmp';
      final downloadsDir = Directory('$homeDir/Downloads');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }
      
      final file = File('${downloadsDir.path}/$filename');
      await file.writeAsString(buffer.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${products.length} items to Downloads'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open Folder',
              textColor: Colors.white,
              onPressed: () => Process.run('xdg-open', [downloadsDir.path]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddProductDialog(BuildContext context, {Product? product}) {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => AddProductModal(product: product),
    );
  }
}
