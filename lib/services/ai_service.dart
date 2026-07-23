import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('openrouter_api_key');
    if (key != null && key.isNotEmpty) return key;
    return null;
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openrouter_api_key', key.trim());
  }

  static Future<String> getAiResponse({
    required String systemPrompt,
    required String userMessage,
    required List<Map<String, String>> chatHistory,
  }) async {
    final apiKey = await getApiKey();
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key not found. Please add your OpenRouter API Key in Settings.');
    }

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...chatHistory,
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/TharushaAkash/BudgetBuddy', // Optional, for OpenRouter rankings
          'X-Title': 'BudgetBuddy AI', // Optional, for OpenRouter rankings
        },
        body: jsonEncode({
          // 'google/gemini-1.5-pro' is excellent for complex financial reasoning
          'model': 'google/gemini-1.5-pro',
          'messages': messages,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'No response generated.';
      } else {
        throw Exception('Failed to get response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to AI: $e');
    }
  }
}
