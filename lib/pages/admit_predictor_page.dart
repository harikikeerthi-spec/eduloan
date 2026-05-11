import 'package:flutter/material.dart';
import '../services/ai_logic_service.dart';
import '../widgets/mesh_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/glass_text_field.dart';

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
  final _moiMarksController = TextEditingController();
  final _moiInstitutionController = TextEditingController();

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
    _moiMarksController.dispose();
    _moiInstitutionController.dispose();
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
        'englishTestType': (_englishType == 'MOI')
            ? 'MOI'
            : (_englishScoreController.text.isEmpty ? 'None' : _englishType),
        'englishTestScore': _englishScoreController.text.isEmpty
            ? 0
            : double.parse(_englishScoreController.text),
        'experienceYears': _experienceYears,
        'researchPapers': _researchPapers,
        'programLevel': _programLevel,
        if (_englishType == 'MOI') ...{
          'moiIntermediateMarks': _moiMarksController.text.isNotEmpty
              ? double.parse(_moiMarksController.text)
              : 0,
          'moiInstitution': _moiInstitutionController.text,
        },
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
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Admit Predictor'),
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [if (_result != null) _buildResultCard(), _buildForm()],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    Color color;
    if (_result!.probability >= 80) {
      color = const Color(0xFF00C853); // Bright Green
    } else if (_result!.probability >= 50) {
      color = const Color(0xFFFFAB00); // Amber
    } else {
      color = const Color(0xFFD50000); // Red
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GlassCard(
        child: Column(
          children: [
            const Text(
              'Admission Probability',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildRadialProgress(_result!.probability, color),
            const SizedBox(height: 16),
            Text(
              _result!.university,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Noto Serif',
                color: Color(0xFF311B92),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'AI Analysis & Feedback:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            ..._result!.feedback.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: Color(0xFF6605C7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.7),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadialProgress(int percentage, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 12,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const Text(
              'Chance',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return GlassCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Start Your Journey",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Noto Serif',
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),
            GlassTextField(
              controller: _targetUniController,
              hintText: "Enter Target University",
              labelText: "Target University",
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GlassTextField(
                    controller: _gpaController,
                    hintText: "Enter GPA",
                    labelText: "GPA",
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
                  child: GlassTextField(
                    controller: _testScoreController,
                    hintText: "Optional",
                    labelText: "Score",
                    isNumber: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final val = double.tryParse(v);
                      if (val == null) return 'Invalid';
                      if (_testType == 'GRE' && (val < 260 || val > 340)) {
                        return '260-340';
                      }
                      if (_testType == 'GMAT' && (val < 200 || val > 800)) {
                        return '200-800';
                      }
                      if (_testType == 'SAT' && (val < 400 || val > 1600)) {
                        return '400-1600';
                      }
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
                    ['IELTS', 'TOEFL', 'PTE', 'Duolingo', 'MOI'],
                    (v) => setState(() => _englishType = v!),
                  ),
                ),
                if (_englishType != 'MOI') ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: GlassTextField(
                      controller: _englishScoreController,
                      hintText: "Score",
                      labelText: "Score",
                      isNumber: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final val = double.tryParse(v);
                        if (val == null) return 'Invalid';
                        if (_englishType == 'IELTS' && (val < 0 || val > 9)) {
                          return '0-9';
                        }
                        if (_englishType == 'TOEFL' && (val < 0 || val > 120)) {
                          return '0-120';
                        }
                        if (_englishType == 'PTE' && (val < 10 || val > 90)) {
                          return '10-90';
                        }
                        if (_englishType == 'Duolingo' &&
                            (val < 10 || val > 160)) {
                          return '10-160';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ],
            ),
            if (_englishType == 'MOI') ...[
              const SizedBox(height: 16),
              GlassTextField(
                controller: _moiMarksController,
                hintText: "Intermediate English Marks (Max 200)",
                labelText: "English Marks",
                isNumber: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final val = double.tryParse(v);
                  if (val == null) return 'Invalid';
                  if (val < 0 || val > 200) return 'Max 200';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GlassTextField(
                controller: _moiInstitutionController,
                hintText: "Previous Institution Name",
                labelText: "Institution",
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
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
                  selectedColor: const Color(0xFF6605C7),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.grey.shade300,
                    ),
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
            PrimaryButton(
              text: 'Predict Chance',
              onPressed: _predict,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
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
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
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
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(
                  Icons.remove,
                  color: Color(0xFF311B92),
                  size: 20,
                ),
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
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF311B92),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
