import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/shared/controller/shared_controller.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/features/suppliers/view/add_supplier_modal.dart';
import 'package:mbm_app/features/suppliers/view/supplier_history_dialog.dart';

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final suppliers = ref.watch(supplierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Supplier Network', style: theme.textTheme.displayMedium?.copyWith(fontSize: 28)),
                const Text('Manage corporate vendors and mobile distribution networks.', style: TextStyle(color: Colors.grey)),
              ],
            ),
            PrimaryButton(
              label: 'Add Supplier',
              onPressed: () => _showAddSupplierDialog(context),
              icon: LucideIcons.truck,
              width: 180,
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Search (Visual Placeholder)
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Company, Contact or Address...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _FilterBtn(label: 'Active', icon: LucideIcons.checkCircle, color: Colors.green),
          ],
        ),

        const SizedBox(height: 24),

        // Table
        Expanded(
          child: suppliers.isEmpty 
          ? const Center(child: Text('No suppliers found.'))
          : FadeInUp(
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
                      child: Row(
                        children: const [
                          Expanded(flex: 3, child: Text('Company & Representative', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Contact Details', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Status & Terms', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('Payables', style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: suppliers.length,
                        itemBuilder: (context, index) {
                          final s = suppliers[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03)))),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(LucideIcons.building2, size: 20, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.company, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text(s.name, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.contact, style: const TextStyle(fontSize: 13)),
                                      if (s.email != null) Text(s.email!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (s.isActive ? Colors.green : Colors.red).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(s.isActive ? 'Active' : 'Archived', style: TextStyle(color: s.isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      if (s.paymentTerms != null) Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(s.paymentTerms!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text('Rs. ${s.balance}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(LucideIcons.moreHorizontal, size: 20),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showAddSupplierDialog(context, supplier: s);
                                    } else if (value == 'delete') {
                                      _confirmDelete(context, ref, s);
                                    } else if (value == 'history') {
                                      showDialog(
                                        context: context,
                                        builder: (_) => SupplierHistoryDialog(supplier: s),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'history', child: Row(children: [Icon(LucideIcons.history, size: 16), SizedBox(width: 8), Text('View History')])),
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(LucideIcons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(LucideIcons.trash2, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ),
      ],
    );
  }

  void _showAddSupplierDialog(BuildContext context, {Supplier? supplier}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddSupplierModal(supplier: supplier),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete ${supplier.company}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(supplierProvider.notifier).deleteSupplier(supplier.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Supplier deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _FilterBtn({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
