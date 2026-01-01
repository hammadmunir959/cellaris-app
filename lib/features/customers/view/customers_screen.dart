import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/shared/controller/shared_controller.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/features/customers/view/add_customer_modal.dart';
import 'package:mbm_app/features/customers/view/customer_history_dialog.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customers = ref.watch(customerProvider);

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
                Text('Customer Directory', style: theme.textTheme.displayMedium?.copyWith(fontSize: 28)),
                const Text('Manage client relationships and wholesale accounts.', style: TextStyle(color: Colors.grey)),
              ],
            ),
            PrimaryButton(
              label: 'Add Customer',
              onPressed: () => _showAddCustomerDialog(context),
              icon: LucideIcons.userPlus,
              width: 180,
            ),
          ],
        ),
        
        const SizedBox(height: 32),

        // Search & Filter (Visual Placeholder)
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Name, Contact or Tax ID...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _FilterBtn(label: 'Wholesale', icon: LucideIcons.briefcase, color: Colors.blue),
          ],
        ),

        const SizedBox(height: 24),

        // Table / Grid
        Expanded(
          child: customers.isEmpty 
          ? const Center(child: Text('No customers found.'))
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
                          Expanded(flex: 3, child: Text('Customer Identification', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Relationship', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Contact Details', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final c = customers[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03)))),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                        child: Text(c.name.isNotEmpty ? c.name[0] : '?', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          if (c.taxId != null) Text(c.taxId!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (c.isWholesale ? Colors.blue : Colors.green).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(c.isWholesale ? LucideIcons.building : LucideIcons.user, size: 10, color: c.isWholesale ? Colors.blue : Colors.green),
                                        const SizedBox(width: 6),
                                        Text(c.isWholesale ? 'Wholesale' : 'Retail', style: TextStyle(color: c.isWholesale ? Colors.blue : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.contact, style: const TextStyle(fontSize: 13)),
                                      if (c.email != null) Text(c.email!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text('Rs. ${c.balance}', style: TextStyle(fontWeight: FontWeight.bold, color: c.balance < 0 ? Colors.red : Colors.green)),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(LucideIcons.moreHorizontal, size: 20),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showAddCustomerDialog(context, customer: c);
                                    } else if (value == 'delete') {
                                      _confirmDelete(context, ref, c);
                                    } else if (value == 'history') {
                                      showDialog(
                                        context: context,
                                        builder: (_) => CustomerHistoryDialog(customer: c),
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

  void _showAddCustomerDialog(BuildContext context, {Customer? customer}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddCustomerModal(customer: customer),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(customerProvider.notifier).deleteCustomer(customer.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer deleted successfully')),
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
