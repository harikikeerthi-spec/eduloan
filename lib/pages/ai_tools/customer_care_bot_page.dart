import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/mesh_background.dart';
import '../../services/ai_logic_service.dart';

class CustomerCareBotPage extends StatefulWidget {
  const CustomerCareBotPage({super.key});

  @override
  State<CustomerCareBotPage> createState() => _CustomerCareBotPageState();
}

class _CustomerCareBotPageState extends State<CustomerCareBotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiLogicService _aiService = AiLogicService();
  bool _isTyping = false;

  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text':
          'Hello! 👋 I am your VidhyaLoan AI Support Assistant.\n\nI can help you with education loan eligibility, bank options, interest rates, document requirements, and study-abroad funding. How can I assist you today?',
    },
  ];

  final List<String> _quickSuggestions = [
    '📑 Required Documents',
    '💰 Non-Collateral Loan Options',
    '📊 Current Interest Rates',
    '🎓 Top Study Destinations',
    '📞 Contact Human Specialist',
  ];

  @override
  void dispose() {
    _controller.dispose();
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

  Future<void> _sendMessage([String? customText]) async {
    final userText = (customText ?? _controller.text).trim();
    if (userText.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': userText});
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final history = _messages
          .map(
            (m) => {
              'role': m['sender'] == 'user' ? 'user' : 'assistant',
              'content': m['text'] ?? '',
            },
          )
          .toList();

      final response = await _aiService.sendSupportMessage(
        userText,
        history: history,
      );

      if (mounted) {
        setState(() {
          _messages.add({'sender': 'bot', 'text': response});
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text':
                'I am currently experiencing a temporary connection issue. Please feel free to email support@vidyaloans.in or call our counselor team at +91 92402 09000.',
          });
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF311B92);
    const accentColor = Color(0xFF673AB7);

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primaryColor, accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Support Assistant',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Online • 24/7 Assistance',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            18,
                          ).copyWith(bottomLeft: Radius.zero),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Thinking & typing...',
                              style: GoogleFonts.outfit(
                                color: Colors.black54,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.82,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isUser
                            ? const LinearGradient(
                                colors: [primaryColor, accentColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isUser ? null : Colors.white,
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
                            color: isUser
                                ? primaryColor.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SelectableText(
                        msg['text']!,
                        style: GoogleFonts.outfit(
                          color: isUser
                              ? Colors.white
                              : const Color(0xFF1E293B),
                          fontSize: 14.5,
                          height: 1.45,
                          fontWeight: isUser
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Quick suggestion chips
            Container(
              height: 46,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _quickSuggestions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final suggestion = _quickSuggestions[i];
                  return ActionChip(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: primaryColor.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    label: Text(
                      suggestion,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    onPressed: () => _sendMessage(suggestion),
                  );
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1E293B),
                          fontSize: 14.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask anything about education loans...',
                          hintStyle: GoogleFonts.outfit(
                            color: const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _sendMessage(),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [primaryColor, accentColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
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
