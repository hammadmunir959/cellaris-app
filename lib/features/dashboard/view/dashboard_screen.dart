import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/core/models/invoice.dart';
import '../controller/dashboard_kpi_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final kpisAsync = ref.watch(dashboardKPIProvider);
    final todayFormatted = ref.watch(todayFormattedProvider);
    final f = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════════════════════════
            // HEADER
            // ═══════════════════════════════════════════════════════════════
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            todayFormatted,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _HeaderButton(
                        icon: LucideIcons.refreshCw,
                        onPressed: () => ref.read(dashboardKPIProvider.notifier).refresh(),
                        tooltip: 'Refresh',
                      ),
                      const SizedBox(width: 12),
                      _GradientButton(
                        label: 'New Sale',
                        icon: LucideIcons.plus,
                        onPressed: () => context.go('/pos'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ═══════════════════════════════════════════════════════════════
            // KPI CONTENT
            // ═══════════════════════════════════════════════════════════════
            kpisAsync.when(
              loading: () => const _LoadingState(),
              error: (e, _) => _ErrorState(error: e.toString()),
              data: (kpis) => _DashboardContent(kpis: kpis, formatter: f),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DASHBOARD CONTENT
// ═══════════════════════════════════════════════════════════════════════════

class _DashboardContent extends StatelessWidget {
  final DashboardKPIs kpis;
  final NumberFormat formatter;

  const _DashboardContent({
    required this.kpis,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Primary KPIs
        _buildKPIRow([
          _KPICardData(
            title: "Today's Revenue",
            value: 'Rs. ${formatter.format(kpis.todaySales)}',
            subtitle: '${kpis.todayQuantity} items sold',
            icon: LucideIcons.dollarSign,
            gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
            index: 0,
          ),
          _KPICardData(
            title: "Today's Profit",
            value: 'Rs. ${formatter.format(kpis.todayProfit)}',
            subtitle: 'Gross margin',
            icon: LucideIcons.trendingUp,
            gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
            index: 1,
          ),
          _KPICardData(
            title: 'Pending Orders',
            value: '${kpis.pendingOrders}',
            subtitle: '${kpis.confirmedOrders} confirmed',
            icon: LucideIcons.clipboardList,
            gradient: const [Color(0xFFF093FB), Color(0xFFF5576C)],
            index: 2,
          ),
          _KPICardData(
            title: 'Active Repairs',
            value: '${kpis.activeRepairs}',
            subtitle: '${kpis.pendingRepairs} pending',
            icon: LucideIcons.wrench,
            gradient: const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
            index: 3,
          ),
        ]),

        const SizedBox(height: 20),

        // Row 2: Financial KPIs
        _buildKPIRow([
          _KPICardData(
            title: 'Cash In-Hand',
            value: 'Rs. ${formatter.format(kpis.inHandBalance)}',
            subtitle: 'Available balance',
            icon: LucideIcons.wallet,
            gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            index: 4,
          ),
          _KPICardData(
            title: 'Receivables',
            value: 'Rs. ${formatter.format(kpis.receivables)}',
            subtitle: 'Due from customers',
            icon: LucideIcons.arrowDownCircle,
            gradient: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
            index: 5,
          ),
          _KPICardData(
            title: 'Payables',
            value: 'Rs. ${formatter.format(kpis.payables)}',
            subtitle: 'Due to suppliers',
            icon: LucideIcons.arrowUpCircle,
            gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
            index: 6,
          ),
          _KPICardData(
            title: 'Stock Value',
            value: 'Rs. ${formatter.format(kpis.stockValue)}',
            subtitle: '${kpis.lowStockCount} low • ${kpis.outOfStockCount} out',
            icon: LucideIcons.package,
            gradient: kpis.outOfStockCount > 0
                ? const [Color(0xFFEF4444), Color(0xFFB91C1C)]
                : const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            index: 7,
          ),
        ]),

        const SizedBox(height: 32),

        // Row 3: Month Summary + Quick Actions
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: _MonthSummaryCard(
                  monthSales: kpis.monthSales,
                  monthProfit: kpis.monthProfit,
                  formatter: formatter,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 450),
                child: const _QuickActionsCard(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Row 4: Chart + Activity
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: _RevenueChartCard(chartData: kpis.chartData),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 550),
                child: _RecentActivityCard(
                  recentSales: kpis.recentSales,
                  formatter: formatter,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPIRow(List<_KPICardData> cards) {
    return Row(
      children: cards.asMap().entries.map((entry) {
        final i = entry.key;
        final card = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 10, right: i == cards.length - 1 ? 0 : 10),
            child: _ModernKPICard(data: card),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KPI CARD
// ═══════════════════════════════════════════════════════════════════════════

class _KPICardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final int index;

  const _KPICardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.index,
  });
}

class _ModernKPICard extends StatefulWidget {
  final _KPICardData data;

  const _ModernKPICard({required this.data});

  @override
  State<_ModernKPICard> createState() => _ModernKPICardState();
}

class _ModernKPICardState extends State<_ModernKPICard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeInUp(
      delay: Duration(milliseconds: widget.data.index * 60),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.08) 
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.data.gradient[0].withOpacity(_isHovered ? 0.25 : 0.1),
                blurRadius: _isHovered ? 30 : 20,
                offset: Offset(0, _isHovered ? 12 : 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with gradient background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.data.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.data.gradient[0].withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.data.icon,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Value
              Text(
                widget.data.value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              // Title
              Text(
                widget.data.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              // Subtitle
              Text(
                widget.data.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MONTH SUMMARY CARD
// ═══════════════════════════════════════════════════════════════════════════

class _MonthSummaryCard extends StatelessWidget {
  final double monthSales;
  final double monthProfit;
  final NumberFormat formatter;

  const _MonthSummaryCard({
    required this.monthSales,
    required this.monthProfit,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monthName = DateFormat('MMMM yyyy').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Month info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(LucideIcons.calendar, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Month to Date Summary',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _SummaryMetric(
                  label: 'Total Sales',
                  value: 'Rs. ${formatter.format(monthSales)}',
                  color: theme.colorScheme.onSurface,
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                ),
                _SummaryMetric(
                  label: 'Gross Profit',
                  value: 'Rs. ${formatter.format(monthProfit)}',
                  color: AppTheme.accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// QUICK ACTIONS CARD
// ═══════════════════════════════════════════════════════════════════════════

class _QuickActionsCard extends ConsumerWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final actions = ref.watch(quickActionsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.zap,
                size: 18,
                color: AppTheme.warningColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: actions.take(6).map((action) => _QuickActionChip(
              label: action.label,
              onTap: () => context.go(action.route),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<_QuickActionChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: _isHovered
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                : null,
            color: _isHovered
                ? null
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? Colors.transparent
                  : AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isHovered
                  ? Colors.white
                  : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REVENUE CHART CARD
// ═══════════════════════════════════════════════════════════════════════════

class _RevenueChartCard extends StatelessWidget {
  final List<Invoice> chartData;

  const _RevenueChartCard({required this.chartData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.lineChart, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Revenue Overview',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.calendar, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Text(
                      'Last 7 Days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 280,
            child: _ModernRevenueChart(invoices: chartData),
          ),
        ],
      ),
    );
  }
}

class _ModernRevenueChart extends StatelessWidget {
  final List<Invoice> invoices;

  const _ModernRevenueChart({required this.invoices});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.barChart3,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No sales data yet',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start making sales to see your revenue chart',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Group sales by date
    final now = DateTime.now();
    final Map<String, double> dailyRevenue = {};
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dailyRevenue[DateFormat('MM/dd').format(date)] = 0.0;
    }

    for (final invoice in invoices) {
      final dateStr = DateFormat('MM/dd').format(invoice.date);
      if (dailyRevenue.containsKey(dateStr)) {
        dailyRevenue[dateStr] = dailyRevenue[dateStr]! + invoice.summary.netValue;
      }
    }

    final chartData = dailyRevenue.entries.toList();
    double maxRevenue = dailyRevenue.values.fold(0.0, (max, v) => v > max ? v : max);
    if (maxRevenue == 0) maxRevenue = 1000;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxRevenue / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= chartData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    chartData[value.toInt()].key,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxRevenue / 4,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                return Text(
                  'Rs.${(value / 1000).toStringAsFixed(0)}k',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: chartData.length.toDouble() - 1,
        minY: 0,
        maxY: maxRevenue * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(chartData.length, (i) => FlSpot(i.toDouble(), chartData[i].value)),
            isCurved: true,
            curveSmoothness: 0.3,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: const Color(0xFF6366F1),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.3),
                  const Color(0xFF6366F1).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: isDark ? const Color(0xFF374151) : Colors.white,
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'Rs. ${NumberFormat('#,###').format(spot.y.toInt())}',
                  TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RECENT ACTIVITY CARD
// ═══════════════════════════════════════════════════════════════════════════

class _RecentActivityCard extends StatelessWidget {
  final List<Invoice> recentSales;
  final NumberFormat formatter;

  const _RecentActivityCard({
    required this.recentSales,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.activity, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recentSales.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.inbox,
                      size: 40,
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentSales.take(5).map((invoice) => _ActivityItem(
              title: 'Sale #${invoice.billNo.split("-").last}',
              subtitle: '${invoice.totalQuantity} items • Rs. ${formatter.format(invoice.summary.netValue)}',
              time: DateFormat('HH:mm').format(invoice.date),
              icon: LucideIcons.shoppingBag,
              gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            )),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final List<Color> gradient;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _HeaderButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _HeaderButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppTheme.primaryColor.withOpacity(0.15)
                  : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _isHovered
                  ? AppTheme.primaryColor
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isHovered
                  ? [const Color(0xFF8B5CF6), const Color(0xFF6366F1)]
                  : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(_isHovered ? 0.5 : 0.3),
                blurRadius: _isHovered ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading dashboard...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: AppTheme.errorColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
