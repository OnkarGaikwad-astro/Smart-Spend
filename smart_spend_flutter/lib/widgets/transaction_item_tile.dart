import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/utils.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import 'add_transaction_dialog.dart';

class TransactionItemTile extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionItemTile({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isIncome = transaction.isIncome;
    final emoji = AppUtils.getCategoryIcon(
      transaction.category,
      type: transaction.type,
    );
    final formattedAmount =
        '${isIncome ? '+' : '−'}${AppUtils.formatCurrency(transaction.amount.abs())}';

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => AddTransactionDialog(
            transactionToEdit: transaction,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: colors.borderSubtle == Colors.transparent
                    ? null
                    : Border.all(
                        color: colors.borderSubtle.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
              ),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.category} • ${AppUtils.formatDateReadable(transaction.date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formattedAmount,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isIncome ? colors.success : colors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
