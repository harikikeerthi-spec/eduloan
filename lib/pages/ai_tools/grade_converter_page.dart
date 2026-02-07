import 'package:flutter/material.dart';
import '../../services/ai_logic_service.dart';
import '../../widgets/mesh_background.dart';

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
            ),
          );
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
          backgroundColor: Colors.transparent,
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
              if (_result != null) _buildResultCard(),
              _buildFormCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final analysis = _result!.analysis;
    final String strength = analysis['strength'];
    final List<String> recommendations = List<String>.from(
      analysis['recommendations'] ?? [],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC51162).withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFC51162).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strength.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC51162),
                  letterSpacing: 1.1,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Percentage', '${_result!.percentage}%'),
          _buildInfoRow('US GPA (4.0)', '${_result!.gpa}'),
          _buildInfoRow('CGPA (10.0)', '${_result!.cgpa}'),
          _buildInfoRow('Classification', _result!.classification),

          const Divider(height: 32),
          Text(
            analysis['competitiveness'],
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Recommendations:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFFC51162),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(rec, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC51162).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown("Input Type", _inputType, const [
              DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
              DropdownMenuItem(value: 'marks', child: Text('Marks (x/y)')),
              DropdownMenuItem(value: 'gpa', child: Text('GPA (4.0)')),
              DropdownMenuItem(value: 'cgpa', child: Text('CGPA (10.0)')),
              DropdownMenuItem(
                value: 'letterGrade',
                child: Text('Letter Grade (A, B+)'),
              ),
            ], (val) => setState(() => _inputType = val!)),
            const SizedBox(height: 16),

            _buildInputField(
              "Input Value",
              _inputType == 'letterGrade' ? "e.g. A+" : "e.g. 85",
              _valueController,
              isNumber: _inputType != 'letterGrade',
            ),
            const SizedBox(height: 16),

            if (_inputType == 'marks')
              _buildInputField(
                "Total Marks",
                "e.g. 100",
                _totalMarksController,
                isNumber: true,
              ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _analyzeGrades,
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
                        'Analyze Grades',
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
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
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
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            onChanged: (val) {
              if (!isNumber) {
                _valueController.value = _valueController.value.copyWith(
                  text: val.toUpperCase(),
                  selection: TextSelection.collapsed(offset: val.length),
                );
              }
            },
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!isNumber && double.tryParse(v) != null) {
                return 'Please enter a letter grade (e.g. A, B+)';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
