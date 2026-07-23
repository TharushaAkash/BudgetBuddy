import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/goal_model.dart';

class AiService {
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('gemini_api_key');
    if (key != null && key.isNotEmpty) return key;
    return null;
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key.trim());
  }

  static Future<String> _callGemini(String prompt) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API Key not found.');
    }

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ?? '';
      } else {
        throw Exception('Failed to get response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to AI: $e');
    }
  }

  static Future<String> getGoalSuggestion(GoalModel goal, String financialSummary) async {
    final prompt = '''
You are a concise financial advisor in a finance app. 
The user has a goal: "${goal.name}". 
Target: ${goal.targetAmount}, Saved so far: ${goal.savedAmount}, Deadline: ${goal.targetDate.toString().split(" ")[0]}.
Here is their financial summary:
$financialSummary

Provide a very short, 1-2 sentence suggestion on how much they should save TODAY or THIS WEEK to stay on track for this goal, considering their current cash and upcoming expenses. Keep it extremely brief and encouraging. Do not use markdown formatting. IMPORTANT: You MUST respond entirely in the Sinhala language.
''';
    return _callGemini(prompt);
  }

  static Future<String> getExpenseImpactPrediction(double amount, String category, String financialSummary) async {
    final prompt = '''
You are a concise financial advisor. The user is about to add a new expense of $amount for category "$category".
Here is their financial summary:
$financialSummary

Provide a very short 1-sentence prediction on whether this expense is safe to make right now or if it will jeopardize their goals or loan payments. If it's safe because of upcoming income, mention it briefly. Do not use markdown formatting. IMPORTANT: You MUST respond entirely in the Sinhala language.
''';
    return _callGemini(prompt);
  }
}
