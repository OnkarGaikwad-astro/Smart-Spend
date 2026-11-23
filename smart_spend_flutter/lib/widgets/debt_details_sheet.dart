import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/utils.dart';
import '../models/debt_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'debt_dialogs.dart';

class DebtDetailsSheet extends StatelessWidget {
  final String debtId;

  const DebtDetailsSheet({super.key, required this.debtId});

  void _copyReminder(BuildContext context, DebtModel debt) {
    HapticFeedback.mediumImpact();
    final message = debt.isLent
        ? 'Hey ${debt.personName}, friendly reminder that ${AppUtils.formatCurrency(debt.totalOwed)} is pending for ${debt.lastNote}. Thanks!'
        : 'Hey ${debt.personName}, just checking in regarding the ${AppUtils.formatCurrency(debt.totalOwed)} I borrowed for ${debt.lastNote}. I will repay you soon!';
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied friendly reminder to clipboard! 📋'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete(BuildContext context, DebtModel debt) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record?'),
        content: Text(
          'Are you sure you want to delete ${debt.personName}\'s record and all borrowing history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // close sheet
              context.read<AppProvider>().deleteDebt(debt.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final provider = context.watch<AppProvider>();
    final debt = provider.debts.firstWhere(
      (d) => d.id == debtId,
      orElse: () => DebtModel(
        id: '',
        personName: 'Not Found',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (debt.id.isEmpty) {
      return const SizedBox.shrink();
    }

    final isSettled = debt.isSettled;
    final isLent = debt.isLent;
    final sortedEntries = List<DebtEntry>.from(debt.entries)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: colors.borderSubtle == Colors.transparent
            ? null
            : Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isLent
                          ? colors.primarySoft
                          : const Color(0xFFEF5350).withValues(alpha: 0.12),
                      child: Text(
                        debt.personName.isNotEmpty
                            ? debt.personName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isLent ? colors.primary : const Color(0xFFEF5350),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              debt.personName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: colors.textMain,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLent
                                    ? colors.primarySoft
                                    : const Color(0xFFEF5350).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isLent ? "You'll Get" : "You'll Give",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isLent ? colors.primary : const Color(0xFFEF5350),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (debt.phoneNumber != null && debt.phoneNumber!.isNotEmpty)
                          Text(
                            debt.phoneNumber!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          )
                        else
                          Text(
                            '${debt.entries.length} entries recorded',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (!isSettled)
                      IconButton(
                        tooltip: 'Copy Reminder Text',
                        icon: Icon(Icons.share_outlined, size: 20, color: colors.textMuted),
                        onPressed: () => _copyReminder(context, debt),
                      ),
                    IconButton(
                      tooltip: 'Delete Record',
                      icon: Icon(Icons.delete_outline_rounded, size: 20, color: colors.textMuted),
                      onPressed: () => _confirmDelete(context, debt),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: colors.textMuted),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colors.borderSubtle == Colors.transparent
                ? colors.textMuted.withValues(alpha: 0.08)
                : colors.borderSubtle,
          ),

          // Total Balance Hero Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSettled
                    ? const Color(0xFF66BB6A).withValues(alpha: 0.08)
                    : (isLent
                        ? colors.primary.withValues(alpha: 0.08)
                        : const Color(0xFFEF5350).withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSettled
                      ? const Color(0xFF66BB6A).withValues(alpha: 0.25)
                      : (isLent
                          ? colors.primary.withValues(alpha: 0.25)
                          : const Color(0xFFEF5350).withValues(alpha: 0.25)),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSettled
                          ? const Color(0xFF66BB6A).withValues(alpha: 0.16)
                          : (isLent
                              ? colors.primarySoft
                              : const Color(0xFFEF5350).withValues(alpha: 0.16)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSettled
                          ? Icons.check_circle_rounded
                          : (isLent
                              ? Icons.arrow_outward_rounded
                              : Icons.arrow_downward_rounded),
                      color: isSettled
                          ? const Color(0xFF66BB6A)
                          : (isLent ? colors.primary : const Color(0xFFEF5350)),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSettled
                              ? 'Balance Settled'
                              : (isLent
                                  ? 'Total Pending to Collect'
                                  : 'Total You Currently Owe'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSettled
                              ? 'All Cleared'
                              : AppUtils.formatCurrency(debt.totalOwed),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isSettled
                                ? const Color(0xFF66BB6A)
                                : (isLent ? colors.primary : const Color(0xFFEF5350)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isLent
                            ? 'Lent: ${AppUtils.formatCurrency(debt.totalPrincipal)}'
                            : 'Borrowed: ${AppUtils.formatCurrency(debt.totalPrincipal)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Repaid: ${AppUtils.formatCurrency(debt.totalRepaid)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF66BB6A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons: "+ Lend/Borrow More" & "✓ Repaid"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(isLent ? 'Lend More' : 'Borrow More'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLent ? colors.primary : const Color(0xFFEF5350),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AddMoreMoneyDialog(debt: debt),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(isLent ? 'Repaid' : 'Pay Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF66BB6A),
                      side: const BorderSide(color: Color(0xFF66BB6A), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSettled
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => RecordRepaymentDialog(debt: debt),
                            );
                          },
                  ),
                ),
              ],
            ),
          ),

          // History Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                ),
                Text(
                  '${sortedEntries.length} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Entries List
          Expanded(
            child: sortedEntries.isEmpty
                ? Center(
                    child: Text(
                      'No transactions yet.',
                      style: TextStyle(color: colors.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: sortedEntries.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = sortedEntries[index];
                      final isPrincipal =
                          entry.type == 'LENT' || entry.type == 'BORROWED';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: colors.borderSubtle == Colors.transparent
                              ? null
                              : Border.all(color: colors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isPrincipal
                                        ? (isLent ? colors.primary : const Color(0xFFEF5350))
                                        : const Color(0xFF66BB6A))
                                    .withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPrincipal
                                    ? (isLent ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded)
                                    : Icons.check_rounded,
                                size: 16,
                                color: isPrincipal
                                    ? (isLent ? colors.primary : const Color(0xFFEF5350))
                                    : const Color(0xFF66BB6A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.note.isEmpty
                                        ? (isPrincipal
                                            ? (isLent ? 'Lent' : 'Borrowed')
                                            : 'Repayment')
                                        : entry.note,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppUtils.formatDate(entry.date),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isPrincipal ? '+' : '-'}${AppUtils.formatCurrency(entry.amount)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isPrincipal
                                    ? (isLent ? colors.primary : const Color(0xFFEF5350))
                                    : const Color(0xFF66BB6A),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
