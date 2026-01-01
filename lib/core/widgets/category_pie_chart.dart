import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mbm_app/core/models/app_models.dart';

class CategoryPieChart extends StatelessWidget {
  final List<Product> products;
  const CategoryPieChart({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('No product data available', style: TextStyle(color: Colors.grey)));
    }

    final Map<String, int> categories = {};
    for (final p in products) {
      categories[p.category] = (categories[p.category] ?? 0) + 1;
    }

    final List<Color> colors = [Colors.blue, Colors.purple, Colors.green, Colors.orange, Colors.red, Colors.teal];

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: categories.entries.toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final category = entry.value.key;
          final count = entry.value.value;
          return PieChartSectionData(
            color: colors[idx % colors.length],
            value: count.toDouble(),
            title: count > 0 ? category : '',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }
}
