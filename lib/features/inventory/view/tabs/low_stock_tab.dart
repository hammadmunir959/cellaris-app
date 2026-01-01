import 'dart:io';
import 'dart:ui';
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
import '../purchase_order_dialog.dart';
import '../add_product_modal.dart';

class LowStockTab extends ConsumerStatefulWidget {
  const LowStockTab({super.key});

  @override
  ConsumerState<LowStockTab> createState() => _LowStockTabState();
}

class _LowStockTabState extends ConsumerState<LowStockTab> {
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
    final products = ref.watch(productProvider);
    
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
          // KPI Cards
          Row(
            children: [
              Expanded(child: _buildKPI('Total Alerts', lowStockProducts.length.toString(), LucideIcons.alertTriangle, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _buildKPI('Out of Stock', outOfStockCount.toString(), LucideIcons.package, Colors.red)),
              const SizedBox(width: 16),
              Expanded(child: _buildKPI('Critical Level', criticalCount.toString(), LucideIcons.zap, Colors.amber)),
              const SizedBox(width: 16),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('QUICK ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          PrimaryButton(
                            label: 'Create Bulk PO',
                            onPressed: () => _showBulkOrderDialog(context),
                            icon: LucideIcons.shoppingCart,
                            width: 160,
                          ),
                        ],
                      ),
                      const Icon(LucideIcons.shoppingBag, size: 24, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters
          Row(
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
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
                    items: ['All', 'Out of Stock', 'Critical', 'Low Stock'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (val) => setState(() => _selectedStatus = val ?? 'All'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _exportLowStockData(context, lowStockProducts),
                icon: const Icon(LucideIcons.download, size: 16),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // List
          Expanded(
            child: lowStockProducts.isEmpty
                ? _buildEmptyState()
                : _buildProductList(lowStockProducts),
          ),
        ],
      ),
    );
  }

  Widget _buildKPI(String label, String value, IconData icon, Color color) {
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

  Widget _buildEmptyState() {
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

  Widget _buildProductList(List<Product> products) {
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
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: (isOut ? Colors.red : (isCritical ? Colors.orange : Colors.blue)).withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(isOut ? LucideIcons.packageX : (isCritical ? LucideIcons.alertCircle : LucideIcons.trendingDown), color: isOut ? Colors.red : (isCritical ? Colors.orange : Colors.blue), size: 20),
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
                          Text('${p.stock} Units', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isOut ? Colors.red : (isCritical ? Colors.orange : Colors.white))),
                          Text('Target: ${p.lowStockThreshold}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: Colors.white.withOpacity(0.05), valueColor: AlwaysStoppedAnimation<Color>(isOut ? Colors.red : (isCritical ? Colors.orange : AppTheme.primaryColor))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                _buildStatusBadge(isOut, isCritical),
                const SizedBox(width: 40),
                PrimaryButton(label: 'Create PO', onPressed: () => _showReplenishDialog([p]), width: 100, height: 36, fontSize: 12),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreHorizontal, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') _showAddProductDialog(context, product: p);
                    else if (value == 'adjust') _showStockAdjustmentDialog(context, p);
                    else if (value == 'delete') _confirmDelete(context, p);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(LucideIcons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'adjust', child: Row(children: [Icon(LucideIcons.sliders, size: 16), SizedBox(width: 8), Text('Adjust Stock')])),
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

  Widget _buildStatusBadge(bool isOut, bool isCritical) {
    final label = isOut ? 'Out of Stock' : (isCritical ? 'Critical' : 'Low Stock');
    final color = isOut ? Colors.red : (isCritical ? Colors.orange : Colors.blue);
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.2))),
      child: Center(child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
    );
  }

  void _showReplenishDialog(List<Product> products) {
    final items = products.map((p) => PurchaseOrderItem(productId: p.id, productName: p.name, quantity: p.lowStockThreshold * 2, costPrice: p.purchasePrice)).toList();
    showDialog(context: context, barrierDismissible: false, builder: (context) => PurchaseOrderDialog(initialItems: items));
  }

  void _showBulkOrderDialog(BuildContext context) {
    final draftPOs = ref.read(purchaseOrderProvider).where((p) => p.status == PurchaseOrderStatus.draft).toList();
    final draftItems = <PurchaseOrderItem>[];
    for (final po in draftPOs) draftItems.addAll(po.items);

    final lowStockProducts = ref.read(productProvider).where((p) => p.stock <= p.lowStockThreshold).toList();
    final lowStockItems = lowStockProducts.map((p) => PurchaseOrderItem(productId: p.id, productName: p.name, quantity: p.lowStockThreshold * 2, costPrice: p.purchasePrice)).toList();

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No items to order.'), backgroundColor: Colors.orange));
      return;
    }
    showDialog(context: context, barrierDismissible: false, builder: (context) => PurchaseOrderDialog(initialItems: mergedItems));
  }

  void _showAddProductDialog(BuildContext context, {Product? product}) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AddProductModal(product: product));
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { ref.read(productProvider.notifier).deleteProduct(product.id); Navigator.pop(context); }, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
  }

  void _showStockAdjustmentDialog(BuildContext context, Product product) {
    final qtyCtrl = TextEditingController();
    String type = 'add';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: const Row(children: [Icon(LucideIcons.sliders, color: AppTheme.primaryColor), SizedBox(width: 12), Text('Adjust Stock')]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Product: ${product.name}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildAdjustOption(type == 'add', 'Add', Colors.green, LucideIcons.plus, () => setDialogState(() => type = 'add'))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildAdjustOption(type == 'remove', 'Remove', Colors.red, LucideIcons.minus, () => setDialogState(() => type = 'remove'))),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            PrimaryButton(label: 'Apply', width: 100, onPressed: () {
              final qty = int.tryParse(qtyCtrl.text);
              if (qty == null || qty <= 0) return;
              ref.read(productProvider.notifier).updateStock(product.id, type == 'add' ? qty : -qty);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustOption(bool selected, String label, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: selected ? color.withOpacity(0.1) : Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8), border: Border.all(color: selected ? color : Colors.transparent)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: selected ? color : Colors.grey), const SizedBox(width: 8), Text(label, style: TextStyle(color: selected ? color : Colors.grey))]),
      ),
    );
  }

  void _exportLowStockData(BuildContext context, List<Product> products) async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No low stock items to export'), backgroundColor: Colors.orange));
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('Name,SKU,Current Stock,Threshold,Status');
    for (final p in products) {
      final status = p.stock == 0 ? 'Out of Stock' : (p.stock <= (p.lowStockThreshold / 2) ? 'Critical' : 'Low Stock');
      buffer.writeln('"${p.name}","${p.sku}",${p.stock},${p.lowStockThreshold},"$status"');
    }
    try {
      final ts = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final file = File('${Platform.environment['HOME'] ?? '/tmp'}/Downloads/low_stock_report_$ts.csv');
      await file.writeAsString(buffer.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported ${products.length} items'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
    }
  }
}
