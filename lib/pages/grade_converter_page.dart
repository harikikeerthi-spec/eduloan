import 'package:flutter/material.dart';
import '../services/ai_logic_service.dart';
import '../widgets/mesh_background.dart';

class GradeConverterPage extends StatefulWidget {
  const GradeConverterPage({super.key});

  @override
  State<GradeConverterPage> createState() => _GradeConverterPageState();
}

class _GradeConverterPageState extends State<GradeConverterPage> {
  final _formKey = GlobalKey<FormState>();
  final _aiService = AiLogicService();
  final _inputController = TextEditingController();
  final _totalMarksController = TextEditingController();

  String _inputType =
      'percentage'; // 'letterGrade', 'percentage', 'gpa', 'cgpa', 'marks'
  String _outputType = 'gpa'; // 'letterGrade', 'percentage', 'gpa', 'cgpa'
  bool _isLoading = false;
  GradeConversionResult? _result;

  @override
  void dispose() {
    _inputController.dispose();
    _totalMarksController.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _result = null;
      });

      try {
        final input = GradeConversionInput(
          inputType: _inputType,
          inputValue:
              _inputController.text, // Parsing handled by service or backend
          totalMarks:
              _inputType == 'marks' ||
                  _inputType == 'percentage' &&
                      _totalMarksController.text.isNotEmpty
              ? double.tryParse(_totalMarksController.text)
              : null,
          outputType: _outputType,
          gradingSystem: 'Standard',
        );

        final result = await _aiService.convertGrade(input);
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
        title: const Text('Grade Converter'),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Converted Result',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _result!.outputGrade,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Color(0xFF311B92),
            ),
          ),
          if (_result!.analysis['strength'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _result!.analysis['strength'],
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'International Equivalents:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ..._result!.internationalEquivalent.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: const TextStyle(color: Colors.grey)),
                  Text(
                    e.value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
        autovalidateMode:
            AutovalidateMode.onUserInteraction, // Enable auto validation
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown("Input Type", _inputType, [
              'percentage',
              'gpa',
              'cgpa',
              'marks',
              'letterGrade',
            ], (v) => setState(() => _inputType = v!)),
            const SizedBox(height: 16),
            _buildTextField(
              "Value",
              _inputController,
              isNumber: _inputType != 'letterGrade',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (_inputType != 'letterGrade') {
                  final val = double.tryParse(v);
                  if (val == null) return 'Invalid number';
                  // Adding client-side limits here as well
                  if (_inputType == 'percentage' && (val < 0 || val > 100))
                    return '0-100';
                  if (_inputType == 'gpa' && (val < 0 || val > 4.0))
                    return '0-4.0';
                  if (_inputType == 'cgpa' && (val < 0 || val > 10.0))
                    return '0-10.0';

                  // Check marks vs total marks
                  if (_inputType == 'marks' &&
                      _totalMarksController.text.isNotEmpty) {
                    final total = double.tryParse(_totalMarksController.text);
                    if (total != null && val > total) {
                      return 'Cannot exceed Total Marks ($total)';
                    }
                  }
                }
                return null;
              },
            ),
            if (_inputType == 'marks' || _inputType == 'percentage') ...[
              const SizedBox(height: 16),
              _buildTextField(
                "Total Marks (Optional)",
                _totalMarksController,
                isNumber: true,
                hint: "100",
                validator: (v) {
                  // If marks/percentage is entered but total marks is weird?
                  // If input type is percentage, convert to marks? No.
                  // Just basic number check here.
                  if (v != null && v.isNotEmpty) {
                    final val = double.tryParse(v);
                    if (val == null) return 'Invalid';
                    if (val <= 0) return '> 0';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDropdown("Convert To", _outputType, [
              'gpa',
              'cgpa',
              'percentage',
              'letterGrade',
            ], (v) => setState(() => _outputType = v!)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _convert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF311B92),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Convert Grade',
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
            validator: validator,
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
}
