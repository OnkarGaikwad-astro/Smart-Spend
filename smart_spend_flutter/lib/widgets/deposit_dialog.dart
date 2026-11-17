import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils.dart';
import '../models/goal_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class DepositDialog extends StatefulWidget {
  final GoalModel goal;

  const DepositDialog({super.key, required this.goal});

  @override
  State<DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addAmount(double add) {
    final current = double.tryParse(_amountController.text.trim()) ?? 0.0;
    _amountController.text = (current + add).toStringAsFixed(0);
  }

  Future<void> _submit() async {
    final amtText = _amountController.text.trim();
    final double? amount = double.tryParse(amtText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid deposit amount.')),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    await provider.depositToGoal(widget.goal.id, amount);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deposited ${AppUtils.formatCurrency(amount)} into ${widget.goal.name}!',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final remaining = (widget.goal.target - widget.goal.saved).clamp(0, double.infinity);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: colors.borderSubtle, width: 1),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.secondarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.savings_rounded,
                          color: colors.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deposit to Savings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textMain,
                            ),
                          ),
                          Text(
                            widget.goal.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface2.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Saved', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          AppUtils.formatCurrency(widget.goal.saved),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: colors.textMain,
                          ),
                        ),
                      ],
                    ),
                    Container(height: 24, width: 1, color: colors.borderSubtle),
                    Column(
                      children: [
                        Text('Target', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          AppUtils.formatCurrency(widget.goal.target),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: colors.textMain,
                          ),
                        ),
                      ],
                    ),
                    Container(height: 24, width: 1, color: colors.borderSubtle),
                    Column(
                      children: [
                        Text('Remaining', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          AppUtils.formatCurrency(remaining),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: colors.textMain,
                ),
                decoration: InputDecoration(
                  labelText: 'Deposit Amount (₹)',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quick Amount Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [100.0, 500.0, 1000.0, 2000.0].map((amt) {
                  return ActionChip(
                    label: Text('+₹${amt.toInt()}'),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textMain,
                    ),
                    backgroundColor: colors.surface2,
                    side: BorderSide(color: colors.borderSubtle),
                    onPressed: () => _addAmount(amt),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Confirm Deposit',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
