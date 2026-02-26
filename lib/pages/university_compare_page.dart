import 'package:flutter/material.dart';
import '../services/ai_logic_service.dart';
import '../widgets/mesh_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/glass_text_field.dart';

class UniversityComparePage extends StatefulWidget {
  const UniversityComparePage({super.key});

  @override
  State<UniversityComparePage> createState() => _UniversityComparePageState();
}

class _UniversityComparePageState extends State<UniversityComparePage> {
  final _uni1Controller = TextEditingController();
  final _uni2Controller = TextEditingController();
  final _aiService = AiLogicService();

  bool _isLoading = false;
  Map<String, UniversityData>? _result;

  @override
  void dispose() {
    _uni1Controller.dispose();
    _uni2Controller.dispose();
    super.dispose();
  }

  Future<void> _compare() async {
    if (_uni1Controller.text.isEmpty || _uni2Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both university names')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final result = await _aiService.compareUniversities(
        _uni1Controller.text,
        _uni2Controller.text,
      );
      if (mounted) {
        setState(() {
          _result = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll("Exception: ", "")}',
            ),
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

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('University Compare'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1F2937),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Noto Serif',
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              _buildVersusHeader(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Compare Selection',
                  onPressed: _compare,
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(height: 40),
              if (_result != null) _buildComparisonResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersusHeader() {
    return Column(
      children: [
        Row(children: [Expanded(child: _buildUniSelector(1, _uni1Controller))]),
        const SizedBox(height: 16),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.9),
            border: Border.all(
              color: const Color(0xFF6200EA).withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6200EA).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'VS',
              style: TextStyle(
                color: Color(0xFF6200EA),
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: _buildUniSelector(2, _uni2Controller))]),
      ],
    );
  }

  Widget _buildUniSelector(int index, TextEditingController controller) {
    return GlassTextField(
      controller: controller,
      hintText: 'Enter University $index Name...',
      labelText: 'University $index',
    );
  }

  Widget _buildComparisonResult() {
    final uni1 = _result!['uni1']!;
    final uni2 = _result!['uni2']!;

    return Column(
      children: [
        _buildMetricCard(
          "Global Ranking",
          uni1.rank,
          uni2.rank,
          Icons.emoji_events_outlined,
          Colors.amber,
        ),
        _buildMetricCard(
          "Acceptance Rate",
          uni1.rate,
          uni2.rate,
          Icons.fact_check_outlined,
          Colors.green,
        ),
        _buildMetricCard(
          "Avg Tuition (USD)",
          uni1.tuition,
          uni2.tuition,
          Icons.attach_money,
          Colors.blue,
        ),
        _buildMetricCard(
          "Salary",
          uni1.salary,
          uni2.salary,
          Icons.work_outline,
          Colors.purple,
        ),
        _buildMetricCard(
          "Location",
          uni1.loc,
          uni2.loc,
          Icons.location_on_outlined,
          Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String v1,
    String v2,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        v1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'University 1',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.grey.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        v2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'University 2',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
