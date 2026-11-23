import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/app_provider.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import 'brain_icon.dart';

class AIAssistantSheet extends StatefulWidget {
  final String? initialPrompt;

  const AIAssistantSheet({super.key, this.initialPrompt});

  @override
  State<AIAssistantSheet> createState() => _AIAssistantSheetState();
}

class _AIAssistantSheetState extends State<AIAssistantSheet> {
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'ai',
      'content':
          'Hi there! I am Aurex, your AI financial assistant. How can I help you manage your money today?',
    }
  ];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    'Who owes me money?',
    'Lent ₹500 to Rahul for lunch',
    'I borrowed ₹1000 from Rohit',
    'How much did I spend this month?',
    'Add expense: ₹250 for Lunch',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialPrompt!);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateTransactionsCsv(List<TransactionModel> txns) {
    if (txns.isEmpty) {
      return 'Date,Title,Category,Type,Amount (INR)\n';
    }
    final sorted = List<TransactionModel>.from(txns)
      ..sort((a, b) => b.date.compareTo(a.date));

    final header = 'Date,Title,Category,Type,Amount (INR)';
    final lines = sorted.map((t) {
      final dateStr =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      final safeTitle = t.title.replaceAll('"', '""');
      final safeCategory = t.category.replaceAll('"', '""');
      final amountFormatted = t.amount.toStringAsFixed(2);
      return '"$dateStr","$safeTitle","$safeCategory","${t.type}",$amountFormatted';
    }).toList();

    return '$header\n${lines.join('\n')}';
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isLoading) return;

    final provider = context.read<AppProvider>();
    _textController.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': query});
      _isLoading = true;
    });
    _scrollToBottom();

    // Generate complete transactions CSV file to send along with prompt
    final csvData = _generateTransactionsCsv(provider.transactions);

    // Prepare financial context for Gemini
    final contextData = {
      'totalBalance': provider.totalBalance,
      'totalIncome': provider.totalIncome,
      'totalExpense': provider.totalExpense,
      'totalLentPending': provider.totalLentPending,
      'totalBorrowedPending': provider.totalBorrowedPending,
      'debts': provider.debts
          .map((d) => {
                'person': d.personName,
                'type': d.type,
                'owed': d.totalOwed,
                'isSettled': d.isSettled,
                'lastNote': d.lastNote,
                'entries': d.entries
                    .map((e) => '${e.type}: ₹${e.amount} (${e.note})')
                    .toList(),
              })
          .toList(),
      'goals': provider.goals
          .map((g) => {
                'name': g.name,
                'target': g.target,
                'saved': g.saved,
              })
          .toList(),
    };

    final history = _messages
        .map((m) => {
              'role': m['role']?.toString() ?? '',
              'content': m['content']?.toString() ?? '',
            })
        .toList();

    final result = await GeminiService().chatWithAurex(
      messages: history,
      context: contextData,
      transactionsCsv: csvData,
    );

    // If Gemini instructed to add any transactions or income, execute them now
    final List<Map<String, dynamic>> addedTxns = [];
    if (result.actions.isNotEmpty) {
      HapticFeedback.mediumImpact();
      for (final act in result.actions) {
        final title = act['title']?.toString().trim() ?? 'Transaction';
        final amt = (act['amount'] is num)
            ? (act['amount'] as num).toDouble()
            : double.tryParse(act['amount']?.toString() ?? '0') ?? 0.0;
        final type = (act['type']?.toString().toUpperCase() == 'INCOME')
            ? 'INCOME'
            : 'EXPENSE';
        final category = act['category']?.toString() ?? 'Other';
        final date =
            DateTime.tryParse(act['date']?.toString() ?? '') ?? DateTime.now();

        if (amt > 0) {
          await provider.addTransaction(
            title: title,
            category: category,
            amount: type == 'EXPENSE' ? -amt.abs() : amt.abs(),
            date: date,
            type: type,
          );
          addedTxns.add({
            'title': title,
            'amount': amt,
            'type': type,
            'category': category,
            'date': date,
          });
        }
      }
    }

    // If Gemini instructed to perform any Debt / Lent actions, execute them now
    final List<Map<String, dynamic>> addedDebts = [];
    if (result.debtActions.isNotEmpty) {
      HapticFeedback.mediumImpact();
      for (final dAct in result.debtActions) {
        final action = dAct['action']?.toString().toUpperCase() ?? 'LEND';
        final person = dAct['person']?.toString().trim() ?? 'Unknown';
        final amt = (dAct['amount'] is num)
            ? (dAct['amount'] as num).toDouble()
            : double.tryParse(dAct['amount']?.toString() ?? '0') ?? 0.0;
        final note = dAct['note']?.toString().trim() ?? '';
        final date =
            DateTime.tryParse(dAct['date']?.toString() ?? '') ?? DateTime.now();

        if (amt > 0 && person.isNotEmpty) {
          final existingIndex = provider.debts.indexWhere(
            (d) => d.personName.toLowerCase() == person.toLowerCase(),
          );

          if (action == 'REPAY') {
            if (existingIndex != -1) {
              await provider.recordDebtRepayment(
                debtId: provider.debts[existingIndex].id,
                amount: amt,
                note: note.isEmpty ? 'Repayment' : note,
                date: date,
              );
            }
          } else if (action == 'BORROW') {
            if (existingIndex != -1 && provider.debts[existingIndex].isBorrowed) {
              await provider.addMoreToDebt(
                debtId: provider.debts[existingIndex].id,
                amount: amt,
                note: note.isEmpty ? 'Borrowed more' : note,
                date: date,
              );
            } else {
              await provider.addDebtPerson(
                personName: person,
                initialAmount: amt,
                note: note.isEmpty ? 'Borrowed money' : note,
                date: date,
                type: 'BORROWED',
              );
            }
          } else if (action == 'ADD_MORE') {
            if (existingIndex != -1) {
              await provider.addMoreToDebt(
                debtId: provider.debts[existingIndex].id,
                amount: amt,
                note: note.isEmpty ? 'Additional' : note,
                date: date,
              );
            } else {
              await provider.addDebtPerson(
                personName: person,
                initialAmount: amt,
                note: note.isEmpty ? 'Lent money' : note,
                date: date,
                type: 'LENT',
              );
            }
          } else {
            // LEND
            if (existingIndex != -1 && provider.debts[existingIndex].isLent) {
              await provider.addMoreToDebt(
                debtId: provider.debts[existingIndex].id,
                amount: amt,
                note: note.isEmpty ? 'Lent more' : note,
                date: date,
              );
            } else {
              await provider.addDebtPerson(
                personName: person,
                initialAmount: amt,
                note: note.isEmpty ? 'Lent money' : note,
                date: date,
                type: 'LENT',
              );
            }
          }

          addedDebts.add({
            'action': action,
            'person': person,
            'amount': amt,
            'note': note,
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'content': result.text,
          if (addedTxns.isNotEmpty) 'actions': addedTxns,
          if (addedDebts.isNotEmpty) 'debtActions': addedDebts,
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final provider = context.watch<AppProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: colors.borderSubtle == Colors.transparent
            ? null
            : Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: BrainIcon(
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aurex AI Assistant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textMain,
                          ),
                        ),
                        Text(
                          'Always here to help you save',
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
          ),
          Divider(
            height: 1,
            color: colors.borderSubtle == Colors.transparent
                ? colors.textMuted.withValues(alpha: 0.08)
                : colors.borderSubtle,
          ),

          // Attached CSV Status Indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file_rounded,
                    size: 13,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'transactions.csv attached (${provider.transactions.length} records)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF66BB6A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'AI Grounded',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Prompt Chips
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickPrompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  label: Text(prompt),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: colors.textMain,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: colors.surface2,
                  side: colors.borderSubtle == Colors.transparent
                      ? BorderSide.none
                      : BorderSide(color: colors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _sendMessage(prompt);
                  },
                );
              },
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: BrainIcon(
                              size: 16,
                              color: colors.primary,
                              strokeWidth: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: colors.surface2,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(colors.primary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Aurex is thinking...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: BrainIcon(
                              size: 16,
                              color: colors.primary,
                              strokeWidth: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isUser ? colors.primary : colors.surface2,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['content'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: isUser ? Colors.white : colors.textMain,
                                ),
                              ),
                              if (msg['actions'] != null &&
                                  (msg['actions'] as List).isNotEmpty) ...[
                                const SizedBox(height: 10),
                                for (final action in (msg['actions'] as List))
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: (action['type'] == 'INCOME'
                                              ? const Color(0xFF66BB6A)
                                              : const Color(0xFFEF5350))
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: (action['type'] == 'INCOME'
                                                ? const Color(0xFF66BB6A)
                                                : const Color(0xFFEF5350))
                                            .withValues(alpha: 0.28),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          action['type'] == 'INCOME'
                                              ? Icons.arrow_downward_rounded
                                              : Icons.arrow_upward_rounded,
                                          size: 15,
                                          color: action['type'] == 'INCOME'
                                              ? const Color(0xFF66BB6A)
                                              : const Color(0xFFEF5350),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${action['title']} • ${action['type'] == 'INCOME' ? '+' : '-'}₹${(action['amount'] as num).toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: colors.textMain,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${action['category']}  •  Recorded',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: colors.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  size: 11,
                                                  color: Color(0xFF66BB6A),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              if (msg['debtActions'] != null &&
                                  (msg['debtActions'] as List).isNotEmpty) ...[
                                const SizedBox(height: 10),
                                for (final dAct in (msg['debtActions'] as List))
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: (dAct['action'] == 'BORROW'
                                              ? const Color(0xFFEF5350)
                                              : colors.primary)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: (dAct['action'] == 'BORROW'
                                                ? const Color(0xFFEF5350)
                                                : colors.primary)
                                            .withValues(alpha: 0.28),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.handshake_rounded,
                                          size: 15,
                                          color: dAct['action'] == 'BORROW'
                                              ? const Color(0xFFEF5350)
                                              : colors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${dAct['action'] == 'BORROW' ? 'Borrowed from' : (dAct['action'] == 'REPAY' ? 'Repayment' : 'Lent to')} ${dAct['person']} • ₹${(dAct['amount'] as num).toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: colors.textMain,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Khata / Debts  •  Recorded',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: colors.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  size: 11,
                                                  color: Color(0xFF66BB6A),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (isUser) const SizedBox(width: 10),
                    ],
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(color: colors.textMain),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: 'Ask about your budget, savings, tips...',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      fillColor: colors.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: colors.borderSubtle == Colors.transparent
                            ? BorderSide.none
                            : BorderSide(color: colors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: colors.borderSubtle == Colors.transparent
                            ? BorderSide.none
                            : BorderSide(color: colors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: colors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _sendMessage(_textController.text);
                  },
                  icon: const Icon(Icons.arrow_upward_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
