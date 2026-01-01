import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/account.dart';
import '../../../../core/repositories/ledger_repository.dart';
import '../../../../core/repositories/account_repository.dart';

/// Profit & Loss Statement Report
class ProfitLossReport extends ConsumerStatefulWidget {
  const ProfitLossReport({super.key});

  @override
  ConsumerState<ProfitLossReport> createState() => _ProfitLossReportState();
}

class _ProfitLossReportState extends ConsumerState<ProfitLossReport> {
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  bool _isLoading = false;

  // P&L data
  List<PLLineItem> _revenueItems = [];
  List<PLLineItem> _costOfGoodsItems = [];
  List<PLLineItem> _operatingExpenses = [];
  List<PLLineItem> _otherIncome = [];
  List<PLLineItem> _otherExpenses = [];

  double get _totalRevenue => _revenueItems.fold(0.0, (sum, i) => sum + i.amount);
  double get _totalCOGS => _costOfGoodsItems.fold(0.0, (sum, i) => sum + i.amount);
  double get _grossProfit => _totalRevenue - _totalCOGS;
  double get _totalOpEx => _operatingExpenses.fold(0.0, (sum, i) => sum + i.amount);
  double get _totalOtherIncome => _otherIncome.fold(0.0, (sum, i) => sum + i.amount);
  double get _totalOtherExpenses => _otherExpenses.fold(0.0, (sum, i) => sum + i.amount);
  double get _operatingIncome => _grossProfit - _totalOpEx;
  double get _netProfit => _operatingIncome + _totalOtherIncome - _totalOtherExpenses;

  @override
  void initState() {
    super.initState();
    _loadPLData();
  }

  Future<void> _loadPLData() async {
    setState(() => _isLoading = true);

    try {
      final accountRepo = ref.read(accountRepositoryProvider);
      final ledgerRepo = ref.read(ledgerRepositoryProvider);

      final accounts = await accountRepo.getAll();
      final tbData = await ledgerRepo.getTrialBalance(asOfDate: _toDate);

      // Group accounts by type
      final revenue = <PLLineItem>[];
      final cogs = <PLLineItem>[];
      final opex = <PLLineItem>[];
      final otherInc = <PLLineItem>[];
      final otherExp = <PLLineItem>[];

      for (final entry in tbData.entries) {
        final account = accounts.where((a) => a.accountNo == entry.key).firstOrNull;
        if (account == null) continue;

        final item = PLLineItem(
          accountNo: account.accountNo,
          title: account.title,
          amount: entry.value.abs(),
        );

        // Categorize by account number prefix (simplified - actual would use AccountGroup)
        if (account.accountNo.startsWith('4')) {
          // Revenue accounts
          revenue.add(item);
        } else if (account.accountNo.startsWith('5')) {
          // Cost of Goods Sold
          cogs.add(item);
        } else if (account.accountNo.startsWith('6')) {
          // Operating Expenses
          opex.add(item);
        } else if (account.accountNo.startsWith('7')) {
          // Other Income
          otherInc.add(item);
        } else if (account.accountNo.startsWith('8')) {
          // Other Expenses
          otherExp.add(item);
        }
      }

      setState(() {
        _revenueItems = revenue;
        _costOfGoodsItems = cogs;
        _operatingExpenses = opex;
        _otherIncome = otherInc;
        _otherExpenses = otherExp;
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
        width: 700,
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
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.trendingUp, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profit & Loss Statement',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${df.format(_fromDate)} - ${df.format(_toDate)}',
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

            // Date range
            Row(
              children: [
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
                        _loadPLData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
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
                        _loadPLData();
                      }
                    },
                  ),
                ),
                const Spacer(),
                IconButton.filled(
                  icon: const Icon(LucideIcons.refreshCw),
                  onPressed: _loadPLData,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // P&L Statement
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Revenue Section
                          _buildSection(theme, f, 'Revenue', _revenueItems, Colors.green),
                          _buildSubtotal(theme, f, 'Total Revenue', _totalRevenue, Colors.green),

                          const SizedBox(height: 8),

                          // COGS Section
                          _buildSection(theme, f, 'Cost of Goods Sold', _costOfGoodsItems, Colors.orange),
                          _buildSubtotal(theme, f, 'Total COGS', _totalCOGS, Colors.orange),

                          // Gross Profit
                          _buildHighlight(theme, f, 'GROSS PROFIT', _grossProfit, 
                            _grossProfit >= 0 ? Colors.green : Colors.red),

                          const SizedBox(height: 16),

                          // Operating Expenses
                          _buildSection(theme, f, 'Operating Expenses', _operatingExpenses, Colors.red),
                          _buildSubtotal(theme, f, 'Total Operating Expenses', _totalOpEx, Colors.red),

                          // Operating Income
                          _buildHighlight(theme, f, 'OPERATING INCOME', _operatingIncome,
                            _operatingIncome >= 0 ? Colors.green : Colors.red),

                          const SizedBox(height: 16),

                          // Other Income/Expenses
                          if (_otherIncome.isNotEmpty) ...[
                            _buildSection(theme, f, 'Other Income', _otherIncome, Colors.blue),
                          ],
                          if (_otherExpenses.isNotEmpty) ...[
                            _buildSection(theme, f, 'Other Expenses', _otherExpenses, Colors.purple),
                          ],
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Net Profit
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _netProfit >= 0
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _netProfit >= 0 ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _netProfit >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                        color: _netProfit >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'NET PROFIT / (LOSS)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Text(
                    'Rs. ${f.format(_netProfit.abs())}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: _netProfit >= 0 ? Colors.green : Colors.red,
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

  Widget _buildSection(ThemeData theme, NumberFormat f, String title, List<PLLineItem> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Text(item.title, style: const TextStyle(fontSize: 13))),
              Text('Rs. ${f.format(item.amount)}', style: const TextStyle(fontSize: 13)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildSubtotal(ThemeData theme, NumberFormat f, String label, double amount, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ),
          Text(
            'Rs. ${f.format(amount)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlight(ThemeData theme, NumberFormat f, String label, double amount, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            'Rs. ${f.format(amount.abs())}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }
}

class PLLineItem {
  final String accountNo;
  final String title;
  final double amount;

  const PLLineItem({
    required this.accountNo,
    required this.title,
    required this.amount,
  });
}

/// Show P&L report dialog
Future<void> showProfitLossReport(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const ProfitLossReport(),
  );
}
