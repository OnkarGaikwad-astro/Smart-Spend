import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/utils.dart';
import '../models/debt_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Dialog to add a new person (either lent money to them, or borrowed from them)
class AddPersonDebtDialog extends StatefulWidget {
  final String initialType; // 'LENT' or 'BORROWED'
  final VoidCallback? onComplete;

  const AddPersonDebtDialog({
    super.key,
    this.initialType = 'LENT',
    this.onComplete,
  });

  @override
  State<AddPersonDebtDialog> createState() => _AddPersonDebtDialogState();
}

class _AddPersonDebtDialogState extends State<AddPersonDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  late String _type;
  DateTime _selectedDate = DateTime.now();

  void _dismiss() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _addQuickAmount(double val) {
    HapticFeedback.selectionClick();
    final current = double.tryParse(_amountController.text.trim()) ?? 0.0;
    _amountController.text = (current + val).toStringAsFixed(0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final note = _noteController.text.trim();
    final phone = _phoneController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final provider = context.read<AppProvider>();
    final defaultNote = _type == 'BORROWED' ? 'Borrowed money' : 'Lent money';

    await provider.addDebtPerson(
      personName: name,
      phoneNumber: phone.isEmpty ? null : phone,
      initialAmount: amount,
      note: note.isEmpty ? defaultNote : note,
      date: _selectedDate,
      type: _type,
    );

    if (mounted) {
      _dismiss();
      final msg = _type == 'BORROWED'
          ? 'Recorded: Borrowed ${AppUtils.formatCurrency(amount)} from $name'
          : 'Recorded: Lent ${AppUtils.formatCurrency(amount)} to $name';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isLent = _type == 'LENT';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: colors.borderSubtle == Colors.transparent
              ? null
              : Border.all(color: colors.borderSubtle, width: 1),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isLent
                                ? colors.primarySoft
                                : const Color(0xFFEF5350).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isLent
                                ? Icons.arrow_outward_rounded
                                : Icons.arrow_downward_rounded,
                            color: isLent ? colors.primary : const Color(0xFFEF5350),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isLent ? 'Record Lent Money' : 'Record Borrowed Money',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textMain,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: colors.textMuted),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _dismiss();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Direction Toggle (I Lent / I Borrowed)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surface2,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _type = 'LENT');
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isLent ? colors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 15,
                                  color: isLent ? Colors.white : colors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "I Lent (They owe me)",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isLent ? Colors.white : colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _type = 'BORROWED');
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isLent
                                  ? const Color(0xFFEF5350)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 15,
                                  color: !isLent ? Colors.white : colors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "I Borrowed (I owe them)",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: !isLent ? Colors.white : colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Person Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: colors.textMain),
                  decoration: InputDecoration(
                    labelText: isLent ? "Borrower / Friend's Name *" : "Lender / Person's Name *",
                    hintText: 'e.g. Rahul, Rohit, Sneha, Colleague',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: colors.textMuted),
                    fillColor: colors.surface2,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter their name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                  decoration: InputDecoration(
                    labelText: isLent ? 'Amount Lent (₹) *' : 'Amount Borrowed (₹) *',
                    hintText: '0.00',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        '₹',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    fillColor: colors.surface2,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the amount';
                    }
                    if (double.tryParse(val.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Quick Amount Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [100.0, 200.0, 500.0, 1000.0, 2000.0, 5000.0].map((amt) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text('+₹${amt.toInt()}'),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textMain,
                          ),
                          backgroundColor: colors.surface2,
                          side: colors.borderSubtle == Colors.transparent
                              ? BorderSide.none
                              : BorderSide(color: colors.borderSubtle),
                          onPressed: () => _addQuickAmount(amt),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Note / Reason
                TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: colors.textMain),
                  decoration: InputDecoration(
                    labelText: 'Reason / For what? (optional)',
                    hintText: isLent
                        ? 'e.g. Dinner bill, Movie ticket, Metro pass'
                        : 'e.g. Urgent cash, Concert ticket, EMI help',
                    prefixIcon: Icon(Icons.notes_rounded, color: colors.textMuted),
                    fillColor: colors.surface2,
                  ),
                ),
                const SizedBox(height: 12),

                // Phone (optional)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: colors.textMain),
                  decoration: InputDecoration(
                    labelText: 'Phone Number (optional)',
                    hintText: 'e.g. 9876543210',
                    prefixIcon: Icon(Icons.phone_outlined, color: colors.textMuted),
                    fillColor: colors.surface2,
                  ),
                ),
                const SizedBox(height: 12),

                // Date Picker row
                InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: colors.borderSubtle == Colors.transparent
                          ? null
                          : Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: colors.textMuted),
                        const SizedBox(width: 10),
                        Text(
                          'Date: ${AppUtils.formatDate(_selectedDate)}',
                          style: TextStyle(fontSize: 13, color: colors.textMain),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down_rounded, color: colors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLent ? colors.primary : const Color(0xFFEF5350),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLent ? 'Save Lent Money' : 'Save Borrowed Money',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog to add MORE money when a person borrows or lends again
class AddMoreMoneyDialog extends StatefulWidget {
  final DebtModel debt;

  const AddMoreMoneyDialog({super.key, required this.debt});

  @override
  State<AddMoreMoneyDialog> createState() => _AddMoreMoneyDialogState();
}

class _AddMoreMoneyDialogState extends State<AddMoreMoneyDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addQuickAmount(double val) {
    HapticFeedback.selectionClick();
    final current = double.tryParse(_amountController.text.trim()) ?? 0.0;
    _amountController.text = (current + val).toStringAsFixed(0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final note = _noteController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final provider = context.read<AppProvider>();
    final defaultNote = widget.debt.isBorrowed ? 'Borrowed more' : 'Lent more';

    await provider.addMoreToDebt(
      debtId: widget.debt.id,
      amount: amount,
      note: note.isEmpty ? defaultNote : note,
      date: _selectedDate,
    );

    if (mounted) {
      Navigator.pop(context);
      final newTotal = widget.debt.totalOwed + amount;
      final actionStr = widget.debt.isBorrowed ? 'borrowed from' : 'lent to';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${AppUtils.formatCurrency(amount)} $actionStr ${widget.debt.personName}! Total now: ${AppUtils.formatCurrency(newTotal)}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isLent = widget.debt.isLent;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: colors.borderSubtle == Colors.transparent
              ? null
              : Border.all(color: colors.borderSubtle, width: 1),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isLent
                                ? colors.primarySoft
                                : const Color(0xFFEF5350).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.add_circle_outline_rounded,
                            color: isLent ? colors.primary : const Color(0xFFEF5350),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLent ? 'Lend More Money' : 'Borrow More Money',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textMain,
                              ),
                            ),
                            Text(
                              isLent
                                  ? 'To ${widget.debt.personName}'
                                  : 'From ${widget.debt.personName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                const SizedBox(height: 12),

                // Current Outstanding Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isLent ? 'Currently Owes You:' : 'You Currently Owe:',
                        style: TextStyle(fontSize: 13, color: colors.textMuted),
                      ),
                      Text(
                        AppUtils.formatCurrency(widget.debt.totalOwed),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isLent ? colors.primary : const Color(0xFFEF5350),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // New Amount
                TextFormField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                  decoration: InputDecoration(
                    labelText: isLent ? 'Additional Amount Lent (₹) *' : 'Additional Amount Borrowed (₹) *',
                    hintText: '0.00',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        '₹',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    fillColor: colors.surface2,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the amount';
                    }
                    if (double.tryParse(val.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Quick Amount Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [50.0, 100.0, 200.0, 500.0, 1000.0, 2000.0].map((amt) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text('+₹${amt.toInt()}'),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textMain,
                          ),
                          backgroundColor: colors.surface2,
                          side: colors.borderSubtle == Colors.transparent
                              ? BorderSide.none
                              : BorderSide(color: colors.borderSubtle),
                          onPressed: () => _addQuickAmount(amt),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Note / Reason
                TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: colors.textMain),
                  decoration: InputDecoration(
                    labelText: 'Reason for new borrow (optional)',
                    hintText: isLent ? 'e.g. Cab fare, Food order, Xerox prints' : 'e.g. Extra fuel, Dinner split',
                    prefixIcon: Icon(Icons.notes_rounded, color: colors.textMuted),
                    fillColor: colors.surface2,
                  ),
                ),
                const SizedBox(height: 12),

                // Date
                InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: colors.borderSubtle == Colors.transparent
                          ? null
                          : Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: colors.textMuted),
                        const SizedBox(width: 10),
                        Text(
                          'Date: ${AppUtils.formatDate(_selectedDate)}',
                          style: TextStyle(fontSize: 13, color: colors.textMain),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down_rounded, color: colors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLent ? colors.primary : const Color(0xFFEF5350),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLent ? 'Save Additional Lent Money' : 'Save Additional Borrowed Money',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog to record repayment (either received from a friend, or paid to a lender)
class RecordRepaymentDialog extends StatefulWidget {
  final DebtModel debt;

  const RecordRepaymentDialog({super.key, required this.debt});

  @override
  State<RecordRepaymentDialog> createState() => _RecordRepaymentDialogState();
}

class _RecordRepaymentDialogState extends State<RecordRepaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.debt.totalOwed > 0) {
      _amountController.text = widget.debt.totalOwed.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final note = _noteController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final provider = context.read<AppProvider>();
    final isLent = widget.debt.isLent;
    final defaultNote = isLent ? 'Repayment received' : 'Repayment paid';

    await provider.recordDebtRepayment(
      debtId: widget.debt.id,
      amount: amount,
      note: note.isEmpty ? defaultNote : note,
      date: _selectedDate,
    );

    if (mounted) {
      Navigator.pop(context);
      final remaining = (widget.debt.totalOwed - amount).clamp(0.0, double.infinity);
      final statusStr = remaining <= 0
          ? '🎉 All cleared with ${widget.debt.personName}!'
          : 'Recorded ${AppUtils.formatCurrency(amount)}. Remaining: ${AppUtils.formatCurrency(remaining)}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(statusStr),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isLent = widget.debt.isLent;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: colors.borderSubtle == Colors.transparent
              ? null
              : Border.all(color: colors.borderSubtle, width: 1),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF66BB6A).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFF66BB6A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLent ? 'Record Payment Received' : 'Record Payment Made',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textMain,
                              ),
                            ),
                            Text(
                              isLent
                                  ? 'From ${widget.debt.personName}'
                                  : 'To ${widget.debt.personName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                const SizedBox(height: 12),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                  decoration: InputDecoration(
                    labelText: isLent ? 'Amount Received (₹) *' : 'Amount Paid (₹) *',
                    hintText: '0.00',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        '₹',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    fillColor: colors.surface2,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the amount';
                    }
                    if (double.tryParse(val.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Quick Settle Full Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF66BB6A)),
                    label: Text('Full Amount (${AppUtils.formatCurrency(widget.debt.totalOwed)})'),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textMain,
                    ),
                    backgroundColor: colors.surface2,
                    side: colors.borderSubtle == Colors.transparent
                        ? BorderSide.none
                        : BorderSide(color: colors.borderSubtle),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _amountController.text = widget.debt.totalOwed.toStringAsFixed(0);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Note / Mode
                TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: colors.textMain),
                  decoration: InputDecoration(
                    labelText: 'Payment Note / Mode (optional)',
                    hintText: 'e.g. PhonePe UPI, Cash, GPay, Bank Transfer',
                    prefixIcon: Icon(Icons.payment_rounded, color: colors.textMuted),
                    fillColor: colors.surface2,
                  ),
                ),
                const SizedBox(height: 12),

                // Date
                InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: colors.borderSubtle == Colors.transparent
                          ? null
                          : Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: colors.textMuted),
                        const SizedBox(width: 10),
                        Text(
                          'Date: ${AppUtils.formatDate(_selectedDate)}',
                          style: TextStyle(fontSize: 13, color: colors.textMain),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down_rounded, color: colors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLent ? 'Confirm Payment Received' : 'Confirm Payment Made',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
