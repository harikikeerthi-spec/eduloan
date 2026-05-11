import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_logic_service.dart';
import '../widgets/mesh_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/glass_text_field.dart';

class SopWriterPage extends StatefulWidget {
  const SopWriterPage({super.key});

  @override
  State<SopWriterPage> createState() => _SopWriterPageState();
}

class _SopWriterPageState extends State<SopWriterPage> {
  final _sopController = TextEditingController();
  final _aiService = AiLogicService();
  bool _isLoading = false;
  SopAnalysisResult? _result;

  @override
  void dispose() {
    _sopController.dispose();
    super.dispose();
  }

  Future<void> _analyzeSop() async {
    if (_sopController.text.trim().length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least 50 chars')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final result = await _aiService.analyzeSop(_sopController.text);
      setState(() {
        _result = result;
      });
    } catch (e) {
      debugPrint('SOP Analysis Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    if (_result != null) {
      final text =
          "SOP Analysis Score: ${_result!.totalScore}\nQuality: ${_result!.quality}\nSummary: ${_result!.summary}";
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Analysis copied!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('AI SOP Assistant'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Noto Serif',
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1F2937),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_result != null)
              IconButton(
                icon: const Icon(Icons.copy, color: Color(0xFF1F2937)),
                onPressed: _copyToClipboard,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_result == null) ...[
                GlassCard(
                  child: Column(
                    children: [
                      const Text(
                        'Write or paste your Statement of Purpose below. Our AI will analyze it for clarity, impact, and structure.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassTextField(
                        controller: _sopController,
                        hintText: 'Start typing your SOP here...',
                        maxLines: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Analyze SOP',
                  onPressed: _analyzeSop,
                  isLoading: _isLoading,
                ),
              ] else
                _buildResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      children: [
        _buildScoreCard(),
        const SizedBox(height: 24),
        _buildAnalysisList(),
        const SizedBox(height: 24),
        if (_result!.weakAreas.isNotEmpty) _buildWeakAreas(),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _result = null),
            icon: const Icon(Icons.refresh),
            label: const Text('Analyze Again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF311B92),
              side: const BorderSide(color: Color(0xFF311B92)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    Color scoreColor = Colors.red;
    if (_result!.totalScore >= 80) {
      scoreColor = const Color(0xFF00C853);
    } else if (_result!.totalScore >= 60) {
      scoreColor = const Color(0xFFFFAB00);
    }

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SOP Quality',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _result!.quality.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _result!.totalScore.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _result!.summary,
            style: const TextStyle(
              height: 1.5,
              fontSize: 15,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisList() {
    return Column(
      children: _result!.categories.map((cat) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    cat['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Text(
                  '${cat['score']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF311B92),
                  ),
                ),
                const Text('/25', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeakAreas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Improvements Needed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        ..._result!.weakAreas.map((area) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          area['issue']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    area['recommendation']!,
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
