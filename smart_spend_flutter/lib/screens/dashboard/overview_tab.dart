import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_transaction_dialog.dart';
import '../../widgets/overview_card.dart';
import '../../widgets/transaction_item_tile.dart';

class OverviewTab extends StatelessWidget {
  final VoidCallback onNavigateToTransactions;

  const OverviewTab({
    super.key,
    required this.onNavigateToTransactions,
  });

  List<_MonthlyData> _get6MonthsData(AppProvider provider) {
    final months = <_MonthlyData>[];
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthName = DateFormat('MMM').format(date);

      double income = 0;
      double expense = 0;

      for (final t in provider.transactions) {
        if (t.date.year == date.year && t.date.month == date.month) {
          if (t.isIncome) income += t.amount;
          if (t.isExpense) expense += t.amount.abs();
        }
      }

      months.add(_MonthlyData(month: monthName, income: income, expense: expense));
    }
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final provider = context.watch<AppProvider>();
    final monthlyData = _get6MonthsData(provider);

    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.surface,
      onRefresh: () => provider.fetchData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 4 Overview Cards (2x2 Grid)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                OverviewCard(
                  title: 'Total Balance',
                  amount: AppUtils.formatCurrency(provider.totalBalance),
                  trend: 'Current balance',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: colors.primary,
                  iconBg: colors.primarySoft,
                  positive: provider.totalBalance >= 0,
                ),
                OverviewCard(
                  title: 'Income',
                  amount: AppUtils.formatCurrency(provider.totalIncome),
                  trend: 'Total earned',
                  icon: Icons.arrow_outward_rounded,
                  iconColor: colors.secondary,
                  iconBg: colors.secondarySoft,
                  positive: true,
                ),
                OverviewCard(
                  title: 'Expenses',
                  amount: AppUtils.formatCurrency(provider.totalExpense),
                  trend: 'Total spent',
                  icon: Icons.arrow_downward_rounded,
                  iconColor: colors.danger,
                  iconBg: colors.dangerSoft,
                  positive: false,
                ),
                OverviewCard(
                  title: 'Savings Rate',
                  amount: '${provider.savingsRate}%',
                  trend: 'Of total income',
                  icon: Icons.savings_rounded,
                  iconColor: colors.accent,
                  iconBg: colors.accentSoft,
                  positive: provider.totalBalance > 0,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Spending Overview Bar Chart Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spending Overview',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Income vs Expenses — last 6 months',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      // Legend
                      Row(
                        children: [
                          _buildLegendDot(colors.secondary, 'Income', colors),
                          const SizedBox(width: 12),
                          _buildLegendDot(colors.danger, 'Expenses', colors),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chart Area
                  SizedBox(
                    height: 220,
                    child: provider.transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bar_chart_rounded,
                                    size: 32, color: colors.textMuted),
                                const SizedBox(height: 8),
                                Text(
                                  'Not enough data to generate chart.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => colors.surface2,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final month = monthlyData[groupIndex].month;
                                    final isInc = rodIndex == 0;
                                    return BarTooltipItem(
                                      '$month\n${isInc ? "Income" : "Expense"}: ${AppUtils.formatCurrency(rod.toY)}',
                                      TextStyle(
                                        color: colors.textMain,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= monthlyData.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          monthlyData[idx].month,
                                          style: TextStyle(
                                            color: colors.textMuted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 5000,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: colors.borderSubtle.withValues(alpha: 0.5),
                                  strokeWidth: 1,
                                  dashArray: [4, 4],
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(monthlyData.length, (i) {
                                final d = monthlyData[i];
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: d.income,
                                      color: colors.secondary,
                                      width: 12,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                    BarChartRodData(
                                      toY: d.expense,
                                      color: colors.danger,
                                      width: 12,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recent Transactions Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.borderSubtle, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.textMain,
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const AddTransactionDialog(),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.add_rounded,
                                      size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: onNavigateToTransactions,
                            child: Text(
                              'View all →',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (provider.recentTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No transactions yet. Add your first expense or income!',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.recentTransactions.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: colors.borderSubtle.withValues(alpha: 0.5),
                      ),
                      itemBuilder: (ctx, idx) {
                        return TransactionItemTile(
                          transaction: provider.recentTransactions[idx],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, AppColors colors) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MonthlyData {
  final String month;
  final double income;
  final double expense;

  _MonthlyData({
    required this.month,
    required this.income,
    required this.expense,
  });
}
