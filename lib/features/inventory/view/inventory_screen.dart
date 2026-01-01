import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbm_app/features/inventory/controller/inventory_controller.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/features/inventory/view/add_product_modal.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = ref.watch(filteredProductsProvider);
    final allProducts = ref.watch(productProvider);
    final currentCategory = ref.watch(categoryFilterProvider);

    // Dynamic categories from data
    final categories = ['All', ...allProducts.map((e) => e.category).toSet()];

    // Financial summaries
    final totalCost = allProducts.fold(0.0, (sum, p) => sum + (p.purchasePrice * p.stock));
    final totalMarket = allProducts.fold(0.0, (sum, p) => sum + (p.sellingPrice * p.stock));
    final lowStockCount = allProducts.where((p) => p.stock <= p.lowStockThreshold).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(context, allProducts.length),
        const SizedBox(height: 24),

        // KPI Section
        FadeInDown(
          duration: const Duration(milliseconds: 400),
          child: Row(
            children: [
              _buildKPI(context, 'Inventory Value', 'Rs. ${totalCost.toStringAsFixed(0)}', LucideIcons.coins, AppTheme.primaryColor),
              const SizedBox(width: 16),
              _buildKPI(context, 'Market Potential', 'Rs. ${totalMarket.toStringAsFixed(0)}', LucideIcons.trendingUp, AppTheme.accentColor),
              const SizedBox(width: 16),
              _buildKPI(context, 'Low Stock Items', lowStockCount.toString(), LucideIcons.package, AppTheme.warningColor),
              const SizedBox(width: 16),
              _buildKPI(context, 'Out of Stock', allProducts.where((p) => p.stock == 0).length.toString(), LucideIcons.history, AppTheme.errorColor),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Controls Area
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                  decoration: InputDecoration(
                    hintText: 'Search by Name, SKU, or IMEI...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _buildCategoryFilters(categories, currentCategory),
          ],
        ),

        const SizedBox(height: 24),

        // Inventory Table
        Expanded(
          child: products.isEmpty? _buildEmptyState() : FadeInUp(
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildTableHeader(theme),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: products.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.03), height: 1),
                      itemBuilder: (context, index) => _buildRow(context, products[index]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inventory Ledger', style: theme.textTheme.displayMedium?.copyWith(fontSize: 28)),
            const SizedBox(height: 4),
            Text('Viewing $count unique products in your catalog.', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _exportData(context),
              icon: const Icon(LucideIcons.download, size: 16),
              label: const Text('Export Data'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 16),
            PrimaryButton(
              label: 'Add Product',
              onPressed: () => _showAddProductDialog(context),
              icon: LucideIcons.plus,
              width: 160,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPI(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                Icon(icon, size: 16, color: color.withOpacity(0.8)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(List<String> categories, String current) {
    return Row(
      children: categories.map((cat) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: ChoiceChip(
          label: Text(cat),
          selected: current == cat,
          onSelected: (val) {
            if (val) ref.read(categoryFilterProvider.notifier).state = cat;
          },
          backgroundColor: Colors.white.withOpacity(0.05),
          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
          labelStyle: TextStyle(
            color: current == cat ? AppTheme.primaryColor : Colors.grey,
            fontSize: 12,
            fontWeight: current == cat ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide(color: current == cat ? AppTheme.primaryColor.withOpacity(0.3) : Colors.transparent),
          showCheckmark: false,
        ),
      )).toList(),
    );
  }

  Widget _buildTableHeader(ThemeData theme) {
    final sortBy = ref.watch(inventorySortByProvider);
    final isAsc = ref.watch(inventorySortOrderProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          _buildSortableHead('Product Name', 'name', 3, sortBy, isAsc),
          _buildSortableHead('SKU / IMEI', 'sku', 2, sortBy, isAsc),
          const Expanded(flex: 1, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          _buildSortableHead('Stock', 'stock', 1, sortBy, isAsc),
          _buildSortableHead('Price', 'price', 1, sortBy, isAsc),
          const Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSortableHead(String label, String key, int flex, String currentSort, bool isAsc) {
    final bool isSelected = currentSort == key;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () {
          if (isSelected) {
            ref.read(inventorySortOrderProvider.notifier).state = !isAsc;
          } else {
            ref.read(inventorySortByProvider.notifier).state = key;
            ref.read(inventorySortOrderProvider.notifier).state = true;
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(width: 4),
            Icon(
              isSelected ? (isAsc ? LucideIcons.chevronUp : LucideIcons.chevronDown) : LucideIcons.arrowUpDown,
              size: 12,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, Product product) {
    final bool isLow = product.stock <= product.lowStockThreshold;
    final bool isOut = product.stock == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.smartphone, size: 18, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(product.brand ?? 'Generic', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(product.sku, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFeatures: [FontFeature.tabularFigures()]))),
          Expanded(flex: 1, child: Badge(label: Text(product.category), backgroundColor: Colors.white.withOpacity(0.05))),
          Expanded(
            flex: 1, 
            child: Text(
              '${product.stock} Units', 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: isOut ? Colors.red : (isLow ? Colors.orange : Colors.grey[300]),
              )
            )
          ),
          Expanded(flex: 1, child: Text('Rs. ${product.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900))),
          Expanded(flex: 1, child: _StatusBadge(
            label: isOut ? 'Out of Stock' : (isLow ? 'Low Stock' : 'Healthy'),
            color: isOut ? Colors.red : (isLow ? Colors.orange : Colors.teal),
          )),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreHorizontal, size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                _showAddProductDialog(context, product: product);
              } else if (value == 'history') {
                _showProductHistoryDialog(context, product);
              } else if (value == 'adjust') {
                _showStockAdjustmentDialog(context, product);
              } else if (value == 'delete') {
                _confirmDelete(context, product);
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
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No matching products found.'));
  }

  void _showAddProductDialog(BuildContext context, {Product? product}) {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => AddProductModal(product: product),
    );
  }

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
                      Text('Product History', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Value', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('Rs. ${(product.stock * product.sellingPrice).toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
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

  void _exportData(BuildContext context) async {
    final products = ref.read(productProvider);
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products to export'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Generate CSV content
    final buffer = StringBuffer();
    
    // Header row
    buffer.writeln('Name,SKU,Category,Brand,Stock,Purchase Price,Selling Price,Status');
    
    // Data rows
    for (final p in products) {
      final status = p.stock == 0 ? 'Out of Stock' : (p.stock <= p.lowStockThreshold ? 'Low Stock' : 'Healthy');
      buffer.writeln(
        '"${p.name}","${p.sku}","${p.category}","${p.brand ?? ''}",${p.stock},${p.purchasePrice},${p.sellingPrice},"$status"'
      );
    }

    try {
      // Generate filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final filename = 'inventory_export_$timestamp.csv';
      
      // Save to documents/downloads directory
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
            content: Text('Exported ${products.length} products to ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open Folder',
              textColor: Colors.white,
              onPressed: () {
                Process.run('xdg-open', [downloadsDir.path]);
              },
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
}




class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
