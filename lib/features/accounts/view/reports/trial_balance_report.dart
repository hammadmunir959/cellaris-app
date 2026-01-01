import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/account.dart';
import '../../../../core/repositories/ledger_repository.dart';
import '../../../../core/repositories/account_repository.dart';

/// Trial Balance Report
class TrialBalanceReport extends ConsumerStatefulWidget {
  const TrialBalanceReport({super.key});

  @override
  ConsumerState<TrialBalanceReport> createState() => _TrialBalanceReportState();
}

class _TrialBalanceReportState extends ConsumerState<TrialBalanceReport> {
  DateTime _asOfDate = DateTime.now();
  int _levelFilter = 0; // 0 = All, 2 = 2nd level, 3 = 3rd level
  List<TrialBalanceRow> _rows = [];
  bool _isLoading = false;
  double _totalDebit = 0;
  double _totalCredit = 0;

  @override
  void initState() {
    super.initState();
    _loadTrialBalance();
  }

  Future<void> _loadTrialBalance() async {
    setState(() => _isLoading = true);

    try {
      final ledgerRepo = ref.read(ledgerRepositoryProvider);
      final accountRepo = ref.read(accountRepositoryProvider);
      
      final tbData = await ledgerRepo.getTrialBalance(asOfDate: _asOfDate);
      final accounts = await accountRepo.getAll();

      // Build rows with account details
      final rows = <TrialBalanceRow>[];
      double totalDr = 0;
      double totalCr = 0;

      for (final entry in tbData.entries) {
        final account = accounts.where((a) => a.accountNo == entry.key).firstOrNull;
        if (account == null) continue;

        // Apply level filter
        if (_levelFilter > 0) {
          final level = account.accountNo.length ~/ 2; // 2 digits per level
          if (level != _levelFilter) continue;
        }

        rows.add(TrialBalanceRow(
          accountNo: account.accountNo,
          accountTitle: account.title,
          groupName: account.groupId.toString(),
          debit: entry.value > 0 ? entry.value : 0,
          credit: entry.value < 0 ? entry.value.abs() : 0,
        ));

        if (entry.value > 0) {
          totalDr += entry.value;
        } else {
          totalCr += entry.value.abs();
        }
      }

      rows.sort((a, b) => a.accountNo.compareTo(b.accountNo));

      setState(() {
        _rows = rows;
        _totalDebit = totalDr;
        _totalCredit = totalCr;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = NumberFormat('#,###');
    final df = DateFormat('dd MMM yyyy');

    return Dialog(
      child: Container(
        width: 800,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.scale, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trial Balance',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'As of ${df.format(_asOfDate)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Filters
            Row(
              children: [
                // Date picker
                SizedBox(
                  width: 180,
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'As of Date',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      prefixIcon: Icon(LucideIcons.calendar, size: 18),
                    ),
                    controller: TextEditingController(text: df.format(_asOfDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _asOfDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _asOfDate = date);
                        _loadTrialBalance();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Level filter
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('All')),
                    ButtonSegment(value: 2, label: Text('2nd Level')),
                    ButtonSegment(value: 3, label: Text('3rd Level')),
                  ],
                  selected: {_levelFilter},
                  onSelectionChanged: (value) {
                    setState(() => _levelFilter = value.first);
                    _loadTrialBalance();
                  },
                ),

                const Spacer(),

                // Balance check
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_totalDebit - _totalCredit).abs() < 0.01
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (_totalDebit - _totalCredit).abs() < 0.01
                            ? LucideIcons.checkCircle
                            : LucideIcons.alertCircle,
                        size: 16,
                        color: (_totalDebit - _totalCredit).abs() < 0.01
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (_totalDebit - _totalCredit).abs() < 0.01
                            ? 'Balanced'
                            : 'Diff: ${f.format((_totalDebit - _totalCredit).abs())}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: (_totalDebit - _totalCredit).abs() < 0.01
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _rows.isEmpty
                      ? const Center(child: Text('No data found'))
                      : _buildTable(theme, f),
            ),

            const SizedBox(height: 16),

            // Totals
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'TOTAL',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Rs. ${f.format(_totalDebit)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Rs. ${f.format(_totalCredit)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(ThemeData theme, NumberFormat f) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 80, child: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Account Title', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 120, child: Text('Debit', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                SizedBox(width: 120, child: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
          ),

          // Body
          Expanded(
            child: ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (context, index) {
                final row = _rows[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: index.isEven ? theme.colorScheme.surface : null,
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(row.accountNo, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                      ),
                      Expanded(
                        child: Text(row.accountTitle, style: const TextStyle(fontSize: 13)),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          row.debit > 0 ? f.format(row.debit) : '-',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: row.debit > 0 ? Colors.green : null,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          row.credit > 0 ? f.format(row.credit) : '-',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: row.credit > 0 ? Colors.red : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TrialBalanceRow {
  final String accountNo;
  final String accountTitle;
  final String groupName;
  final double debit;
  final double credit;

  const TrialBalanceRow({
    required this.accountNo,
    required this.accountTitle,
    required this.groupName,
    required this.debit,
    required this.credit,
  });
}

/// Show trial balance dialog
Future<void> showTrialBalanceReport(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const TrialBalanceReport(),
  );
}
