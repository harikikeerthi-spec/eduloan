import 'package:flutter/material.dart';
import '../services/ai_logic_service.dart';
import '../widgets/mesh_background.dart';

class AdmitPredictorPage extends StatefulWidget {
  const AdmitPredictorPage({super.key});

  @override
  State<AdmitPredictorPage> createState() => _AdmitPredictorPageState();
}

class _AdmitPredictorPageState extends State<AdmitPredictorPage> {
  final _formKey = GlobalKey<FormState>();
  final _aiService = AiLogicService();

  // Controllers
  final _targetUniController = TextEditingController();
  final _gpaController = TextEditingController();
  final _testScoreController = TextEditingController();
  final _englishScoreController = TextEditingController();

  // Dropdown Values
  double _gpaScale = 4.0;
  String _testType = 'GRE';
  String _englishType = 'IELTS';
  String _programLevel = 'Masters';
  int _experienceYears = 0;
  int _researchPapers = 0;

  bool _isLoading = false;
  AdmitPredictionResult? _result;

  @override
  void dispose() {
    _targetUniController.dispose();
    _gpaController.dispose();
    _testScoreController.dispose();
    _englishScoreController.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _result = null;
      });

      final profile = {
        'targetUniversity': _targetUniController.text,
        'gpa': double.parse(_gpaController.text),
        'gpaScale': _gpaScale.toInt(),
        'testScoreType': _testScoreController.text.isEmpty ? 'None' : _testType,
        'testScore': _testScoreController.text.isEmpty
            ? 0
            : double.parse(_testScoreController.text),
        'englishTestType': _englishScoreController.text.isEmpty
            ? 'None'
            : _englishType,
        'englishTestScore': _englishScoreController.text.isEmpty
            ? 0
            : double.parse(_englishScoreController.text),
        'experienceYears': _experienceYears,
        'researchPapers': _researchPapers,
        'programLevel': _programLevel,
      };

      try {
        final result = await _aiService.predictAdmission(profile);
        setState(() {
          _result = result;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Admit Predictor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 20,
          fontWeight: FontWeight.bold,
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
              children: [if (_result != null) _buildResultCard(), _buildForm()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    Color color;
    if (_result!.probability >= 80)
      color = Colors.green;
    else if (_result!.probability >= 50)
      color = Colors.orange;
    else
      color = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Admission Probability',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '${_result!.probability}%',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            _result!.university,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'AI Feedback:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ..._result!.feedback.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f, style: TextStyle(color: Colors.grey[800])),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField("Target University", _targetUniController),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    "GPA",
                    _gpaController,
                    isNumber: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null) return 'Invalid number';
                      if (val < 0 || val > _gpaScale) {
                        return '0 - $_gpaScale';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    "Scale",
                    _gpaScale.toString(),
                    ['4.0', '10.0'],
                    (v) => setState(() => _gpaScale = double.parse(v!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown("Test Type", _testType, [
                    'GRE',
                    'GMAT',
                    'SAT',
                  ], (v) => setState(() => _testType = v!)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    "Score",
                    _testScoreController,
                    isNumber: true,
                    hint: "Optional",
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final val = double.tryParse(v);
                      if (val == null) return 'Invalid';
                      if (_testType == 'GRE' && (val < 260 || val > 340))
                        return '260-340';
                      if (_testType == 'GMAT' && (val < 200 || val > 800))
                        return '200-800';
                      if (_testType == 'SAT' && (val < 400 || val > 1600))
                        return '400-1600';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    "English Test",
                    _englishType,
                    ['IELTS', 'TOEFL'],
                    (v) => setState(() => _englishType = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    "Score",
                    _englishScoreController,
                    isNumber: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null) return 'Invalid';
                      if (_englishType == 'IELTS' && (val < 0 || val > 9))
                        return '0-9';
                      if (_englishType == 'TOEFL' && (val < 0 || val > 120))
                        return '0-120';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Program Level",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Undergraduate', 'Masters', 'PhD', 'MBA'].map((level) {
                final isSelected = _programLevel == level;
                return ChoiceChip(
                  label: Text(level),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _programLevel = level);
                  },
                  selectedColor: const Color(0xFF311B92),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCounter(
                    "Work Exp (Yrs)",
                    _experienceYears,
                    (v) => setState(() => _experienceYears = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCounter(
                    "Papers/Projects",
                    _researchPapers,
                    (v) => setState(() => _researchPapers = v),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _predict,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF311B92),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF311B92).withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Predict Chance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            validator:
                validator ??
                (v) {
                  if (hint == "Optional") return null;
                  return v!.isEmpty ? 'Required' : null;
                },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounter(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => onChanged(value > 0 ? value - 1 : 0),
              child: const Icon(
                Icons.remove_circle_outline,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$value',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => onChanged(value + 1),
              child: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF311B92),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
