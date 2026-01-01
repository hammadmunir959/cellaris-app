import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/features/transactions/controller/transaction_controller.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TransactionsHistoryScreen extends ConsumerStatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  ConsumerState<TransactionsHistoryScreen> createState() => _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends ConsumerState<TransactionsHistoryScreen> {
  // Filters
  TransactionType? selectedType;
  TransactionStatus? selectedStatus;
  String searchQuery = '';
  DateTimeRange? dateRange;
  
  // Pagination
  static const int pageSize = 20;
  int currentPage = 0;
  
  // Sorting
  String sortBy = 'date';
  bool sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionLogProvider);
    final filteredTransactions = _getFilteredTransactions(allTransactions);
    final paginatedTransactions = _getPaginatedTransactions(filteredTransactions);
    
    // Stats
    final totalIncome = filteredTransactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = filteredTransactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
    final netAmount = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),
              
              // Stats Row
              _buildStatsRow(filteredTransactions.length, totalIncome, totalExpense, netAmount),
              const SizedBox(height: 24),
              
              // Filters
              _buildFiltersRow(),
              const SizedBox(height: 16),
              
              // Table Header
              _buildTableHeader(),
              
              // Transaction List
              Expanded(
                child: filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionList(paginatedTransactions),
              ),
              
              // Pagination
              if (filteredTransactions.length > pageSize)
                _buildPaginationControls(filteredTransactions.length),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FadeInLeft(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaction History', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Complete audit trail of all business activities', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
            ],
          ),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _exportToPdf,
              icon: const Icon(LucideIcons.download, size: 16),
              label: const Text('Export PDF'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(int total, double income, double expense, double net) {
    return FadeInUp(
      child: Row(
        children: [
          Expanded(child: _StatCard(
            label: 'Total Transactions',
            value: total.toString(),
            icon: LucideIcons.activity,
            color: Colors.blue,
          )),
          const SizedBox(width: 16),
          Expanded(child: _StatCard(
            label: 'Income',
            value: 'Rs. ${_formatAmount(income)}',
            icon: LucideIcons.trendingUp,
            color: Colors.green,
          )),
          const SizedBox(width: 16),
          Expanded(child: _StatCard(
            label: 'Expense',
            value: 'Rs. ${_formatAmount(expense)}',
            icon: LucideIcons.trendingDown,
            color: Colors.red,
          )),
          const SizedBox(width: 16),
          Expanded(child: _StatCard(
            label: 'Net',
            value: 'Rs. ${_formatAmount(net)}',
            icon: LucideIcons.wallet,
            color: net >= 0 ? Colors.teal : Colors.orange,
          )),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by ID, customer, product...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Type Filter
          _buildDropdown<TransactionType?>(
            value: selectedType,
            hint: 'All Types',
            items: [null, ...TransactionType.values],
            labelBuilder: (t) => t == null ? 'All Types' : _getTypeLabel(t),
            onChanged: (v) => setState(() { selectedType = v; currentPage = 0; }),
          ),
          const SizedBox(width: 12),
          
          // Status Filter
          _buildDropdown<TransactionStatus?>(
            value: selectedStatus,
            hint: 'All Status',
            items: [null, ...TransactionStatus.values],
            labelBuilder: (s) => s == null ? 'All Status' : s.name.toUpperCase(),
            onChanged: (v) => setState(() { selectedStatus = v; currentPage = 0; }),
          ),
          const SizedBox(width: 12),
          
          // Date Range
          OutlinedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(LucideIcons.calendar, size: 16),
            label: Text(dateRange == null 
                ? 'Date Range' 
                : '${DateFormat('dd/MM').format(dateRange!.start)} - ${DateFormat('dd/MM').format(dateRange!.end)}'),
          ),
          if (dateRange != null)
            IconButton(
              icon: const Icon(LucideIcons.x, size: 16),
              onPressed: () => setState(() => dateRange = null),
            ),
          const SizedBox(width: 12),
          
          // Clear Filters
          if (_hasActiveFilters())
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(LucideIcons.filterX, size: 16),
              label: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          items: items.map((item) => DropdownMenuItem<T>(
            value: item,
            child: Text(labelBuilder(item), style: const TextStyle(fontSize: 13)),
          )).toList(),
          onChanged: onChanged,
          dropdownColor: AppTheme.darkBg,
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Date/Time', flex: 2, sortKey: 'date'),
          _buildHeaderCell('Type', flex: 1),
          _buildHeaderCell('Reference', flex: 2),
          _buildHeaderCell('Party', flex: 2),
          _buildHeaderCell('Items', flex: 1),
          _buildHeaderCell('Amount', flex: 2, sortKey: 'amount'),
          _buildHeaderCell('Status', flex: 1),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1, String? sortKey}) {
    final isActive = sortBy == sortKey;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: sortKey != null ? () => _toggleSort(sortKey) : null,
        child: Row(
          children: [
            Text(title, style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.primaryColor : Colors.grey,
            )),
            if (sortKey != null) ...[
              const SizedBox(width: 4),
              Icon(
                isActive 
                    ? (sortAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown)
                    : LucideIcons.arrowUpDown,
                size: 12,
                color: isActive ? AppTheme.primaryColor : Colors.grey.withOpacity(0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionLog> transactions) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
        itemBuilder: (context, index) => _buildTransactionRow(transactions[index]),
      ),
    );
  }

  Widget _buildTransactionRow(TransactionLog transaction) {
    return InkWell(
      onTap: () => _showTransactionDetails(transaction),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Date/Time
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('MMM dd, yyyy').format(transaction.timestamp), style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(DateFormat('hh:mm a').format(transaction.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            
            // Type
            Expanded(
              flex: 1,
              child: _buildTypeBadge(transaction.type),
            ),
            
            // Reference
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.referenceNumber ?? '#${transaction.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (transaction.paymentMethod != null)
                    Text(transaction.paymentMethod!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            
            // Party
            Expanded(
              flex: 2,
              child: Text(transaction.partyName, style: const TextStyle(fontSize: 13)),
            ),
            
            // Items
            Expanded(
              flex: 1,
              child: Text('${transaction.items.length} items', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ),
            
            // Amount
            Expanded(
              flex: 2,
              child: Text(
                '${transaction.isExpense ? '-' : '+'} Rs. ${_formatAmount(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: transaction.isExpense ? Colors.red[400] : Colors.green[400],
                ),
              ),
            ),
            
            // Status
            Expanded(
              flex: 1,
              child: _buildStatusBadge(transaction.status),
            ),
            
            // Actions
            IconButton(
              icon: const Icon(LucideIcons.chevronRight, size: 18),
              onPressed: () => _showTransactionDetails(transaction),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(TransactionType type) {
    final color = _getTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _getTypeLabel(type),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusBadge(TransactionStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.inbox, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No transactions found', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters() ? 'Try adjusting your filters' : 'Transactions will appear here as you make sales, purchases, etc.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(int totalCount) {
    final totalPages = (totalCount / pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${currentPage * pageSize + 1}-${((currentPage + 1) * pageSize).clamp(0, totalCount)} of $totalCount',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.chevronsLeft, size: 18),
                onPressed: currentPage > 0 ? () => setState(() => currentPage = 0) : null,
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft, size: 18),
                onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${currentPage + 1} / $totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronRight, size: 18),
                onPressed: currentPage < totalPages - 1 ? () => setState(() => currentPage++) : null,
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronsRight, size: 18),
                onPressed: currentPage < totalPages - 1 ? () => setState(() => currentPage = totalPages - 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(TransactionLog transaction) {
    showDialog(
      context: context,
      builder: (context) => _TransactionDetailDialog(transaction: transaction),
    );
  }

  // Helpers
  List<TransactionLog> _getFilteredTransactions(List<TransactionLog> all) {
    var filtered = all.where((t) {
      if (selectedType != null && t.type != selectedType) return false;
      if (selectedStatus != null && t.status != selectedStatus) return false;
      if (dateRange != null) {
        if (t.timestamp.isBefore(dateRange!.start) || t.timestamp.isAfter(dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return t.id.toLowerCase().contains(query) ||
            (t.referenceNumber?.toLowerCase().contains(query) ?? false) ||
            (t.customerName?.toLowerCase().contains(query) ?? false) ||
            (t.supplierName?.toLowerCase().contains(query) ?? false) ||
            t.items.any((i) => i.productName.toLowerCase().contains(query));
      }
      return true;
    }).toList();
    
    // Sort
    filtered.sort((a, b) {
      int compare;
      switch (sortBy) {
        case 'amount':
          compare = a.amount.compareTo(b.amount);
          break;
        case 'date':
        default:
          compare = a.timestamp.compareTo(b.timestamp);
      }
      return sortAscending ? compare : -compare;
    });
    
    return filtered;
  }

  List<TransactionLog> _getPaginatedTransactions(List<TransactionLog> filtered) {
    final start = currentPage * pageSize;
    final end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  bool _hasActiveFilters() {
    return selectedType != null || selectedStatus != null || dateRange != null || searchQuery.isNotEmpty;
  }

  void _clearFilters() {
    setState(() {
      selectedType = null;
      selectedStatus = null;
      dateRange = null;
      searchQuery = '';
      currentPage = 0;
    });
  }

  void _toggleSort(String key) {
    setState(() {
      if (sortBy == key) {
        sortAscending = !sortAscending;
      } else {
        sortBy = key;
        sortAscending = false;
      }
    });
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: dateRange,
    );
    if (range != null) {
      setState(() {
        dateRange = range;
        currentPage = 0;
      });
    }
  }

  void _refreshData() {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data refreshed'), duration: Duration(seconds: 1)),
    );
  }

  void _exportToPdf() async {
    final transactions = _getFilteredTransactions(ref.read(transactionLogProvider));
    
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text('Transaction History Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Generated on ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['Date', 'Type', 'Reference', 'Party', 'Amount', 'Status'],
            data: transactions.map((t) => [
              DateFormat('dd/MM/yyyy').format(t.timestamp),
              t.typeLabel,
              t.referenceNumber ?? t.id.substring(0, 8),
              t.partyName,
              'Rs. ${t.amount.toStringAsFixed(0)}',
              t.status.name,
            ]).toList(),
          ),
        ],
      ),
    );
    
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  String _getTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.sale: return 'Sale';
      case TransactionType.purchase: return 'Purchase';
      case TransactionType.buyback: return 'Buyback';
      case TransactionType.repair: return 'Repair';
      case TransactionType.return_: return 'Return';
      case TransactionType.stockAdjustment: return 'Adjustment';
      case TransactionType.purchaseOrder: return 'PO';
    }
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.sale: return Colors.green;
      case TransactionType.purchase: return Colors.blue;
      case TransactionType.buyback: return Colors.teal;
      case TransactionType.repair: return Colors.orange;
      case TransactionType.return_: return Colors.red;
      case TransactionType.stockAdjustment: return Colors.purple;
      case TransactionType.purchaseOrder: return Colors.indigo;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed: return Colors.green;
      case TransactionStatus.pending: return Colors.orange;
      case TransactionStatus.cancelled: return Colors.red;
      case TransactionStatus.refunded: return Colors.purple;
    }
  }
}

// --- Stat Card ---
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// --- Transaction Detail Dialog ---
class _TransactionDetailDialog extends StatelessWidget {
  final TransactionLog transaction;
  const _TransactionDetailDialog({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildTypeBadge(transaction.type),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(transaction.referenceNumber ?? '#${transaction.id.substring(0, 8)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(DateFormat('MMMM dd, yyyy • hh:mm a').format(transaction.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _printReceipt(context),
                      icon: const Icon(LucideIcons.printer, size: 16),
                      label: const Text('Print'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Party & Payment
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PARTY', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(transaction.partyName, style: const TextStyle(fontWeight: FontWeight.w500)),
                              if (transaction.customerId != null || transaction.supplierId != null)
                                Text('ID: ${transaction.customerId ?? transaction.supplierId}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PAYMENT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(transaction.paymentMethod ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500)),
                              _buildStatusBadge(transaction.status),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Items
                    const Text('ITEMS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...transaction.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                if (item.imei != null) Text('IMEI: ${item.imei}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          Text('${item.quantity} x Rs. ${item.unitPrice.toStringAsFixed(0)}'),
                          const SizedBox(width: 16),
                          Text('Rs. ${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
                    const Divider(height: 24),
                    
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 24),
                        Text(
                          'Rs. ${transaction.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: transaction.isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    
                    if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('NOTES', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(transaction.notes!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(TransactionType type) {
    Color color;
    switch (type) {
      case TransactionType.sale: color = Colors.green;
      case TransactionType.purchase: color = Colors.blue;
      case TransactionType.buyback: color = Colors.teal;
      case TransactionType.repair: color = Colors.orange;
      case TransactionType.return_: color = Colors.red;
      case TransactionType.stockAdjustment: color = Colors.purple;
      case TransactionType.purchaseOrder: color = Colors.indigo;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(_getTypeIcon(type), color: color),
    );
  }

  Widget _buildStatusBadge(TransactionStatus status) {
    Color color;
    switch (status) {
      case TransactionStatus.completed: color = Colors.green;
      case TransactionStatus.pending: color = Colors.orange;
      case TransactionStatus.cancelled: color = Colors.red;
      case TransactionStatus.refunded: color = Colors.purple;
    }
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.name.toUpperCase(), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.sale: return LucideIcons.shoppingCart;
      case TransactionType.purchase: return LucideIcons.package;
      case TransactionType.buyback: return LucideIcons.smartphone;
      case TransactionType.repair: return LucideIcons.wrench;
      case TransactionType.return_: return LucideIcons.undo2;
      case TransactionType.stockAdjustment: return LucideIcons.clipboardList;
      case TransactionType.purchaseOrder: return LucideIcons.fileText;
    }
  }

  void _printReceipt(BuildContext context) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('MBM Store', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(transaction.typeLabel, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text('Ref: ${transaction.referenceNumber ?? transaction.id.substring(0, 8)}'),
            pw.Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.timestamp)}'),
            pw.Divider(),
            pw.SizedBox(height: 12),
            pw.Text('Party: ${transaction.partyName}'),
            pw.Text('Payment: ${transaction.paymentMethod ?? 'N/A'}'),
            pw.SizedBox(height: 16),
            pw.Text('Items:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...transaction.items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text(item.productName)),
                  pw.Text('${item.quantity} x ${item.unitPrice.toStringAsFixed(0)}'),
                  pw.Text('Rs. ${item.total.toStringAsFixed(0)}'),
                ],
              ),
            )),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text('Rs. ${transaction.amount.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
    
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
