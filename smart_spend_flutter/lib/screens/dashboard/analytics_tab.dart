import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  String _timeRange = 'this_month'; // 'this_month' | 'last_month'

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> txns) {
    final now = DateTime.now();
    int targetMonth = now.month;
    int targetYear = now.year;

    if (_timeRange == 'last_month') {
      targetMonth = now.month == 1 ? 12 : now.month - 1;
      targetYear = now.month == 1 ? now.year - 1 : now.year;
    }

    return txns
        .where((t) => t.date.month == targetMonth && t.date.year == targetYear)
        .toList();
  }

  Future<void> _exportCSV(List<TransactionModel> txns) async {
    final filtered = _getFilteredTransactions(txns);
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export for this period.')),
      );
      return;
    }

    try {
      final rows = <List<dynamic>>[
        ['Date', 'Title', 'Category', 'Type', 'Amount (INR)'],
        ...filtered.map((t) => [
              AppUtils.formatDateDDMMYYYY(t.date),
              t.title,
              t.category,
              t.type,
              t.amount,
            ]),
      ];

      final csvData = rows.map((row) => row.map((cell) {
        final str = cell.toString().replaceAll('"', '""');
        return '"$str"';
      }).join(',')).join('\n');

      final tempDir = await getTemporaryDirectory();
      final fileName = 'SmartSpend_Analytics_${_timeRange}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvData);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'SmartSpend Analytics Export',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final provider = context.watch<AppProvider>();
    final periodTxns = _getFilteredTransactions(provider.transactions);

    final expenses = periodTxns.where((t) => t.isExpense).toList();
    final totalExpense =
        expenses.fold(0.0, (sum, t) => sum + t.amount.abs());

    // Category Breakdown Map
    final Map<String, double> categoryMap = {};
    for (final e in expenses) {
      categoryMap[e.category] =
          (categoryMap[e.category] ?? 0.0) + e.amount.abs();
    }

    final palette = [
      const Color(0xFFF43F5E),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    // Daily spending map for line chart
    final now = DateTime.now();
    int targetMonth = now.month;
    int targetYear = now.year;
    if (_timeRange == 'last_month') {
      targetMonth = now.month == 1 ? 12 : now.month - 1;
      targetYear = now.month == 1 ? now.year - 1 : now.year;
    }
    final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;

    final List<FlSpot> spots = [];
    final Map<int, double> dailyExpenses = {};
    for (int d = 1; d <= daysInMonth; d++) {
      dailyExpenses[d] = 0.0;
    }
    for (final e in expenses) {
      final day = e.date.day;
      dailyExpenses[day] = (dailyExpenses[day] ?? 0.0) + e.amount.abs();
    }
    for (int d = 1; d <= daysInMonth; d++) {
      spots.add(FlSpot(d.toDouble(), dailyExpenses[d] ?? 0.0));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter & Export Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTimeButton('This Month', 'this_month', colors),
                    _buildTimeButton('Last Month', 'last_month', colors),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _exportCSV(provider.transactions),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.borderSubtle),
                  backgroundColor: colors.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Activity Heatmap Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.borderSubtle, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity Heatmap',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Days you recorded spending activity',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                const SizedBox(height: 16),

                // Heatmap Grid (7 columns for days of week)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemCount: daysInMonth,
                  itemBuilder: (ctx, i) {
                    final day = i + 1;
                    final amt = dailyExpenses[day] ?? 0.0;
                    Color cellColor = colors.surface2;

                    if (amt > 2000) {
                      cellColor = colors.primary;
                    } else if (amt > 800) {
                      cellColor = colors.secondary;
                    } else if (amt > 0) {
                      cellColor = colors.accentSoft;
                    }

                    return Tooltip(
                      message:
                          'Day $day: ${amt > 0 ? AppUtils.formatCurrency(amt) : "No spending"}',
                      child: Container(
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: amt > 800 ? Colors.white : colors.textMuted,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Heatmap Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Less', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                    Row(
                      children: [
                        _buildHeatmapLegendBox(colors.surface2),
                        const SizedBox(width: 4),
                        _buildHeatmapLegendBox(colors.accentSoft),
                        const SizedBox(width: 4),
                        _buildHeatmapLegendBox(colors.secondary),
                        const SizedBox(width: 4),
                        _buildHeatmapLegendBox(colors.primary),
                      ],
                    ),
                    Text('More', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Spending Trend Line Chart Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.borderSubtle, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spending Trend',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total spent: ${AppUtils.formatCurrency(totalExpense)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 200,
                  child: totalExpense <= 0
                      ? Center(
                          child: Text(
                            'Record expenses to see your spending trend.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 2000,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: colors.borderSubtle.withValues(alpha: 0.5),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 5,
                                  getTitlesWidget: (val, _) {
                                    return Text(
                                      '${val.toInt()}d',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colors.textMuted,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => colors.surface2,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      'Day ${spot.x.toInt()}: ${AppUtils.formatCurrency(spot.y)}',
                                      TextStyle(
                                        color: colors.textMain,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: colors.primary,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: colors.primary.withValues(alpha: 0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Category Breakdown Donut Chart Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.borderSubtle, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Breakdown',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Where your money went this period',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                const SizedBox(height: 20),

                if (categoryMap.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        'Record expenses to see category breakdown.',
                        style: TextStyle(fontSize: 12, color: colors.textMuted),
                      ),
                    ),
                  )
                else ...[
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 46,
                        sections: categoryMap.entries.toList().asMap().entries.map((item) {
                          final idx = item.key;
                          final entry = item.value;
                          final pct = totalExpense > 0
                              ? (entry.value / totalExpense) * 100
                              : 0.0;
                          return PieChartSectionData(
                            color: palette[idx % palette.length],
                            value: entry.value,
                            title: '${pct.round()}%',
                            radius: 36,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Legend Pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categoryMap.entries.toList().asMap().entries.map((item) {
                      final idx = item.key;
                      final entry = item.value;
                      final color = palette[idx % palette.length];

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: colors.borderSubtle.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${entry.key}: ${AppUtils.formatCurrency(entry.value)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colors.textMain,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton(String title, String val, AppColors colors) {
    final isSelected = _timeRange == val;
    return GestureDetector(
      onTap: () => setState(() => _timeRange = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? colors.textMain : colors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapLegendBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
