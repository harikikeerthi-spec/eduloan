import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart';
import '../widgets/mesh_background.dart';

class UserDetailsPage extends StatefulWidget {
  final String email;
  final bool isEdit;
  final String? currentName;
  final String? currentPhone;
  final String? currentDob;

  const UserDetailsPage({
    super.key,
    required this.email,
    this.isEdit = false,
    this.currentName,
    this.currentPhone,
    this.currentDob,
  });

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();

    // Pre-fill data if editing
    if (widget.isEdit) {
      if (widget.currentName != null) {
        final parts = widget.currentName!.split(' ');
        if (parts.isNotEmpty) {
          _firstNameController.text = parts[0];
          if (parts.length > 1) {
            _lastNameController.text = parts.sublist(1).join(' ');
          }
        } else {
          _firstNameController.text = widget.currentName!;
        }
      }
      if (widget.currentPhone != null && widget.currentPhone != 'Not set') {
        String cleanedPhone = widget.currentPhone!.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanedPhone.length > 10) {
          cleanedPhone = cleanedPhone.substring(cleanedPhone.length - 10);
        }
        _phoneController.text = cleanedPhone;
      }
      if (widget.currentDob != null && widget.currentDob != 'Not set' && widget.currentDob!.contains('-')) {
        _dobController.text = widget.currentDob!;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime eighteenYearsAgo = now.subtract(
      const Duration(days: 365 * 18),
    );

    DateTime initial = eighteenYearsAgo;
    if (_dobController.text.isNotEmpty) {
      final clean = _dobController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.length == 8) {
        final d = int.tryParse(clean.substring(0, 2));
        final m = int.tryParse(clean.substring(2, 4));
        final y = int.tryParse(clean.substring(4, 8));
        if (d != null && m != null && y != null && y >= 1900 && y <= now.year) {
          try {
            initial = DateTime(y, m, d);
          } catch (_) {}
        }
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(eighteenYearsAgo) ? initial : eighteenYearsAgo,
      firstDate: DateTime(1900),
      lastDate: eighteenYearsAgo, // Prevent under 18 selection
      initialEntryMode: DatePickerEntryMode.calendar,
      helpText: 'SELECT DATE OF BIRTH (MUST BE 18+)',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF311B92),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF311B92),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
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
      return 'Enter 8 digits (DD-MM-YYYY)';
    }

    if (!cleanValue.contains('-') && !cleanValue.contains('/')) {
      cleanValue =
          '${rawDigits.substring(0, 2)}-${rawDigits.substring(2, 4)}-${rawDigits.substring(4, 8)}';
    }

    try {
      int day = 0, month = 0, year = 0;
      if (cleanValue.contains('-')) {
        final parts = cleanValue.split('-');
        if (parts.length != 3) return 'Invalid format (DD-MM-YYYY)';
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = int.parse(parts[2]);
      } else if (cleanValue.contains('/')) {
        final parts = cleanValue.split('/');
        if (parts.length != 3) return 'Invalid format (DD-MM-YYYY)';
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
      if (age < 18) {
        return 'Must be 18+ years old';
      }
      if (dob.year < 1920 || dob.isAfter(today)) {
        return 'Please enter a valid date of birth';
      }
    } catch (e) {
      return 'Invalid date';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Map<String, dynamic> result;
      // Unified update logic (handles both edit and complete registration)
      result = await AuthService.updateUserDetails(
        widget.email,
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _phoneController.text.isEmpty ? '' : _phoneController.text.trim(),
        _dobController.text.isEmpty ? '' : _dobController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        if (widget.isEdit) {
          Navigator.pop(context, true); // Return success to refresh profile
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Navigate to home page
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigation()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  InputDecoration _getInputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
      prefixIcon: Icon(icon, color: const Color(0xFF311B92)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF311B92), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: widget.isEdit
            ? AppBar(
                title: const Text('Edit Profile'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                titleTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!widget.isEdit) ...[
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_add,
                            size: 60,
                            color: Color(0xFF311B92),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        const Text(
                          'Complete Profile',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tell us a bit about yourself',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],

                      // Form Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // First Name
                              TextFormField(
                                controller: _firstNameController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                decoration: _getInputDecoration(
                                  'First Name',
                                  Icons.person_outline,
                                  hint: 'Enter your first name',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your first name';
                                  }
                                  if (value.length < 3) {
                                    return 'Min 3 characters';
                                  }
                                  if (value.length > 30) {
                                    return 'Max 30 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Last Name
                              TextFormField(
                                controller: _lastNameController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                decoration: _getInputDecoration(
                                  'Last Name',
                                  Icons.person_outline,
                                  hint: 'Enter your last name',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your last name';
                                  }
                                  if (value.isEmpty) {
                                    return 'Min 1 character';
                                  }
                                  if (value.length > 30) {
                                    return 'Max 30 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Date of Birth
                              TextFormField(
                                controller: _dobController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                                  DateTextInputFormatter(),
                                ],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                decoration: _getInputDecoration(
                                  'Date of Birth',
                                  Icons.calendar_today,
                                  hint: 'DD-MM-YYYY',
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF311B92)),
                                    onPressed: () => _selectDate(context),
                                    tooltip: 'Pick date from calendar',
                                  ),
                                ),
                                validator: _validateDob,
                              ),
                              const SizedBox(height: 16),

                              // Phone Number
                              TextFormField(
                                controller: _phoneController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                decoration: _getInputDecoration(
                                  'Mobile Number',
                                  Icons.phone_outlined,
                                  hint: 'XXXXXXXXXX',
                                ).copyWith(
                                  prefixText: '+91 ',
                                  prefixStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your mobile number';
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
                              const SizedBox(height: 32),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF311B92),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          widget.isEdit
                                              ? 'Save Changes'
                                              : 'Complete Registration',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
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
              ),
            ),
          ),
        ),
      ),
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
    } else if (digits.length <= 4) {
      formatted = '${digits.substring(0, 2)}-${digits.substring(2)}';
    } else {
      formatted =
          '${digits.substring(0, 2)}-${digits.substring(2, 4)}-${digits.substring(4)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
