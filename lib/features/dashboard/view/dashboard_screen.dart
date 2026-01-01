import 'package:flutter/material.dart';
import 'package:mbm_app/core/widgets/revenue_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbm_app/features/pos/controller/pos_controller.dart';
import 'package:mbm_app/features/inventory/controller/inventory_controller.dart';
import 'package:mbm_app/features/repairs/controller/repair_controller.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../controller/dashboard_kpi_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final kpisAsync = ref.watch(dashboardKPIProvider);
    final todayFormatted = ref.watch(todayFormattedProvider);
    final f = NumberFormat('#,###');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: theme.textTheme.displayMedium?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todayFormatted,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw),
                    onPressed: () => ref.read(dashboardKPIProvider.notifier).refresh(),
                    tooltip: 'Refresh KPIs',
                  ),
                  const SizedBox(width: 8),
                  PrimaryButton(
                    label: 'Download Report',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report generation started...')),
                      );
                    },
                    icon: LucideIcons.fileText,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // KPI Grid
          kpisAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (kpis) => Column(
              children: [
                // Row 1: Sales & Orders
                Row(
                  children: [
                    Expanded(child: _KPICard(
                      title: "Today's Sales",
                      value: 'Rs. ${f.format(kpis.todaySales)}',
                      subtitle: '${kpis.todayQuantity} items sold',
                      icon: LucideIcons.banknote,
                      color: Colors.green,
                      index: 0,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _KPICard(
                      title: "Today's Profit",
                      value: 'Rs. ${f.format(kpis.todayProfit)}',
                      subtitle: 'Gross margin',
                      icon: LucideIcons.trendingUp,
                      color: Colors.teal,
                      index: 1,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _KPICard(
                      title: 'Pending Orders',
                      value: '${kpis.pendingOrders}',
                      subtitle: '${kpis.confirmedOrders} confirmed',
                      icon: LucideIcons.clipboardList,
                      color: Colors.orange,
                      index: 2,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _KPICard(
                      title: 'Active Repairs',
                      value: '${kpis.activeRepairs}',
                      subtitle: '${kpis.pendingRepairs} pending',
                      icon: LucideIcons.wrench,
                      color: Colors.purple,
                      index: 3,
                    )),
                  ],
                ),

                const SizedBox(height: 16),

                // Row 2: Financial metrics
                Row(
                  children: [
                    Expanded(child: _KPICard(
                      title: 'Cash In-Hand',
                      value: 'Rs. ${f.format(kpis.inHandBalance)}',
                      subtitle: 'Cash + Bank',
                      icon: LucideIcons.wallet,
                      color: Colors.blue,
                      index: 4,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _KPICard(
                      title: 'Receivables',
                      value: 'Rs. ${f.format(kpis.receivables)}',
                      subtitle: 'Due from customers',
                      icon: LucideIcons.arrowDownCircle,
                      color: Colors.amber,
                      index: 5,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _KPICard(
                      title: 'Payables',
                      value: 'Rs. ${f.format(kpis.payables)}',
                      subtitle: 'Due to suppliers',
                      icon: LucideIcons.arrowUpCircle,
                      color: Colors.red,
                      index: 6,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _KPICard(
                      title: 'Stock Value',
                      value: 'Rs. ${f.format(kpis.stockValue)}',
                      subtitle: '${kpis.lowStockCount} low, ${kpis.outOfStockCount} out',
                      icon: LucideIcons.package,
                      color: kpis.outOfStockCount > 0 ? Colors.red : Colors.indigo,
                      index: 7,
                    )),
                  ],
                ),

                const SizedBox(height: 16),

                // Row 3: Month summary
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _MonthSummaryCard(
                        monthSales: kpis.monthSales,
                        monthProfit: kpis.monthProfit,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _QuickActionsCard(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Charts & Activity
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Revenue Overview', style: theme.textTheme.titleLarge),
                                const _DateSelector(),
                              ],
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              height: 250,
                              child: RevenueLineChart(invoices: kpis.chartData),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recent Activity', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 20),
                            if (kpis.recentSales.isEmpty)
                               const Center(child: Padding(
                                 padding: EdgeInsets.all(20.0),
                                 child: Text('No recent sales activity.'),
                               ))
                            else
                              ...kpis.recentSales.take(5).map((invoice) => _ActivityItem(
                                title: 'Sale #${invoice.billNo.split("-").last}',
                                subtitle: '${invoice.totalQuantity} items • Rs. ${f.format(invoice.summary.netValue)}',
                                time: DateFormat('HH:mm').format(invoice.date),
                                icon: LucideIcons.shoppingBag,
                                color: Colors.blue,
                              )),
                          ],
                        ),
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
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int index;

  const _KPICard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: Duration(milliseconds: index * 50),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  final double monthSales;
  final double monthProfit;

  const _MonthSummaryCard({
    required this.monthSales,
    required this.monthProfit,
  });

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###');
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.calendar, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text(
                    'Month to Date Summary',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Sales', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${f.format(monthSales)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gross Profit', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${f.format(monthProfit)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(quickActionsProvider);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.take(4).map((action) => _QuickActionChip(
              label: action.label,
              onTap: () => context.go(action.route),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.calendar, size: 14, color: Colors.grey),
          SizedBox(width: 8),
          Text('Last 7 Days', style: TextStyle(fontSize: 12)),
          SizedBox(width: 8),
          Icon(LucideIcons.chevronDown, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}
