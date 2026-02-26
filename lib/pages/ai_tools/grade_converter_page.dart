import 'package:flutter/material.dart';
import '../../services/ai_logic_service.dart';
import '../../widgets/primary_button.dart';

class GradeConverterPage extends StatefulWidget {
  const GradeConverterPage({super.key});

  @override
  State<GradeConverterPage> createState() => _GradeConverterPageState();
}

class _GradeConverterPageState extends State<GradeConverterPage> {
  final _formKey = GlobalKey<FormState>();
  final _aiService = AiLogicService();

  final _valueController = TextEditingController();
  final _totalMarksController = TextEditingController();

  String _inputType = 'percentage';
  bool _isLoading = false;
  GradeConversionResult? _result;

  @override
  void dispose() {
    _valueController.dispose();
    _totalMarksController.dispose();
    super.dispose();
  }

  Future<void> _analyzeGrades() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      setState(() {
        _isLoading = true;
        _result = null;
      });

      final input = GradeConversionInput(
        inputType: _inputType,
        inputValue: _inputType == 'letterGrade'
            ? _valueController.text
            : double.parse(_valueController.text),
        totalMarks: _totalMarksController.text.isNotEmpty
            ? double.parse(_totalMarksController.text)
            : null,
        outputType: 'percentage', // Default base for logic
      );

      try {
        final result = await _aiService.convertGrade(input);
        if (mounted) {
          setState(() {
            _result = result;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${e.toString().replaceAll("Exception: ", "")}',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Grade AI Analyzer',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_result != null) _buildResultSection(),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Input Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDropdown(
                      "Input Type",
                      _inputType,
                      const [
                        DropdownMenuItem(
                          value: 'percentage',
                          child: Text('Percentage'),
                        ),
                        DropdownMenuItem(
                          value: 'marks',
                          child: Text('Marks (x/y)'),
                        ),
                        DropdownMenuItem(
                          value: 'gpa',
                          child: Text('GPA (4.0)'),
                        ),
                        DropdownMenuItem(
                          value: 'cgpa',
                          child: Text('CGPA (10.0)'),
                        ),
                        DropdownMenuItem(
                          value: 'letterGrade',
                          child: Text('Letter Grade (A, B+)'),
                        ),
                      ],
                      (val) => setState(() => _inputType = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _valueController,
                      decoration: InputDecoration(
                        hintText: _inputType == 'letterGrade'
                            ? "e.g. A+"
                            : "e.g. 85",
                        labelText: "Input Value",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                      ),
                      keyboardType: _inputType == 'letterGrade'
                          ? TextInputType.text
                          : const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                      onChanged: (val) {
                        if (_inputType == 'letterGrade' && val.isNotEmpty) {
                          final upper = val.toUpperCase();
                          if (upper != val) {
                            _valueController.value = _valueController.value
                                .copyWith(
                                  text: upper,
                                  selection: TextSelection.collapsed(
                                    offset: upper.length,
                                  ),
                                );
                          }
                        }
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (_inputType == 'letterGrade') {
                          if (double.tryParse(v) != null) {
                            return 'Enter a letter grade';
                          }
                        } else {
                          if (double.tryParse(v) == null) {
                            return 'Enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    if (_inputType == 'marks') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _totalMarksController,
                        decoration: InputDecoration(
                          hintText: "e.g. 100",
                          labelText: "Total Marks",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: 'Analyze Grades',
                      onPressed: _analyzeGrades,
                      isLoading: _isLoading,
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

  Widget _buildResultSection() {
    final analysis = _result!.analysis;
    final strength = analysis['strength'] ?? 'N/A';
    final recommendations = List<String>.from(
      analysis['recommendations'] ?? [],
    );

    return Column(
      children: [
        // Main Result Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Analysis Result',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0C389).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0C389).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insights,
                      size: 20,
                      color: Color(0xFF8D6E63),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strength,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5D4037),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildScoreBadge(
                    'Percentage',
                    '${_result!.percentage}%',
                    const Color(0xFF4CAF50),
                  ),
                  _buildScoreBadge(
                    'US GPA',
                    '${_result!.gpa}',
                    const Color(0xFF2196F3),
                  ),
                  _buildScoreBadge(
                    'CGPA',
                    '${_result!.cgpa}',
                    const Color(0xFF9C27B0),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "Recommendations",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...recommendations.map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Color(0xFF6605C7),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rec,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.7),
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
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildScoreBadge(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Text(
              value.replaceAll('%', ''),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              dropdownColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
