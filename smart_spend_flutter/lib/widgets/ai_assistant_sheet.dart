import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/transaction_model.dart';
import '../providers/app_provider.dart';
import '../services/gemini_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import 'brain_icon.dart';

class AIAssistantSheet extends StatefulWidget {
  final String? initialPrompt;
  final bool autoListen;

  const AIAssistantSheet({
    super.key,
    this.initialPrompt,
    this.autoListen = false,
  });

  @override
  State<AIAssistantSheet> createState() => _AIAssistantSheetState();
}

class _AIAssistantSheetState extends State<AIAssistantSheet>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'ai',
      'content':
          'Hi there! I am Aurex, your AI financial assistant. Speak or type to add transactions, record debts, or ask anything about your money!',
    }
  ];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Speech-to-text integration with sound-level reactivity
  final SpeechToText _speech = SpeechToText();
  bool _speechInitialized = false;
  bool _isListening = false;
  String _spokenWords = '';
  double _soundLevel = 0.0;
  String? _selectedLocaleId;
  Timer? _finalResultDebounceTimer;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  final List<String> _quickPrompts = [
    '🎙️ Speak to Add Expense',
    'Spent ₹250 on Lunch',
    'Lent ₹500 to Rahul for lunch',
    'Received ₹15000 salary',
    'I borrowed ₹1000 from Rohit',
    'Who owes me money?',
    'How much did I spend this month?',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _initSpeech();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialPrompt!);
      });
    } else if (widget.autoListen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted && !_isListening) {
            _startListening();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _finalResultDebounceTimer?.cancel();
    TtsService().stop();
    _speech.stop();
    _pulseController.dispose();
    _waveController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _detectPreferredLocale() async {
    try {
      final locales = await _speech.locales();
      for (final loc in locales) {
        final id = loc.localeId.toLowerCase().replaceAll('_', '-');
        if (id == 'en-in') {
          _selectedLocaleId = loc.localeId;
          return;
        }
      }
      final sys = await _speech.systemLocale();
      if (sys != null && sys.localeId.toLowerCase().startsWith('en')) {
        _selectedLocaleId = sys.localeId;
        return;
      }
      for (final loc in locales) {
        if (loc.localeId.toLowerCase().startsWith('en')) {
          _selectedLocaleId = loc.localeId;
          return;
        }
      }
      _selectedLocaleId = 'en_IN';
    } catch (e) {
      debugPrint('[SpeechToText] Detect locale error: $e');
      _selectedLocaleId = 'en_IN';
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechInitialized = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      if (_speechInitialized) {
        await _detectPreferredLocale();
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[SpeechToText] Init exception: $e');
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening(autoSubmit: true);
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    HapticFeedback.mediumImpact();

    // 1. Explicitly request runtime microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Microphone permission is required to speak transactions. Tap Settings to allow.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!_speechInitialized) {
      try {
        _speechInitialized = await _speech.initialize(
          onStatus: _onSpeechStatus,
          onError: _onSpeechError,
        );
      } catch (e) {
        debugPrint('[SpeechToText] Re-init failed: $e');
      }
    }

    if (!_speechInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Microphone permission is required to speak transactions. Please enable it in Settings.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    _spokenWords = '';
    _soundLevel = 0.0;
    setState(() {
      _isListening = true;
    });
    _pulseController.repeat(reverse: true);
    _waveController.repeat();

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        onSoundLevelChange: _onSoundLevelChange,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.deviceDefault,
          cancelOnError: false,
          partialResults: true,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          autoPunctuation: true,
          enableHapticFeedback: true,
          localeId: _selectedLocaleId,
        ),
      );
    } catch (e) {
      debugPrint('[SpeechToText] Listen error: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
          _soundLevel = 0.0;
        });
        _pulseController.stop();
        _waveController.stop();
      }
    }
  }

  Future<void> _stopListening({bool autoSubmit = true}) async {
    _finalResultDebounceTimer?.cancel();
    _finalResultDebounceTimer = null;

    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('[SpeechToText] Stop error: $e');
    }

    if (mounted) {
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
      _pulseController.stop();
      _pulseController.reset();
      _waveController.stop();
      _waveController.reset();
    }

    final textToSend = _textController.text.trim();
    if (autoSubmit && textToSend.isNotEmpty) {
      HapticFeedback.lightImpact();
      _sendMessage(textToSend);
    }
  }

  void _onSoundLevelChange(double level) {
    if (!mounted || !_isListening) return;
    // Map Android/iOS sound level (typically -2 to 10+ dB) into 0.0 .. 1.0 range
    final normalized = ((level + 2.0) / 10.0).clamp(0.0, 1.0);
    setState(() {
      // Smooth interpolation for fluid wavy reactivity
      _soundLevel = (_soundLevel * 0.25) + (normalized * 0.75);
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    final words = result.recognizedWords.trim();
    if (words.isNotEmpty) {
      setState(() {
        _spokenWords = words;
        _textController.text = _spokenWords;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      });
    }

    if (result.finalResult && words.isNotEmpty) {
      _finalResultDebounceTimer?.cancel();
      _finalResultDebounceTimer = Timer(const Duration(milliseconds: 450), () {
        if (mounted && _isListening) {
          _stopListening(autoSubmit: true);
        }
      });
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint('[SpeechToText] Status: $status');
    if (!mounted) return;

    if (status == 'listening') {
      if (!_isListening) {
        setState(() => _isListening = true);
      }
    } else if (status == 'notListening') {
      // Do NOT stop speech immediately! Engine is finalizing transcription.
      if (_isListening) {
        _finalResultDebounceTimer?.cancel();
        _finalResultDebounceTimer = Timer(const Duration(milliseconds: 1600), () {
          if (mounted && _isListening) {
            _stopListening(autoSubmit: true);
          }
        });
      }
    } else if (status == 'done') {
      _finalResultDebounceTimer?.cancel();
      if (_isListening) {
        _stopListening(autoSubmit: true);
      }
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    debugPrint('[SpeechToText] Error: ${error.errorMsg}');
    if (mounted && _isListening) {
      _stopListening(autoSubmit: false);
    }
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

      // If the user's message was spoken or contains voice action, speak reply
      if (_spokenWords.isNotEmpty) {
        TtsService().speak(result.text);
      }
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
                    if (prompt.contains('Speak')) {
                      _toggleListening();
                    } else {
                      _sendMessage(prompt);
                    }
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      msg['content'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                        color: isUser ? Colors.white : colors.textMain,
                                      ),
                                    ),
                                  ),
                                  if (!isUser &&
                                      (msg['content'] ?? '').toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          TtsService().speak(msg['content'] ?? '');
                                        },
                                        child: Icon(
                                          Icons.volume_up_rounded,
                                          size: 16,
                                          color:
                                              colors.textMuted.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                ],
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

          // Live Voice Listening Banner with Equalizer Bars
          if (_isListening)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF5350).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEF5350).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    // Dynamic 5-bar sound equalizer reacting to voice volume
                    AnimatedBuilder(
                      animation: Listenable.merge([_waveController, _pulseController]),
                      builder: (context, child) {
                        return SoundBarsVisualizer(
                          soundLevel: _soundLevel,
                          pulseValue: _pulseController.value,
                          barColor: const Color(0xFFEF5350),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _spokenWords.isEmpty
                            ? 'Listening... Speak e.g., "Spent ₹250 on Lunch"'
                            : _spokenWords,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textMain,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _stopListening(autoSubmit: true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF5350),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded,
                                size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Input Bar
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 4,
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
                      hintText: _isListening
                          ? 'Listening to you speak...'
                          : 'Ask Aurex or speak a transaction...',
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
                // Voice Recognition Mic Button with Sound-Reactive Wavy Ripples
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (_isListening)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: VoiceWaveRipplesPainter(
                                waveAnimation: _waveController.value,
                                soundLevel: _soundLevel,
                                baseColor: const Color(0xFFEF5350),
                              ),
                            );
                          },
                        ),
                      ),
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final bounceScale = _isListening
                            ? (1.0 + (0.12 * _soundLevel)).clamp(1.0, 1.15)
                            : 1.0;
                        return Transform.scale(
                          scale: bounceScale,
                          child: IconButton.filled(
                            onPressed: _isLoading ? null : _toggleListening,
                            icon: Icon(
                              _isListening
                                  ? Icons.graphic_eq_rounded
                                  : Icons.mic_rounded,
                              size: 22,
                            ),
                            tooltip: _isListening
                                ? 'Stop & send transaction'
                                : 'Speak to add transaction',
                            style: IconButton.styleFrom(
                              backgroundColor: _isListening
                                  ? const Color(0xFFEF5350)
                                  : colors.surface2,
                              foregroundColor: _isListening
                                  ? Colors.white
                                  : colors.primary,
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(12),
                              side: _isListening
                                  ? null
                                  : (colors.borderSubtle == Colors.transparent
                                      ? null
                                      : BorderSide(color: colors.borderSubtle)),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Send Button
                IconButton.filled(
                  onPressed: _isLoading
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          if (_isListening) {
                            _stopListening(autoSubmit: true);
                          } else {
                            _sendMessage(_textController.text);
                          }
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

/// Outward-propagating fluid wavy ripples that react in real-time to speech volume
class VoiceWaveRipplesPainter extends CustomPainter {
  final double waveAnimation;
  final double soundLevel;
  final Color baseColor;

  VoiceWaveRipplesPainter({
    required this.waveAnimation,
    required this.soundLevel,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    // 1. Fluid Sound-Reactive Radial Glow Fill
    final glowRadius = baseRadius + 14 + (24 * soundLevel);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: (0.16 + 0.35 * soundLevel).clamp(0.0, 0.6)),
          baseColor.withValues(alpha: (0.05 + 0.15 * soundLevel).clamp(0.0, 0.3)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    // 2. Three Outward-Propagating Wavy Ripple Rings
    for (int i = 0; i < 3; i++) {
      final phase = (waveAnimation + (i * 0.33)) % 1.0;
      final waveRadius = baseRadius + (phase * (14.0 + 22.0 * soundLevel));
      final opacity =
          ((1.0 - phase) * (0.35 + 0.65 * soundLevel)).clamp(0.0, 1.0);
      final strokeWidth =
          (1.5 + (2.0 * soundLevel) * (1.0 - phase)).clamp(1.0, 4.0);

      final ringPaint = Paint()
        ..color = baseColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawCircle(center, waveRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant VoiceWaveRipplesPainter oldDelegate) {
    return oldDelegate.waveAnimation != waveAnimation ||
        oldDelegate.soundLevel != soundLevel ||
        oldDelegate.baseColor != baseColor;
  }
}

/// 5 vertical equalizer bars dancing to speech volume
class SoundBarsVisualizer extends StatelessWidget {
  final double soundLevel;
  final double pulseValue;
  final Color barColor;

  const SoundBarsVisualizer({
    super.key,
    required this.soundLevel,
    required this.pulseValue,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final barMultipliers = [0.45, 0.75, 1.0, 0.75, 0.45];
    final barBases = [5.0, 7.0, 9.0, 7.0, 5.0];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(5, (index) {
        final height = barBases[index] +
            (18.0 * soundLevel * barMultipliers[index]) +
            (4.0 * pulseValue * barMultipliers[index]);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 3.2,
          height: height.clamp(4.0, 26.0),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
