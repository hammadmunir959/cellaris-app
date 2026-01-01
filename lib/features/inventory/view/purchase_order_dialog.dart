import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/features/inventory/controller/purchase_order_controller.dart';
import 'package:mbm_app/shared/controller/shared_controller.dart';
import 'package:mbm_app/features/inventory/controller/inventory_controller.dart';

import 'package:mbm_app/core/services/pdf_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class PurchaseOrderDialog extends ConsumerStatefulWidget {
  final PurchaseOrder? purchaseOrder;
  final List<PurchaseOrderItem>? initialItems;

  const PurchaseOrderDialog({super.key, this.purchaseOrder, this.initialItems});

  @override
  ConsumerState<PurchaseOrderDialog> createState() => _PurchaseOrderDialogState();
}

class _PurchaseOrderDialogState extends ConsumerState<PurchaseOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSupplierId;
  late List<PurchaseOrderItem> _items;
  late PurchaseOrderStatus _status;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.purchaseOrder != null;
    _selectedSupplierId = widget.purchaseOrder?.supplierId;
    
    if (widget.purchaseOrder != null) {
      _items = List.from(widget.purchaseOrder!.items);
    } else if (widget.initialItems != null) {
      _items = List.from(widget.initialItems!);
      // Attempt to set supplier from first item if possible (mock logic or from product)
      if (_items.isNotEmpty && _selectedSupplierId == null) {
        // We might need to fetch the product to get the supplierId
      }
    } else {
      _items = [];
    }
    
    _status = widget.purchaseOrder?.status ?? PurchaseOrderStatus.draft;
  }

  double get _totalCost => _items.fold(0, (sum, item) => sum + (item.costPrice * item.quantity));

  void _addItem() {
    setState(() {
      _items.add(PurchaseOrderItem(productId: '', productName: '', quantity: 1, costPrice: 0));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    if (_selectedSupplierId == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier and add at least one item.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supplier = ref.read(supplierProvider).firstWhere((s) => s.id == _selectedSupplierId);
      
      if (_isEditing) {
        // Create a new PurchaseOrder with updated fields since copyWith doesn't support supplier changes
        final updatedPO = PurchaseOrder(
          id: widget.purchaseOrder!.id,
          supplierId: supplier.id,
          supplierName: supplier.name,
          items: _items,
          totalCost: _totalCost,
          status: _status,
          notes: widget.purchaseOrder!.notes,
          createdAt: widget.purchaseOrder!.createdAt,
          receivedAt: widget.purchaseOrder!.receivedAt,
        );
        await ref.read(purchaseOrderProvider.notifier).updatePurchaseOrder(updatedPO);
      } else {
        await ref.read(purchaseOrderProvider.notifier).addPurchaseOrder(
          supplierId: supplier.id,
          supplierName: supplier.name,
          items: _items,
        );
      }

      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suppliers = ref.watch(supplierProvider);
    final products = ref.watch(productProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Purchase Order' : 'New Purchase Order',
                          style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
                        ),
                        if (_isEditing)
                          Text('ID: ${widget.purchaseOrder!.id}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (_isEditing) ...[
                        IconButton(
                          icon: const Icon(LucideIcons.printer, color: Colors.blue),
                          onPressed: () => PdfService.generateAndPrintPO(widget.purchaseOrder!),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),

              // Supplier Selection
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Supplier', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedSupplierId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                          onChanged: (v) => setState(() => _selectedSupplierId = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<PurchaseOrderStatus>(
                          value: _status,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          items: PurchaseOrderStatus.values.map((v) => DropdownMenuItem(value: v, child: Text(v.name.toUpperCase()))).toList(),
                          onChanged: (v) => setState(() => _status = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Items Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  TextButton.icon(onPressed: _addItem, icon: const Icon(LucideIcons.plus, size: 16), label: const Text('Add Item')),
                ],
              ),
              const SizedBox(height: 12),

              // Items List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) => const Divider(height: 24, color: Colors.white10),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<String>(
                              hint: const Text('Select Product'),
                              value: item.productId.isEmpty ? null : item.productId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                final p = products.firstWhere((prod) => prod.id == v);
                                setState(() {
                                  _items[index] = item.copyWith(productId: p.id, productName: p.name, costPrice: p.purchasePrice);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.quantity.toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Qty',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (v) {
                                final q = int.tryParse(v) ?? 1;
                                setState(() {
                                  _items[index] = item.copyWith(quantity: q);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: item.costPrice.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Cost',
                                isDense: true,
                                prefixText: 'Rs. ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (v) {
                                final p = double.tryParse(v) ?? 0;
                                setState(() {
                                  _items[index] = item.copyWith(costPrice: p);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removeItem(index),
                            icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Footer: Totals and Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL ESTIMATED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${_totalCost.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      const SizedBox(width: 16),
                      PrimaryButton(
                        label: _isEditing ? 'Update Order' : 'Create Order',
                        width: 180,
                        isLoading: _isLoading,
                        onPressed: _handleSave,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
