import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_logic_service.dart';
import '../widgets/mesh_background.dart';
import '../widgets/rupee_amount_helper.dart';

class LoanEligibilityCheckerPage extends StatefulWidget {
  const LoanEligibilityCheckerPage({super.key});

  @override
  State<LoanEligibilityCheckerPage> createState() =>
      _LoanEligibilityCheckerPageState();
}

class _LoanEligibilityCheckerPageState
    extends State<LoanEligibilityCheckerPage> {
  final _formKey = GlobalKey<FormState>();
  final _aiService = AiLogicService();

  // Controllers
  final _ageController = TextEditingController();
  final _creditScoreController = TextEditingController();
  final _incomeController = TextEditingController();
  final _loanAmountController = TextEditingController();

  // Dropdown / Boolean Values
  String _employment = 'student';
  String _studyLevel = 'masters';
  bool _coApplicant = true;
  bool _collateral = false;

  bool _isLoading = false;
  EligibilityResult? _result;

  @override
  void dispose() {
    _ageController.dispose();
    _creditScoreController.dispose();
    _incomeController.dispose();
    _loanAmountController.dispose();
    super.dispose();
  }

  Future<void> _checkEligibility() async {
    if (_formKey.currentState!.validate()) {
      final creditScore = int.tryParse(_creditScoreController.text) ?? 0;
      if (creditScore < 700) {
        setState(() {
          _isLoading = false;
          _result = EligibilityResult(
            score: ((creditScore / 700) * 40).clamp(10, 45).toInt(),
            status: 'unlikely',
            ratio: 0.0,
            rateRange: 'N/A',
            coverage: '0%',
            summary:
                'CIBIL score below 700 ($creditScore) is NOT eligible for loan approval. Minimum 700 CIBIL score is required by financial institutions.',
          );
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _result = null;
      });

      try {
        final dto = EligibilityCheckDto(
          age: int.parse(_ageController.text),
          credit: creditScore,
          income: double.parse(_incomeController.text),
          loan: double.parse(_loanAmountController.text),
          employment: _employment,
          study: _studyLevel,
          maritalStatus: 'single', // Default or add UI control if needed
          coApplicant: _coApplicant,
          collateral: _collateral,
        );

        final result = await _aiService.checkEligibility(dto);
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
        title: const Text('Eligibility Check'),
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
    if (_result!.score >= 80) {
      color = Colors.green;
    } else if (_result!.score >= 50) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status', style: TextStyle(color: Colors.grey)),
                  Text(
                    _result!.status.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${_result!.score}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          _buildResultItem('Interest Rate', _result!.rateRange),
          _buildResultItem('Max Coverage', _result!.coverage),
          _buildResultItem(
            'Income/Loan Ratio',
            _result!.ratio.toStringAsFixed(2),
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _result!.summary,
              style: const TextStyle(
                height: 1.5,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    "Age",
                    _ageController,
                    isNumber: true,
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      final age = int.tryParse(v);
                      if (age == null || age < 18 || age > 40) return '18-40';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    "Credit Score",
                    _creditScoreController,
                    isNumber: true,
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      final s = int.tryParse(v);
                      if (s == null || s < 300 || s > 900) return '300-900';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              "Annual Income",
              _incomeController,
              isNumber: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              "Required Loan",
              _loanAmountController,
              isNumber: true,
            ),
            const SizedBox(height: 16),
            _buildDropdown("Employment", _employment, [
              'employed',
              'self',
              'student',
              'unemployed',
            ], (v) => setState(() => _employment = v!)),
            const SizedBox(height: 16),
            _buildDropdown("Study Level", _studyLevel, [
              'undergrad',
              'masters',
              'doctoral',
              'diploma',
            ], (v) => setState(() => _studyLevel = v!)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text(
                "Co-Applicant Available?",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              value: _coApplicant,
              activeThumbColor: const Color(0xFF311B92),
              activeTrackColor: const Color(0xFF311B92).withValues(alpha: 0.5),
              onChanged: (v) => setState(() => _coApplicant = v),
            ),
            SwitchListTile(
              title: const Text(
                "Collateral Available?",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              value: _collateral,
              activeThumbColor: const Color(0xFF311B92),
              activeTrackColor: const Color(0xFF311B92).withValues(alpha: 0.5),
              onChanged: (v) => setState(() => _collateral = v),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkEligibility,
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
                        'Check Eligibility',
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
    String? Function(String?)? validator,
  }) {
    final isAmountField = isNumber && (label.contains('Income') || label.contains('Loan') || label.contains('Amount') || label.contains('EMI') || label.contains('Fee') || label.contains('Salary'));

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
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            onChanged: isAmountField ? (v) => setState(() {}) : null,
            inputFormatters: isAmountField
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    IndianCurrencyFormatter(),
                  ]
                : null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            validator:
                validator ??
                (v) {
                  return v!.isEmpty ? 'Required' : null;
                },
          ),
        ),
        if (isAmountField)
          RupeeAmountHelperCard(
            amountText: controller.text,
            label: label,
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
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
