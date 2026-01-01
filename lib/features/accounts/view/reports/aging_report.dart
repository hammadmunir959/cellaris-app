import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/account.dart';
import '../../../../core/repositories/voucher_repository.dart';
import '../../../../core/repositories/account_repository.dart';

enum AgingType { receivables, payables }

class AgingBucket {
  double current = 0; // 0-30
  double days30To60 = 0;
  double days60To90 = 0;
  double days90Plus = 0;
  double total = 0;

  void addAmount(double amount, int days) {
    if (days <= 30) {
      current += amount;
    } else if (days <= 60) {
      days30To60 += amount;
    } else if (days <= 90) {
      days60To90 += amount;
    } else {
      days90Plus += amount;
    }
    total += amount;
  }
}

class AgingReport extends ConsumerStatefulWidget {
  final AgingType type;

  const AgingReport({super.key, required this.type});

  @override
  ConsumerState<AgingReport> createState() => _AgingReportState();
}

class _AgingReportState extends ConsumerState<AgingReport> {
  bool _isLoading = false;
  Map<Account, AgingBucket> _agingData = {};
  DateTime _asOfDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);

    try {
      final accountRepo = ref.read(accountRepositoryProvider);
      final voucherRepo = ref.read(voucherRepositoryProvider);

      // 1. Get relevant accounts
      // Receivables are usually Assets (e.g. Customers)
      // Payables are usually Liabilities (e.g. Suppliers)
      // Ideally we'd filter by specific group, but for now we filter by type and balance direction
      final allAccounts = await accountRepo.getAll();
      final relevantAccounts = allAccounts.where((a) {
        if (widget.type == AgingType.receivables) {
           // Include if Asset and balance > 0, OR just all Assets with transactions
           // Simplification: Include all Assets and Income
           return a.groupId.toString() == "10" || a.title.toLowerCase().contains("customer"); 
           // Better: Use StandardAccountGroups.assets.id which is 10
        } else {
           // Liabilities
           return a.groupId.toString() == "20" || a.title.toLowerCase().contains("supplier");
        }
      }).toList();

      final data = <Account, AgingBucket>{};

      for (final account in relevantAccounts) {
        // Get all entries for account
        final entries = await voucherRepo.getEntriesForAccount(account.accountNo);
        
        // Calculate current balance
        double balance = entries.fold(0.0, (sum, e) => sum + (e.debit - e.credit));

        // Skip zero balance accounts
        if (balance.abs() < 1) continue;

        // Determine direction:
        // Receivables: Positive Balance means they owe us (Debit balance)
        // Payables: Negative Balance means we owe them (Credit balance)
        // We work with absolute 'Due' amount
        
        if (widget.type == AgingType.receivables && balance <= 0) continue; // Only positive debtors
        if (widget.type == AgingType.payables && balance >= 0) continue; // Only negative creditors

        double dueAmount = balance.abs();
        final bucket = AgingBucket();

        // FIFO Allocation:
        // We match the 'Balance Due' against the latest transactions going backwards.
        // E.g. Due 100.
        // Last txn: Debit 40 (5 days ago). Bucket 0-30 += 40. Remaining Due 60.
        // Prev txn: Debit 70 (45 days ago). Bucket 30-60 += 60 (capped at remaining). Remaining 0.

        // Sort entries by date descending (latest first)
        final sortedEntries = List.of(entries)..sort((a, b) => b.date.compareTo(a.date));

        for (final entry in sortedEntries) {
          if (dueAmount <= 0) break;

          // For Receivables, we look for Debits (increases to debt)
          // For Payables, we look for Credits (increases to liability)
          double amount = widget.type == AgingType.receivables ? entry.debit : entry.credit;

          if (amount <= 0) continue; // Skip contra-entries (payments)

          double allocatable = amount;
          if (allocatable > dueAmount) allocatable = dueAmount;

          final ageDays = _asOfDate.difference(entry.date).inDays;
          bucket.addAmount(allocatable, ageDays);

          dueAmount -= allocatable;
        }

        // If generic balance remains (e.g. opening balance w/o entries), put in 90+
        if (dueAmount > 0) {
          bucket.addAmount(dueAmount, 999);
        }

        data[account] = bucket;
      }

      setState(() {
        _agingData = data;
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = NumberFormat('#,###');

    return Dialog(
      child: Container(
        width: 1000,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (widget.type == AgingType.receivables ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.type == AgingType.receivables ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    color: widget.type == AgingType.receivables ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.type == AgingType.receivables ? 'Aging Receivables' : 'Aging Payables',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'As of ${DateFormat('dd MMM yyyy').format(_asOfDate)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _agingData.isEmpty
                      ? const Center(child: Text('No data found'))
                      : SingleChildScrollView(
                          child: Table(
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                color: theme.dividerColor.withValues(alpha: 0.1),
                              ),
                            ),
                            columnWidths: const {
                              0: FlexColumnWidth(2), // Account
                              1: FlexColumnWidth(1), // Total
                              2: FlexColumnWidth(1), // 0-30
                              3: FlexColumnWidth(1), // 30-60
                              4: FlexColumnWidth(1), // 60-90
                              5: FlexColumnWidth(1), // >90
                            },
                            children: [
                              // Header Row
                              TableRow(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                ),
                                children: [
                                  _buildHeaderCell('Account Name'),
                                  _buildHeaderCell('Total Due', align: TextAlign.right),
                                  _buildHeaderCell('0-30 Days', align: TextAlign.right),
                                  _buildHeaderCell('31-60 Days', align: TextAlign.right),
                                  _buildHeaderCell('61-90 Days', align: TextAlign.right),
                                  _buildHeaderCell('> 90 Days', align: TextAlign.right),
                                ],
                              ),
                              // Data Rows
                              ..._agingData.entries.map((e) {
                                final account = e.key;
                                final bucket = e.value;
                                return TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(account.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text(account.accountNo, style: theme.textTheme.bodySmall),
                                        ],
                                      ),
                                    ),
                                    _buildCell(f.format(bucket.total), bold: true),
                                    _buildCell(f.format(bucket.current)),
                                    _buildCell(f.format(bucket.days30To60)),
                                    _buildCell(f.format(bucket.days60To90)),
                                    _buildCell(f.format(bucket.days90Plus), color: Colors.red),
                                  ],
                                );
                              }),
                              // Total Row
                              TableRow(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                                ),
                                children: [
                                  _buildCell('TOTAL', bold: true),
                                  _buildCell(f.format(_calculateTotal((b) => b.total)), bold: true),
                                  _buildCell(f.format(_calculateTotal((b) => b.current)), bold: true),
                                  _buildCell(f.format(_calculateTotal((b) => b.days30To60)), bold: true),
                                  _buildCell(f.format(_calculateTotal((b) => b.days60To90)), bold: true),
                                  _buildCell(f.format(_calculateTotal((b) => b.days90Plus)), bold: true, color: Colors.red),
                                ],
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCell(String text, {bool bold = false, TextAlign align = TextAlign.right, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  double _calculateTotal(double Function(AgingBucket) selector) {
    return _agingData.values.fold(0.0, (sum, b) => sum + selector(b));
  }
}

Future<void> showAgingReport(BuildContext context, AgingType type) {
  return showDialog(
    context: context,
    builder: (context) => AgingReport(type: type),
  );
}
