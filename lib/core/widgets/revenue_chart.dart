import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/models/invoice.dart';
import 'package:intl/intl.dart';

class RevenueLineChart extends StatelessWidget {
  final List<Invoice> invoices;
  const RevenueLineChart({super.key, required this.invoices});

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Center(child: Text('No sales data available', style: TextStyle(color: Colors.grey)));
    }

    // Group sales by date for the last 7 days
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
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= chartData.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(chartData[value.toInt()].key, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxRevenue / 4,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text('Rs.${(value / 1000).toStringAsFixed(0)}k', style: const TextStyle(color: Colors.grey, fontSize: 10));
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
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor.withOpacity(0.2), AppTheme.primaryColor.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
