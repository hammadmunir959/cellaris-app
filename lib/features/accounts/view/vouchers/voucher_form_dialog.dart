import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/voucher.dart';
import '../../../../core/models/account.dart';
import '../../../../core/repositories/voucher_repository.dart';
import '../../../../core/repositories/account_repository.dart';

/// Voucher Entry Form Dialog
class VoucherFormDialog extends ConsumerStatefulWidget {
  final VoucherType voucherType;
  final Voucher? editVoucher;

  const VoucherFormDialog({
    super.key,
    required this.voucherType,
    this.editVoucher,
  });

  @override
  ConsumerState<VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends ConsumerState<VoucherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _narrationController = TextEditingController();
  
  late DateTime _date;
  final List<VoucherLineEntry> _entries = [];
  List<Account> _accounts = [];
  bool _isLoading = false;
  bool _isSaving = false;

  double get _totalDebit => _entries.fold(0.0, (sum, e) => sum + e.debit);
  double get _totalCredit => _entries.fold(0.0, (sum, e) => sum + e.credit);
  bool get _isBalanced => (_totalDebit - _totalCredit).abs() < 0.01;

  @override
  void initState() {
    super.initState();
    _date = widget.editVoucher?.date ?? DateTime.now();
    _narrationController.text = widget.editVoucher?.narration ?? '';
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final accountRepo = ref.read(accountRepositoryProvider);
    final accounts = await accountRepo.getAll();
    setState(() {
      _accounts = accounts;
      _isLoading = false;
      // Add initial empty rows
      if (_entries.isEmpty) {
        _entries.add(VoucherLineEntry());
        _entries.add(VoucherLineEntry());
      }
    });
  }

  void _addRow() {
    setState(() => _entries.add(VoucherLineEntry()));
  }

  void _removeRow(int index) {
    if (_entries.length > 2) {
      setState(() => _entries.removeAt(index));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isBalanced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debit and Credit totals must be equal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate entries
    final validEntries = _entries.where((e) => 
      e.accountId != null && (e.debit > 0 || e.credit > 0)
    ).toList();

    if (validEntries.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 valid entries are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final voucherRepo = ref.read(voucherRepositoryProvider);
      
      // Generate voucher number
      final voucherNo = await voucherRepo.generateVoucherNo(widget.voucherType);

      // Build ledger entries
      final ledgerEntries = validEntries.map((e) {
        final account = _accounts.firstWhere((a) => a.id == e.accountId);
        return LedgerEntry(
          id: const Uuid().v4(),
          accountNo: e.accountId!,
          accountName: account.title,
          date: _date,
          debit: e.debit,
          credit: e.credit,
          particular: _narrationController.text,
          sourceId: voucherNo,
          sourceType: widget.voucherType.name,
        );
      }).toList();

      // Create voucher
      final voucher = Voucher(
        voucherNo: voucherNo,
        type: widget.voucherType,
        date: _date,
        totalAmount: _totalDebit,
        narration: _narrationController.text,
        createdBy: 'System',
        createdAt: DateTime.now(),
        entries: ledgerEntries,
      );

      await voucherRepo.save(voucher);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voucher $voucherNo saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, voucher);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _narrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = NumberFormat('#,###');
    final df = DateFormat('dd/MM/yyyy');

    final color = _getTypeColor(widget.voucherType);
    final icon = _getTypeIcon(widget.voucherType);

    return Dialog(
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getTypeLabel(widget.voucherType)} Voucher',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.editVoucher != null ? 'Edit Voucher' : 'New Entry',
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

              const SizedBox(height: 20),

              // Date and narration
              Row(
                children: [
                  SizedBox(
                    width: 180,
                    child: TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.calendar, size: 18),
                      ),
                      controller: TextEditingController(text: df.format(_date)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) setState(() => _date = date);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _narrationController,
                      decoration: const InputDecoration(
                        labelText: 'Narration / Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Entries table header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: const [
                    SizedBox(width: 40),
                    Expanded(flex: 3, child: Text('Account', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 16),
                    SizedBox(width: 150, child: Text('Debit', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    SizedBox(width: 16),
                    SizedBox(width: 150, child: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    SizedBox(width: 48),
                  ],
                ),
              ),

              // Entries
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                        ),
                        child: ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (context, index) => _buildEntryRow(index),
                        ),
                      ),
              ),

              // Add row button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Add Row'),
                ),
              ),

              // Totals
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isBalanced
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isBalanced ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isBalanced ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                      color: _isBalanced ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isBalanced ? 'Balanced' : 'Out of Balance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isBalanced ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(
                        'Rs. ${f.format(_totalDebit)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 150,
                      child: Text(
                        'Rs. ${f.format(_totalCredit)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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
                    onPressed: _isSaving || !_isBalanced ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.save, size: 18),
                    label: Text(_isSaving ? 'Saving...' : 'Save Voucher'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryRow(int index) {
    final entry = _entries[index];
    final theme = Theme.of(context);

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
            width: 40,
            child: Text('${index + 1}', style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              value: entry.accountId,
              hint: const Text('Select Account'),
              items: _accounts.map((a) => DropdownMenuItem(
                value: a.id,
                child: Text('${a.accountNo} - ${a.title}', overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) => setState(() => entry.accountId = v),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 150,
            child: TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixText: 'Rs. ',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              initialValue: entry.debit > 0 ? entry.debit.toString() : '',
              onChanged: (v) {
                final val = double.tryParse(v) ?? 0;
                setState(() {
                  entry.debit = val;
                  if (val > 0) entry.credit = 0;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 150,
            child: TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixText: 'Rs. ',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              initialValue: entry.credit > 0 ? entry.credit.toString() : '',
              onChanged: (v) {
                final val = double.tryParse(v) ?? 0;
                setState(() {
                  entry.credit = val;
                  if (val > 0) entry.debit = 0;
                });
              },
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
              onPressed: _entries.length > 2 ? () => _removeRow(index) : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(VoucherType type) {
    switch (type) {
      case VoucherType.cashPayment:
        return Colors.red;
      case VoucherType.cashReceipt:
        return Colors.green;
      case VoucherType.bankPayment:
        return Colors.orange;
      case VoucherType.bankReceipt:
        return Colors.teal;
      case VoucherType.partyPayment:
        return Colors.purple;
      case VoucherType.partyReceipt:
        return Colors.blue;
      case VoucherType.journalVoucher:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(VoucherType type) {
    switch (type) {
      case VoucherType.cashPayment:
        return LucideIcons.arrowUpCircle;
      case VoucherType.cashReceipt:
        return LucideIcons.arrowDownCircle;
      case VoucherType.bankPayment:
        return LucideIcons.banknote;
      case VoucherType.bankReceipt:
        return LucideIcons.landmark;
      case VoucherType.partyPayment:
        return LucideIcons.userMinus;
      case VoucherType.partyReceipt:
        return LucideIcons.userPlus;
      case VoucherType.journalVoucher:
        return LucideIcons.fileText;
    }
  }

  String _getTypeLabel(VoucherType type) {
    switch (type) {
      case VoucherType.cashPayment:
        return 'Cash Payment';
      case VoucherType.cashReceipt:
        return 'Cash Receipt';
      case VoucherType.bankPayment:
        return 'Bank Payment';
      case VoucherType.bankReceipt:
        return 'Bank Receipt';
      case VoucherType.partyPayment:
        return 'Party Payment';
      case VoucherType.partyReceipt:
        return 'Party Receipt';
      case VoucherType.journalVoucher:
        return 'Journal';
    }
  }
}

class VoucherLineEntry {
  String? accountId;
  double debit = 0;
  double credit = 0;
}

/// Show voucher form dialog
Future<Voucher?> showVoucherFormDialog(
  BuildContext context,
  VoucherType type, {
  Voucher? editVoucher,
}) {
  return showDialog<Voucher>(
    context: context,
    builder: (context) => VoucherFormDialog(
      voucherType: type,
      editVoucher: editVoucher,
    ),
  );
}
