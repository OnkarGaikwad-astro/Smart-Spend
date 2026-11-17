import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/transaction_model.dart';
import '../providers/app_provider.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

class AddTransactionDialog extends StatefulWidget {
  final TransactionModel? transactionToEdit;

  const AddTransactionDialog({super.key, this.transactionToEdit});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  late String _type;
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late String _category;
  late DateTime _selectedDate;
  bool _isScanning = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final edit = widget.transactionToEdit;
    _type = edit?.type ?? 'EXPENSE';
    _amountController =
        TextEditingController(text: edit != null ? edit.amount.abs().toString() : '');
    _titleController = TextEditingController(text: edit?.title ?? '');
    _category = edit?.category ?? (_type == 'EXPENSE' ? 'Food' : 'Parents');
    _selectedDate = edit?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  List<String> _getCategories(AppProvider provider) {
    if (_type == 'EXPENSE') {
      final budgetCategories = provider.budgets.map((b) => b.category).toList();
      final set = <String>{
        ...budgetCategories,
        ...AppConstants.defaultExpenseCategories,
      };
      return set.toList();
    } else {
      return AppConstants.defaultIncomeCategories;
    }
  }

  Future<void> _scanReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = AppTheme.of(ctx);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Scan Receipt / Bill with AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.camera_alt_rounded, color: colors.primary),
                  title: Text('Take a Photo', style: TextStyle(color: colors.textMain)),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library_rounded, color: colors.secondary),
                  title: Text('Choose from Gallery', style: TextStyle(color: colors.textMain)),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() => _isScanning = true);

      final Uint8List bytes = await image.readAsBytes();
      final mimeType = image.mimeType ?? 'image/jpeg';

      final results = await GeminiService().extractReceipt(
        imageBytes: bytes,
        mimeType: mimeType,
      );

      if (!mounted) return;

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions detected in receipt.')),
        );
      } else if (results.length == 1) {
        final item = results.first;
        setState(() {
          _type = 'EXPENSE';
          if (item['amount'] != null) {
            _amountController.text = item['amount'].toString();
          }
          if (item['title'] != null) {
            _titleController.text = item['title'].toString();
          }
          if (item['category'] != null) {
            _category = item['category'].toString();
          }
          if (item['date'] != null) {
            _selectedDate =
                DateTime.tryParse(item['date'].toString()) ?? DateTime.now();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt details autofilled!')),
        );
      } else {
        // Multiple transactions found
        final provider = context.read<AppProvider>();
        int count = 0;
        for (final item in results) {
          final amt = (item['amount'] is num)
              ? (item['amount'] as num).toDouble()
              : double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
          if (amt > 0 && item['title'] != null) {
            await provider.addTransaction(
              title: item['title'].toString(),
              category: item['category']?.toString() ?? 'Other',
              amount: -amt,
              date: item['date'] != null
                  ? (DateTime.tryParse(item['date'].toString()) ?? DateTime.now())
                  : DateTime.now(),
              type: 'EXPENSE',
            );
            count++;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added $count transactions from receipt!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse receipt: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final amtText = _amountController.text.trim();
    final title = _titleController.text.trim();

    if (amtText.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    final double? parsed = double.tryParse(amtText);
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final amount = _type == 'EXPENSE' ? -parsed.abs() : parsed.abs();

    if (widget.transactionToEdit != null) {
      await provider.updateTransaction(
        widget.transactionToEdit!.id,
        title: title,
        category: _category,
        amount: amount,
        date: _selectedDate,
        type: _type,
      );
    } else {
      await provider.addTransaction(
        title: title,
        category: _category,
        amount: amount,
        date: _selectedDate,
        type: _type,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('Are you sure you want to delete this transaction?'),
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
      await provider.deleteTransaction(widget.transactionToEdit!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final provider = context.watch<AppProvider>();
    final categories = _getCategories(provider);
    if (!categories.contains(_category)) {
      _category = categories.first;
    }

    final isEdit = widget.transactionToEdit != null;

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
              // Header
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
                            isEdit ? 'Edit Transaction' : 'New Transaction',
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
              const SizedBox(height: 16),

              // AI Receipt Scanner Button
              if (!isEdit)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: _isScanning ? null : _scanReceipt,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_outlined, size: 18),
                    label: Text(_isScanning
                        ? 'Analyzing Receipt with Gemini AI...'
                        : 'Scan Bill / Receipt with AI'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              // Type Switcher (Expense / Income)
              Container(
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _type = 'EXPENSE';
                            _category = 'Food';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _type == 'EXPENSE'
                                ? colors.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _type == 'EXPENSE'
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Expense',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _type == 'EXPENSE'
                                  ? colors.danger
                                  : colors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _type = 'INCOME';
                            _category = 'Parents';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _type == 'INCOME'
                                ? colors.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _type == 'INCOME'
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Income',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _type == 'INCOME'
                                  ? colors.success
                                  : colors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: colors.textMain,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Field
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: colors.textMain),
                decoration: const InputDecoration(
                  labelText: 'Title / Description',
                  hintText: 'e.g., Grocery, Cafe, Allowance',
                ),
              ),
              const SizedBox(height: 14),

              // Category Selector
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                dropdownColor: colors.surface,
                items: categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(
                            cat,
                            style: TextStyle(color: colors.textMain),
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 14),

              // Date & Time Picker Tile
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surface2.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date & Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy, h:mm a')
                                .format(_selectedDate),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textMain,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.calendar_month_rounded, color: colors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
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
                  isEdit ? 'Save Changes' : 'Add Transaction',
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
