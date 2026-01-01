import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/account.dart';
import '../controller/accounts_providers.dart';
import '../../../../core/repositories/account_repository.dart';

class AccountGroupFormDialog extends ConsumerStatefulWidget {
  final AccountGroup? editGroup;

  const AccountGroupFormDialog({super.key, this.editGroup});

  @override
  ConsumerState<AccountGroupFormDialog> createState() => _AccountGroupFormDialogState();
}

class _AccountGroupFormDialogState extends ConsumerState<AccountGroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  AccountType _selectedType = AccountType.asset;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editGroup != null) {
      _nameController.text = widget.editGroup!.name;
      _selectedType = widget.editGroup!.type;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(accountRepositoryProvider);
      
      final group = AccountGroup(
        id: widget.editGroup?.id ?? DateTime.now().millisecondsSinceEpoch, // Simple ID gen
        name: _nameController.text,
        type: _selectedType,
        parentGroupId: widget.editGroup?.parentGroupId,
      );

      await repo.saveGroup(group);

      if (mounted) {
        ref.invalidate(accountGroupsProvider);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account Group saved'), backgroundColor: Colors.green),
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
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.editGroup != null ? 'Edit Account Group' : 'New Account Group',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.folder),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<AccountType>(
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.tag),
                ),
                value: _selectedType,
                items: AccountType.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.name.toUpperCase()),
                )).toList(),
                onChanged: widget.editGroup == null 
                  ? (t) => setState(() => _selectedType = t!)
                  : null, // Lock type on edit to prevent inconsistency
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: Text(_isSaving ? 'Saving...' : 'Save Group'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> showAccountGroupFormDialog(BuildContext context, {AccountGroup? editGroup}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AccountGroupFormDialog(editGroup: editGroup),
  );
}
