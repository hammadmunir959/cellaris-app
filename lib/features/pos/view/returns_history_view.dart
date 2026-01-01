import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/models/invoice.dart';
import '../../../core/repositories/invoice_repository.dart';

class ReturnsHistoryView extends ConsumerWidget {
  const ReturnsHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Invoice>>(
      future: ref.read(invoiceRepositoryProvider).getAll(type: InvoiceType.saleReturn),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final returns = snapshot.data ?? [];

        if (returns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.history, size: 48, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                const Text('No return history found'),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: returns.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final ret = returns[index];
            return Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.undo2, color: Colors.orange),
                ),
                title: Text(ret.billNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Orig: ${ret.originalBillNo ?? "N/A"} • ${_formatDate(ret.date)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${ret.summary.netValue.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                    Text(ret.partyName, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                onTap: () {
                   showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Return Details: ${ret.billNo}'),
                      content: SizedBox(
                         width: 400,
                         child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text('Original Invoice: ${ret.originalBillNo}', style: const TextStyle(fontWeight: FontWeight.bold)),
                               const SizedBox(height: 4),
                               Text('Date: ${ret.date.toString().split('.')[0]}'),
                               const SizedBox(height: 4),
                               Text('Party: ${ret.partyName}'),
                               if (ret.notes != null && ret.notes!.isNotEmpty) ...[
                                 const SizedBox(height: 4),
                                 Text('Reason: ${ret.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                               ],
                               const Divider(height: 24),
                               const Text('Items Returned:', style: TextStyle(fontWeight: FontWeight.bold)),
                               const SizedBox(height: 8),
                               ...ret.items.map((item) => Padding(
                                 padding: const EdgeInsets.symmetric(vertical: 4),
                                 child: Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Text(item.productName),
                                           Text('Qty: ${item.quantity}', style: Theme.of(context).textTheme.bodySmall),
                                         ],
                                       ),
                                     ),
                                     Text('Rs. ${item.lineTotal.toStringAsFixed(0)}'),
                                   ],
                                 ),
                               )),
                               const Divider(height: 24),
                               Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   const Text('Total Refund:', style: TextStyle(fontWeight: FontWeight.bold)),
                                   Text('Rs. ${ret.summary.netValue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                                 ],
                               )
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
