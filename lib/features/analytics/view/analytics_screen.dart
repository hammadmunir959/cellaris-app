import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/models/invoice.dart';
import 'package:mbm_app/core/repositories/invoice_repository.dart';
import 'package:mbm_app/core/widgets/revenue_chart.dart';
import 'package:mbm_app/core/widgets/category_pie_chart.dart';
import 'package:mbm_app/features/inventory/controller/inventory_controller.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final products = ref.watch(productProvider);
    
    // Fetch invoices for analytics
    final invoiceRepo = ref.watch(invoiceRepositoryProvider);
    
    return FutureBuilder<List<Invoice>>(
      future: invoiceRepo.getAll(type: InvoiceType.sale),
      builder: (context, snapshot) {
        final invoices = snapshot.data ?? [];
        final totalRevenue = invoices.fold(0.0, (sum, inv) => sum + inv.summary.netValue);
        final totalOrders = invoices.length;
        final avgOrder = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Executive Analytics',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontSize: 32, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Live market data synced',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _DateRangePicker(),
                  ],
                ),

                const SizedBox(height: 40),

                // Metrics Grid
                Row(
                  children: [
                    Expanded(child: _MetricItem(label: 'Net Revenue', value: 'Rs. ${(totalRevenue / 1000).toStringAsFixed(1)}k', growth: '+18.4%', icon: LucideIcons.trendingUp, color: Colors.blue)),
                    const SizedBox(width: 24),
                    Expanded(child: _MetricItem(label: 'Avg Basket', value: 'Rs. ${(avgOrder / 1000).toStringAsFixed(1)}k', growth: '+5.2%', icon: LucideIcons.shoppingBag, color: Colors.purple)),
                    const SizedBox(width: 24),
                    Expanded(child: _MetricItem(label: 'Order Count', value: totalOrders.toString(), growth: '+12.1%', icon: LucideIcons.package, color: Colors.green)),
                    const SizedBox(width: 24),
                    Expanded(child: _MetricItem(label: 'Retention', value: '84%', growth: '+2.4%', icon: LucideIcons.users, color: Colors.orange)),
                  ],
                ),

                const SizedBox(height: 40),

                // Main Visualization Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: FadeInLeft(
                        delay: const Duration(milliseconds: 200),
                        child: GlassCard(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Revenue Velocity', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                      const Text('Daily revenue trends vs baseline', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                  _ChartToggle(),
                                ],
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                height: 300,
                                child: RevenueLineChart(invoices: invoices),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: FadeInRight(
                        delay: const Duration(milliseconds: 300),
                        child: GlassCard(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Inventory Mix', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const Text('Top contributing categories', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 40),
                              SizedBox(
                                height: 250,
                                child: CategoryPieChart(products: products),
                              ),
                              const SizedBox(height: 20),
                              const _CategoryLegend(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // High Performance Products
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: GlassCard(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Top Performer Report', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            TextButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.download, size: 16), label: const Text('Export Details')),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const _TableHeader(),
                        const SizedBox(height: 16),
                        _ProductPerformanceRow(name: 'iPhone 15 Pro Max', sales: '142 Units', revenue: 'Rs. 63.9M', share: '42%', isFirst: true),
                        const Divider(height: 32, color: Colors.white10),
                        _ProductPerformanceRow(name: 'iPhone 14', sales: '85 Units', revenue: 'Rs. 21.2M', share: '18%'),
                        const Divider(height: 32, color: Colors.white10),
                        _ProductPerformanceRow(name: 'Samsung S24 Ultra', sales: '64 Units', revenue: 'Rs. 19.2M', share: '15%'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final String growth;
  final IconData icon;
  final Color color;

  const _MetricItem({
    required this.label, 
    required this.value, 
    required this.growth, 
    required this.icon,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = growth.startsWith('+');
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight, 
                      size: 14, 
                      color: isPositive ? Colors.green : Colors.red
                    ),
                    const SizedBox(width: 4),
                    Text(
                      growth,
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.7,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartToggle extends StatefulWidget {
  @override
  State<_ChartToggle> createState() => _ChartToggleState();
}

class _ChartToggleState extends State<_ChartToggle> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ToggleBtn(label: 'Revenue', isSelected: index == 0, onTap: () => setState(() => index = 0)),
          _ToggleBtn(label: 'Orders', isSelected: index == 1, onTap: () => setState(() => index = 1)),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: const [
          Icon(LucideIcons.calendar, size: 16, color: Colors.grey),
          SizedBox(width: 12),
          Text('Last 30 Days', style: TextStyle(fontSize: 13)),
          SizedBox(width: 12),
          Icon(LucideIcons.chevronDown, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 3, child: Text('PRODUCT NAME', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Center(child: Text('SALES', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)))),
        Expanded(flex: 2, child: Center(child: Text('REVENUE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)))),
        Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('SHARE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)))),
      ],
    );
  }
}

class _ProductPerformanceRow extends StatelessWidget {
  final String name;
  final String sales;
  final String revenue;
  final String share;
  final bool isFirst;

  const _ProductPerformanceRow({
    required this.name, 
    required this.sales, 
    required this.revenue, 
    required this.share,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3, 
            child: Row(
              children: [
                if (isFirst) ...[
                  const Icon(LucideIcons.crown, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                ],
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            )
          ),
          Expanded(flex: 1, child: Center(child: Text(sales, style: const TextStyle(color: Colors.white70)))),
          Expanded(flex: 2, child: Center(child: Text(revenue, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)))),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Text(
                  share, 
                  style: const TextStyle(
                    color: AppTheme.primaryColor, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 12
                  )
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend();

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'label': 'Smartphones', 'color': Colors.blue, 'value': '65%'},
      {'label': 'Accessories', 'color': Colors.purple, 'value': '25%'},
      {'label': 'Services', 'color': Colors.green, 'value': '10%'},
    ];

    return Column(
      children: categories.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: c['color'] as Color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Text(c['label'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(c['value'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      )).toList(),
    );
  }
}
