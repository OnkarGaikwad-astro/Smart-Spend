import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const String _geminiModel = 'gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Chat with Aurex, the AI financial assistant
  Future<String> chatWithAurex({
    required List<Map<String, String>> messages,
    required Map<String, dynamic> context,
  }) async {
    final apiKey = AppConstants.geminiApiKey;
    if (apiKey.isEmpty) {
      return 'Error: Gemini API key is missing.';
    }

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final transactionsList = (context['transactions'] as List? ?? [])
        .map((t) =>
            '- ${t['date']?.toString().split('T')[0] ?? ''}: ${t['title']} (${t['category']}) - ${t['type'] == 'INCOME' ? '+' : '-'}₹${(t['amount'] as num?)?.abs() ?? 0}')
        .join('\n');

    final goalsList = (context['goals'] as List? ?? [])
        .map((g) => '- ${g['name']}: ₹${g['saved']} / ₹${g['target']} saved')
        .join('\n');

    final systemInstruction = '''
You are Aurex, a helpful, encouraging, and friendly financial assistant for the SmartSpend app.
The current date and time right now is: $dateStr.
Use this date to answer questions like "this week", "today", "last month", etc.

Here is the user's current financial context:
- Total Balance: ₹${context['totalBalance']}
- Total Income: ₹${context['totalIncome']}
- Total Expenses: ₹${context['totalExpense']}

All Transactions History:
$transactionsList

Active Goals:
$goalsList

Please use this context to answer the user's questions in a short, conversational, and helpful manner. Avoid huge blocks of text. Use emojis occasionally!
''';

    final contents = <Map<String, dynamic>>[];

    // Add context and conversation history
    for (int i = 0; i < messages.length; i++) {
      final m = messages[i];
      final isLast = i == messages.length - 1;
      final role = m['role'] == 'ai' ? 'model' : 'user';
      var text = m['content'] ?? '';

      if (i == 0 && role == 'user') {
        text = '$systemInstruction\n\nUser Question: $text';
      } else if (isLast && role == 'user') {
        text = 'User Question: $text';
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
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 800,
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
            return parts[0]['text'] ?? 'No response generated.';
          }
        }
        return 'No response generated.';
      } else {
        debugPrint('[GeminiService] API error: ${response.statusCode} - ${response.body}');
        return 'Sorry, I encountered an issue communicating with the AI service. (Code ${response.statusCode})';
      }
    } catch (e) {
      debugPrint('[GeminiService] Network error: $e');
      return 'Sorry, I could not connect to Aurex. Please check your internet connection.';
    }
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
