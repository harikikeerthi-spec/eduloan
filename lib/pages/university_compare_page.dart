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
          title: const Text('Compare Universities'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1F2937),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Noto Serif',
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildVersusHeader(),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Compare Universities',
                onPressed: _compare,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 32),
              if (_result != null) _buildComparisonResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersusHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildUniSelector(1, _uni1Controller)),
            const SizedBox(width: 40), // Space for VS badge
            Expanded(child: _buildUniSelector(2, _uni2Controller)),
          ],
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUniSelector(int index, TextEditingController controller) {
    return GlassTextField(
      controller: controller,
      hintText: 'University $index',
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
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    v1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.grey[300]),
                Expanded(
                  child: Text(
                    v2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
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
