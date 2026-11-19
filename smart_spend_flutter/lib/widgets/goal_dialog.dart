import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/goal_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class GoalDialog extends StatefulWidget {
  final GoalModel? goalToEdit;

  const GoalDialog({super.key, this.goalToEdit});

  @override
  State<GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<GoalDialog> {
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late DateTime _targetDate;
  late String _color;

  @override
  void initState() {
    super.initState();
    final edit = widget.goalToEdit;
    _nameController = TextEditingController(text: edit?.name ?? '');
    _targetController = TextEditingController(
        text: edit != null ? edit.target.toString() : '');
    _targetDate = edit != null
        ? (DateTime.tryParse(edit.targetDate) ??
            DateTime.now().add(const Duration(days: 365)))
        : DateTime.now().add(const Duration(days: 365));
    _color = edit?.color ?? 'primary';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (date != null) {
      setState(() => _targetDate = date);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final targetText = _targetController.text.trim();

    if (name.isEmpty || targetText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    final double? target = double.tryParse(targetText);
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target amount.')),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_targetDate);

    if (widget.goalToEdit != null) {
      await provider.updateGoal(
        widget.goalToEdit!.id,
        name: name,
        target: target,
        targetDate: dateStr,
        color: _color,
      );
    } else {
      await provider.addGoal(
        name: name,
        target: target,
        targetDate: dateStr,
        color: _color,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: const Text('Are you sure you want to delete this savings goal?'),
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
      await provider.deleteGoal(widget.goalToEdit!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isEdit = widget.goalToEdit != null;

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
                            color: colors.secondarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.flag_rounded,
                            color: colors.secondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit Savings Goal' : 'New Savings Goal',
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

              // Goal Name
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: colors.textMain),
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  hintText: 'e.g., MacBook M3, Trip to Goa, Emergency Fund',
                ),
              ),
              const SizedBox(height: 16),

              // Target Amount
              TextField(
                controller: _targetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: colors.textMain,
                ),
                decoration: InputDecoration(
                  labelText: 'Target Amount (₹)',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Target Date
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surface2.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: colors.borderSubtle == Colors.transparent
                        ? null
                        : Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMMM yyyy').format(_targetDate),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textMain,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.event_rounded, color: colors.secondary),
                    ],
                  ),
                ),
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
                  isEdit ? 'Save Goal' : 'Create Goal',
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
