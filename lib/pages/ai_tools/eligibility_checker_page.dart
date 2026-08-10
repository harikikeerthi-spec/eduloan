import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/rupee_amount_helper.dart';
import '../../services/ai_logic_service.dart';

class EligibilityCheckerPage extends StatefulWidget {
  const EligibilityCheckerPage({super.key});

  @override
  State<EligibilityCheckerPage> createState() => _EligibilityCheckerPageState();
}

class _EligibilityCheckerPageState extends State<EligibilityCheckerPage> {
  final _formKey = GlobalKey<FormState>();
  final _aiService = AiLogicService();

  // Controllers
  final _ageController = TextEditingController();
  final _creditController = TextEditingController();
  final _incomeController = TextEditingController();
  final _loanController = TextEditingController();

  // Dropdown Values
  String _employment = 'employed';
  String _study = 'masters';
  final String _maritalStatus = 'single';
  bool _coApplicant = false;
  bool _collateral = false;

  bool _isLoading = false;
  EligibilityResult? _result;

  @override
  void dispose() {
    _ageController.dispose();
    _creditController.dispose();
    _incomeController.dispose();
    _loanController.dispose();
    super.dispose();
  }

  Future<void> _checkEligibility() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      final creditScore = int.tryParse(_creditController.text) ?? 0;
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

      final dto = EligibilityCheckDto(
        age: int.parse(_ageController.text),
        credit: creditScore,
        income: double.parse(_incomeController.text),
        loan: double.parse(_loanController.text),
        employment: _employment,
        study: _study,
        maritalStatus: _maritalStatus,
        coApplicant: _coApplicant,
        collateral: _collateral,
      );

      try {
        final result = await _aiService.checkEligibility(dto);
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
          title: const Text(
            "Eligibility Checker",
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Find out if you qualify for a loan in seconds.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                if (_result != null) _buildResultCard(),
                _buildFormCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    Color badgeColor;
    Color textColor;

    if (_result!.status == 'eligible') {
      badgeColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green.shade700;
    } else if (_result!.status == 'borderline') {
      badgeColor = Colors.orange.withValues(alpha: 0.1);
      textColor = Colors.orange.shade700;
    } else {
      badgeColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI ANALYSIS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B7280),
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: textColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _result!.status.toUpperCase(),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Qualification Score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Text(
                '${_result!.score}%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _result!.score / 100,
              backgroundColor: Colors.black.withValues(alpha: 0.05),
              color: textColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _result!.summary,
            style: const TextStyle(
              height: 1.6,
              fontSize: 14,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              "Profile Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),
            _buildNumberField(
              "Age",
              "e.g. 24",
              Icons.person_outline,
              _ageController,
            ),
            const SizedBox(height: 20),
            _buildNumberField(
              "Credit Score",
              "e.g. 750",
              Icons.credit_score_outlined,
              _creditController,
            ),
            const SizedBox(height: 20),
            _buildNumberField(
              "Annual Income",
              "e.g. 50000",
              Icons.payments_outlined,
              _incomeController,
            ),
            const SizedBox(height: 20),
            _buildNumberField(
              "Loan Amount",
              "e.g. 25000",
              Icons.account_balance_outlined,
              _loanController,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            _buildDropdown(
              "Employment Status",
              _employment,
              const [
                DropdownMenuItem(value: 'employed', child: Text('Employed')),
                DropdownMenuItem(value: 'self', child: Text('Self-Employed')),
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(
                  value: 'unemployed',
                  child: Text('Unemployed'),
                ),
              ],
              (val) => setState(() => _employment = val!),
            ),
            const SizedBox(height: 20),
            _buildDropdown("Study Level", _study, const [
              DropdownMenuItem(
                value: 'undergrad',
                child: Text('Undergraduate'),
              ),
              DropdownMenuItem(value: 'masters', child: Text('Masters')),
              DropdownMenuItem(value: 'doctoral', child: Text('Doctoral')),
              DropdownMenuItem(value: 'diploma', child: Text('Diploma')),
            ], (val) => setState(() => _study = val!)),
            const SizedBox(height: 24),
            const Text(
              "Additional Info",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSwitch(
                    "Co-applicant",
                    _coApplicant,
                    (v) => setState(() => _coApplicant = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSwitch(
                    "Collateral",
                    _collateral,
                    (v) => setState(() => _collateral = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _checkEligibility,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF311B92),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Check Eligibility',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    final isAmountField = label.contains('Income') || label.contains('Loan') || label.contains('Amount') || label.contains('EMI') || label.contains('Fee') || label.contains('Salary');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF374151),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: isAmountField ? (v) => setState(() {}) : null,
            inputFormatters: isAmountField
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    IndianCurrencyFormatter(),
                  ]
                : null,
            validator: (v) => v!.isEmpty ? 'Required' : null,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.black.withValues(alpha: 0.3),
                fontSize: 14,
              ),
              border: InputBorder.none,
              suffixIcon: Icon(icon, color: Colors.black45, size: 20),
            ),
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

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF6200EA).withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? const Color(0xFF6200EA).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: value ? const Color(0xFF6200EA) : Colors.black54,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value ? "Yes" : "No",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: const Color(0xFF6200EA),
                  activeTrackColor: const Color(0xFF6200EA).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
