import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/account.dart';
import '../../../../core/models/voucher.dart';
import '../../../../core/repositories/voucher_repository.dart';
import '../../../../core/repositories/account_repository.dart';

/// Account Ledger Report Dialog
class AccountLedgerReport extends ConsumerStatefulWidget {
  final Account? initialAccount;

  const AccountLedgerReport({super.key, this.initialAccount});

  @override
  ConsumerState<AccountLedgerReport> createState() => _AccountLedgerReportState();
}

class _AccountLedgerReportState extends ConsumerState<AccountLedgerReport> {
  Account? _selectedAccount;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  List<LedgerEntry> _entries = [];
  bool _isLoading = false;
  double _openingBalance = 0;
  double _closingBalance = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialAccount != null) {
      _selectedAccount = widget.initialAccount;
      _loadLedger();
    }
  }

  Future<void> _loadLedger() async {
    if (_selectedAccount == null) return;

    setState(() => _isLoading = true);

    try {
      final voucherRepo = ref.read(voucherRepositoryProvider);
      final entries = await voucherRepo.getEntriesForAccount(
        _selectedAccount!.accountNo,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      // Calculate balances
      double balance = 0;
      for (final entry in entries) {
        balance += entry.debit - entry.credit;
      }

      setState(() {
        _entries = entries;
        _openingBalance = 0; // Would be calculated from previous period
        _closingBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ledger: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = NumberFormat('#,###');
    final df = DateFormat('dd/MM/yyyy');

    return Dialog(
      child: Container(
        width: 900,
        height: 700,
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
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.bookOpen, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Ledger',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedAccount != null)
                        Text(
                          _selectedAccount!.title,
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
                // Account selector
                Expanded(
                  child: FutureBuilder<List<Account>>(
                    future: ref.read(accountRepositoryProvider).getAll(),
                    builder: (context, snapshot) {
                      final accounts = snapshot.data ?? [];
                      // Use accountNo as the value key to avoid object comparison issues
                      final selectedAccountNo = _selectedAccount?.accountNo;
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Account',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: accounts.any((a) => a.accountNo == selectedAccountNo) ? selectedAccountNo : null,
                        items: accounts.map((a) => DropdownMenuItem(
                          value: a.accountNo,
                          child: Text('${a.accountNo} - ${a.title}'),
                        )).toList(),
                        onChanged: (accountNo) {
                          if (accountNo != null) {
                            final account = accounts.firstWhere((a) => a.accountNo == accountNo);
                            setState(() => _selectedAccount = account);
                            _loadLedger();
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // From date
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'From',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    controller: TextEditingController(text: df.format(_fromDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _fromDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _fromDate = date);
                        _loadLedger();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // To date
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    controller: TextEditingController(text: df.format(_toDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _toDate,
                        firstDate: _fromDate,
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _toDate = date);
                        _loadLedger();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Refresh
                IconButton.filled(
                  icon: const Icon(LucideIcons.refreshCw),
                  onPressed: _loadLedger,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Opening balance
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Opening Balance', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    'Rs. ${f.format(_openingBalance.abs())}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _openingBalance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Ledger table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? const Center(child: Text('No entries found'))
                      : _buildLedgerTable(theme, f, df),
            ),

            const SizedBox(height: 16),

            // Closing balance
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Closing Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'Rs. ${f.format(_closingBalance.abs())} ${_closingBalance >= 0 ? "Dr" : "Cr"}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue,
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

  Widget _buildLedgerTable(ThemeData theme, NumberFormat f, DateFormat df) {
    double runningBalance = _openingBalance;

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
                SizedBox(width: 80, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Particulars', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 100, child: Text('Debit', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                SizedBox(width: 100, child: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                SizedBox(width: 120, child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
          ),

          // Body
          Expanded(
            child: ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                runningBalance += entry.debit - entry.credit;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(df.format(entry.date), style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(entry.particular ?? '', style: const TextStyle(fontSize: 12)),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          entry.debit > 0 ? f.format(entry.debit) : '-',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          entry.credit > 0 ? f.format(entry.credit) : '-',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${f.format(runningBalance.abs())} ${runningBalance >= 0 ? "Dr" : "Cr"}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: runningBalance >= 0 ? Colors.green : Colors.red,
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

/// Show account ledger dialog
Future<void> showAccountLedgerReport(BuildContext context, {Account? account}) {
  return showDialog(
    context: context,
    builder: (context) => AccountLedgerReport(initialAccount: account),
  );
}
