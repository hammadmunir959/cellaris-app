import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/models/app_models.dart';
import '../../../core/models/invoice.dart';
import '../../../core/models/unit_imei.dart';
import '../../../core/repositories/invoice_repository.dart';
import '../../../core/repositories/unit_repository.dart';
import '../../../shared/controller/shared_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';

// ============================================================
// PURCHASE RETURN STATE
// ============================================================

class PurchaseReturnState {
  final Supplier? selectedSupplier;
  final List<ReturnItem> returnItems;
  final double deductionPercent;
  final bool isProcessing;
  final String? error;
  final String? generatedReturnNo;

  const PurchaseReturnState({
    this.selectedSupplier,
    this.returnItems = const [],
    this.deductionPercent = 0,
    this.isProcessing = false,
    this.error,
    this.generatedReturnNo,
  });

  double get totalReturnValue => returnItems.fold(
    0.0,
    (sum, item) => sum + (item.costPrice * item.quantity),
  );

  double get deductionAmount => totalReturnValue * (deductionPercent / 100);
  double get netRefund => totalReturnValue - deductionAmount;

  PurchaseReturnState copyWith({
    Supplier? selectedSupplier,
    List<ReturnItem>? returnItems,
    double? deductionPercent,
    bool? isProcessing,
    String? error,
    String? generatedReturnNo,
    bool clearSupplier = false,
  }) {
    return PurchaseReturnState(
      selectedSupplier: clearSupplier ? null : (selectedSupplier ?? this.selectedSupplier),
      returnItems: returnItems ?? this.returnItems,
      deductionPercent: deductionPercent ?? this.deductionPercent,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      generatedReturnNo: generatedReturnNo ?? this.generatedReturnNo,
    );
  }
}

class ReturnItem {
  final String imei;
  final String productId;
  final String productName;
  final double costPrice;
  final int quantity;

  const ReturnItem({
    required this.imei,
    required this.productId,
    required this.productName,
    required this.costPrice,
    this.quantity = 1,
  });
}

// ============================================================
// PURCHASE RETURN SCREEN
// ============================================================

class PurchaseReturnScreen extends ConsumerStatefulWidget {
  const PurchaseReturnScreen({super.key});

  @override
  ConsumerState<PurchaseReturnScreen> createState() => _PurchaseReturnScreenState();
}

class _PurchaseReturnScreenState extends ConsumerState<PurchaseReturnScreen> {
  Supplier? _selectedSupplier;
  final List<ReturnItem> _returnItems = [];
  double _deductionPercent = 0;
  bool _isProcessing = false;
  List<Unit> _availableUnits = [];
  bool _isLoadingUnits = false;

  double get _totalReturnValue => _returnItems.fold(
    0.0,
    (sum, item) => sum + (item.costPrice * item.quantity),
  );

  double get _deductionAmount => _totalReturnValue * (_deductionPercent / 100);
  double get _netRefund => _totalReturnValue - _deductionAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suppliers = ref.watch(supplierProvider);
    final f = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // Left panel - Item selection
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.undo2,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Purchase Return',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Return items to supplier',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Supplier selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: DropdownButtonFormField<Supplier>(
                    decoration: InputDecoration(
                      labelText: 'Select Supplier',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(LucideIcons.truck, size: 18),
                    ),
                    value: _selectedSupplier,
                    items: suppliers.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.name),
                    )).toList(),
                    onChanged: (supplier) {
                      setState(() {
                        _selectedSupplier = supplier;
                        _returnItems.clear();
                      });
                      if (supplier != null) _loadAvailableUnits(supplier.id);
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Available units for return
                Expanded(
                  child: _isLoadingUnits
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedSupplier == null
                          ? _buildEmptyState(theme, 'Select a supplier to view returnable items')
                          : _availableUnits.isEmpty
                              ? _buildEmptyState(theme, 'No items available for return')
                              : _buildUnitsList(theme),
                ),
              ],
            ),
          ),

          // Right panel - Return summary
          Container(
            width: 380,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                left: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              children: [
                // Return items list
                Expanded(
                  child: _returnItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.packageMinus,
                                size: 48,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No items selected',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _returnItems.length,
                          itemBuilder: (context, index) {
                            final item = _returnItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(LucideIcons.smartphone),
                                title: Text(
                                  item.productName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  item.imei,
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Rs. ${f.format(item.costPrice)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.x, size: 16, color: Colors.red),
                                      onPressed: () => setState(() => _returnItems.removeAt(index)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Deduction slider
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Deduction %',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${_deductionPercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _deductionPercent,
                        min: 0,
                        max: 50,
                        divisions: 50,
                        onChanged: (value) => setState(() => _deductionPercent = value),
                      ),
                    ],
                  ),
                ),

                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Total Value', value: 'Rs. ${f.format(_totalReturnValue)}'),
                      _SummaryRow(
                        label: 'Deduction (${_deductionPercent.toStringAsFixed(0)}%)',
                        value: '- Rs. ${f.format(_deductionAmount)}',
                        isDeduction: true,
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Net Refund',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Rs. ${f.format(_netRefund)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _returnItems.isNotEmpty && !_isProcessing
                              ? _processReturn
                              : null,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(LucideIcons.checkCircle, size: 18),
                          label: Text(_isProcessing ? 'Processing...' : 'Process Return'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.package,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsList(ThemeData theme) {
    final f = NumberFormat('#,###');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableUnits.length,
      itemBuilder: (context, index) {
        final unit = _availableUnits[index];
        final isSelected = _returnItems.any((i) => i.imei == unit.imei);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleItem(unit),
            ),
            title: Text(
              unit.imei,
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              unit.productId,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Text(
              'Rs. ${f.format(unit.purchasePrice)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () => _toggleItem(unit),
          ),
        );
      },
    );
  }

  void _toggleItem(Unit unit) {
    setState(() {
      final existingIndex = _returnItems.indexWhere((i) => i.imei == unit.imei);
      if (existingIndex >= 0) {
        _returnItems.removeAt(existingIndex);
      } else {
        _returnItems.add(ReturnItem(
          imei: unit.imei,
          productId: unit.productId,
          productName: unit.productId, // TODO: Get product name from product provider
          costPrice: unit.purchasePrice ?? 0,
        ));
      }
    });
  }

  Future<void> _loadAvailableUnits(String supplierId) async {
    setState(() => _isLoadingUnits = true);

    final unitRepo = ref.read(unitRepositoryProvider);
    // Get units available for purchase return (in stock, not yet sold)
    final units = await unitRepo.getAvailableForPurchaseReturn();

    setState(() {
      _availableUnits = units;
      _isLoadingUnits = false;
    });
  }

  Future<void> _processReturn() async {
    if (_selectedSupplier == null || _returnItems.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final unitRepo = ref.read(unitRepositoryProvider);

      // Generate return bill number
      final returnBillNo = await invoiceRepo.generateBillNo(InvoiceType.purchaseReturn);

      // Build line items
      final lineItems = _returnItems.map((item) => InvoiceLineItem(
        id: '',
        invoiceId: returnBillNo,
        productId: item.productId,
        productName: item.productName,
        imei: item.imei,
        unitPrice: item.costPrice,
        costPrice: item.costPrice,
        quantity: item.quantity,
        lineTotal: item.costPrice * item.quantity,
      )).toList();

      // Create return invoice
      final invoice = Invoice(
        billNo: returnBillNo,
        type: InvoiceType.purchaseReturn,
        partyId: _selectedSupplier!.id,
        partyName: _selectedSupplier!.name,
        date: DateTime.now(),
        summary: InvoiceSummary(
          grossValue: _totalReturnValue,
          discount: _deductionAmount,
          discountPercent: _deductionPercent,
          tax: 0,
          netValue: _netRefund,
          paidAmount: 0,
          balance: _netRefund, // Supplier credit
        ),
        paymentMode: InvoicePaymentMode.credit,
        status: InvoiceStatus.completed,
        notes: 'Purchase return with ${_deductionPercent.toStringAsFixed(0)}% deduction',
        createdAt: DateTime.now(),
        createdBy: 'System',
        items: lineItems,
      );

      await invoiceRepo.save(invoice);

      // Update unit status (mark as returned)
      for (final item in _returnItems) {
        await unitRepo.restock(item.imei); // Restock marks as returned status
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Return processed: $returnBillNo'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _returnItems.clear();
          _deductionPercent = 0;
          _selectedSupplier = null;
          _availableUnits = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDeduction;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isDeduction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDeduction ? Colors.orange : Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDeduction ? Colors.orange : null,
            ),
          ),
        ],
      ),
    );
  }
}
