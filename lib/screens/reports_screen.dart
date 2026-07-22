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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - (_rangeMonths - 1), 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final expenseMap = provider.expenseByCategory(start, end);
    final totalExpense = expenseMap.values.fold(0.0, (a, b) => a + b);
    final totalIncome = provider.totalIncomeInRange(start, end);
    final sortedEntries = expenseMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildRangePill('This Month', 1, isDark),
                _buildRangePill('3 Months', 3, isDark),
                _buildRangePill('6 Months', 6, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn('Income', totalIncome, AppColors.income, provider.currencySymbol, isDark),
                Container(width: 1, height: 40, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                _statColumn('Expense', totalExpense, AppColors.expense, provider.currencySymbol, isDark),
                Container(width: 1, height: 40, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                _statColumn('Net Savings', totalIncome - totalExpense, AppColors.primary, provider.currencySymbol, isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Monthly Comparison', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 12),
          _buildMonthlyBarChart(context, provider, isDark),
          const SizedBox(height: 24),
          Text('Expense Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 12),
          if (sortedEntries.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('No expenses recorded for this period', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildPieChart(context, provider, sortedEntries, totalExpense, isDark),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ...sortedEntries.map((entry) {
                    final category = provider.categoryById(entry.key);
                    final percent = totalExpense == 0 ? 0.0 : (entry.value / totalExpense * 100);
                    final color = category?.color ?? Colors.grey;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(category?.icon ?? Icons.category_rounded, color: color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(category?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('${percent.toStringAsFixed(1)}% of total', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.currency(entry.value, provider.currencySymbol),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRangePill(String label, int months, bool isDark) {
    final selected = _rangeMonths == months;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rangeMonths = months),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, double value, Color color, String symbol, bool isDark) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(
          Formatters.currencyCompact(value, symbol),
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildMonthlyBarChart(BuildContext context, FinanceProvider provider, bool isDark) {
    final data = provider.monthlyTrend(6);
    final maxVal = data
        .expand((m) => [m['income'] as double, m['expense'] as double])
        .fold(1.0, (a, b) => a > b ? a : b);

    return Container(
      height: 210,
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.25,
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
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      Formatters.monthShort(data[idx]['month']),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
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
                  BarChartRodData(toY: data[i]['income'], color: AppColors.income, width: 9, borderRadius: BorderRadius.circular(4)),
                  BarChartRodData(toY: data[i]['expense'], color: AppColors.expense, width: 9, borderRadius: BorderRadius.circular(4)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, FinanceProvider provider, List<MapEntry<String, double>> entries, double total, bool isDark) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 55,
              sections: entries.map((e) {
                final category = provider.categoryById(e.key);
                final percent = total == 0 ? 0.0 : (e.value / total * 100);
                return PieChartSectionData(
                  value: e.value,
                  color: category?.color ?? Colors.grey,
                  title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
                  radius: 45,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(
                Formatters.currencyCompact(total, provider.currencySymbol),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

