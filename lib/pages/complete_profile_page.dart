import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart';
import 'onboarding_page.dart';
import '../widgets/mesh_background.dart';

class CompleteProfilePage extends StatefulWidget {
  final String email;
  final bool isNewUser;

  const CompleteProfilePage({
    super.key,
    required this.email,
    this.isNewUser = false,
  });

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final DateTime fortyYearsAgo = DateTime(now.year - 40, now.month, now.day);

    DateTime initial = eighteenYearsAgo;
    if (_dobController.text.isNotEmpty) {
      final clean = _dobController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.length == 8) {
        final d = int.tryParse(clean.substring(0, 2));
        final m = int.tryParse(clean.substring(2, 4));
        final y = int.tryParse(clean.substring(4, 8));
        if (d != null && m != null && y != null && y >= now.year - 40 && y <= now.year - 18) {
          try {
            initial = DateTime(y, m, d);
          } catch (_) {}
        }
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(eighteenYearsAgo) && initial.isAfter(fortyYearsAgo) ? initial : eighteenYearsAgo,
      firstDate: fortyYearsAgo,
      lastDate: eighteenYearsAgo,
      initialEntryMode: DatePickerEntryMode.calendar,
      helpText: 'SELECT DATE OF BIRTH (ELIGIBLE: 18 - 40 YEARS)',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  String? _validateDob(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    String cleanValue = value.trim();
    final rawDigits = cleanValue.replaceAll(RegExp(r'[^0-9]'), '');

    if (rawDigits.length != 8) {
      return 'Enter 8 digits (DD/MM/YYYY)';
    }

    if (!cleanValue.contains('-') && !cleanValue.contains('/')) {
      cleanValue =
          '${rawDigits.substring(0, 2)}/${rawDigits.substring(2, 4)}/${rawDigits.substring(4, 8)}';
    }

    try {
      int day = 0, month = 0, year = 0;
      if (cleanValue.contains('/')) {
        final parts = cleanValue.split('/');
        if (parts.length != 3) return 'Invalid format (DD/MM/YYYY)';
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = int.parse(parts[2]);
      } else if (cleanValue.contains('-')) {
        final parts = cleanValue.split('-');
        if (parts.length != 3) return 'Invalid format (DD/MM/YYYY)';
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = int.parse(parts[2]);
      }

      if (month < 1 || month > 12) return 'Invalid month (1-12)';
      if (day < 1 || day > 31) return 'Invalid day (1-31)';

      final dob = DateTime(year, month, day);
      final today = DateTime.now();
      var age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      if (age < 18 || age > 40) {
        return 'Age must be between 18 and 40 years';
      }
      if (dob.isAfter(today)) {
        return 'Please enter a valid date of birth';
      }
    } catch (e) {
      return 'Invalid date format';
    }
    return null;
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.updateUserDetails(
        widget.email,
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _phoneController.text.trim(),
        _dobController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile completed successfully!')),
        );

        final prefs = await SharedPreferences.getInstance();
        final bool onboardingShown = prefs.getBool('onboarding_shown') ?? false;

        if (!mounted) return;

        if (!onboardingShown) {
          // Mandatory Onboarding Page completion first
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingPage()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainNavigation()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to complete profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: MeshBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // --- Header (Outside Card) ---
                    Text(
                      'Setup Profile',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We need a few details to get you started',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
  
                    // --- Main Content Card ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Personal Details',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 24),
  
                            // First Name
                            _buildLabel('First Name'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _firstNameController,
                              hint: 'John',
                              icon: Icons.person_outline,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (value.length < 3) return 'Min 3 characters';
                                if (value.length > 30) return 'Max 30 characters';
                                return null;
                              },
                            ),
  
                            const SizedBox(height: 16),
  
                            // Last Name
                            _buildLabel('Last Name'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _lastNameController,
                              hint: 'Doe',
                              icon: Icons.person_outline,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (value.isEmpty) return 'Min 1 character';
                                if (value.length > 30) return 'Max 30 characters';
                                return null;
                              },
                            ),
  
                            const SizedBox(height: 16),
  
                            // Phone
                            _buildLabel('Phone Number'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _phoneController,
                              hint: '1234567890',
                              icon: Icons.phone_outlined,
                              inputType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (value.length != 10) {
                                  return 'Must be 10 digits';
                                }
                                if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
                                  return 'Invalid Indian mobile number';
                                }
                                if (value.split('').toSet().length < 3) {
                                  return 'Highly repetitive number not allowed';
                                }
                                return null;
                              },
                            ),
  
                            const SizedBox(height: 16),
  
                            // DOB
                            _buildLabel('Date of Birth'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _dobController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9\/]')),
                                DateTextInputFormatter(),
                              ],
                              style: GoogleFonts.inter(fontSize: 16),
                              decoration: _inputDecoration(
                                'DD/MM/YYYY',
                                Icons.calendar_today_outlined,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_month_rounded, color: Colors.black),
                                  onPressed: () => _selectDate(context),
                                  tooltip: 'Pick date from calendar',
                                ),
                              ),
                              validator: _validateDob,
                            ),
  
                            const SizedBox(height: 32),
  
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF281C9D),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
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
                                    : Text(
                                        'Complete Setup',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7), // Surface color
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLength: inputType == TextInputType.phone ? 10 : null,
        buildCounter: inputType == TextInputType.phone
            ? (context, {required currentLength, required isFocused, maxLength}) => null
            : null,
        inputFormatters: inputFormatters ??
            (inputType == TextInputType.phone
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ]
                : null),
        style: GoogleFonts.inter(fontSize: 16),
        decoration: InputDecoration(
          hintText: inputType == TextInputType.phone ? 'XXXXXXXXXX' : hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          prefixIcon: Icon(icon, color: Colors.grey),
          prefixText: inputType == TextInputType.phone ? '+91 ' : null,
          prefixStyle: inputType == TextInputType.phone 
              ? GoogleFonts.inter(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w600)
              : null,
        ),
        validator:
            validator ??
            (value) {
              if (value == null || value.isEmpty) return 'Required';
              return null;
            },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F5F7),
      hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide.none, // Removed bold border to match login clean style
      ),
      prefixIcon: Icon(icon, color: Colors.grey),
    );
  }
}

class DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }

    String formatted = '';
    if (digits.length <= 2) {
      formatted = digits;
      if (digits.length == 2) {
        formatted = '$digits/';
      }
    } else if (digits.length <= 4) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
      if (digits.length == 4) {
        formatted = '${digits.substring(0, 2)}/${digits.substring(2)}/';
      }
    } else {
      formatted =
          '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
