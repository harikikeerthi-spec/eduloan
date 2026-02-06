import 'package:flutter/material.dart';
import '../services/ai_logic_service.dart';
import '../widgets/mesh_background.dart';

class UniversityComparePage extends StatefulWidget {
  const UniversityComparePage({super.key});

  @override
  State<UniversityComparePage> createState() => _UniversityComparePageState();
}

class _UniversityComparePageState extends State<UniversityComparePage> {
  final AiLogicService _aiService = AiLogicService();
  bool _isLoading = false;
  final TextEditingController _uni1Controller = TextEditingController(
    text: 'Harvard University',
  );
  final TextEditingController _uni2Controller = TextEditingController(
    text: 'Stanford University',
  );

  @override
  void dispose() {
    _uni1Controller.dispose();
    _uni2Controller.dispose();
    super.dispose();
  }

  Map<String, UniversityData>? _comparisonData;
  String? _error;

  // Removed hardcoded list and format helper since we act on live input

  Future<void> _compare() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _comparisonData = null;
    });

    try {
      final result = await _aiService.compareUniversities(
        _uni1Controller.text.trim(),
        _uni2Controller.text.trim(),
      );
      setState(() {
        _comparisonData = result;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString().replaceAll("Exception:", "")}';
      });
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('University Compare'),
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildVersusHeader(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _compare,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF311B92),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF311B92).withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'COMPARE NOW',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_error != null)
                  _buildError()
                else if (_comparisonData != null)
                  _buildComparisonResults(_comparisonData!),
              ],
            ),
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
            color: const Color(0xFFFF9800),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUniSelector(int index, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: index == 1
                  ? const Color(0xFFE8EAF6)
                  : const Color(0xFFFBE9E7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance,
              color: index == 1
                  ? const Color(0xFF311B92)
                  : const Color(0xFFFF5722),
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Enter University',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  if (index == 1) {
                    _uni1Controller.clear();
                  } else {
                    _uni2Controller.clear();
                  }
                },
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD32F2F)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonResults(Map<String, UniversityData> data) {
    final u1 = data['uni1']!;
    final u2 = data['uni2']!;

    return Column(
      children: [
        _buildMetricCard(
          'Global Ranking',
          u1.rank,
          u2.rank,
          icon: Icons.emoji_events_outlined,
          color: const Color(0xFF311B92),
          lowerIsBetter: true,
        ),
        _buildMetricCard(
          'Annual Tuition',
          u1.tuition,
          u2.tuition,
          icon: Icons.payments_outlined,
          color: const Color(0xFF009688),
          lowerIsBetter: true,
        ),
        _buildMetricCard(
          'Acceptance Rate',
          u1.rate,
          u2.rate,
          icon: Icons.how_to_reg_outlined,
          color: const Color(0xFFC51162),
          lowerIsBetter:
              false, // Higher is "easier", but typically "better" prestige is lower. Context dependent.
        ),
        _buildMetricCard(
          'Median Salary',
          u1.salary,
          u2.salary,
          icon: Icons.attach_money,
          color: const Color(0xFFFF9800),
          lowerIsBetter: false,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Location Comparison',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF311B92),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          u1.loc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[200]),
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFFF5722),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          u2.loc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String v1,
    String v2, {
    required IconData icon,
    required Color color,
    required bool lowerIsBetter,
  }) {
    // Basic logic to determine visual winner if possible
    // Note: Parsing strings like "$57,000" or "#1" is tricky without robust logic.
    // For now, we will just display data elegantly.

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
    );
  }
}
