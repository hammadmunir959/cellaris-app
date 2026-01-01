import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/invoice.dart';
import '../../../core/repositories/invoice_repository.dart';
import '../controller/returns_controller.dart';
import 'returns_history_view.dart';

/// Sales Return screen for processing returns against invoices
class ReturnsScreen extends ConsumerStatefulWidget {
  const ReturnsScreen({super.key});

  @override
  ConsumerState<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends ConsumerState<ReturnsScreen> {
  final _searchController = TextEditingController();
  Invoice? _selectedInvoice;
  final Map<String, int> _returnQuantities = {}; // itemId -> returnQty
  double _deductionPercent = 0.0;
  String _reason = '';
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sales Returns'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'New Return'),
              Tab(text: 'Return History'),
            ],
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        body: TabBarView(
          children: [
            // Tab 1: New Return (Existing Layout)
            Row(
              children: [
                // Left: Invoice search and selection
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(
                        right: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: theme.dividerColor.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.refreshCcw,
                                    color: theme.colorScheme.primary,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Process Return',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Search original invoice to process return',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Search field
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Enter invoice number (e.g., SI-000001)',
                              prefixIcon: const Icon(LucideIcons.search, size: 18),
                              suffixIcon: IconButton(
                                icon: const Icon(LucideIcons.arrowRight),
                                onPressed: _searchInvoice,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _searchInvoice(),
                          ),
                        ),

                        // Selected invoice details
                        Expanded(
                          child: _selectedInvoice != null
                              ? _buildInvoiceDetails(theme)
                              : _buildEmptyState(theme),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right: Return form
                Expanded(
                  flex: 1,
                  child: _selectedInvoice != null
                      ? _buildReturnForm(theme)
                      : _buildNoInvoiceSelected(theme),
                ),
              ],
            ),

            // Tab 2: Return History
            const ReturnsHistoryView(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.fileSearch,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for an invoice',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the bill number to process a return',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoInvoiceSelected(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.clipboardX,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No invoice selected',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search and select an invoice first',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetails(ThemeData theme) {
    final invoice = _selectedInvoice!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        invoice.billNo,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SALE',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: LucideIcons.user,
                    label: 'Customer',
                    value: invoice.partyName ?? 'Walk-in',
                  ),
                  _DetailRow(
                    icon: LucideIcons.calendar,
                    label: 'Date',
                    value: _formatDate(invoice.date),
                  ),
                  _DetailRow(
                    icon: LucideIcons.dollarSign,
                    label: 'Total',
                    value: 'Rs. ${invoice.summary.netValue.toStringAsFixed(0)}',
                  ),
                  if (invoice.salesmanName != null)
                    _DetailRow(
                      icon: LucideIcons.userCheck,
                      label: 'Salesman',
                      value: invoice.salesmanName!,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Line Items',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Line items
          ...invoice.items.map((item) => _InvoiceItemCard(
                item: item,
                returnQty: _returnQuantities[item.id] ?? 0,
                onReturnQtyChanged: (qty) {
                  setState(() {
                    if (qty > 0) {
                      _returnQuantities[item.id] = qty;
                    } else {
                      _returnQuantities.remove(item.id);
                    }
                  });
                },
              )),
        ],
      ),
    );
  }

  Widget _buildReturnForm(ThemeData theme) {
    final totalReturnItems = _returnQuantities.values.fold(0, (a, b) => a + b);
    final returnValue = _calculateReturnValue();
    final finalRefund = returnValue * (1 - _deductionPercent / 100);

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.undo2,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Return Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary card
                  Card(
                    color: Colors.orange.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Items to Return'),
                              Text(
                                '$totalReturnItems',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Return Value'),
                              Text(
                                'Rs. ${returnValue.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Deduction percent
                  Text(
                    'Further Deduction',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _deductionPercent,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: '${_deductionPercent.toInt()}%',
                          onChanged: (value) {
                            setState(() => _deductionPercent = value);
                          },
                        ),
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_deductionPercent.toInt()}%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Reason
                  Text(
                    'Return Reason',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter reason for return...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => _reason = value,
                  ),

                  const SizedBox(height: 32),

                  // Final refund
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Refund Amount',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rs. ${finalRefund.toStringAsFixed(0)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Process button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: totalReturnItems > 0 && !_isProcessing
                    ? _processReturn
                    : null,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.check),
                label: Text(_isProcessing ? 'Processing...' : 'Process Return'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _searchInvoice() async {
    final billNo = _searchController.text.trim();
    if (billNo.isEmpty) return;

    final repository = ref.read(invoiceRepositoryProvider);
    final invoice = await repository.getByBillNo(billNo);

    if (invoice != null && invoice.type == InvoiceType.sale) {
      setState(() {
        _selectedInvoice = invoice;
        _returnQuantities.clear();
        _deductionPercent = 0;
        _reason = '';
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              invoice == null
                  ? 'Invoice not found'
                  : 'Only sale invoices can be returned',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _calculateReturnValue() {
    if (_selectedInvoice == null) return 0;

    double total = 0;
    for (final item in _selectedInvoice!.items) {
      final returnQty = _returnQuantities[item.id] ?? 0;
      if (returnQty > 0) {
        total += (item.lineTotal / item.quantity) * returnQty;
      }
    }
    return total;
  }

  void _processReturn() async {
    if (_selectedInvoice == null || _returnQuantities.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      await ref.read(returnsProvider.notifier).processReturn(
            originalInvoice: _selectedInvoice!,
            returnQuantities: _returnQuantities,
            deductionPercent: _deductionPercent,
            reason: _reason,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return processed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedInvoice = null;
          _returnQuantities.clear();
          _deductionPercent = 0;
          _reason = '';
          _searchController.clear();
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceItemCard extends StatelessWidget {
  final InvoiceLineItem item;
  final int returnQty;
  final Function(int) onReturnQtyChanged;

  const _InvoiceItemCard({
    required this.item,
    required this.returnQty,
    required this.onReturnQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = returnQty > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected
          ? Colors.orange.withValues(alpha: 0.05)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? Colors.orange.withValues(alpha: 0.5)
              : theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Qty: ${item.quantity}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (item.imei != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.imei!,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.primary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Return quantity selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.minus, size: 16),
                    onPressed: returnQty > 0
                        ? () => onReturnQtyChanged(returnQty - 1)
                        : null,
                    constraints: const BoxConstraints(minWidth: 32),
                    padding: EdgeInsets.zero,
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$returnQty',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.orange : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.plus, size: 16),
                    onPressed: returnQty < item.quantity
                        ? () => onReturnQtyChanged(returnQty + 1)
                        : null,
                    constraints: const BoxConstraints(minWidth: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),
            Text(
              'Rs. ${item.lineTotal.toStringAsFixed(0)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
