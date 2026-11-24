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

/// Compact, voice-first dialog for quick transaction speaking.
/// Shows what was spoken, the AI reply, and the recorded receipt badge.
class VoiceAssistantDialog extends StatefulWidget {
  final VoidCallback? onDismiss;
  const VoiceAssistantDialog({super.key, this.onDismiss});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => const VoiceAssistantDialog(),
    );
  }

  @override
  State<VoiceAssistantDialog> createState() => _VoiceAssistantDialogState();
}

class _VoiceAssistantDialogState extends State<VoiceAssistantDialog>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _speechInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _permissionDenied = false;
  String? _selectedLocaleId;
  Timer? _finalResultDebounceTimer;

  String _spokenText = '';
  String? _aiResponse;
  List<Map<String, dynamic>> _addedTxns = [];
  List<Map<String, dynamic>> _addedDebts = [];
  final ValueNotifier<double> _soundLevelNotifier = ValueNotifier<double>(0.0);

  late AnimationController _waveController;
  late AnimationController _pulseController;

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

    // Auto-start listening after smooth sheet slide
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _startListeningFlow();
        }
      });
    });
  }

  @override
  void dispose() {
    _finalResultDebounceTimer?.cancel();
    TtsService().stop();
    _speech.stop();
    _pulseController.dispose();
    _waveController.dispose();
    _soundLevelNotifier.dispose();
    super.dispose();
  }

  void _dismissDialog() {
    TtsService().stop();
    HapticFeedback.lightImpact();
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _detectPreferredLocale() async {
    try {
      final locales = await _speech.locales();
      debugPrint('[VoiceDialog] Found ${locales.length} available locales');
      // Priority 1: Indian English (en_IN or en-IN)
      for (final loc in locales) {
        final id = loc.localeId.toLowerCase().replaceAll('_', '-');
        if (id == 'en-in') {
          _selectedLocaleId = loc.localeId;
          debugPrint('[VoiceDialog] Selected Indian English locale: $_selectedLocaleId');
          return;
        }
      }
      // Priority 2: System locale if English
      final sys = await _speech.systemLocale();
      if (sys != null && sys.localeId.toLowerCase().startsWith('en')) {
        _selectedLocaleId = sys.localeId;
        debugPrint('[VoiceDialog] Selected system English locale: $_selectedLocaleId');
        return;
      }
      // Priority 3: Any English locale available
      for (final loc in locales) {
        if (loc.localeId.toLowerCase().startsWith('en')) {
          _selectedLocaleId = loc.localeId;
          debugPrint('[VoiceDialog] Fallback English locale: $_selectedLocaleId');
          return;
        }
      }
      _selectedLocaleId = 'en_IN';
    } catch (e) {
      debugPrint('[VoiceDialog] Error detecting locale: $e');
      _selectedLocaleId = 'en_IN';
    }
  }

  Future<void> _startListeningFlow() async {
    _finalResultDebounceTimer?.cancel();
    TtsService().stop();
    // 1. Explicitly request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isListening = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _permissionDenied = false;
      });
    }

    // 2. Initialize SpeechToText if not already ready
    if (!_speechInitialized) {
      try {
        _speechInitialized = await _speech.initialize(
          onStatus: _onSpeechStatus,
          onError: _onSpeechError,
        );
        if (_speechInitialized) {
          await _detectPreferredLocale();
        }
      } catch (e) {
        debugPrint('[VoiceDialog] Speech init failed: $e');
      }
    } else if (_selectedLocaleId == null) {
      await _detectPreferredLocale();
    }

    if (!_speechInitialized) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isListening = false;
        });
      }
      return;
    }

    // 3. Begin listening with volume reactivity and Indian English acoustic model
    _spokenText = '';
    _soundLevelNotifier.value = 0.0;
    _aiResponse = null;
    _addedTxns = [];
    _addedDebts = [];

    setState(() {
      _isListening = true;
      _isProcessing = false;
    });

    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    HapticFeedback.mediumImpact();

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
      debugPrint('[VoiceDialog] listen error: $e');
      if (mounted) {
        setState(() => _isListening = false);
        _pulseController.stop();
        _waveController.stop();
      }
    }
  }

  Future<void> _stopListeningAndProcess() async {
    _finalResultDebounceTimer?.cancel();
    _finalResultDebounceTimer = null;

    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('[VoiceDialog] Stop error: $e');
    }

    _pulseController.stop();
    _pulseController.reset();
    _waveController.stop();
    _waveController.reset();

    if (mounted) {
      setState(() {
        _isListening = false;
      });
      _soundLevelNotifier.value = 0.0;
    }

    final query = _spokenText.trim();
    if (query.isNotEmpty) {
      _processVoiceQuery(query);
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    final recognized = result.recognizedWords.trim();
    if (recognized.isNotEmpty) {
      setState(() {
        _spokenText = recognized;
      });
    }

    if (result.finalResult && recognized.isNotEmpty) {
      debugPrint('[VoiceDialog] finalResult: "$recognized"');
      // Google Speech engine finalized utterance. Debounce by 450ms so natural brief pauses don't cut off words.
      _finalResultDebounceTimer?.cancel();
      _finalResultDebounceTimer = Timer(const Duration(milliseconds: 450), () {
        if (mounted && _isListening) {
          _stopListeningAndProcess();
        }
      });
    }
  }

  void _onSoundLevelChange(double level) {
    if (!mounted || !_isListening) return;
    final normalized = ((level + 2.0) / 10.0).clamp(0.0, 1.0);
    // Smoothly update notifier only - ZERO dialog rebuilding or layout shaking!
    _soundLevelNotifier.value =
        (_soundLevelNotifier.value * 0.25) + (normalized * 0.75);
  }

  void _onSpeechStatus(String status) {
    debugPrint('[VoiceDialog] Status: $status');
    if (!mounted) return;

    if (status == 'listening') {
      if (!_isListening) {
        setState(() => _isListening = true);
      }
    } else if (status == 'notListening') {
      // Microphone stopped capturing input, but Google server is actively computing
      // the final high-confidence transcription! DO NOT call _speech.stop() here as
      // that cancels the server before onResults(finalResult: true) arrives!
      if (_isListening) {
        _finalResultDebounceTimer?.cancel();
        _finalResultDebounceTimer = Timer(const Duration(milliseconds: 1600), () {
          if (mounted && _isListening) {
            debugPrint('[VoiceDialog] Fallback finalize after notListening');
            _stopListeningAndProcess();
          }
        });
      }
    } else if (status == 'done') {
      // Recognition session completed
      _finalResultDebounceTimer?.cancel();
      if (_isListening) {
        _stopListeningAndProcess();
      }
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    debugPrint('[VoiceDialog] Error: ${error.errorMsg}');
    if (mounted) {
      setState(() {
        _isListening = false;
        if (error.errorMsg.contains('permission')) {
          _permissionDenied = true;
        }
      });
      _soundLevelNotifier.value = 0.0;
      _pulseController.stop();
      _waveController.stop();
    }
  }

  String _cleanSpokenQuery(String raw) {
    String cleaned = raw.trim();
    cleaned = cleaned.replaceAll(RegExp(r'\brs\.?\b', caseSensitive: false), 'rupees');
    cleaned = cleaned.replaceAll(RegExp(r'\binr\b', caseSensitive: false), 'rupees');
    cleaned = cleaned.replaceAll(RegExp(r'\brupes\b', caseSensitive: false), 'rupees');
    cleaned = cleaned.replaceAll(RegExp(r'\bruppes\b', caseSensitive: false), 'rupees');
    cleaned = cleaned.replaceAll(RegExp(r'\brupay\b', caseSensitive: false), 'rupees');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return cleaned;
  }

  String _generateTransactionsCsv(List<TransactionModel> txns) {
    if (txns.isEmpty) return 'Date,Title,Category,Type,Amount (INR)\n';
    final sorted = List<TransactionModel>.from(txns)
      ..sort((a, b) => b.date.compareTo(a.date));
    final lines = sorted.take(40).map((t) {
      final dateStr =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      return '"$dateStr","${t.title.replaceAll('"', '""')}","${t.category}","${t.type}",${t.amount.toStringAsFixed(2)}';
    }).toList();
    return 'Date,Title,Category,Type,Amount (INR)\n${lines.join('\n')}';
  }

  Future<void> _processVoiceQuery(String query) async {
    final provider = context.read<AppProvider>();
    setState(() {
      _isProcessing = true;
    });

    final normalizedQuery = _cleanSpokenQuery(query);

    final csvData = _generateTransactionsCsv(provider.transactions);
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
              })
          .toList(),
      'goals': provider.goals
          .map((g) => {'name': g.name, 'target': g.target, 'saved': g.saved})
          .toList(),
    };

    final result = await GeminiService().chatWithAurex(
      messages: [
        {'role': 'user', 'content': normalizedQuery}
      ],
      context: contextData,
      transactionsCsv: csvData,
    );

    final List<Map<String, dynamic>> recordedTxns = [];
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
          recordedTxns.add({
            'title': title,
            'amount': amt,
            'type': type,
            'category': category,
          });
        }
      }
    }

    final List<Map<String, dynamic>> recordedDebts = [];
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
                note: note.isEmpty ? 'Borrowed' : note,
                date: date,
                type: 'BORROWED',
              );
            }
          } else {
            // LEND or ADD_MORE
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
                note: note.isEmpty ? 'Lent' : note,
                date: date,
                type: 'LENT',
              );
            }
          }

          recordedDebts.add({
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
        _isProcessing = false;
        _aiResponse = result.text;
        _addedTxns = recordedTxns;
        _addedDebts = recordedDebts;
      });

      // Speak the AI confirmation aloud with natural human cadence
      TtsService().speak(result.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      elevation: 0,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 380, minHeight: 330),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.22),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: BrainIcon(color: colors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aurex Voice',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textMain,
                    ),
                  ),
                  Text(
                    _isListening
                        ? 'Listening to you speak...'
                        : (_isProcessing ? 'Processing...' : 'Voice Assistant'),
                    style: TextStyle(
                      fontSize: 11,
                      color: _isListening
                          ? colors.primary
                          : colors.textMuted,
                      fontWeight:
                          _isListening ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  TtsService().isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: TtsService().isMuted ? colors.textMuted : colors.primary,
                  size: 20,
                ),
                tooltip: TtsService().isMuted ? 'Unmute speech' : 'Mute speech',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    TtsService().toggleMute();
                  });
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded, color: colors.textMuted, size: 20),
                onPressed: _dismissDialog,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Permission Request Banner
          if (_permissionDenied) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEF5350).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.mic_off_rounded,
                          color: Color(0xFFEF5350), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Microphone permission is required to speak transactions.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF5350),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await openAppSettings();
                        },
                        child: const Text('Open Settings'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _startListeningFlow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                        child: const Text('Allow & Retry'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Listening State: Animated Wave Mic + Equalizer + Spoken Words
            if (_isListening) ...[
              const SizedBox(height: 8),
              // Strictly fixed-height 32dp Sound Equalizer
              SizedBox(
                height: 32,
                child: Center(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _soundLevelNotifier,
                    builder: (context, soundLevel, child) {
                      return AnimatedBuilder(
                        animation:
                            Listenable.merge([_waveController, _pulseController]),
                        builder: (context, _) {
                          return _SoundBarsVisualizer(
                            soundLevel: soundLevel,
                            pulseValue: _pulseController.value,
                            barColor: colors.primary,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Strictly fixed-height 100x100 Mic Ripple Orb (Zero Layout Shifting)
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ValueListenableBuilder<double>(
                    valueListenable: _soundLevelNotifier,
                    builder: (context, soundLevel, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _waveController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: _VoiceWavePainter(
                                    waveAnimation: _waveController.value,
                                    soundLevel: soundLevel,
                                    baseColor: colors.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final bounce = 1.0 + (0.05 * soundLevel);
                              return Transform.scale(
                                scale: bounce.clamp(1.0, 1.10),
                                child: Material(
                                  shape: const CircleBorder(),
                                  color: colors.primary,
                                  elevation: 4,
                                  child: InkWell(
                                    onTap: _stopListeningAndProcess,
                                    customBorder: const CircleBorder(),
                                    child: const Padding(
                                      padding: EdgeInsets.all(18),
                                      child: Icon(
                                        Icons.mic_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Strict fixed-height Spoken Text Display (eliminates vertical jumping)
              SizedBox(
                height: 56,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.borderSubtle == Colors.transparent
                          ? colors.textMuted.withValues(alpha: 0.1)
                          : colors.borderSubtle,
                    ),
                  ),
                  child: Text(
                    _spokenText.isEmpty
                        ? 'Say e.g., "Spent ₹250 on Lunch" or "Lent 500 to Rahul"'
                        : _spokenText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _spokenText.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: _spokenText.isEmpty
                          ? colors.textMuted
                          : colors.textMain,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Done Button
              Center(
                child: TextButton.icon(
                  onPressed: _stopListeningAndProcess,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Done Speaking'),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ]
            // Processing State
            else if (_isProcessing) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '"$_spokenText"',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: colors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Recording transaction with Aurex AI...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ]
            // Reply State (Showing Spoken Query + AI Response + Receipt Card)
            else if (_aiResponse != null) ...[
              // What was spoken
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic_rounded,
                        size: 16, color: Color(0xFFEF5350)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _spokenText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // AI Confirmation
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _aiResponse!,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textMain,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        TtsService().speak(_aiResponse!);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction Receipt Badges
              if (_addedTxns.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final act in _addedTxns)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF66BB6A).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 16, color: Color(0xFF66BB6A)),
                        const SizedBox(width: 8),
                        Text(
                          '${act['title']} • ${act['type'] == 'INCOME' ? '+' : '-'}₹${(act['amount'] as num).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textMain,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${act['category']} • Recorded',
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              // Debt Receipt Badges
              if (_addedDebts.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final dAct in _addedDebts)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (dAct['action'] == 'BORROW'
                                ? const Color(0xFFEF5350)
                                : colors.primary)
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.handshake_rounded,
                          size: 16,
                          color: dAct['action'] == 'BORROW'
                              ? const Color(0xFFEF5350)
                              : colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${dAct['action'] == 'BORROW' ? 'Borrowed from' : 'Lent to'} ${dAct['person']} • ₹${(dAct['amount'] as num).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textMain,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Khata • Recorded',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF66BB6A),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 14),

              // Action Buttons: Speak Again & Close
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _startListeningFlow,
                      icon: const Icon(Icons.mic_rounded, size: 16),
                      label: const Text('Speak Again'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _dismissDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ]
            // Idle State: Ready to tap and speak with quick example chips
            else ...[
              const SizedBox(height: 12),
              Center(
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _startListeningFlow,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            colors.primary,
                            colors.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.40),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Tap the orb to speak',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Say e.g. "Spent 250 on Lunch" or "Rahul returned 500"',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickVoiceChip(
                    label: '☕ Spent ₹150 Coffee',
                    onTap: () {
                      _spokenText = 'Spent 150 on Coffee';
                      _processVoiceQuery(_spokenText);
                    },
                  ),
                  _QuickVoiceChip(
                    label: '🍕 Spent ₹350 Pizza',
                    onTap: () {
                      _spokenText = 'Spent 350 on Pizza';
                      _processVoiceQuery(_spokenText);
                    },
                  ),
                  _QuickVoiceChip(
                    label: '🤝 Lent ₹500 to Rahul',
                    onTap: () {
                      _spokenText = 'Lent 500 to Rahul';
                      _processVoiceQuery(_spokenText);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    ),
  );
}
}

/// Outward-propagating fluid wavy ripples reacting to voice volume
class _VoiceWavePainter extends CustomPainter {
  final double waveAnimation;
  final double soundLevel;
  final Color baseColor;

  _VoiceWavePainter({
    required this.waveAnimation,
    required this.soundLevel,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2.6;

    final glowRadius = baseRadius + 14 + (24 * soundLevel);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: (0.18 + 0.35 * soundLevel).clamp(0.0, 0.6)),
          baseColor.withValues(alpha: (0.05 + 0.15 * soundLevel).clamp(0.0, 0.3)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    for (int i = 0; i < 3; i++) {
      final phase = (waveAnimation + (i * 0.33)) % 1.0;
      final waveRadius = baseRadius + (phase * (14.0 + 22.0 * soundLevel));
      final opacity =
          ((1.0 - phase) * (0.35 + 0.65 * soundLevel)).clamp(0.0, 1.0);
      final strokeWidth =
          (1.5 + (2.0 * soundLevel) * (1.0 - phase)).clamp(1.0, 3.5);

      final ringPaint = Paint()
        ..color = baseColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawCircle(center, waveRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWavePainter oldDelegate) {
    return oldDelegate.waveAnimation != waveAnimation ||
        oldDelegate.soundLevel != soundLevel;
  }
}

/// 5-bar vertical sound visualizer
class _SoundBarsVisualizer extends StatelessWidget {
  final double soundLevel;
  final double pulseValue;
  final Color barColor;

  const _SoundBarsVisualizer({
    required this.soundLevel,
    required this.pulseValue,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final barMultipliers = [0.45, 0.75, 1.0, 0.75, 0.45];
    final barBases = [5.0, 7.0, 9.0, 7.0, 5.0];

    return SizedBox(
      height: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (index) {
          final height = barBases[index] +
              (14.0 * soundLevel * barMultipliers[index]) +
              (4.0 * pulseValue * barMultipliers[index]);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3.2,
            height: height.clamp(4.0, 24.0),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

/// Quick suggestion pill for testing/immediate voice shortcuts
class _QuickVoiceChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickVoiceChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: colors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.borderSubtle == Colors.transparent
                ? colors.textMuted.withValues(alpha: 0.15)
                : colors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textMain,
          ),
        ),
      ),
    );
  }
}
