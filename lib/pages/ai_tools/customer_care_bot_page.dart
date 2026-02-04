import 'package:flutter/material.dart';
import '../../widgets/mesh_background.dart';

class CustomerCareBotPage extends StatefulWidget {
  const CustomerCareBotPage({super.key});

  @override
  State<CustomerCareBotPage> createState() => _CustomerCareBotPageState();
}

class _CustomerCareBotPageState extends State<CustomerCareBotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text': 'Hi! I am the EduLoan AI Assistant. How can I help you today?',
    },
  ];

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    final userText = _controller.text;
    setState(() {
      _messages.add({'sender': 'user', 'text': userText});
      _controller.clear();
    });

    // Mock AI Delay
    Future.delayed(const Duration(seconds: 1), () {
      final response = _getBotResponse(userText);
      setState(() {
        _messages.add({'sender': 'bot', 'text': response});
      });
    });
  }

  String _getBotResponse(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('interest') || lower.contains('rate')) {
      return "Our interest rates currently start from 8.5% for international studies and 9% for domestic. Check the Eligibility tool for a personalized rate!";
    } else if (lower.contains('document') || lower.contains('required')) {
      return "You typically need: 1. ID Proof, 2. Academic Records, 3. Admission Letter, 4. Income Proof of Co-applicant.";
    } else if (lower.contains('contact') || lower.contains('support')) {
      return "You can reach our human team at support@eduloan.com or call +1-800-EDU-LOAN.";
    } else if (lower.contains('emi')) {
      return "We have an EMI Calculator! Go to the 'Loans' section to plan your repayment.";
    } else if (lower.contains('hello') || lower.contains('hi')) {
      return "Hello there! Ask me anything about loans or your application.";
    }
    return "I'm still learning! Please contact support for complex queries, or ask me about interest rates, documents, or EMI.";
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Support Assistant',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF009688) : Colors.white,
                        borderRadius: BorderRadius.circular(20).copyWith(
                          bottomRight: isUser
                              ? Radius.zero
                              : const Radius.circular(20),
                          bottomLeft: !isUser
                              ? Radius.zero
                              : const Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        msg['text']!,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type your question...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: const Color(0xFF009688),
                    elevation: 0,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
