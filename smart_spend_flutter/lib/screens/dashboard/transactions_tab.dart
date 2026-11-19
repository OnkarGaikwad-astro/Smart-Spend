import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_transaction_dialog.dart';
import '../../widgets/transaction_item_tile.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All categories';

  DateTime? _exportStartDate;
  DateTime? _exportEndDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getUniqueCategories(List<TransactionModel> txns) {
    final set = {'All categories'};
    for (final t in txns) {
      if (t.category.isNotEmpty) set.add(t.category);
    }
    return set.toList();
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> all) {
    final query = _searchController.text.trim().toLowerCase();
    return all.where((t) {
      final matchesSearch = query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          t.category.toLowerCase().contains(query);
      final matchesCat = _selectedCategory == 'All categories' ||
          t.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCat;
    }).toList();
  }

  Future<void> _exportCSV(List<TransactionModel> txns) async {
    // Show Date Range Dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = AppTheme.of(ctx);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              title: Text('Export Transactions to CSV',
                  style: TextStyle(color: colors.textMain, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Optionally filter by date before exporting:',
                    style: TextStyle(fontSize: 13, color: colors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(_exportStartDate != null
                        ? DateFormat('dd/MM/yyyy').format(_exportStartDate!)
                        : 'Any'),
                    trailing: const Icon(Icons.calendar_today_rounded, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _exportStartDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setModalState(() => _exportStartDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(_exportEndDate != null
                        ? DateFormat('dd/MM/yyyy').format(_exportEndDate!)
                        : 'Any'),
                    trailing: const Icon(Icons.calendar_today_rounded, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _exportEndDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setModalState(() => _exportEndDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _exportStartDate = null;
                    _exportEndDate = null;
                    Navigator.pop(ctx, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    var exportList = txns;
    if (_exportStartDate != null) {
      exportList = exportList.where((t) => t.date.isAfter(_exportStartDate!.subtract(const Duration(seconds: 1)))).toList();
    }
    if (_exportEndDate != null) {
      final end = DateTime(_exportEndDate!.year, _exportEndDate!.month, _exportEndDate!.day, 23, 59, 59);
      exportList = exportList.where((t) => t.date.isBefore(end)).toList();
    }

    if (exportList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions match the selected date range.')),
        );
      }
      return;
    }

    try {
      final rows = <List<dynamic>>[
        ['Date', 'Title', 'Category', 'Type', 'Amount (INR)'],
        ...exportList.map((t) => [
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
      final fileName = 'SmartSpend_Transactions_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvData);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'SmartSpend Transactions Export',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final provider = context.watch<AppProvider>();
    final categories = _getUniqueCategories(provider.transactions);
    final filtered = _filterTransactions(provider.transactions);

    final totalSpent = filtered
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.surface,
      onRefresh: () => provider.fetchData(),
      child: Column(
        children: [
          // Filter & Search Header Card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: colors.surface,
              border: colors.borderSubtle == Colors.transparent
                  ? null
                  : Border(
                      bottom: BorderSide(color: colors.borderSubtle, width: 0.5),
                    ),
            ),
            child: Column(
              children: [
                // Search Bar + Export Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: colors.textMain, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search transactions...',
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 20, color: colors.textMuted),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          fillColor: colors.surface2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.download_rounded),
                      tooltip: 'Export CSV',
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surface2,
                        foregroundColor: colors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: colors.borderSubtle == Colors.transparent
                              ? BorderSide.none
                              : BorderSide(color: colors.borderSubtle),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _exportCSV(filtered);
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'New Transaction',
                      style: IconButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const AddTransactionDialog(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category Chips Scroll
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final cat = categories[i];
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : colors.textMain,
                        ),
                        selectedColor: colors.primary,
                        backgroundColor: colors.surface2,
                        side: BorderSide(
                          color: isSelected
                              ? colors.primary
                              : colors.borderSubtle,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = cat);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Total Spent Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: colors.surface2.withValues(alpha: 0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} transactions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
                Text(
                  'Spent: ${AppUtils.formatCurrency(totalSpent)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: colors.danger,
                  ),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 48, color: colors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions found.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try resetting your search or filter.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  )
                : RepaintBoundary(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: colors.borderSubtle == Colors.transparent
                            ? colors.textMuted.withValues(alpha: 0.08)
                            : colors.borderSubtle.withValues(alpha: 0.5),
                      ),
                      itemBuilder: (ctx, idx) {
                        return TransactionItemTile(
                          transaction: filtered[idx],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
