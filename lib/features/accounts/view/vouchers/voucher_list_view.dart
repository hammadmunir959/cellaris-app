import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/voucher.dart';
import '../../controller/accounts_providers.dart';
import '../../model/accounts_state.dart';

/// Voucher list view with filtering and search
class VoucherListView extends ConsumerStatefulWidget {
  const VoucherListView({super.key});

  @override
  ConsumerState<VoucherListView> createState() => _VoucherListViewState();
}

class _VoucherListViewState extends ConsumerState<VoucherListView> {
  VoucherType? _filterType;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = VoucherFilter(
      type: _filterType,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    final vouchersAsync = ref.watch(vouchersProvider(filter));

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              // Search
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search vouchers...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 16),
              
              // Type filter
              DropdownButton<VoucherType?>(
                value: _filterType,
                hint: const Text('All Types'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Types')),
                  ...VoucherType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(_getVoucherTypeName(type)),
                  )),
                ],
                onChanged: (value) => setState(() => _filterType = value),
              ),
              const SizedBox(width: 16),
              
              // Date range
              OutlinedButton.icon(
                onPressed: () => _selectDateRange(context),
                icon: const Icon(LucideIcons.calendar, size: 16),
                label: Text(
                  '${_formatDate(_fromDate)} - ${_formatDate(_toDate)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        // Vouchers list
        Expanded(
          child: vouchersAsync.when(
            data: (vouchers) {
              var filtered = vouchers;
              
              if (_searchQuery.isNotEmpty) {
                filtered = filtered.where((v) =>
                  v.voucherNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (v.partyName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                  (v.narration?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                ).toList();
              }

              if (filtered.isEmpty) {
                return _buildEmptyState(theme);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final voucher = filtered[index];
                  return _buildVoucherCard(theme, voucher);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.receipt,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No vouchers found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create vouchers using the buttons above',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(ThemeData theme, Voucher voucher) {
    final color = _getVoucherColor(voucher.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => _showVoucherDetails(voucher),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Type icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getVoucherIcon(voucher.type),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Voucher info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          voucher.voucherNo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getVoucherTypeName(voucher.type),
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (voucher.isPosted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Posted',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voucher.partyName ?? voucher.narration ?? 'No description',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Amount and date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${voucher.totalAmount.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isPaymentVoucher(voucher.type) ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(voucher.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Actions
              IconButton(
                icon: const Icon(LucideIcons.moreVertical, size: 18),
                onPressed: () => _showVoucherActions(voucher),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getVoucherTypeName(VoucherType type) {
    switch (type) {
      case VoucherType.cashPayment:
        return 'Cash Payment';
      case VoucherType.cashReceipt:
        return 'Cash Receipt';
      case VoucherType.bankPayment:
        return 'Bank Payment';
      case VoucherType.bankReceipt:
        return 'Bank Receipt';
      case VoucherType.partyPayment:
        return 'Party Payment';
      case VoucherType.partyReceipt:
        return 'Party Receipt';
      case VoucherType.journalVoucher:
        return 'Journal';
    }
  }

  IconData _getVoucherIcon(VoucherType type) {
    switch (type) {
      case VoucherType.cashPayment:
        return LucideIcons.arrowUpCircle;
      case VoucherType.cashReceipt:
        return LucideIcons.arrowDownCircle;
      case VoucherType.bankPayment:
        return LucideIcons.building2;
      case VoucherType.bankReceipt:
        return LucideIcons.building;
      case VoucherType.partyPayment:
        return LucideIcons.userMinus;
      case VoucherType.partyReceipt:
        return LucideIcons.userPlus;
      case VoucherType.journalVoucher:
        return LucideIcons.fileText;
    }
  }

  Color _getVoucherColor(VoucherType type) {
    switch (type) {
      case VoucherType.cashPayment:
        return Colors.red;
      case VoucherType.cashReceipt:
        return Colors.green;
      case VoucherType.bankPayment:
        return Colors.orange;
      case VoucherType.bankReceipt:
        return Colors.teal;
      case VoucherType.partyPayment:
        return Colors.purple;
      case VoucherType.partyReceipt:
        return Colors.blue;
      case VoucherType.journalVoucher:
        return Colors.grey;
    }
  }

  bool _isPaymentVoucher(VoucherType type) {
    return type == VoucherType.cashPayment ||
           type == VoucherType.bankPayment ||
           type == VoucherType.partyPayment;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  void _showVoucherDetails(Voucher voucher) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    voucher.voucherNo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow('Type', voucher.typeName),
              _buildDetailRow('Date', _formatDate(voucher.date)),
              _buildDetailRow('Amount', 'Rs. ${voucher.totalAmount.toStringAsFixed(0)}'),
              if (voucher.partyName != null)
                _buildDetailRow('Party', voucher.partyName!),
              if (voucher.bankName != null)
                _buildDetailRow('Bank', voucher.bankName!),
              if (voucher.narration != null)
                _buildDetailRow('Narration', voucher.narration!),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Entries:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...voucher.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(e.accountName)),
                    Expanded(child: Text('Dr: ${e.debit.toStringAsFixed(0)}')),
                    Expanded(child: Text('Cr: ${e.credit.toStringAsFixed(0)}')),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showVoucherActions(Voucher voucher) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(LucideIcons.eye),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              _showVoucherDetails(voucher);
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.printer),
            title: const Text('Print'),
            onTap: () => Navigator.pop(context),
          ),
          if (!voucher.isPosted)
            ListTile(
              leading: const Icon(LucideIcons.edit),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context),
            ),
          if (!voucher.isPosted)
            ListTile(
              leading: const Icon(LucideIcons.trash, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}
