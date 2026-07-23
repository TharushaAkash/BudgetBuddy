import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/finance_provider.dart';
import '../services/ai_service.dart';
import '../utils/app_theme.dart';

class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _hasApiKey = true;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _addInitialGreeting();
  }

  Future<void> _checkApiKey() async {
    final key = await AiService.getApiKey();
    if (key == null || key.isEmpty) {
      setState(() => _hasApiKey = false);
    }
  }

  void _addInitialGreeting() {
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': 'Hello! I am your AI Financial Advisor. I have analyzed your Income, Expenses, Goals, and Loans. How can I help you today?'
      });
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final systemPrompt = '''
You are a highly intelligent financial advisor AI built into the "BudgetBuddy" app.
Always reply in a friendly and professional tone.
If the user speaks in Sinhala, reply in Sinhala. If English, reply in English.

Here is the user's LIVE financial data:
${provider.getFinancialSummary()}

Use this data to answer their questions. If they ask about buying something, predict if it will affect their goals or loans based on their petty cash and expenses.
''';

      // Convert local UI messages format to the format AiService expects (excluding the first greeting to save tokens if needed, but it's fine)
      final history = _messages.where((m) => m['role'] != 'assistant' || m['content'] != 'Hello! I am your AI Financial Advisor. I have analyzed your Income, Expenses, Goals, and Loans. How can I help you today?').toList();
      
      // Remove the last user message from history because it's passed separately
      history.removeLast();

      final response = await AiService.getAiResponse(
        systemPrompt: systemPrompt,
        userMessage: text,
        chatHistory: history,
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': response});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Error: ${e.toString()}'});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasApiKey) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Advisor')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.smart_toy_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'API Key Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please go to Settings and add your OpenRouter API Key to use the AI Advisor.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 8),
            Text('AI Advisor', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppColors.card,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.bg,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                        bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: isUser 
                        ? Text(
                            msg['content']!, 
                            style: const TextStyle(color: Colors.white, fontSize: 16)
                          )
                        : MarkdownBody(
                            data: msg['content']!,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(color: Colors.black87, fontSize: 16),
                              strong: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask about your finances...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.bg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
