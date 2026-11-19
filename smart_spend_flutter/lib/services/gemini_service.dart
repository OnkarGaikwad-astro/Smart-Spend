import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class AurexChatResult {
  final String text;
  final List<Map<String, dynamic>> actions;

  AurexChatResult({
    required this.text,
    this.actions = const [],
  });
}

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const String _geminiModel = 'gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Chat with Aurex, the AI financial assistant
  Future<AurexChatResult> chatWithAurex({
    required List<Map<String, String>> messages,
    required Map<String, dynamic> context,
    String? transactionsCsv,
  }) async {
    final apiKey = AppConstants.geminiApiKey;
    if (apiKey.isEmpty) {
      return AurexChatResult(text: 'Error: Gemini API key is missing.');
    }

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final goalsList = (context['goals'] as List? ?? [])
        .map((g) => '- ${g['name']}: ₹${g['saved']} / ₹${g['target']} saved')
        .join('\n');

    final csvContent = (transactionsCsv != null && transactionsCsv.trim().isNotEmpty)
        ? transactionsCsv.trim()
        : 'Date,Title,Category,Type,Amount (INR)\n(No transactions recorded yet)';

    final systemInstruction = '''
You are Aurex, the expert financial AI assistant for the SmartSpend app.
The current date and time right now is: $dateStr.
Use this timestamp for questions regarding "today", "yesterday", "this week", "this month", "last month", etc.

User's Financial Summary:
- Total Balance: ₹${context['totalBalance']}
- Total Income: ₹${context['totalIncome']}
- Total Expenses: ₹${context['totalExpense']}

Active Savings Goals:
$goalsList

ATTACHED TRANSACTIONS CSV FILE (transactions.csv):
```csv
$csvContent
```

CAPABILITY - ADDING TRANSACTIONS & INCOME:
You can directly add transactions or income to the user's account!
When the user asks you to add, log, spend, earn, or record an expense or income (e.g. "add 200 for lunch", "spent 150 on petrol", "add 5000 income from salary", "I earned 1200 freelancing today", "bought groceries for 450 add it"):
1. In your message, warmly confirm what you have recorded (e.g. "✅ Added expense of ₹200 for Lunch under Food!").
2. At the very end of your response, output a TRANSACTION_ACTION block formatted EXACTLY as:
<<<TRANSACTION_ACTION
{
  "title": "<Short Description>",
  "amount": <positive number, e.g. 200.0>,
  "type": "<EXPENSE or INCOME>",
  "category": "<Food | Transport | Subscriptions | Entertainment | Shopping | Bills | Salary | Freelance | Investment | Gift | Other>",
  "date": "<ISO 8601 string, e.g. 2026-11-19T12:00:00>"
}
TRANSACTION_ACTION>>>
If multiple transactions are requested in one prompt, you may output a JSON array of objects inside the block.

CRITICAL INSTRUCTIONS:
1. An official transactions.csv file has been attached above containing all user transactions with Date, Title, Category, Type, and Amount.
2. ALWAYS base your answers, totals, categories, merchant breakdowns, and trend analyses directly on this attached CSV.
3. Calculate sums and counts accurately from the CSV entries. Mention specific transaction names, dates, and amounts when helpful.
4. Keep answers friendly, conversational, concise, and easy to read. Use bullet points for breakdowns and emojis occasionally. Always use ₹ (INR) for amounts.
''';

    final contents = <Map<String, dynamic>>[];

    // Add conversation history
    for (int i = 0; i < messages.length; i++) {
      final m = messages[i];
      final isLast = i == messages.length - 1;
      final role = m['role'] == 'ai' ? 'model' : 'user';
      var text = m['content'] ?? '';

      if (isLast && role == 'user') {
        text = '''[Attached File: transactions.csv]
$text''';
      }

      contents.add({
        'role': role,
        'parts': [
          {'text': text}
        ]
      });
    }

    try {
      final url = Uri.parse('$_baseUrl/$_geminiModel:generateContent?key=$apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': systemInstruction}
            ]
          },
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1000,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final rawText = parts[0]['text']?.toString() ?? 'No response generated.';
            return _parseAurexResponse(rawText);
          }
        }
        return AurexChatResult(text: 'No response generated.');
      } else {
        debugPrint('[GeminiService] API error: ${response.statusCode} - ${response.body}');
        return AurexChatResult(
          text: 'Sorry, I encountered an issue communicating with the AI service. (Code ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('[GeminiService] Network error: $e');
      return AurexChatResult(
        text: 'Sorry, I could not connect to Aurex. Please check your internet connection.',
      );
    }
  }

  /// Parses action blocks out of the response
  AurexChatResult _parseAurexResponse(String raw) {
    final actionRegex = RegExp(
      r'<<<TRANSACTION_ACTION\s*([\s\S]*?)\s*TRANSACTION_ACTION>>>',
      caseSensitive: false,
    );
    final match = actionRegex.firstMatch(raw);
    List<Map<String, dynamic>> actions = [];
    String cleanText = raw;

    if (match != null) {
      final jsonBlock = match.group(1)?.trim() ?? '';
      cleanText = raw.replaceAll(actionRegex, '').trim();
      try {
        final parsed = jsonDecode(jsonBlock);
        if (parsed is List) {
          actions = List<Map<String, dynamic>>.from(parsed);
        } else if (parsed is Map) {
          actions = [Map<String, dynamic>.from(parsed)];
        }
      } catch (e) {
        debugPrint('[GeminiService] Failed to parse transaction action: $e');
      }
    }

    return AurexChatResult(
      text: cleanText.isEmpty ? 'Transaction recorded successfully!' : cleanText,
      actions: actions,
    );
  }

  /// Extract transactions from receipt or bill image
  Future<List<Map<String, dynamic>>> extractReceipt({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    final apiKey = AppConstants.geminiApiKey;
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured.');
    }

    final base64Image = base64Encode(imageBytes);

    const prompt = '''
Analyze this image (which could be a receipt, a bill, or a screenshot of transactions like PhonePe, Google Pay, Paytm, or bank SMS).
Extract ALL visible transactions. Return a JSON ARRAY of objects.
For each transaction, extract:
- amount: The total amount as a positive number (without currency symbols).
- title: A short description of the merchant, person, or place.
- category: Pick ONE from: "Food", "Transport", "Subscriptions", "Entertainment", "Shopping", "Bills", "Other".
- date: The date and time of the transaction in ISO 8601 format (YYYY-MM-DDTHH:mm). If time is missing, assume 12:00. If date is missing, use current date.

Return ONLY the raw JSON array of objects, without any markdown formatting or backticks. Example:
[
  {
    "amount": 250.0,
    "title": "Starbucks Coffee",
    "category": "Food",
    "date": "2026-11-17T12:00"
  }
]
''';

    try {
      final url = Uri.parse('$_baseUrl/$_geminiModel:generateContent?key=$apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': mimeType,
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates[0]['content']['parts'][0]['text'] as String;
          final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
          final parsed = jsonDecode(cleaned);
          if (parsed is List) {
            return List<Map<String, dynamic>>.from(parsed);
          } else if (parsed is Map) {
            return [Map<String, dynamic>.from(parsed)];
          }
        }
      } else {
        throw Exception('Gemini API Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[GeminiService] Error extracting receipt: $e');
      rethrow;
    }
    return [];
  }
}
