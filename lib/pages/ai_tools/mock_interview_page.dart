import 'package:flutter/material.dart';
import '../../widgets/mesh_background.dart';
import '../../services/ai_logic_service.dart';

class MockInterviewPage extends StatefulWidget {
  const MockInterviewPage({super.key});

  @override
  State<MockInterviewPage> createState() => _MockInterviewPageState();
}

class _MockInterviewPageState extends State<MockInterviewPage> {
  final AiLogicService _aiService = AiLogicService();
  final TextEditingController _uniController = TextEditingController();
  final TextEditingController _programController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSetupComplete = false;
  bool _isLoading = false;
  bool _isTyping = false;
  bool _isFeedbackLoaded = false;
  String? _sessionId;
  String? _feedbackText;
  int? _score;
  
  final List<Map<String, String>> _messages = [];

  Future<void> _startInterview() async {
    if (_uniController.text.isEmpty || _programController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both University and Program')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _aiService.startMockInterview(
        _uniController.text,
        _programController.text,
      );

      setState(() {
        _sessionId = response['sessionId'];
        _isSetupComplete = true;
        _isLoading = false;
        _messages.add({
          'sender': 'bot',
          'text': response['message'] ?? 'Hello! I am your interviewer. Let\'s begin.',
        });
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start interview: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.isEmpty || _sessionId == null) return;

    final userText = _chatController.text;
    setState(() {
      _messages.add({'sender': 'user', 'text': userText});
      _chatController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await _aiService.sendMockInterviewMessage(_sessionId!, userText);
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': response['message'] ?? '...',
          });
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Sorry, I encountered an error. Please check your connection.',
          });
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _endInterview() async {
    if (_sessionId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Interview?'),
        content: const Text('Are you sure you want to end the interview and receive feedback?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6200EE)),
            child: const Text('End & Evaluate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await _aiService.evaluateInterview(_sessionId!);
      setState(() {
        _isFeedbackLoaded = true;
        _feedbackText = response['feedback'];
        _score = response['score'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get feedback: $e')),
      );
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
          title: Text(
            _isFeedbackLoaded
                ? 'Performance Review'
                : (_isSetupComplete ? 'AI Mock Interview' : 'Interview Setup'),
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_isSetupComplete && !_isFeedbackLoaded)
              TextButton(
                onPressed: _isLoading ? null : _endInterview,
                child: const Text(
                  'Finish',
                  style: TextStyle(
                    color: Color(0xFF6200EE),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: _isFeedbackLoaded
            ? _buildFeedbackUI()
            : (_isSetupComplete ? _buildChatUI() : _buildSetupUI()),
      ),
    );
  }

  Widget _buildSetupUI() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about your target',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We will tailor the interview questions based on your university and program.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _uniController,
            label: 'Target University',
            hint: 'e.g. University of Leeds',
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _programController,
            label: 'Program / Course',
            hint: 'e.g. Masters in Data Science',
            icon: Icons.book_outlined,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _startInterview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6200EE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Start Interview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: const Color(0xFF6200EE)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatUI() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                return _buildTypingIndicator();
              }
              final msg = _messages[index];
              final isUser = msg['sender'] == 'user';
              return _buildMessageBubble(msg['text']!, isUser);
            },
          ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6200EE) : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
            bottomLeft: !isUser ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20).copyWith(bottomLeft: Radius.zero),
        ),
        child: const Text(
          'Interviewer is typing...',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _chatController,
                  decoration: const InputDecoration(
                    hintText: 'Type your answer...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF6200EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: CircularProgressIndicator(
                        value: (_score ?? 0) / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey[100],
                        color: const Color(0xFF6200EE),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${_score ?? 0}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const Text(
                          '/ 100',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Interview Performance Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: Color(0xFF6200EE)),
                    SizedBox(width: 8),
                    Text(
                      'Detailed Feedback',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _feedbackText ?? 'No detailed feedback available at this time.',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6200EE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Done practicing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _isFeedbackLoaded = false;
                _isSetupComplete = false;
                _messages.clear();
                _sessionId = null;
              });
            },
            child: const Text('Try another interview'),
          ),
        ],
      ),
    );
  }
}
