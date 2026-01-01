import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../model/accounts_state.dart';
import 'account_ledger_report.dart';
import 'trial_balance_report.dart';
import 'profit_loss_report.dart';
import 'aging_report.dart';

/// Reports menu with navigation to different financial reports
class ReportsMenuView extends ConsumerWidget {
  const ReportsMenuView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Reports',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a report to view detailed financial information',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildReportCard(
                  context,
                  theme,
                  'Account Ledger',
                  'View detailed transaction history for any account',
                  LucideIcons.bookOpen,
                  Colors.blue,
                  ReportType.accountLedger,
                ),
                _buildReportCard(
                  context,
                  theme,
                  'Trial Balance',
                  'Summary of all account balances at a point in time',
                  LucideIcons.scale,
                  Colors.purple,
                  ReportType.trialBalance,
                ),
                _buildReportCard(
                  context,
                  theme,
                  'Profit & Loss',
                  'Income statement showing revenue and expenses',
                  LucideIcons.trendingUp,
                  Colors.green,
                  ReportType.profitLoss,
                ),
                _buildReportCard(
                  context,
                  theme,
                  'Aging Receivables',
                  'Outstanding customer balances by age',
                  LucideIcons.clock,
                  Colors.orange,
                  ReportType.agingReceivables,
                ),
                _buildReportCard(
                  context,
                  theme,
                  'Aging Payables',
                  'Outstanding supplier balances by age',
                  LucideIcons.clock,
                  Colors.red,
                  ReportType.agingPayables,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    ThemeData theme,
    String title,
    String description,
    IconData icon,
    Color color,
    ReportType reportType,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () => _openReport(context, reportType),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Open Report',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.arrowRight, size: 16, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReport(BuildContext context, ReportType reportType) {
    switch (reportType) {
      case ReportType.accountLedger:
        showAccountLedgerReport(context);
        break;
      case ReportType.trialBalance:
        showTrialBalanceReport(context);
        break;
      case ReportType.profitLoss:
        showProfitLossReport(context);
        break;
      case ReportType.agingReceivables:
        showAgingReport(context, AgingType.receivables);
        break;
      case ReportType.agingPayables:
        showAgingReport(context, AgingType.payables);
        break;

    }
  }

  String _getReportTitle(ReportType type) {
    switch (type) {
      case ReportType.accountLedger:
        return 'Account Ledger';
      case ReportType.trialBalance:
        return 'Trial Balance';
      case ReportType.profitLoss:
        return 'Profit & Loss Statement';
      case ReportType.agingReceivables:
        return 'Aging Receivables';
      case ReportType.agingPayables:
        return 'Aging Payables';
    }
  }
}
