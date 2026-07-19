import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../widgets/mesh_background.dart';
import '../services/loan_service.dart';
import '../services/auth_service.dart';
import '../services/ai_logic_service.dart';
import 'main_navigation.dart';

class ApplyLoanPage extends StatefulWidget {
  final String? initialUniversity;
  final String? initialCourse;
  final String? initialCountry;
  final String? initialBank;
  final VoidCallback? onLoanSubmitted;

  const ApplyLoanPage({
    super.key,
    this.initialUniversity,
    this.initialCourse,
    this.initialCountry,
    this.initialBank,
    this.onLoanSubmitted,
  });

  @override
  State<ApplyLoanPage> createState() => _ApplyLoanPageState();
}

class _ApplyLoanPageState extends State<ApplyLoanPage> {
  int _currentStep = 0;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
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
  
  // Residential Details
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _resCountryController = TextEditingController();
  bool _isPincodeResolving = false;

  // Co-Applicant Details
  final TextEditingController _coApplicantNameController = TextEditingController();
  final TextEditingController _coApplicantRelationController = TextEditingController();
  final TextEditingController _coApplicantPhoneController = TextEditingController();
  final TextEditingController _coApplicantEmailController = TextEditingController();
  final TextEditingController _coApplicantIncomeController = TextEditingController();

  final List<String> _relations = [
    'Father',
    'Mother',
    'Spouse',
    'Brother',
    'Sister',
    'Uncle',
    'Aunt',
    'Other',
  ];

  // Collateral & Purpose
  bool _hasCollateral = false;
  final TextEditingController _collateralController = TextEditingController();
  final Map<TextEditingController, String?> _fieldErrors = {};
  final TextEditingController _purposeController = TextEditingController();
  bool _isManualCountryEntry = false;
  String _selectedCountryFlag = '';

  // University verification caching
  String? _verifiedUniversityName;
  String? _verifiedCountry;
  bool _isVerifiedReal = false;

  // Static country → flag emoji map (no API needed, works fully offline)
  static const Map<String, String> _countryFlags = {
    'usa': '🇺🇸',
    'united states': '🇺🇸',
    'united states of america': '🇺🇸',
    'uk': '🇬🇧',
    'united kingdom': '🇬🇧',
    'england': '🇬🇧',
    'britain': '🇬🇧',
    'canada': '🇨🇦',
    'australia': '🇦🇺',
    'germany': '🇩🇪',
    'france': '🇫🇷',
    'ireland': '🇮🇪',
    'singapore': '🇸🇬',
    'new zealand': '🇳🇿',
    'netherlands': '🇳🇱',
    'holland': '🇳🇱',
    'sweden': '🇸🇪',
    'switzerland': '🇨🇭',
    'norway': '🇳🇴',
    'denmark': '🇩🇰',
    'finland': '🇫🇮',
    'italy': '🇮🇹',
    'spain': '🇪🇸',
    'portugal': '🇵🇹',
    'japan': '🇯🇵',
    'south korea': '🇰🇷',
    'korea': '🇰🇷',
    'china': '🇨🇳',
    'hong kong': '🇭🇰',
    'uae': '🇦🇪',
    'dubai': '🇦🇪',
    'united arab emirates': '🇦🇪',
    'malaysia': '🇲🇾',
    'indonesia': '🇮🇩',
    'philippines': '🇵🇭',
    'thailand': '🇹🇭',
    'taiwan': '🇹🇼',
    'austria': '🇦🇹',
    'belgium': '🇧🇪',
    'poland': '🇵🇱',
    'czech republic': '🇨🇿',
    'czechia': '🇨🇿',
    'hungary': '🇭🇺',
    'romania': '🇷🇴',
    'greece': '🇬🇷',
    'turkey': '🇹🇷',
    'russia': '🇷🇺',
    'mexico': '🇲🇽',
    'brazil': '🇧🇷',
    'argentina': '🇦🇷',
    'chile': '🇨🇱',
    'colombia': '🇨🇴',
    'india': '🇮🇳',
    'sri lanka': '🇱🇰',
    'pakistan': '🇵🇰',
    'bangladesh': '🇧🇩',
    'nepal': '🇳🇵',
    'south africa': '🇿🇦',
    'nigeria': '🇳🇬',
    'kenya': '🇰🇪',
    'egypt': '🇪🇬',
    'israel': '🇮🇱',
    'saudi arabia': '🇸🇦',
    'qatar': '🇶🇦',
    'kuwait': '🇰🇼',
    'bahrain': '🇧🇭',
  };

  /// Returns the flag emoji for the given country name (case-insensitive).
  /// Returns empty string if not found.
  String _getFlagForCountry(String countryName) {
    final key = countryName.trim().toLowerCase();
    return _countryFlags[key] ?? '';
  }

  String _amountInLakhsLabel = '';
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _countryController.dispose();
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
    _coApplicantNameController.dispose();
    _coApplicantRelationController.dispose();
    _coApplicantPhoneController.dispose();
    _coApplicantEmailController.dispose();
    _coApplicantIncomeController.dispose();
    _collateralController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateAmountLabel);
    _loadUserData();
    if (widget.initialUniversity != null) {
      _instituteController.text = widget.initialUniversity!;
    }
    if (widget.initialCourse != null) {
      _courseController.text = widget.initialCourse!;
    }
    if (widget.initialBank != null) {
      _bankController.text = widget.initialBank!;
    }
    if (widget.initialCountry != null) {
      final country = widget.initialCountry!;
      _countryController.text = country;
      final normalizedCountries = _countries.map((c) => c.toLowerCase()).toList();
      if (!normalizedCountries.contains(country.toLowerCase())) {
        _isManualCountryEntry = true;
        _selectedCountryFlag = _getFlagForCountry(country);
      } else {
        _selectedCountryFlag = _getFlagForCountry(country);
      }
    }
    // Auto-detect flag as user types manually
    _countryController.addListener(() {
      if (_isManualCountryEntry) {
        final flag = _getFlagForCountry(_countryController.text);
        if (flag != _selectedCountryFlag) {
          setState(() => _selectedCountryFlag = flag);
        }
      }
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. First, try to load whatever we have locally
    void updateFromLocal() {
      setState(() {
        _firstNameController.text = prefs.getString('user_firstName') ?? prefs.getString('user_name') ?? '';
        _lastNameController.text = prefs.getString('user_lastName') ?? prefs.getString('user_last_name') ?? '';
        _phoneController.text = prefs.getString('user_phone') ?? 
                               prefs.getString('user_phoneNumber') ?? 
                               prefs.getString('user_phone_number') ?? 
                               prefs.getString('phone_number') ?? '';
        _emailController.text = prefs.getString('user_email') ?? '';
      });
    }

    updateFromLocal();

    // 2. If phone number is still missing, proactively fetch from backend
    if (_phoneController.text.isEmpty || _firstNameController.text.isEmpty) {
      final email = prefs.getString('user_email') ?? '';
      if (email.isNotEmpty) {
        try {
          final result = await AuthService.getUserDashboard(email);
          if (result['success'] == true) {
            final data = result['data']['user'] ?? result['user'];
            if (data != null) {
              await prefs.setString('user_firstName', data['firstName'] ?? '');
              await prefs.setString('user_lastName', data['lastName'] ?? '');
              await prefs.setString('user_phone', data['phoneNumber'] ?? data['phone'] ?? '');
              // Refresh the UI with new data
              updateFromLocal();
            }
          }
        } catch (e) {
          debugPrint('Error pre-filling user data from dashboard: $e');
        }
      }
    }
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



  final List<String> _countries = [
    'USA',
    'UK',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Ireland',
    'Singapore',
    'New Zealand',
    'Netherlands',
    'Sweden',
    'Switzerland',
    'Italy',
    'Spain',
    'Japan',
    'South Korea',
    'UAE',
    'Malaysia',
    'Denmark',
    'Finland',
    'Norway',
    'Other',
  ];


  void _showCountrySelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Select Target Country',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF311B92),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _countries.length,
                itemBuilder: (context, index) {
                  final country = _countries[index];
                  final flag = country == 'Other' ? '🌍' : _getFlagForCountry(country);
                  final isSelected = _countryController.text == country;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: flag.isNotEmpty
                        ? Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF311B92).withValues(alpha: 0.1)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                flag,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          )
                        : null,
                    title: Text(
                      country,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF311B92) : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                        : const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      setState(() {
                        if (country == 'Other') {
                          _countryController.clear();
                          _isManualCountryEntry = true;
                          _selectedCountryFlag = '';
                        } else {
                          _countryController.text = country;
                          _isManualCountryEntry = false;
                          _selectedCountryFlag = flag;
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showRelationSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Select Relationship',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF311B92),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _relations.length,
                itemBuilder: (context, index) {
                  final rel = _relations[index];
                  final isSelected = _coApplicantRelationController.text == rel;
                  return ListTile(
                    title: Text(
                      rel,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF311B92) : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                        : null,
                    onTap: () {
                      setState(() {
                        _coApplicantRelationController.text = rel;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitApplication() async {
    if (!_validateStep(0) ||
        !_validateStep(1) ||
        !_validateStep(2) ||
        !_validateStep(3) ) {
      return;
    }

    final isReal = await _verifyUniversityName();
    if (!isReal) {
      _showError('Target University is not recognized in this country');
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
            final data = authResult['data']['user'];
            userId = data['id'] ?? '';
            if (userId.isNotEmpty) {
              await prefs.setString('userId', userId);
            }
            if (data['lastName'] != null) {
              await prefs.setString('user_lastName', data['lastName']);
            }
            if (data['phoneNumber'] != null) {
              await prefs.setString('user_phone', data['phoneNumber']);
            }
            if (data['dateOfBirth'] != null) {
              await prefs.setString('user_dob', data['dateOfBirth']);
            }
          }
        }
      }

      if (userId.isEmpty) {
        if (!mounted) return;
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
        targetCountry: _countryController.text,
        universityName: _instituteController.text,
        courseName: _courseController.text,
        bank: _bankController.text.isEmpty
            ? 'HDFC Credila'
            : _bankController.text,
        loanType: _loanTypeController.text,
        amount: double.parse(_amountController.text.replaceAll(',', '')),
        tenure: 12, // Default tenure since field was removed
        purpose: _purposeController.text,
        fatherName: _fatherNameController.text,
        fatherPhone: _fatherPhoneController.text,
        fatherEmail: _fatherEmailController.text,
        motherName: _motherNameController.text,
        motherPhone: _motherPhoneController.text,
        motherEmail: _motherEmailController.text,
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
        country: _resCountryController.text.trim().isEmpty ? null : _resCountryController.text.trim(),
        hasCollateral: _hasCollateral,
        collateralDetails: _collateralController.text,
        hasCoApplicant: true,
        coApplicantName: _coApplicantNameController.text,
        coApplicantRelation: _coApplicantRelationController.text,
        coApplicantPhone: _coApplicantPhoneController.text,
        coApplicantEmail: _coApplicantEmailController.text.isEmpty
            ? null
            : _coApplicantEmailController.text,
        coApplicantIncome: double.tryParse(_coApplicantIncomeController.text.replaceAll(',', '')),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      final mainNav = MainNavigation.of(context);
      widget.onLoanSubmitted?.call();
      
      if (mainNav != null) {
        mainNav.switchToTab(1); // Switch to My Loans tab (which becomes index 1 after Apply is hidden)
      } else {
        Navigator.pop(context); // Go back to main navigation if pushed as a separate screen
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan Application Submitted Successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _autoDetectCityCountry(String pincode) async {
    if (pincode.isEmpty || _isPincodeResolving) return;

    setState(() {
      _isPincodeResolving = true;
    });

    try {
      final res = await AiLogicService().lookupPincodeDetails(pincode);
      if (res != null && res['success'] == true) {
        setState(() {
          if (res['city'] != null && res['city'].toString().isNotEmpty) {
            _cityController.text = res['city'].toString();
          }
          if (res['country'] != null && res['country'].toString().isNotEmpty) {
            _resCountryController.text = res['country'].toString();
          }
        });
      }
    } catch (e) {
      debugPrint('Error auto-detecting city and country: $e');
    } finally {
      setState(() {
        _isPincodeResolving = false;
      });
    }
  }

  bool _validateStep(int step) {
    setState(() {
      _fieldErrors.clear();
    });

    if (step == 0) {
      if (_firstNameController.text.length < 3) {
        setState(() => _fieldErrors[_firstNameController] = 'Enter at least 3 chars');
        _showError('First name must be at least 3 characters long');
        return false;
      }
      if (_lastNameController.text.isEmpty) {
        setState(() => _fieldErrors[_lastNameController] = 'Required');
        _showError('Last name is required');
        return false;
      }
      String phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (phone.length != 10) {
        setState(() => _fieldErrors[_phoneController] = 'Enter 10 digits');
        _showError('Phone number must be exactly 10 digits');
        return false;
      }
      if (!RegExp(r'^[6-9]').hasMatch(phone)) {
        setState(() => _fieldErrors[_phoneController] = 'Must start with 6-9');
        _showError('Enter a valid Indian mobile number');
        return false;
      }
      if (phone.split('').toSet().length < 3) {
        setState(() => _fieldErrors[_phoneController] = 'Invalid pattern');
        _showError('Phone number cannot be highly repetitive (e.g., 8787878787)');
        return false;
      }
      if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
        setState(() => _fieldErrors[_emailController] = 'Enter valid email');
        _showError('Please enter a valid email address');
        return false;
      }
    } else if (step == 1) {
      if (_fatherNameController.text.length < 3) {
        setState(() => _fieldErrors[_fatherNameController] = 'Required');
        _showError('Father\'s name is required (min 3 chars)');
        return false;
      }
      String fPhone = _fatherPhoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (fPhone.length != 10) {
        setState(() => _fieldErrors[_fatherPhoneController] = 'Enter 10 digits');
        _showError('Father\'s phone number must be 10 digits');
        return false;
      }
      if (!RegExp(r'^[6-9]').hasMatch(fPhone)) {
        setState(() => _fieldErrors[_fatherPhoneController] = 'Must start with 6-9');
        _showError('Enter a valid Indian mobile number for father');
        return false;
      }
      if (fPhone.split('').toSet().length < 3) {
        setState(() => _fieldErrors[_fatherPhoneController] = 'Invalid pattern');
        _showError('Father\'s phone number cannot be highly repetitive');
        return false;
      }
      if (_motherNameController.text.length < 3) {
        setState(() => _fieldErrors[_motherNameController] = 'Required');
        _showError('Mother\'s name is required (min 3 chars)');
        return false;
      }
      String mPhone = _motherPhoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (mPhone.length != 10) {
        setState(() => _fieldErrors[_motherPhoneController] = 'Enter 10 digits');
        _showError('Mother\'s phone number must be 10 digits');
        return false;
      }
      if (!RegExp(r'^[6-9]').hasMatch(mPhone)) {
        setState(() => _fieldErrors[_motherPhoneController] = 'Must start with 6-9');
        _showError('Enter a valid Indian mobile number for mother');
        return false;
      }
      if (mPhone.split('').toSet().length < 3) {
        setState(() => _fieldErrors[_motherPhoneController] = 'Invalid pattern');
        _showError('Mother\'s phone number cannot be highly repetitive');
        return false;
      }
      if (_pincodeController.text.trim().length < 4) {
        setState(() => _fieldErrors[_pincodeController] = 'Required');
        _showError('Please enter a valid pincode/zipcode');
        return false;
      }
      if (_cityController.text.trim().length < 2) {
        setState(() => _fieldErrors[_cityController] = 'Required');
        _showError('Please enter a city');
        return false;
      }
      if (_resCountryController.text.trim().length < 2) {
        setState(() => _fieldErrors[_resCountryController] = 'Required');
        _showError('Please enter a country');
        return false;
      }
    } else if (step == 2) {
      if (_coApplicantNameController.text.length < 3) {
        setState(() => _fieldErrors[_coApplicantNameController] = 'Required');
        _showError('Co-applicant\'s name is required (min 3 chars)');
        return false;
      }
      if (_coApplicantRelationController.text.isEmpty) {
        setState(() => _fieldErrors[_coApplicantRelationController] = 'Required');
        _showError('Co-applicant relationship is required');
        return false;
      }
      String caPhone = _coApplicantPhoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (caPhone.length != 10) {
        setState(() => _fieldErrors[_coApplicantPhoneController] = 'Enter 10 digits');
        _showError('Co-applicant\'s phone number must be 10 digits');
        return false;
      }
      if (!RegExp(r'^[6-9]').hasMatch(caPhone)) {
        setState(() => _fieldErrors[_coApplicantPhoneController] = 'Must start with 6-9');
        _showError('Enter a valid Indian mobile number for co-applicant');
        return false;
      }
      if (caPhone.split('').toSet().length < 3) {
        setState(() => _fieldErrors[_coApplicantPhoneController] = 'Invalid pattern');
        _showError('Co-applicant\'s phone number cannot be highly repetitive');
        return false;
      }
      if (_coApplicantEmailController.text.isNotEmpty && !_coApplicantEmailController.text.contains('@')) {
        setState(() => _fieldErrors[_coApplicantEmailController] = 'Enter valid email');
        _showError('Please enter a valid email address for co-applicant');
        return false;
      }
      final incomeText = _coApplicantIncomeController.text.replaceAll(',', '');
      if (incomeText.isEmpty) {
        setState(() => _fieldErrors[_coApplicantIncomeController] = 'Required');
        _showError('Co-applicant\'s annual income is required');
        return false;
      }
      final income = double.tryParse(incomeText);
      if (income == null || income <= 0) {
        setState(() => _fieldErrors[_coApplicantIncomeController] = 'Enter positive amount');
        _showError('Enter a valid positive annual income');
        return false;
      }
    } else if (step == 3) {
      if (_countryController.text.isEmpty) {
        setState(() => _fieldErrors[_countryController] = 'Required');
        _showError('Please select your target country');
        return false;
      }
      if (_instituteController.text.isEmpty) {
        setState(() => _fieldErrors[_instituteController] = 'Required');
        _showError('Please select your target university');
        return false;
      }
      if (_courseController.text.isEmpty) {
        setState(() => _fieldErrors[_courseController] = 'Required');
        _showError('Please select your course');
        return false;
      }
      if (_amountController.text.isEmpty) {
        setState(() => _fieldErrors[_amountController] = 'Required');
        _showError('Please enter the desired loan amount');
        return false;
      }
    }
    return true;
  }

  Future<bool> _verifyUniversityName() async {
    final name = _instituteController.text.trim();
    final country = _countryController.text.trim();
    if (name.isEmpty || country.isEmpty) return false;

    if (_verifiedUniversityName == name && _verifiedCountry == country) {
      return _isVerifiedReal;
    }

    try {
      final aiService = AiLogicService();
      final result = await aiService.verifyUniversity(name, country);
      if (result['success'] == true) {
        _verifiedUniversityName = name;
        _verifiedCountry = country;
        _isVerifiedReal = result['isReal'] ?? false;
        return _isVerifiedReal;
      }
    } catch (e) {
      debugPrint('Error verifying university name: $e');
    }
    // Fail permissive if server/network fails so user is not blocked
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
              const SizedBox(height: 10),
              _buildCustomProgressHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildStepContent(_currentStep),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildCustomControls(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  final List<String> _stepLabels = ['Personal', 'Parents', 'Co-Applicant', 'Info', 'Review'];

  Widget _buildCustomProgressHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(5, (index) {
          bool isActive = index <= _currentStep;
          bool isCurrent = index == _currentStep;
          bool isPassed = index < _currentStep;

          return Expanded(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Connector Line (Background)
                Positioned(
                  top: 14, // Vertical center of circle
                  left: index == 0 ? 0.5 : 0, // Don't extend left for first step
                  right: index == 4 ? 0.5 : 0, // Don't extend right for last step
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index > 0 && isPassed || (index > 0 && isActive && index <= _currentStep)
                              ? const Color(0xFF311B92) 
                              : (index > 0 ? Colors.black.withValues(alpha: 0.1) : Colors.transparent),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < 4 && isPassed
                              ? const Color(0xFF311B92) 
                              : (index < 4 ? Colors.black.withValues(alpha: 0.1) : Colors.transparent),
                        ),
                      ),
                    ],
                  ),
                ),
                // Circle and Label (Foreground)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCurrent 
                            ? const Color(0xFF311B92) 
                            : (isActive ? const Color(0xFF311B92).withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.1)),
                        shape: BoxShape.circle,
                        boxShadow: isCurrent ? [
                          BoxShadow(
                            color: const Color(0xFF311B92).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrent || isActive ? Colors.white : Colors.black.withValues(alpha: 0.4),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _stepLabels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                        color: isActive ? const Color(0xFF311B92) : Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildStepContainer(
          children: [
            _buildTextInput(
              hint: 'First Name',
              icon: Icons.person_outline,
              controller: _firstNameController,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildTextInput(
              hint: 'Last Name',
              icon: Icons.person_outline,
              controller: _lastNameController,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildTextInput(
              hint: 'Phone Number',
              icon: Icons.phone_outlined,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildTextInput(
              hint: 'Email Address',
              icon: Icons.email_outlined,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              isRequired: true,
            ),
          ],
        );
      case 1:
        return _buildStepContainer(
          children: [
            const Text(
              "Father's Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildTextInput(
              hint: 'Name',
              icon: Icons.person_outline,
              controller: _fatherNameController,
              isRequired: true,
            ),
            const SizedBox(height: 12),
            _buildTextInput(
              hint: 'Phone',
              icon: Icons.phone_outlined,
              controller: _fatherPhoneController,
              keyboardType: TextInputType.phone,
              isRequired: true,
            ),
            const SizedBox(height: 20),
            const Text(
              "Mother's Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildTextInput(
              hint: 'Name',
              icon: Icons.person_outline,
              controller: _motherNameController,
              isRequired: true,
            ),
            const SizedBox(height: 12),
            _buildTextInput(
              hint: 'Phone',
              icon: Icons.phone_outlined,
              controller: _motherPhoneController,
              keyboardType: TextInputType.phone,
              isRequired: true,
            ),
            const SizedBox(height: 20),
            const Text(
              "Residential Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildTextInput(
              hint: 'Pincode / ZIP Code',
              icon: Icons.pin_drop_outlined,
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              isRequired: true,
              onChanged: (val) {
                if (val.trim().length >= 6) {
                  _autoDetectCityCountry(val.trim());
                }
              },
              suffixIcon: _isPincodeResolving
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF311B92),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            _buildTextInput(
              hint: 'City',
              icon: Icons.location_city_outlined,
              controller: _cityController,
              isRequired: true,
            ),
            const SizedBox(height: 12),
            _buildTextInput(
              hint: 'Country',
              icon: Icons.public_outlined,
              controller: _resCountryController,
              isRequired: true,
            ),
          ],
        );
      case 2:
        return _buildStepContainer(
          children: [
            _buildTextInput(
              hint: 'Co-applicant Name',
              icon: Icons.person_outline,
              controller: _coApplicantNameController,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildReadOnlyInput(
              hint: 'Relationship',
              icon: Icons.people_outline,
              controller: _coApplicantRelationController,
              onTap: _showRelationSelection,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildTextInput(
              hint: 'Phone Number',
              icon: Icons.phone_outlined,
              controller: _coApplicantPhoneController,
              keyboardType: TextInputType.phone,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildTextInput(
              hint: 'Email Address',
              icon: Icons.email_outlined,
              controller: _coApplicantEmailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextInput(
              hint: 'Annual Income (INR)',
              icon: Icons.currency_rupee,
              controller: _coApplicantIncomeController,
              keyboardType: TextInputType.number,
              isRequired: true,
            ),
          ],
        );
      case 3:
        return _buildStepContainer(
          children: [
            Row(
              children: [
                Checkbox(
                  value: _hasCollateral,
                  onChanged: (val) => setState(() => _hasCollateral = val ?? false),
                  fillColor: WidgetStateProperty.all(const Color(0xFF311B92)),
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
            const Text(
              'Education Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _isManualCountryEntry
                ? _buildCountryManualInput()
                : _buildCountryReadOnlyInput(),
            const SizedBox(height: 16),
            _buildTextInput(
              hint: 'Target University',
              icon: Icons.account_balance_outlined,
              controller: _instituteController,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildTextInput(
              hint: 'Course Name',
              icon: Icons.school_outlined,
              controller: _courseController,
              isRequired: true,
            ),
            const SizedBox(height: 20),
            const Text(
              'Financial Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildTextInput(
              hint: 'Desired Loan Amount (₹)',
              icon: Icons.currency_rupee,
              controller: _amountController,
              keyboardType: TextInputType.number,
              isRequired: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                IndianCurrencyFormatter(),
              ],
            ),
            if (_amountInLakhsLabel.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF311B92).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF311B92).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF311B92)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_amountInLakhsLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF311B92)))),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _buildTextInput(
              hint: 'Course Details / Purpose',
              icon: Icons.info_outline,
              controller: _purposeController,
              maxLines: 3,
            ),
          ],
        );
      case 4:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCustomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep -= 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF311B92),
                  side: const BorderSide(color: Color(0xFF311B92)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () async {
                if (_validateStep(_currentStep)) {
                  if (_currentStep == 3) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: Card(
                          margin: EdgeInsets.all(24),
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF311B92)),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Verifying target university with AI...',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );

                    final isReal = await _verifyUniversityName();

                    if (context.mounted) {
                      Navigator.pop(context); // Pop the progress dialog
                    }

                    if (!isReal) {
                      setState(() => _fieldErrors[_instituteController] = 'Not recognized');
                      _showError('Target University is not recognized in this country');
                      return;
                    }
                  }

                  if (_currentStep < 4) {
                    setState(() => _currentStep += 1);
                  } else {
                    _submitApplication();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF311B92),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _currentStep == 4
                    ? 'Submit Application'
                    : _currentStep == 3
                        ? 'Review Details'
                        : 'Continue',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return _buildStepContainer(
      children: [
        _buildReviewSection(
          'Personal Details',
          [
            _buildReviewRow('Name', '${_firstNameController.text} ${_lastNameController.text}'),
            _buildReviewRow('Phone', _phoneController.text),
            _buildReviewRow('Email', _emailController.text),
          ],
          onEdit: () => setState(() => _currentStep = 0),
        ),
        const SizedBox(height: 16),
        _buildReviewSection(
          'Parent Details',
          [
            _buildReviewRow("Father's Name", _fatherNameController.text),
            _buildReviewRow("Father's Phone", _fatherPhoneController.text),
            _buildReviewRow("Mother's Name", _motherNameController.text),
            _buildReviewRow("Mother's Phone", _motherPhoneController.text),
            _buildReviewRow("Pincode / ZIP", _pincodeController.text),
            _buildReviewRow("City", _cityController.text),
            _buildReviewRow("Country", _resCountryController.text),
          ],
          onEdit: () => setState(() => _currentStep = 1),
        ),
        const SizedBox(height: 16),
        _buildReviewSection(
          'Co-Applicant Details',
          [
            _buildReviewRow('Name', _coApplicantNameController.text),
            _buildReviewRow('Relationship', _coApplicantRelationController.text),
            _buildReviewRow('Phone', _coApplicantPhoneController.text),
            _buildReviewRow('Email', _coApplicantEmailController.text.isEmpty ? 'N/A' : _coApplicantEmailController.text),
            _buildReviewRow('Annual Income', '₹${_coApplicantIncomeController.text}'),
          ],
          onEdit: () => setState(() => _currentStep = 2),
        ),
        const SizedBox(height: 16),
        _buildReviewSection(
          'Education & Loan',
          [
            _buildReviewRow('Country', _countryController.text),
            _buildReviewRow('University', _instituteController.text),
            _buildReviewRow('Course', _courseController.text),
            _buildReviewRow('Amount', '₹${_amountController.text}'),
            _buildReviewRow('Collateral', _hasCollateral ? 'Yes (${_collateralController.text})' : 'No'),
          ],
          onEdit: () => setState(() => _currentStep = 3),
        ),
        const SizedBox(height: 20),
        const Text(
          'By submitting, you agree to our terms and conditions and permit us to share your details with selected lending partners.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReviewSection(String title, List<Widget> children, {VoidCallback? onEdit}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF311B92).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF311B92),
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF311B92),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
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
    bool isRequired = false,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
  }) {
    final errorText = _fieldErrors[controller];
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: hasError 
                ? Colors.red.withValues(alpha: 0.05) 
                : const Color(0xFF311B92).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError 
                  ? Colors.red 
                  : const Color(0xFF311B92).withValues(alpha: 0.05),
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            onChanged: (val) {
              if (hasError) {
                setState(() => _fieldErrors[controller] = null);
              }
              if (onChanged != null) {
                onChanged(val);
              }
            },
            style: const TextStyle(color: Colors.black, fontSize: 16),
            decoration: InputDecoration(
              hintText: isRequired ? '$hint *' : hint,
              hintStyle: TextStyle(
                color: isRequired
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
              prefix: keyboardType == TextInputType.phone 
                  ? Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '+91',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 20,
                            width: 1.5,
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                    )
                  : null,
              suffixIcon: suffixIcon ?? Icon(
                icon,
                color: hasError 
                    ? Colors.red 
                    : const Color(0xFF311B92).withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildReadOnlyInput({
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    required TextEditingController controller,
    bool isRequired = false,
  }) {
    final errorText = _fieldErrors[controller];
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (hasError) {
              setState(() => _fieldErrors[controller] = null);
            }
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: hasError 
                  ? Colors.red.withValues(alpha: 0.05) 
                  : const Color(0xFF311B92).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError 
                    ? Colors.red 
                    : const Color(0xFF311B92).withValues(alpha: 0.05),
                width: hasError ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: controller.text.isEmpty ? hint : controller.text,
                          style: TextStyle(
                            color: controller.text.isEmpty
                                ? Colors.black.withValues(alpha: 0.4)
                                : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        if (isRequired && controller.text.isEmpty)
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  icon, 
                  color: hasError 
                      ? Colors.red 
                      : const Color(0xFF311B92).withValues(alpha: 0.5)
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  /// Country picker field showing flag emoji + country name when selected
  Widget _buildCountryReadOnlyInput() {
    final errorText = _fieldErrors[_countryController];
    final hasError = errorText != null;
    final hasValue = _countryController.text.isNotEmpty;
    final flag = _selectedCountryFlag;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (hasError) setState(() => _fieldErrors[_countryController] = null);
            _showCountrySelection();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: hasError
                  ? Colors.red.withValues(alpha: 0.05)
                  : const Color(0xFF311B92).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError
                    ? Colors.red
                    : const Color(0xFF311B92).withValues(alpha: 0.05),
                width: hasError ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (hasValue && flag.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF311B92).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(flag, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: hasValue ? _countryController.text : 'Target Country',
                          style: TextStyle(
                            color: hasValue
                                ? Colors.black
                                : Colors.black.withValues(alpha: 0.4),
                            fontSize: 16,
                            fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        if (!hasValue)
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasError
                      ? Colors.red
                      : const Color(0xFF311B92).withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                  color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  /// Manual country text entry with real-time flag emoji prefix
  Widget _buildCountryManualInput() {
    final errorText = _fieldErrors[_countryController];
    final hasError = errorText != null;
    final flag = _selectedCountryFlag;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: hasError
                ? Colors.red.withValues(alpha: 0.05)
                : const Color(0xFF311B92).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError
                  ? Colors.red
                  : const Color(0xFF311B92).withValues(alpha: 0.05),
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Animated flag prefix (appears as user types a recognized country)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: flag.isNotEmpty
                    ? Container(
                        key: ValueKey(flag),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF311B92).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(flag,
                            style: const TextStyle(fontSize: 22)),
                      )
                    : Container(
                        key: const ValueKey('globe'),
                        margin: const EdgeInsets.only(right: 10),
                        child: Icon(
                          Icons.public,
                          color: const Color(0xFF311B92).withValues(alpha: 0.4),
                          size: 24,
                        ),
                      ),
              ),
              Expanded(
                child: TextField(
                  controller: _countryController,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  onChanged: (_) {
                    if (hasError) {
                      setState(() => _fieldErrors[_countryController] = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter Target Country *',
                    hintStyle: TextStyle(
                        color: Colors.black.withValues(alpha: 0.4)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              // Tap to switch back to picker
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isManualCountryEntry = false;
                    _countryController.clear();
                    _selectedCountryFlag = '';
                  });
                  _showCountrySelection();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF311B92).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.list_rounded,
                    size: 18,
                    color: const Color(0xFF311B92).withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (flag.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              'Country recognized  $flag',
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                  color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
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
        groupedRemaining = ",$groupedRemaining";
        count = 0;
      }
    }

    return "$groupedRemaining,$lastThree";
  }
}
