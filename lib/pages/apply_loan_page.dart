import 'package:flutter/material.dart';
import '../widgets/mesh_background.dart';
import '../widgets/institute_selection_modal.dart';
import '../data/institutes_data.dart';

class ApplyLoanPage extends StatefulWidget {
  const ApplyLoanPage({super.key});

  @override
  State<ApplyLoanPage> createState() => _ApplyLoanPageState();
}

class _ApplyLoanPageState extends State<ApplyLoanPage> {
  int _currentStep = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _instituteController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _tenureController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _instituteController.dispose();
    _courseController.dispose();
    _amountController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  Future<void> _showInstituteSelection() async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const InstituteSelectionModal(),
    );

    if (result != null && result is Map) {
      final Institute institute = result['institute'];
      final String course = result['course'];

      setState(() {
        _instituteController.text = institute.name;
        _courseController.text = course;
      });
    }
  }

  void _submitApplication() {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _instituteController.text.isEmpty ||
        _courseController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _tenureController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Mock submission
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Application Submitted Successfully!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFF311B92),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Apply for Loan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer for balance
                  ],
                ),
              ),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Colors.transparent,
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF311B92),
                      secondary: Color(0xFF311B92),
                      surface: Colors.white,
                    ),
                  ),
                  child: Stepper(
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepContinue: () {
                      if (_currentStep < 2) {
                        setState(() => _currentStep += 1);
                      } else {
                        _submitApplication();
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep -= 1);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: details.onStepContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF311B92),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: Text(
                                  _currentStep == 2 ? 'Submit' : 'Continue',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (_currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: details.onStepCancel,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF311B92),
                                    side: const BorderSide(
                                      color: Color(0xFF311B92),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text(
                                    'Back',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      Step(
                        title: const Text(
                          'Personal Information',
                          style: TextStyle(
                            color: Colors.black, // Visible on background
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: _buildStepContainer(
                          children: [
                            _buildTextInput(
                              hint: 'Full Name',
                              icon: Icons.person_outline,
                              controller: _nameController,
                            ),
                            const SizedBox(height: 16),
                            _buildTextInput(
                              hint: 'Phone Number',
                              icon: Icons.phone_outlined,
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            _buildTextInput(
                              hint: 'Email Address',
                              icon: Icons.email_outlined,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ],
                        ),
                        isActive: _currentStep >= 0,
                        state: _currentStep > 0
                            ? StepState.complete
                            : StepState.indexed,
                      ),
                      Step(
                        title: const Text(
                          'Educational Details',
                          style: TextStyle(
                            color: Colors.black, // Visible on background
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: _buildStepContainer(
                          children: [
                            _buildReadOnlyInput(
                              hint: 'Select Institute',
                              icon: Icons.account_balance_outlined,
                              onTap: _showInstituteSelection,
                              controller: _instituteController,
                            ),
                            const SizedBox(height: 16),
                            _buildReadOnlyInput(
                              hint: 'Select Course',
                              icon: Icons.school_outlined,
                              onTap: _showInstituteSelection,
                              controller: _courseController,
                            ),
                          ],
                        ),
                        isActive: _currentStep >= 1,
                        state: _currentStep > 1
                            ? StepState.complete
                            : StepState.indexed,
                      ),
                      Step(
                        title: const Text(
                          'Loan Requirements',
                          style: TextStyle(
                            color: Colors.black, // Visible on background
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: _buildStepContainer(
                          children: [
                            _buildTextInput(
                              hint: 'Loan Amount (₹)',
                              icon: Icons.currency_rupee,
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildTextInput(
                              hint: 'Tenure (Months)',
                              icon: Icons.calendar_today_outlined,
                              controller: _tenureController,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                        isActive: _currentStep >= 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextInput({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF311B92).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF311B92).withValues(alpha: 0.05),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
          border: InputBorder.none,
          suffixIcon: Icon(
            icon,
            color: Color(0xFF311B92).withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyInput({
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    required TextEditingController controller,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF311B92).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF311B92).withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                controller.text.isEmpty ? hint : controller.text,
                style: TextStyle(
                  color: controller.text.isEmpty
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.black, // Solid black text
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              icon,
              color: const Color(0xFF311B92).withValues(alpha: 0.5),
            ), // Deep purple icon
          ],
        ),
      ),
    );
  }
}
