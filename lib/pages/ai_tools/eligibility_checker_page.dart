import 'package:flutter/material.dart';
import '../../services/ai_logic_service.dart';
import '../../widgets/mesh_background.dart';

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
  String _maritalStatus = 'single';
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

      setState(() {
        _isLoading = true;
        _result = null;
      });

      final dto = EligibilityCheckDto(
        age: int.parse(_ageController.text),
        credit: int.parse(_creditController.text),
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Eligibility Checker',
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
    Color badgeColor;
    Color textColor;

    if (_result!.status == 'eligible') {
      badgeColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
    } else if (_result!.status == 'borderline') {
      badgeColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
    } else {
      badgeColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6200EA).withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6200EA).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Snapshot',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _result!.status.toUpperCase(),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Eligibility Score: ',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                '${_result!.score}/100',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _result!.score / 100,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            color: const Color(0xFF6200EA),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Text(
            _result!.summary,
            style: const TextStyle(
              height: 1.5,
              fontSize: 14,
              color: Colors.black87,
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
            color: const Color(0xFF6200EA).withValues(alpha: 0.08),
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
            _buildNumberField("Age", "e.g. 24", Icons.person, _ageController),
            const SizedBox(height: 16),
            _buildNumberField(
              "Credit Score",
              "e.g. 750",
              Icons.credit_score,
              _creditController,
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              "Annual Income (\u0024)",
              "e.g. 50000",
              Icons.attach_money,
              _incomeController,
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              "Loan Amount (\u0024)",
              "e.g. 25000",
              Icons.account_balance_wallet,
              _loanController,
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            _buildDropdown("Study Level", _study, const [
              DropdownMenuItem(
                value: 'undergrad',
                child: Text('Undergraduate'),
              ),
              DropdownMenuItem(value: 'masters', child: Text('Masters')),
              DropdownMenuItem(value: 'doctoral', child: Text('Doctoral')),
              DropdownMenuItem(value: 'diploma', child: Text('Diploma')),
            ], (val) => setState(() => _study = val!)),
            const SizedBox(height: 16),

            _buildDropdown(
              "Marital Status",
              _maritalStatus,
              const [
                DropdownMenuItem(value: 'single', child: Text('Single')),
                DropdownMenuItem(value: 'married', child: Text('Married')),
              ],
              (val) => setState(() => _maritalStatus = val!),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildSwitch(
                    "Co-applicant",
                    _coApplicant,
                    (v) => setState(() => _coApplicant = v),
                  ),
                ),
                const SizedBox(width: 16),
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
                  elevation: 4,
                  shadowColor: const Color(0xFF311B92).withOpacity(0.4),
                ),
                child: const Text(
                  'Check Eligibility',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              suffixIcon: Icon(icon, color: Colors.grey),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF6200EA).withValues(alpha: 0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? const Color(0xFF6200EA).withValues(alpha: 0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: value ? const Color(0xFF6200EA) : Colors.black54,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value ? "Yes" : "No",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF6200EA),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
