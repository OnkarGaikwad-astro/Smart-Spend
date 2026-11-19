import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/budget_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class BudgetDialog extends StatefulWidget {
  final BudgetModel? budgetToEdit;

  const BudgetDialog({super.key, this.budgetToEdit});

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<BudgetDialog> {
  late TextEditingController _categoryController;
  late TextEditingController _allocatedController;
  late String _icon;

  final List<String> _commonEmojis = [
    '🍔', '🚗', '🎵', '🎬', '🛍️', '💡', '📚', '☕', '✈️', '🎮', '🏋️', '🎯'
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.budgetToEdit;
    _categoryController = TextEditingController(text: edit?.category ?? '');
    _allocatedController = TextEditingController(
        text: edit != null ? edit.allocated.toString() : '');
    _icon = edit?.icon ?? '🎯';
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _allocatedController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cat = _categoryController.text.trim();
    final amtText = _allocatedController.text.trim();

    if (cat.isEmpty || amtText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    final double? allocated = double.tryParse(amtText);
    if (allocated == null || allocated <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final provider = context.read<AppProvider>();

    if (widget.budgetToEdit != null) {
      await provider.updateBudget(
        widget.budgetToEdit!.id,
        category: cat,
        allocated: allocated,
        icon: _icon,
      );
    } else {
      await provider.addBudget(
        category: cat,
        allocated: allocated,
        icon: _icon,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: const Text('Are you sure you want to delete this budget category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<AppProvider>();
      await provider.deleteBudget(widget.budgetToEdit!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isEdit = widget.budgetToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: colors.borderSubtle == Colors.transparent
              ? null
              : Border.all(color: colors.borderSubtle, width: 1),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_rounded : Icons.add_rounded,
                            color: colors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit Budget' : 'New Budget Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEdit)
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              color: colors.danger),
                          onPressed: _delete,
                        ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: colors.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category Name
              TextField(
                controller: _categoryController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: colors.textMain),
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Food & Groceries, Transport',
                ),
              ),
              const SizedBox(height: 16),

              // Allocated Amount
              TextField(
                controller: _allocatedController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: colors.textMain,
                ),
                decoration: InputDecoration(
                  labelText: 'Monthly Limit (₹)',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon Emoji Picker
              Text(
                'Choose Icon',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _commonEmojis.map((emoji) {
                  final isSelected = _icon == emoji;
                  return InkWell(
                    onTap: () => setState(() => _icon = emoji),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primarySoft : colors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: colors.primary, width: 2)
                            : (colors.borderSubtle == Colors.transparent
                                ? null
                                : Border.all(color: colors.borderSubtle, width: 1)),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
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
                child: Text(
                  isEdit ? 'Save Budget' : 'Create Budget',
                  style: const TextStyle(
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
