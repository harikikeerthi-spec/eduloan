import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../widgets/mesh_background.dart';
import '../widgets/institute_selection_modal.dart';
import '../data/institutes_data.dart';
import '../services/loan_service.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart';

class ApplyLoanPage extends StatefulWidget {
  const ApplyLoanPage({super.key});

  @override
  State<ApplyLoanPage> createState() => _ApplyLoanPageState();
}

class _ApplyLoanPageState extends State<ApplyLoanPage> {
  int _currentStep = 0;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _instituteController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _loanTypeController = TextEditingController(
    text: 'Education Loan',
  );
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _tenureController = TextEditingController();

  // Parent Details
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _fatherPhoneController = TextEditingController();
  final TextEditingController _fatherEmailController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _motherPhoneController = TextEditingController();
  final TextEditingController _motherEmailController = TextEditingController();

  // Collateral & Purpose
  bool _hasCollateral = false;
  final TextEditingController _collateralController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  String _amountInLakhsLabel = '';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _instituteController.dispose();
    _courseController.dispose();
    _bankController.dispose();
    _loanTypeController.dispose();
    _amountController.dispose();
    _tenureController.dispose();
    _fatherNameController.dispose();
    _fatherPhoneController.dispose();
    _fatherEmailController.dispose();
    _motherNameController.dispose();
    _motherPhoneController.dispose();
    _motherEmailController.dispose();
    _collateralController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateAmountLabel);
  }

  void _updateAmountLabel() {
    final text = _amountController.text.replaceAll(',', '');
    if (text.isEmpty) {
      setState(() => _amountInLakhsLabel = '');
      return;
    }
    final amount = double.tryParse(text);
    if (amount != null && amount > 0) {
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      );
      setState(() {
        _amountInLakhsLabel =
            'Amount: ${formatter.format(amount)} (${(amount / 100000).toStringAsFixed(2)} Lakhs)';
      });
    } else {
      setState(() => _amountInLakhsLabel = '');
    }
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

  void _submitApplication() async {
    if (!_validateStep(0) ||
        !_validateStep(1) ||
        !_validateStep(2) ||
        !_validateStep(3)) {
      return;
    }

    if (_instituteController.text.isEmpty ||
        _courseController.text.isEmpty ||
        _amountController.text.isEmpty) {
      _showError('Please fill all required education and financial fields');
      return;
    }

    final amountText = _amountController.text.replaceAll(',', '');
    final amountValue = double.tryParse(amountText) ?? 0;

    // Sanity check: If amount < 1000, they might have entered "35" meaning 35L
    if (amountValue > 0 && amountValue < 1000) {
      _showError(
        'Is the amount correct? (e.g. 35,00,000 for 35 Lakhs). Please enter the full amount.',
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF311B92)),
      ),
    );

    try {
      // Get userId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userId') ?? '';

      if (userId.isEmpty) {
        final email = prefs.getString('user_email') ?? '';
        final token = prefs.getString('auth_token') ?? '';

        if (email.isNotEmpty && token.isNotEmpty) {
          final authResult = await AuthService.getUserDashboard(email);
          if (authResult['success'] == true) {
            final userData = authResult['data']['user'];
            userId = userData['id'] ?? '';
            if (userId.isNotEmpty) {
              await prefs.setString('userId', userId);
            }
          }
        }
      }

      if (userId.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User session expired. Please log in again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Submit loan application
      final loanService = LoanService();

      await loanService.createLoan(
        userId: userId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        universityName: _instituteController.text,
        courseName: _courseController.text,
        bank: _bankController.text.isEmpty
            ? 'HDFC Credila'
            : _bankController.text,
        loanType: _loanTypeController.text,
        amount: double.parse(_amountController.text.replaceAll(',', '')),
        tenure: int.tryParse(_tenureController.text) ?? 12,
        purpose: _purposeController.text,
        fatherName: _fatherNameController.text,
        fatherPhone: _fatherPhoneController.text,
        fatherEmail: _fatherEmailController.text,
        motherName: _motherNameController.text,
        motherPhone: _motherPhoneController.text,
        motherEmail: _motherEmailController.text,
        hasCollateral: _hasCollateral,
        collateralDetails: _collateralController.text,
      );

      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Go back to main navigation

      // Switch to My Loans tab (index 1)
      final mainNav = MainNavigation.of(context);
      if (mainNav != null) {
        mainNav.switchToTab(1);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan Application Submitted Successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (_firstNameController.text.trim().length < 3) {
        _showError('First name must be at least 3 characters long');
        return false;
      }
      if (_lastNameController.text.trim().isEmpty) {
        _showError('Last name must be at least 1 character long');
        return false;
      }
      final phoneDigits = _phoneController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      if (phoneDigits.length != 10) {
        _showError('Phone number must be exactly 10 digits');
        return false;
      }
      if (!_emailController.text.contains('@') ||
          !_emailController.text.contains('.')) {
        _showError('Please enter a valid email address');
        return false;
      }
    } else if (step == 1) {
      // Parents are optional but if filled, must follow rules
      if (_fatherNameController.text.isNotEmpty &&
          _fatherNameController.text.trim().length < 3) {
        _showError('Father\'s name must be at least 3 characters long');
        return false;
      }
      if (_fatherPhoneController.text.isNotEmpty) {
        final fPhoneDigits = _fatherPhoneController.text.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );
        if (fPhoneDigits.length != 10) {
          _showError('Father\'s phone number must be exactly 10 digits');
          return false;
        }
      }
      if (_motherNameController.text.isNotEmpty &&
          _motherNameController.text.trim().length < 3) {
        _showError('Mother\'s name must be at least 3 characters long');
        return false;
      }
      if (_motherPhoneController.text.isNotEmpty) {
        final mPhoneDigits = _motherPhoneController.text.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );
        if (mPhoneDigits.length != 10) {
          _showError('Mother\'s phone number must be exactly 10 digits');
          return false;
        }
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                      if (_validateStep(_currentStep)) {
                        if (_currentStep < 3) {
                          setState(() => _currentStep += 1);
                        } else {
                          _submitApplication();
                        }
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
                                  _currentStep == 3
                                      ? 'Submit Application'
                                      : 'Continue',
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
                          'Personal Details',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: _buildStepContainer(
                          children: [
                            _buildTextInput(
                              hint: 'First Name',
                              icon: Icons.person_outline,
                              controller: _firstNameController,
                            ),
                            const SizedBox(height: 16),
                            _buildTextInput(
                              hint: 'Last Name',
                              icon: Icons.person_outline,
                              controller: _lastNameController,
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
                          'Parent Details',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: _buildStepContainer(
                          children: [
                            const Text(
                              "Father's Details",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextInput(
                              hint: 'Name',
                              icon: Icons.person_outline,
                              controller: _fatherNameController,
                            ),
                            const SizedBox(height: 12),
                            _buildTextInput(
                              hint: 'Phone',
                              icon: Icons.phone_outlined,
                              controller: _fatherPhoneController,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            _buildTextInput(
                              hint: 'Email',
                              icon: Icons.email_outlined,
                              controller: _fatherEmailController,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Mother's Details",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextInput(
                              hint: 'Name',
                              icon: Icons.person_outline,
                              controller: _motherNameController,
                            ),
                            const SizedBox(height: 12),
                            _buildTextInput(
                              hint: 'Phone',
                              icon: Icons.phone_outlined,
                              controller: _motherPhoneController,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            _buildTextInput(
                              hint: 'Email',
                              icon: Icons.email_outlined,
                              controller: _motherEmailController,
                              keyboardType: TextInputType.emailAddress,
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
                          'Loan Details',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: _buildStepContainer(
                          children: [
                            _buildTextInput(
                              hint: 'Preferred Bank',
                              icon: Icons.account_balance_wallet_outlined,
                              controller: _bankController,
                            ),
                            const SizedBox(height: 16),
                            _buildTextInput(
                              hint: 'Loan Type',
                              icon: Icons.layers_outlined,
                              controller: _loanTypeController,
                              readOnly: true,
                            ),
                          ],
                        ),
                        isActive: _currentStep >= 2,
                        state: _currentStep > 2
                            ? StepState.complete
                            : StepState.indexed,
                      ),
                      Step(
                        title: const Text(
                          'Requirements & Education',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: _buildStepContainer(
                          children: [
                            // Collateral Section first
                            Row(
                              children: [
                                Checkbox(
                                  value: _hasCollateral,
                                  onChanged: (val) {
                                    setState(
                                      () => _hasCollateral = val ?? false,
                                    );
                                  },
                                  activeColor: const Color(0xFF311B92),
                                ),
                                const Text('Do you have collateral?'),
                              ],
                            ),
                            if (_hasCollateral) ...[
                              const SizedBox(height: 12),
                              _buildTextInput(
                                hint: 'Collateral Details',
                                icon: Icons.description_outlined,
                                controller: _collateralController,
                                maxLines: 3,
                              ),
                            ],
                            const SizedBox(height: 20),
                            // Target University
                            const Text(
                              'Education Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildReadOnlyInput(
                              hint: 'Target University',
                              icon: Icons.account_balance_outlined,
                              onTap: _showInstituteSelection,
                              controller: _instituteController,
                            ),
                            const SizedBox(height: 16),
                            _buildReadOnlyInput(
                              hint: 'Course Name',
                              icon: Icons.school_outlined,
                              onTap: _showInstituteSelection,
                              controller: _courseController,
                            ),
                            const SizedBox(height: 20),
                            // Loan Requirements
                            const Text(
                              'Financial Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextInput(
                              hint: 'Desired Loan Amount (₹)',
                              icon: Icons.currency_rupee,
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                IndianCurrencyFormatter(),
                              ],
                            ),
                            if (_amountInLakhsLabel.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF311B92,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF311B92,
                                    ).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Color(0xFF311B92),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _amountInLakhsLabel,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF311B92),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            _buildTextInput(
                              hint: 'Tenure (Months)',
                              icon: Icons.calendar_today_outlined,
                              controller: _tenureController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildTextInput(
                              hint: 'Course Details / Purpose',
                              icon: Icons.info_outline,
                              controller: _purposeController,
                              maxLines: 3,
                            ),
                          ],
                        ),
                        isActive: _currentStep >= 3,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextInput({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
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
        readOnly: readOnly,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
          border: InputBorder.none,
          suffixIcon: Icon(
            icon,
            color: const Color(0xFF311B92).withValues(alpha: 0.4),
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
                      : Colors.black,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(icon, color: const Color(0xFF311B92).withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class IndianCurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove anything that's not a digit
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.isEmpty) return newValue.copyWith(text: '');

    String formatted = _formatIndianCurrency(text);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatIndianCurrency(String text) {
    if (text.length <= 3) return text;

    // Group the last 3 digits
    String lastThree = text.substring(text.length - 3);
    String remaining = text.substring(0, text.length - 3);

    // Group the remaining in 2s
    String groupedRemaining = "";
    int count = 0;
    for (int i = remaining.length - 1; i >= 0; i--) {
      groupedRemaining = remaining[i] + groupedRemaining;
      count++;
      if (count == 2 && i > 0) {
        groupedRemaining = "," + groupedRemaining;
        count = 0;
      }
    }

    return groupedRemaining + "," + lastThree;
  }
}
