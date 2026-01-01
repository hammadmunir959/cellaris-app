import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/voucher.dart';
import '../controller/accounts_providers.dart';
import '../model/accounts_state.dart';
import 'chart_of_accounts_view.dart';
import 'vouchers/voucher_list_view.dart';
import 'vouchers/voucher_form_dialog.dart';
import 'reports/reports_menu_view.dart';

/// Main screen for the Accounts module
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  AccountsViewMode _currentMode = AccountsViewMode.chartOfAccounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cashBalance = ref.watch(cashBalanceProvider(null));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header with navigation tabs and cash balance
          _buildHeader(theme, cashBalance),
          
          // Action buttons bar
          _buildActionBar(theme),
          
          // Main content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AsyncValue<double> cashBalance) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          // Title
          Text(
            'Accounts',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 32),
          
          // Navigation tabs
          _buildNavTab(
            theme,
            'Chart of Accounts',
            LucideIcons.layoutList,
            AccountsViewMode.chartOfAccounts,
          ),
          _buildNavTab(
            theme,
            'Vouchers',
            LucideIcons.receipt,
            AccountsViewMode.vouchers,
          ),
          _buildNavTab(
            theme,
            'Reports',
            LucideIcons.barChart3,
            AccountsViewMode.reports,
          ),
          
          const Spacer(),
          
          // Cash balance display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.wallet,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cash Balance',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    cashBalance.when(
                      data: (balance) => Text(
                        'Rs. ${balance.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 
                              ? theme.colorScheme.primary
                              : Colors.red,
                        ),
                      ),
                      loading: () => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => const Text(
                        'Error',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab(
    ThemeData theme,
    String label,
    IconData icon,
    AccountsViewMode mode,
  ) {
    final isSelected = _currentMode == mode;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _currentMode = mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha:0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha:0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    if (_currentMode != AccountsViewMode.vouchers) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          _buildVoucherButton(
            theme,
            'Cash Payment',
            LucideIcons.arrowUpCircle,
            Colors.red,
            VoucherType.cashPayment,
          ),
          const SizedBox(width: 8),
          _buildVoucherButton(
            theme,
            'Cash Receipt',
            LucideIcons.arrowDownCircle,
            Colors.green,
            VoucherType.cashReceipt,
          ),
          const SizedBox(width: 8),
          _buildVoucherButton(
            theme,
            'Bank Payment',
            LucideIcons.building2,
            Colors.orange,
            VoucherType.bankPayment,
          ),
          const SizedBox(width: 8),
          _buildVoucherButton(
            theme,
            'Bank Receipt',
            LucideIcons.building,
            Colors.teal,
            VoucherType.bankReceipt,
          ),
          const SizedBox(width: 8),
          _buildVoucherButton(
            theme,
            'Party Payment',
            LucideIcons.userMinus,
            Colors.purple,
            VoucherType.partyPayment,
          ),
          const SizedBox(width: 8),
          _buildVoucherButton(
            theme,
            'Party Receipt',
            LucideIcons.userPlus,
            Colors.blue,
            VoucherType.partyReceipt,
          ),
          const SizedBox(width: 8),
          _buildVoucherButton(
            theme,
            'Journal',
            LucideIcons.fileText,
            Colors.grey,
            VoucherType.journalVoucher,
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherButton(
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
    VoucherType type,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        ref.read(selectedVoucherTypeProvider.notifier).state = type;
        _showVoucherDialog(type);
      },
      icon: Icon(icon, size: 16, color: color),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  void _showVoucherDialog(VoucherType type) async {
    final result = await showVoucherFormDialog(context, type);
    if (result != null) {
      // Voucher was saved - refresh voucher list
      ref.invalidate(vouchersProvider);
    }
  }

  Widget _buildContent() {
    switch (_currentMode) {
      case AccountsViewMode.chartOfAccounts:
        return const ChartOfAccountsView();
      case AccountsViewMode.vouchers:
        return const VoucherListView();
      case AccountsViewMode.reports:
        return const ReportsMenuView();
    }
  }
}
