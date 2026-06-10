import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../widgets/mesh_background.dart';
import '../../services/ai_logic_service.dart';

class VisaInterviewPage extends StatefulWidget {
  const VisaInterviewPage({super.key});

  @override
  State<VisaInterviewPage> createState() => _VisaInterviewPageState();
}

class _VisaInterviewPageState extends State<VisaInterviewPage> {
  final AiLogicService _aiService = AiLogicService();

  // Voice Call Services
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isSetupComplete = false;
  bool _isLoading = false;
  bool _isFinished = false;
  bool _isEditingProfile = false;
  bool _isSpeakerOn = true;

  // Voice Call State
  bool _isListening = false;
  String _lastWords = '';
  double _voiceLevel = 0.0;

  int _setupStep = 0; // 0: Visa Path, 1: Profile

  late TextEditingController _universityController;
  late TextEditingController _courseController;
  late TextEditingController _financialsController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  String _currentSection = 'Introduction';
  String _visaType = 'F-1 Student Visa';
  String? _finalReport;

  final List<InterviewMessage> _messages = [];
  final List<EvaluationResult> _evaluations = [];

  // Mock profile - in a real app, this would come from user service/provider
  final Map<String, dynamic> _userProfile = {
    'firstName': 'Keerthi',
    'lastName': 'Hari',
    'university': 'Stanford University',
    'course': 'MS in Computer Science',
    'financials': 'Self-funded with bank loan',
    'background': 'Bachelor in Engineering, 2 years work exp',
  };

  @override
  void initState() {
    super.initState();
    _universityController = TextEditingController(
      text: _userProfile['university'],
    );
    _courseController = TextEditingController(text: _userProfile['course']);
    _financialsController = TextEditingController(
      text: _userProfile['financials'],
    );
    _firstNameController = TextEditingController(
      text: _userProfile['firstName'],
    );
    _lastNameController = TextEditingController(text: _userProfile['lastName']);
    _loadUserProfileName();
    _initVoice();
  }

  Future<void> _loadUserProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    final firstName =
        prefs.getString('user_firstName') ?? prefs.getString('user_name');
    final lastName = prefs.getString('user_lastName');

    if (mounted) {
      if (firstName != null && firstName.isNotEmpty) {
        setState(() {
          _userProfile['firstName'] = firstName;
          _firstNameController.text = firstName;
          if (lastName != null) {
            _userProfile['lastName'] = lastName;
            _lastNameController.text = lastName;
          }
        });
      }
    }
  }

  Future<void> _initVoice() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setCompletionHandler(() {
      if (mounted) {
        _startListening();
      }
    });

    var hasSpeech = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() => _isListening = false);
          if (_lastWords.trim().isNotEmpty) {
            _sendMessage(_lastWords.trim());
            _lastWords = '';
          }
        }
      },
      onError: (errorNotification) {
        debugPrint('STT Error: $errorNotification');
        setState(() => _isListening = false);
      },
    );

    if (!hasSpeech) {
      debugPrint('Speech recognition not available');
    }
  }

  Future<void> _speak(String text) async {
    if (!_isSpeakerOn) return;
    await _tts.speak(text);
  }

  void _startListening() async {
    if (await _speech.hasPermission && _speech.isAvailable) {
      // Small delay to prevent catching the end of the TTS
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      setState(() {
        _isListening = true;
        _lastWords = '';
      });

      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _lastWords = result.recognizedWords;
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        ),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        onSoundLevelChange: (level) {
          if (mounted) {
            setState(() => _voiceLevel = level);
          }
        },
      );
    } else {
      debugPrint('Speech recognition permission denied or unavailable');
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _universityController.dispose();
    _courseController.dispose();
    _financialsController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _tts.stop();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _startInterview() async {
    // Update profile from controllers
    _userProfile['firstName'] = _firstNameController.text;
    _userProfile['lastName'] = _lastNameController.text;
    _userProfile['university'] = _universityController.text;
    _userProfile['course'] = _courseController.text;
    _userProfile['financials'] = _financialsController.text;

    setState(() => _isLoading = true);

    try {
      final response = await _aiService.startVisaInterview(
        _userProfile,
        _visaType,
      );

      if (mounted) {
        setState(() {
          _isSetupComplete = true;
          _isLoading = false;
          _currentSection = response.currentSection;
          _messages.add(
            InterviewMessage(sender: 'bot', text: response.message),
          );
        });
        _speak(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start interview: $e')),
      );
    }
  }

  Future<void> _sendMessage(String userText) async {
    if (userText.isEmpty || _isLoading || _isFinished) return;

    final previousQuestion = _messages.last.text;

    setState(() {
      _messages.add(InterviewMessage(sender: 'user', text: userText));
    });

    try {
      // 1. Evaluate the answer
      final evaluation = await _aiService.evaluateVisaAnswer(
        question: previousQuestion,
        transcript: userText,
        visaType: _visaType,
      );
      _evaluations.add(evaluation);

      // 2. Get next question
      final next = await _aiService.continueVisaInterview(
        userProfile: _userProfile,
        previousQuestion: previousQuestion,
        transcript: userText,
        currentSection: _currentSection,
        conversationHistory: _messages,
        visaType: _visaType,
      );

      if (mounted) {
        setState(() {
          _currentSection = next.nextSection;
          _messages.add(
            InterviewMessage(
              sender: 'bot',
              text: next.message.isNotEmpty ? next.message : '...',
            ),
          );
          if (_currentSection.toLowerCase() == 'conclusion' ||
              next.message.contains('thank you for your time')) {
            _isFinished = true;
          }
        });
        _speak(next.message.isNotEmpty ? next.message : '...');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            InterviewMessage(
              sender: 'bot',
              text:
                  'I apologize, I lost connection. Could you please repeat that?',
            ),
          );
        });
        _speak('I apologize, I lost connection. Could you please repeat that?');
      }
    }
  }

  Future<void> _generateFinalReport() async {
    setState(() => _isLoading = true);
    try {
      final report = await _aiService.getVisaFinalReport(
        conversationHistory: _messages,
        evaluations: _evaluations,
        visaType: _visaType,
      );
      setState(() {
        _finalReport = report;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate report: $e')));
    }
  }

  // Intentionally blank hook

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
          title: Column(
            children: [
              const Text(
                'Visa Simulator',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              if (_isSetupComplete && _finalReport == null)
                Text(
                  'Section: $_currentSection',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          centerTitle: true,
          actions: [
            if (_isFinished && _finalReport == null)
              TextButton(
                onPressed: _isLoading ? null : _generateFinalReport,
                child: const Text(
                  'Get Report',
                  style: TextStyle(
                    color: Color(0xFF6200EE),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: _finalReport != null
            ? _buildReportUI()
            : (_isSetupComplete ? _buildChatUI() : _buildSetupUI()),
      ),
    );
  }

  Widget _buildSetupUI() {
    return Column(
      children: [
        Expanded(child: _buildStepContent()),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_setupStep) {
      case 0:
        return _buildVisaPathSelection();
      case 1:
      default:
        return _buildProfileSetupUI();
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_setupStep > 0) ...[
              _buildBackButton(() {
                setState(() => _setupStep--);
              }),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _setupStep == 1
                  ? _buildBeginButton()
                  : _buildNextButton(() {
                      setState(() => _setupStep++);
                    }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeginButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading || _isEditingProfile ? null : _startInterview,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6200EE),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Begin Simulation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
      ),
    );
  }

  Widget _buildVisaPathSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          _buildStepHeader('SELECT YOUR PATH'),
          const SizedBox(height: 24),
          _buildSelectionCard(
            title: 'F-1 Student Visa',
            subtitle: 'For full-time students at accredited US institutions',
            icon: Icons.school,
            isSelected: _visaType == 'F-1 Student Visa',
            onTap: () => setState(() => _visaType = 'F-1 Student Visa'),
          ),
          const SizedBox(height: 16),
          _buildSelectionCard(
            title: 'Tier 4 UK Visa',
            subtitle: 'General student visa for studying in the United Kingdom',
            icon: Icons.eco,
            isSelected: _visaType == 'Tier 4 UK Visa',
            onTap: () => setState(() => _visaType = 'Tier 4 UK Visa'),
          ),
        ],
      ),
    );
  }


  Widget _buildProfileSetupUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepHeader('CONFIRM YOUR PROFILE'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INTERVIEW PROFILE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B7280),
                  letterSpacing: 1,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _isEditingProfile = !_isEditingProfile);
                },
                icon: Icon(
                  _isEditingProfile ? Icons.check : Icons.edit,
                  size: 16,
                  color: const Color(0xFF6200EE),
                ),
                label: Text(
                  _isEditingProfile ? 'Done' : 'Edit Details',
                  style: const TextStyle(
                    color: Color(0xFF6200EE),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditingProfile)
            _buildProfileEditUI()
          else ...[
            _buildInfoTile(
              Icons.person,
              'Name',
              '${_firstNameController.text} ${_lastNameController.text}'.trim(),
            ),
            const SizedBox(height: 12),
            _buildInfoTile(Icons.school, 'Target', _universityController.text),
            const SizedBox(height: 12),
            _buildInfoTile(Icons.book, 'Course', _courseController.text),
            const SizedBox(height: 12),
            _buildInfoTile(
              Icons.account_balance_wallet,
              'Funding',
              _financialsController.text,
            ),
          ],
        ],
      ),
    );
  }

  // Helper Widgets for Multi-step Setup
  Widget _buildStepHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Color(0xFF6200EE),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFD482F6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6200EE).withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6200EE)
                : const Color(0xFFE5E7EB),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6200EE) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: disabled ? Colors.grey : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF6200EE)),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6200EE),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Next Step',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(VoidCallback onPressed) {
    return SizedBox(
      height: 60,
      width: 60,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
        ),
        child: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
      ),
    );
  }

  Widget _buildProfileEditUI() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6200EE).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildEditField(
                  'First Name',
                  _firstNameController,
                  Icons.person_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEditField(
                  'Last Name',
                  _lastNameController,
                  Icons.person_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEditField(
            'University Name',
            _universityController,
            Icons.school_outlined,
          ),
          const SizedBox(height: 16),
          _buildEditField(
            'Course of Study',
            _courseController,
            Icons.book_outlined,
          ),
          const SizedBox(height: 16),
          _buildEditField(
            'Funding Source',
            _financialsController,
            Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6200EE)),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6200EE)),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatUI() {
    return Column(
      children: [
        _buildVoiceUI(),
        if (_finalReport == null && _isFinished) _buildGetReportButton(),
      ],
    );
  }

  Widget _buildVoiceUI() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Interviewer Avatar with Pulse
          Stack(
            alignment: Alignment.center,
            children: [
              // Pulse circles
              for (int i = 1; i <= 3; i++)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: _isListening ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    double scale = 1.0;
                    if (_isListening) {
                      // Normalize voice level (usually -20 to 0) to a positive scale
                      double level = (_voiceLevel + 20).clamp(0, 20) / 20.0;
                      scale = 1.0 + (level * 0.5 * i);
                    }
                    return Container(
                      width: 140 * scale,
                      height: 140 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6200EE).withValues(alpha: (0.05 / i)),
                      ),
                    );
                  },
                ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6200EE).withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Color(0xFF6200EE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _messages.isEmpty
                  ? 'Initializing...'
                  : (_messages.last.sender == 'bot'
                        ? _messages.last.text
                        : 'Listening...'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _lastWords.isEmpty ? 'Say something...' : _lastWords,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const Spacer(),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildVoiceControlButton(
                icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                label: 'Speaker',
                color: _isSpeakerOn ? const Color(0xFF6200EE) : Colors.grey,
                onTap: () {
                  setState(() {
                    _isSpeakerOn = !_isSpeakerOn;
                  });
                  if (!_isSpeakerOn) {
                    _tts.stop();
                  }
                },
              ),
              const SizedBox(width: 32),
              _buildVoiceControlButton(
                icon: _isListening ? Icons.mic : Icons.mic_off,
                label: 'Mic',
                color: _isListening ? Colors.green : Colors.grey,
                onTap: () {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
              ),
              const SizedBox(width: 32),
              _buildVoiceControlButton(
                icon: Icons.call_end,
                label: 'End Call',
                color: Colors.redAccent,
                onTap: () {
                  _stopListening();
                  _tts.stop();
                  setState(() {
                    _isFinished = true;
                  });
                  _generateFinalReport();
                },
              ),
            ],
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildVoiceControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color ?? Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color == null ? const Color(0xFF6200EE) : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGetReportButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6200EE).withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _generateFinalReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6200EE),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics_outlined),
                    SizedBox(width: 12),
                    Text(
                      'Get Detailed AI Report',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildReportUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interview Feedback',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Final analysis for your $_visaType simulation',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Overall Summary Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6200EE),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6200EE).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Automated VO Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _finalReport!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Text(
            'Response Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // List of individual evaluations
          ..._evaluations.map((eval) => _buildEvaluationCard(eval)),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2937),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Back to Tools',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(EvaluationResult eval) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  eval.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (eval.score >= 70 ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${eval.score}%',
                  style: TextStyle(
                    color: eval.score >= 70 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            eval.feedback,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          if (eval.improvements.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '💡 Recommendation:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 4),
            ...eval.improvements.map(
              (imp) => Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text('• $imp', style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
