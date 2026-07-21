import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _rangeMonths = 1; // 1 = this month

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - (_rangeMonths - 1), 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final expenseMap = provider.expenseByCategory(start, end);
    final total = expenseMap.values.fold(0.0, (a, b) => a + b);
    final sortedEntries = expenseMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('This Month')),
              ButtonSegment(value: 3, label: Text('3 Months')),
              ButtonSegment(value: 6, label: Text('6 Months')),
            ],
            selected: {_rangeMonths},
            onSelectionChanged: (s) => setState(() => _rangeMonths = s.first),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statColumn('Income', provider.totalIncomeInRange(start, end), AppColors.income, provider.currencySymbol),
                    _statColumn('Expense', provider.totalExpenseInRange(start, end), AppColors.expense, provider.currencySymbol),
                    _statColumn(
                      'Net',
                      provider.totalIncomeInRange(start, end) - provider.totalExpenseInRange(start, end),
                      AppColors.primary,
                      provider.currencySymbol,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Monthly Trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildMonthlyBarChart(context, provider),
          const SizedBox(height: 24),
          Text('Expense Breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (sortedEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('No expenses in this period', style: TextStyle(color: Colors.grey.shade500))),
            )
          else ...[
            _buildPieChart(context, provider, sortedEntries, total),
            const SizedBox(height: 16),
            ...sortedEntries.map((entry) {
              final category = provider.categoryById(entry.key);
              final percent = total == 0 ? 0.0 : (entry.value / total * 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: category?.color ?? Colors.grey, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(category?.name ?? 'Unknown')),
                    Text('${percent.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(width: 10),
                    Text(
                      Formatters.currency(entry.value, provider.currencySymbol),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _statColumn(String label, double value, Color color, String symbol) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(
          Formatters.currencyCompact(value, symbol),
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildMonthlyBarChart(BuildContext context, FinanceProvider provider) {
    final data = provider.monthlyTrend(6);
    final maxVal = data
        .expand((m) => [m['income'] as double, m['expense'] as double])
        .fold(1.0, (a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      Formatters.monthShort(data[idx]['month']),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 4,
                barRods: [
                  BarChartRodData(toY: data[i]['income'], color: AppColors.income, width: 8, borderRadius: BorderRadius.circular(3)),
                  BarChartRodData(toY: data[i]['expense'], color: AppColors.expense, width: 8, borderRadius: BorderRadius.circular(3)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, FinanceProvider provider, List<MapEntry<String, double>> entries, double total) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: entries.map((e) {
            final category = provider.categoryById(e.key);
            final percent = total == 0 ? 0.0 : (e.value / total * 100);
            return PieChartSectionData(
              value: e.value,
              color: category?.color ?? Colors.grey,
              title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
              radius: 55,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }
}
