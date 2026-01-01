import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/account.dart';
import '../../../core/repositories/account_repository.dart';
import '../controller/accounts_providers.dart';
import 'account_form_dialog.dart';
import 'reports/account_ledger_report.dart';
import 'account_group_form_dialog.dart';

/// Chart of Accounts view with hierarchical tree display
class ChartOfAccountsView extends ConsumerStatefulWidget {
  const ChartOfAccountsView({super.key});

  @override
  ConsumerState<ChartOfAccountsView> createState() => _ChartOfAccountsViewState();
}

class _ChartOfAccountsViewState extends ConsumerState<ChartOfAccountsView> {
  String _searchQuery = '';
  int? _selectedGroupId;
  int _selectedLevel = 0; // 0 = all levels

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountsProvider(null));
    final groupsAsync = ref.watch(accountGroupsProvider);

    return Row(
      children: [
        // Left panel: Groups filter
        Container(
          width: 250,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Account Groups',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.plusCircle, size: 20),
                      onPressed: () => _showAddGroupDialog(context),
                      tooltip: 'Add Group',
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: groupsAsync.when(
                  data: (groups) => ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _buildGroupTile(theme, null, 'All Accounts', LucideIcons.list),
                      const Divider(),
                      ...groups.map((g) => _buildGroupTile(
                        theme,
                        g.id,
                        g.name,
                        _getGroupIcon(g.type),
                      )),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),

        // Right panel: Accounts list
        Expanded(
          child: Column(
            children: [
              // Search and filter bar
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
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search accounts...',
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
                    
                    // Level filter
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('All')),
                        ButtonSegment(value: 1, label: Text('1st')),
                        ButtonSegment(value: 2, label: Text('2nd')),
                        ButtonSegment(value: 3, label: Text('3rd')),
                      ],
                      selected: {_selectedLevel},
                      onSelectionChanged: (selected) {
                        setState(() => _selectedLevel = selected.first);
                      },
                    ),
                    const SizedBox(width: 16),
                    
                    // Add account button
                    ElevatedButton.icon(
                      onPressed: () => _showAddAccountDialog(context),
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('Add Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // Accounts table
              Expanded(
                child: accountsAsync.when(
                  data: (accounts) {
                    var filtered = accounts;
                    
                    // Filter by group
                    if (_selectedGroupId != null) {
                      filtered = filtered.where((a) => a.groupId == _selectedGroupId).toList();
                    }
                    
                    // Filter by level
                    if (_selectedLevel > 0) {
                      filtered = filtered.where((a) => a.level == _selectedLevel).toList();
                    }
                    
                    // Filter by search
                    if (_searchQuery.isNotEmpty) {
                      filtered = filtered.where((a) =>
                        a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        a.accountNo.contains(_searchQuery)
                      ).toList();
                    }

                    // Sort by account number
                    filtered.sort((a, b) => a.accountNo.compareTo(b.accountNo));

                    if (filtered.isEmpty) {
                      return _buildEmptyState(theme);
                    }

                    return _buildAccountsTable(theme, filtered);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupTile(ThemeData theme, int? groupId, String label, IconData icon) {
    final isSelected = _selectedGroupId == groupId;
    
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => setState(() => _selectedGroupId = groupId),
    );
  }

  IconData _getGroupIcon(AccountType type) {
    switch (type) {
      case AccountType.asset:
        return LucideIcons.landmark;
      case AccountType.liability:
        return LucideIcons.creditCard;
      case AccountType.equity:
        return LucideIcons.pieChart;
      case AccountType.income:
        return LucideIcons.trendingUp;
      case AccountType.expense:
        return LucideIcons.trendingDown;
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.folderOpen,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No accounts found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add accounts to get started with Chart of Accounts',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsTable(ThemeData theme, List<Account> accounts) {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Account No.')),
          DataColumn(label: Text('Title')),
          DataColumn(label: Text('Level')),
          DataColumn(label: Text('Balance'), numeric: true),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: accounts.map((account) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  account.accountNo,
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    // Indentation based on level
                    SizedBox(width: (account.level - 1) * 24.0),
                    Flexible(child: Text(account.title, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLevelColor(account.level).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${account.level}${account.level == 1 ? "st" : account.level == 2 ? "nd" : "rd"}',
                    style: TextStyle(
                      color: _getLevelColor(account.level),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  'Rs. ${account.currentBalance.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: account.currentBalance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: account.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    account.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: account.isActive ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.eye, size: 16),
                      onPressed: () => _showAccountLedger(account),
                      tooltip: 'View Ledger',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.edit, size: 16),
                      onPressed: () => _showEditAccountDialog(context, account),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                      onPressed: () => _deleteAccount(context, account),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.purple;
      case 3:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showAddAccountDialog(BuildContext context) async {
    await showAccountFormDialog(context);
    ref.invalidate(accountsProvider);
  }

  Future<void> _showEditAccountDialog(BuildContext context, Account account) async {
    await showAccountFormDialog(context, editAccount: account);
    ref.invalidate(accountsProvider);
  }

  Future<void> _deleteAccount(BuildContext context, Account account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete ${account.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(accountRepositoryProvider).delete(account.accountNo);
        ref.invalidate(accountsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showAccountLedger(Account account) {
    showAccountLedgerReport(context, account: account);
  }

  Future<void> _showAddGroupDialog(BuildContext context) async {
    await showAccountGroupFormDialog(context);
    ref.invalidate(accountGroupsProvider);
  }
}
