import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/account.dart';
import '../controller/accounts_providers.dart';
import '../../../../core/repositories/account_repository.dart';

/// Dialog for creating or editing an account
class AccountFormDialog extends ConsumerStatefulWidget {
  final Account? editAccount;
  final AccountGroup? preselectedGroup;

  const AccountFormDialog({
    super.key,
    this.editAccount,
    this.preselectedGroup,
  });

  @override
  ConsumerState<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends ConsumerState<AccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountNoController = TextEditingController();
  final _titleController = TextEditingController();
  final _balanceController = TextEditingController();

  AccountGroup? _selectedGroup;
  bool _isPublic = true;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    // If editing, populate fields
    if (widget.editAccount != null) {
      final a = widget.editAccount!;
      _accountNoController.text = a.accountNo;
      _titleController.text = a.title;
      _balanceController.text = a.currentBalance.toString();
      _isPublic = a.isPublic;

      // Load group
      final groups = await ref.read(accountGroupsProvider.future);
      try {
        _selectedGroup = groups.firstWhere((g) => g.id == a.groupId);
      } catch (_) {
        // Group not found?
      }
    } else {
      // New account
      if (widget.preselectedGroup != null) {
        _selectedGroup = widget.preselectedGroup;
      }
      _balanceController.text = '0';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account group')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(accountRepositoryProvider);

      final account = Account(
        accountNo: _accountNoController.text,
        title: _titleController.text,
        groupId: _selectedGroup!.id,
        currentBalance: double.tryParse(_balanceController.text) ?? 0,
        isPublic: _isPublic,
        isActive: true, // Default to active
        // Preserve other fields if editing
        incentivePercent: widget.editAccount?.incentivePercent ?? 0,
        companyId: widget.editAccount?.companyId,
      );

      await repo.save(account);

      if (mounted) {
        ref.invalidate(accountsProvider); // Refresh list
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account saved successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(accountGroupsProvider);

    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(LucideIcons.wallet, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.editAccount != null ? 'Edit Account' : 'New Account',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Fill in the details below',
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
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Account Group
                groupsAsync.when(
                  data: (groups) => DropdownButtonFormField<AccountGroup>(
                    decoration: const InputDecoration(
                      labelText: 'Account Group',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(LucideIcons.folder),
                    ),
                    value: _selectedGroup,
                    items: groups.map((g) => DropdownMenuItem(
                      value: g,
                      child: Text(g.name),
                    )).toList(),
                    onChanged: (g) {
                      setState(() => _selectedGroup = g);
                      // Auto-suggestion logic for Account No could go here
                    },
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading groups: $e'),
                ),
                const SizedBox(height: 16),

                // Account No & Title
                Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: _accountNoController,
                        decoration: const InputDecoration(
                          labelText: 'Account No',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(LucideIcons.hash),
                        ),
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                        readOnly: widget.editAccount != null, // Lock ID on edit
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Account Title',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(LucideIcons.type),
                        ),
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Opening Balance (Disable if editing for now, or allow adjustment via JV only typically)
                // For simplicity allowing edit here, but typically this should be separate.
                TextFormField(
                  controller: _balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Current Balance (Opening)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(LucideIcons.coins),
                    helperText: 'For initial setup only. Use Vouchers for transactions.',
                  ),
                  keyboardType: TextInputType.number,
                  // readOnly: widget.editAccount != null, // Uncomment to lock balance editing
                ),
                const SizedBox(height: 16),

                // Options
                SwitchListTile(
                  title: const Text('Public Account'),
                  subtitle: const Text('Visible to all branches'),
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(LucideIcons.save, size: 16),
                      label: Text(_isSaving ? 'Saving...' : 'Save Account'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper to show the dialog
Future<bool?> showAccountFormDialog(
  BuildContext context, {
  Account? editAccount,
  AccountGroup? preselectedGroup,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AccountFormDialog(
      editAccount: editAccount,
      preselectedGroup: preselectedGroup,
    ),
  );
}
