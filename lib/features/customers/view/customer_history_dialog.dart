import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/core/models/invoice.dart';
import 'package:mbm_app/core/repositories/invoice_repository.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/features/repairs/controller/repair_controller.dart';

class CustomerHistoryDialog extends ConsumerStatefulWidget {
  final Customer customer;
  const CustomerHistoryDialog({super.key, required this.customer});

  @override
  ConsumerState<CustomerHistoryDialog> createState() => _CustomerHistoryDialogState();
}

class _CustomerHistoryDialogState extends ConsumerState<CustomerHistoryDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = NumberFormat('#,###');

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        width: 1000,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      radius: 24,
                      child: Text(
                        widget.customer.name.isNotEmpty ? widget.customer.name[0] : '?',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.customer.name, style: theme.textTheme.titleLarge),
                        Text(widget.customer.contact, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.customer.balance < 0 ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Balance: Rs. ${f.format(widget.customer.balance)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.customer.balance < 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Tab Header
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              dividerColor: Colors.white10,
              tabs: const [
                Tab(text: 'Transaction History'),
                Tab(text: 'Repair History'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TransactionsTab(customer: widget.customer),
                  _RepairsTab(customer: widget.customer),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsTab extends ConsumerWidget {
  final Customer customer;
  const _TransactionsTab({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = NumberFormat('#,###');
    return FutureBuilder<List<Invoice>>(
      future: ref.read(invoiceRepositoryProvider).getByParty(customer.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final invoices = snapshot.data ?? [];
        if (invoices.isEmpty) return _emptyState(LucideIcons.inbox, 'No transactions found.');

        return ListView.builder(
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final inv = invoices[index];
            return _itemContainer(
              icon: _getTypeIcon(inv.type),
              color: _getTypeColor(inv.type),
              title: inv.billNo,
              subtitle: '${inv.type.name.toUpperCase()} • ${inv.items.length} items',
              amount: 'Rs. ${f.format(inv.summary.netValue)}',
              date: DateFormat('MMM dd, yyyy').format(inv.date),
            );
          },
        );
      },
    );
  }

  Color _getTypeColor(InvoiceType type) {
    switch (type) {
      case InvoiceType.sale: return Colors.green;
      case InvoiceType.saleReturn: return Colors.orange;
      case InvoiceType.purchase: return Colors.blue;
      case InvoiceType.purchaseReturn: return Colors.red;
    }
  }

  IconData _getTypeIcon(InvoiceType type) {
    switch (type) {
      case InvoiceType.sale: return LucideIcons.shoppingBag;
      case InvoiceType.saleReturn: return LucideIcons.rotateCcw;
      case InvoiceType.purchase: return LucideIcons.package;
      case InvoiceType.purchaseReturn: return LucideIcons.packageX;
    }
  }
}

class _RepairsTab extends ConsumerWidget {
  final Customer customer;
  const _RepairsTab({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(repairProvider).where((t) => t.customerName == customer.name).toList();
    if (tickets.isEmpty) return _emptyState(LucideIcons.wrench, 'No repairs found.');

    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final t = tickets[index];
        return _itemContainer(
          icon: LucideIcons.user,
          color: _getStatusColor(t.status),
          title: t.customerName,
          subtitle: '${t.deviceModel} • ${t.status.name.toUpperCase()}',
          amount: 'Rs. ${t.estimatedCost.toInt()}',
          date: DateFormat('MMM dd, yyyy').format(t.createdAt),
          deviceInfo: t.deviceModel,
          notes: t.notes,
        );
      },
    );
  }

  Color _getStatusColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.received: return Colors.blue;
      case RepairStatus.inRepair: return Colors.orange;
      case RepairStatus.ready: return Colors.green;
      case RepairStatus.delivered: return Colors.grey;
    }
  }
}

Widget _itemContainer({
  required IconData icon,
  required Color color,
  required String title,
  required String subtitle,
  required String amount,
  required String date,
  String? deviceInfo,
  List<String>? notes,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (deviceInfo != null) 
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.smartphone, size: 10, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(deviceInfo, style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 8),
          const Text('Repair Logs:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          ...notes.take(3).map((n) => Text('• $n', style: const TextStyle(fontSize: 10, color: Colors.grey))),
        ],
      ],
    ),
  );
}

Widget _emptyState(IconData icon, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );
}
