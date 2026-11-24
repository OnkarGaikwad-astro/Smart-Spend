import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// High-quality text-to-speech service with natural accent selection,
/// gender selection (Male / Female), natural speech cadence, and currency/markdown normalization.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  static const String _voiceGenderKey = 'aurex_ai_voice_gender';

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  String _currentGender = 'female'; // 'female' or 'male'

  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;
  String get currentGender => _currentGender;

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      stop();
    }
  }

  Future<void> setVoiceGender(String gender) async {
    final lower = gender.toLowerCase();
    if (lower == 'male') {
      _currentGender = 'male';
    } else if (lower == 'female_british') {
      _currentGender = 'female_british';
    } else if (lower == 'female_indian') {
      _currentGender = 'female_indian';
    } else {
      _currentGender = 'female';
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_voiceGenderKey, _currentGender);
    } catch (e) {
      debugPrint('[TtsService] Save gender error: $e');
    }
    await _applyVoiceAndPitch();
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentGender = prefs.getString(_voiceGenderKey) ?? 'female';

      if (Platform.isAndroid) {
        // Explicitly set Google TTS engine if available for natural human speech
        try {
          final engines = await _flutterTts.getEngines;
          if (engines is List && engines.contains('com.google.android.tts')) {
            await _flutterTts.setEngine('com.google.android.tts');
            debugPrint('[TtsService] Successfully set engine to com.google.android.tts');
          }
        } catch (e) {
          debugPrint('[TtsService] Error setting engine: $e');
        }
      }

      // Non-blocking async speech to prevent Android 14 utterance deadlock
      await _flutterTts.awaitSpeakCompletion(false);
      await _applyVoiceAndPitch();

      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        debugPrint('[TtsService] Started speaking');
      });
      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        debugPrint('[TtsService] Finished speaking');
      });
      _flutterTts.setErrorHandler((msg) {
        _isPlaying = false;
        debugPrint('[TtsService] TTS error handler: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[TtsService] Init exception: $e');
    }
  }

  Future<void> _applyVoiceAndPitch() async {
    // Natural 1.0 pitch preserves authentic human formant and eliminates robotic pitch-shift artifacts!
    await _flutterTts.setPitch(1.0);
    // 0.48 speech rate gives a calm, articulate, human conversational cadence
    await _flutterTts.setSpeechRate(0.48);
    await _flutterTts.setVolume(1.0);

    // 1. Determine target language locale based on voice persona
    String targetLocale;
    if (_currentGender == 'female_british') {
      targetLocale = 'en-GB';
    } else if (_currentGender == 'male' || _currentGender == 'female_indian') {
      targetLocale = 'en-IN';
    } else {
      // Default / 'female': Studio Natural US (DeepMind WaveNet)
      targetLocale = 'en-US';
    }

    try {
      final isAvailable = await _flutterTts.isLanguageAvailable(targetLocale);
      if (isAvailable == 1) {
        await _flutterTts.setLanguage(targetLocale);
      } else {
        await _flutterTts.setLanguage('en-US');
      }
    } catch (e) {
      debugPrint('[TtsService] setLanguage exception: $e');
      try {
        await _flutterTts.setLanguage('en-US');
      } catch (_) {}
    }

    // 2. Select high-fidelity neural voices on Android
    if (Platform.isAndroid) {
      try {
        final voices = await _flutterTts.getVoices;
        if (voices is List && voices.isNotEmpty) {
          Map<dynamic, dynamic>? chosenVoice;

          if (_currentGender == 'female_british') {
            // Target Google UK Studio voices: rjs (Studio UK Female), gba, gbd
            for (final v in voices) {
              if (v is Map) {
                final name = (v['name'] ?? '').toString().toLowerCase();
                final locale = (v['locale'] ?? '').toString().toLowerCase();
                if (locale.contains('en-gb') || locale.contains('en_gb')) {
                  if (name.contains('-rjs-local') || name.contains('-rjs-network')) {
                    chosenVoice = v;
                    break;
                  }
                }
              }
            }
            if (chosenVoice == null) {
              for (final v in voices) {
                if (v is Map) {
                  final name = (v['name'] ?? '').toString().toLowerCase();
                  final locale = (v['locale'] ?? '').toString().toLowerCase();
                  if (locale.contains('en-gb') || locale.contains('en_gb')) {
                    if (name.contains('-gba-') || name.contains('-gbc-') || name.contains('-gbd-') || name.contains('female')) {
                      chosenVoice = v;
                      break;
                    }
                  }
                }
              }
            }
          } else if (_currentGender == 'male') {
            // Target Google Indian Male voice: end (deep, confident & natural male)
            for (final v in voices) {
              if (v is Map) {
                final name = (v['name'] ?? '').toString().toLowerCase();
                final locale = (v['locale'] ?? '').toString().toLowerCase();
                if (locale.contains('en-in') || locale.contains('en_in')) {
                  if (name.contains('-end-local') || name.contains('-end-network')) {
                    chosenVoice = v;
                    break;
                  }
                }
              }
            }
            if (chosenVoice == null) {
              for (final v in voices) {
                if (v is Map) {
                  final name = (v['name'] ?? '').toString().toLowerCase();
                  final locale = (v['locale'] ?? '').toString().toLowerCase();
                  if (locale.contains('en-in') || locale.contains('en_in')) {
                    if (name.contains('-enb-') || name.contains('-cxx-') || (name.contains('male') && !name.contains('female'))) {
                      chosenVoice = v;
                      break;
                    }
                  }
                }
              }
            }
          } else if (_currentGender == 'female_indian') {
            // Target Google Indian Female voice: ena (warm & melodic) or ene
            for (final v in voices) {
              if (v is Map) {
                final name = (v['name'] ?? '').toString().toLowerCase();
                final locale = (v['locale'] ?? '').toString().toLowerCase();
                if (locale.contains('en-in') || locale.contains('en_in')) {
                  if (name.contains('-ena-local') || name.contains('-ena-network') || name.contains('-ene-local')) {
                    chosenVoice = v;
                    break;
                  }
                }
              }
            }
          } else {
            // Default / 'female': Google Studio Natural (DeepMind flagship neural US female: sfg)
            for (final v in voices) {
              if (v is Map) {
                final name = (v['name'] ?? '').toString().toLowerCase();
                final locale = (v['locale'] ?? '').toString().toLowerCase();
                if (locale.contains('en-us') || locale.contains('en_us')) {
                  if (name.contains('-sfg-local') || name.contains('-sfg-network')) {
                    chosenVoice = v;
                    break;
                  }
                }
              }
            }
            if (chosenVoice == null) {
              for (final v in voices) {
                if (v is Map) {
                  final name = (v['name'] ?? '').toString().toLowerCase();
                  final locale = (v['locale'] ?? '').toString().toLowerCase();
                  if (locale.contains('en-us') || locale.contains('en_us')) {
                    if (name.contains('-tpf-') || name.contains('-iol-') || name.contains('-iog-')) {
                      chosenVoice = v;
                      break;
                    }
                  }
                }
              }
            }
          }

          if (chosenVoice != null) {
            debugPrint(
                '[TtsService] Selected natural $_currentGender voice: ${chosenVoice['name']} (${chosenVoice['locale']})');
            await _flutterTts.setVoice({
              'name': chosenVoice['name'].toString(),
              'locale': chosenVoice['locale'].toString(),
            });
          }
        }
      } catch (e) {
        debugPrint('[TtsService] Error selecting voice: $e');
      }
    }
  }

  /// Plays a short vocal sample to preview the currently selected voice.
  Future<void> speakSample() async {
    final String sample;
    switch (_currentGender) {
      case 'female_british':
        sample = "Hello! I am Aurex, your personal financial assistant. How may I assist you with your spending and budgets today?";
        break;
      case 'male':
        sample = "Hello! I am Aurex, your financial assistant. All your budgets, accounts, and transactions are in good order.";
        break;
      case 'female_indian':
        sample = "Namaste! I am Aurex, your personal money assistant. What would you like to review today?";
        break;
      case 'female':
      default:
        sample = "Hello! I am Aurex, your smart financial assistant. How can I help you manage your money and savings today?";
        break;
    }
    await speak(sample);
  }

  /// Cleans markdown, action blocks, and emojis, and expands currency symbols
  /// so speech sounds fluent and natural.
  String cleanTextForSpeech(String raw) {
    var text = raw;

    // 1. Remove action blocks entirely
    text = text.replaceAll(RegExp(r'<<<[\s\S]*?>>>'), '');

    // 2. Expand ₹ to "rupees" so speech engines pronounce it perfectly
    text = text.replaceAll('₹', ' rupees ');

    // 3. Expand INR to rupees
    text = text.replaceAll(RegExp(r'\bINR\b', caseSensitive: false), 'rupees');

    // 4. Remove markdown syntax like **, __, ##, ```
    text = text.replaceAll(RegExp(r'[*_#`~]'), '');

    // 5. Expand abbreviations
    text = text.replaceAll(RegExp(r'\btxn[s]?\b', caseSensitive: false), 'transaction');
    text = text.replaceAll(RegExp(r'\bamt\b', caseSensitive: false), 'amount');

    // 6. Remove emojis
    text = text.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{FE00}-\u{FE0F}\u{1F900}-\u{1F9FF}]',
        unicode: true,
      ),
      '',
    );

    // 7. Clean up multiple spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// Speaks the given text with natural cadence. If muted, does nothing.
  Future<void> speak(String text) async {
    if (_isMuted) {
      debugPrint('[TtsService] Speech muted, skipping.');
      return;
    }

    final cleaned = cleanTextForSpeech(text);
    if (cleaned.isEmpty) {
      debugPrint('[TtsService] Cleaned text is empty.');
      return;
    }

    if (!_isInitialized) {
      await init();
    }

    try {
      debugPrint('[TtsService] Speaking: "$cleaned"');
      await stop();
      final res = await _flutterTts.speak(cleaned);
      debugPrint('[TtsService] flutter_tts.speak result: $res');
    } catch (e) {
      debugPrint('[TtsService] Speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('[TtsService] Stop error: $e');
    }
  }
}
