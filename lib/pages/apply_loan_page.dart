import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/mesh_background.dart';
import '../widgets/rupee_amount_helper.dart';
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
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _resCountryController = TextEditingController();
  bool _isPincodeResolving = false;
  Timer? _pincodeLookupTimer;

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
  String? _universityLocationWarning;

  static final Map<String, List<String>> _knownUniversitiesByCountry = {
    'usa': [
      'Harvard University',
      'Massachusetts Institute of Technology',
      'MIT',
      'Stanford University',
      'Columbia University',
      'University of California',
      'UC Berkeley',
      'UCLA',
      'Yale University',
      'Princeton University',
      'Cornell University',
      'New York University',
      'NYU',
      'Carnegie Mellon University',
      'University of Texas at Dallas',
      'University of Southern California',
      'Northeastern University',
      'Arizona State University',
      'University of Illinois',
    ],
    'united states': [
      'Harvard University',
      'Massachusetts Institute of Technology',
      'MIT',
      'Stanford University',
      'Columbia University',
      'University of California',
      'UC Berkeley',
      'UCLA',
      'Yale University',
      'Princeton University',
      'Cornell University',
      'New York University',
      'NYU',
      'Carnegie Mellon University',
      'University of Texas at Dallas',
      'University of Southern California',
      'Northeastern University',
      'Arizona State University',
      'University of Illinois',
    ],
    'uk': [
      'University of Oxford',
      'Oxford University',
      'University of Cambridge',
      'Cambridge University',
      'Imperial College London',
      'University College London',
      'UCL',
      'London School of Economics',
      'LSE',
      'University of Edinburgh',
      'King\'s College London',
      'University of Manchester',
      'University of Warwick',
      'University of Bristol',
    ],
    'united kingdom': [
      'University of Oxford',
      'Oxford University',
      'University of Cambridge',
      'Cambridge University',
      'Imperial College London',
      'University College London',
      'UCL',
      'London School of Economics',
      'LSE',
      'University of Edinburgh',
      'King\'s College London',
      'University of Manchester',
      'University of Warwick',
      'University of Bristol',
    ],
    'canada': [
      'University of Toronto',
      'University of British Columbia',
      'UBC',
      'McGill University',
      'University of Waterloo',
      'University of Alberta',
      'McMaster University',
      'Western University',
      'University of Montreal',
    ],
    'germany': [
      'Technical University of Munich',
      'TUM',
      'Ludwig Maximilian University',
      'LMU Munich',
      'Heidelberg University',
      'Humboldt University of Berlin',
      'RWTH Aachen University',
      'Free University of Berlin',
      'Karlsruhe Institute of Technology',
      'KIT',
      'TU Berlin',
    ],
    'australia': [
      'University of Melbourne',
      'University of Sydney',
      'Australian National University',
      'ANU',
      'University of Queensland',
      'Monash University',
      'UNSW Sydney',
      'University of Western Australia',
      'University of Adelaide',
    ],
    'ireland': [
      'Trinity College Dublin',
      'University College Dublin',
      'UCD',
      'National University of Ireland Galway',
      'University College Cork',
      'Dublin City University',
    ],
    'france': [
      'PSL Research University',
      'Institut Polytechnique de Paris',
      'Sorbonne University',
      'HEC Paris',
      'University of Paris-Saclay',
    ],
    'india': [
      'Indian Institute of Science',
      'IISc',
      'IIT Bombay',
      'IIT Delhi',
      'IIT Madras',
      'IIT Kharagpur',
      'IIT Kanpur',
      'University of Delhi',
      'BITS Pilani',
    ],
  };

  void _validateUniversityLocation() {
    final countryStr = _countryController.text.trim();
    final countryLower = countryStr.toLowerCase();
    final universityStr = _instituteController.text.trim();
    final uniLower = universityStr.toLowerCase();

    if (countryStr.isEmpty || universityStr.isEmpty || universityStr.length < 3) {
      _universityLocationWarning = null;
      return;
    }

    // Explicit cross-country mismatch detection
    String? foundCountry;
    _knownUniversitiesByCountry.forEach((cKey, uniList) {
      bool isSelectedCountryKey = (cKey == countryLower) ||
          (countryLower.contains('usa') && cKey.contains('united states')) ||
          (countryLower.contains('united states') && cKey.contains('usa')) ||
          (countryLower.contains('uk') && cKey.contains('united kingdom')) ||
          (countryLower.contains('united kingdom') && cKey.contains('uk'));

      if (!isSelectedCountryKey) {
        for (var knownUni in uniList) {
          final knownLower = knownUni.toLowerCase();
          if (uniLower == knownLower ||
              (knownLower.length >= 5 && uniLower.contains(knownLower)) ||
              (uniLower.length >= 6 && knownLower.contains(uniLower))) {
            foundCountry = cKey.toUpperCase();
            break;
          }
        }
      }
    });

    if (foundCountry != null) {
      _universityLocationWarning =
          'Warning: "$universityStr" is located in $foundCountry, not in $countryStr. Please enter a correct university located in $countryStr.';
      _fieldErrors[_instituteController] = 'University location mismatch';
      return;
    }

    // Country name token check within university text
    final checkCountries = {
      'usa': 'USA',
      'united states': 'USA',
      'uk': 'UK',
      'united kingdom': 'UK',
      'canada': 'Canada',
      'germany': 'Germany',
      'australia': 'Australia',
      'france': 'France',
      'ireland': 'Ireland',
      'india': 'India',
      'sydney': 'Australia',
      'melbourne': 'Australia',
      'oxford': 'UK',
      'cambridge': 'UK',
      'toronto': 'Canada',
      'munich': 'Germany',
      'berlin': 'Germany',
      'delhi': 'India',
      'bombay': 'India',
    };

    checkCountries.forEach((keyword, countryName) {
      if (uniLower.contains(keyword)) {
        bool matchesSelected = countryLower.contains(keyword) ||
            countryLower.contains(countryName.toLowerCase()) ||
            (countryLower.contains('usa') && countryName == 'USA') ||
            (countryLower.contains('united states') && countryName == 'USA') ||
            (countryLower.contains('uk') && countryName == 'UK') ||
            (countryLower.contains('united kingdom') && countryName == 'UK');

        if (!matchesSelected) {
          _universityLocationWarning =
              'Warning: "$universityStr" does not appear to be located in $countryStr. Please enter a correct university located in $countryStr.';
          _fieldErrors[_instituteController] = 'Location mismatch';
        }
      }
    });

    if (_fieldErrors[_instituteController] != 'University location mismatch' &&
        _fieldErrors[_instituteController] != 'Location mismatch') {
      _universityLocationWarning = null;
      _fieldErrors.remove(_instituteController);
    }
  }

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
    _pincodeLookupTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkExistingLoan();
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
    // Auto-fetch location when exactly 6 digits entered (debounced)
    _pincodeController.addListener(() {
      final clean = _pincodeController.text.trim();
      if (clean.isEmpty) {
        _pincodeLookupTimer?.cancel();
        setState(() {
          _cityController.clear();
          _stateController.clear();
          _resCountryController.clear();
        });
        return;
      }
      if (clean.length == 6 && RegExp(r'^\d{6}$').hasMatch(clean)) {
        _pincodeLookupTimer?.cancel();
        _pincodeLookupTimer = Timer(const Duration(milliseconds: 300), () {
          _autoDetectCityCountry(clean);
        });
      }
    });
  }

  Future<void> _checkExistingLoan() async {
    try {
      final loans = await LoanService().getUserLoans();
      if (loans.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already submitted a loan application.'),
            backgroundColor: Color(0xFF311B92),
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {}
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
        !_validateStep(3)) {
      return;
    }

    _validateUniversityLocation();
    if (_universityLocationWarning != null) {
      _showError(_universityLocationWarning!);
      return;
    }

    if (_countryController.text.isEmpty ||
        _instituteController.text.isEmpty ||
        _amountController.text.isEmpty) {
      _showError('Please complete all required fields in the application');
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
        bank: 'Pending Bank Assignment',
        loanType: _loanTypeController.text,
        amount: double.parse(_amountController.text.replaceAll(',', '')),
        tenure: 12, // Default tenure since field was removed
        purpose: 'Higher Education Loan',
        fatherName: _fatherNameController.text,
        fatherPhone: _fatherPhoneController.text,
        fatherEmail: _fatherEmailController.text,
        motherName: _motherNameController.text,
        motherPhone: _motherPhoneController.text,
        motherEmail: _motherEmailController.text,
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
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

      widget.onLoanSubmitted?.call();

      final uniName = _instituteController.text;
      final loanAmt = _amountController.text;
      final refCode = 'VL-${DateTime.now().year}-${(1000 + (DateTime.now().millisecondsSinceEpoch % 8999))}';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => LoanSuccessDialog(
          applicationRef: refCode,
          universityName: uniName.isEmpty ? 'Target University' : uniName,
          amount: loanAmt.isEmpty ? '0' : loanAmt,
          onViewLoans: () {
            Navigator.pop(dialogCtx);
            final mainNav = MainNavigation.of(context);
            if (mainNav != null) {
              mainNav.switchToTab(2); // Switch to My Loans tab
            } else {
              Navigator.pop(context);
            }
          },
          onGoHome: () {
            Navigator.pop(dialogCtx);
            final mainNav = MainNavigation.of(context);
            if (mainNav != null) {
              mainNav.switchToTab(0); // Switch to Dashboard tab
            } else {
              Navigator.pop(context);
            }
          },
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
          if (res['state'] != null && res['state'].toString().isNotEmpty) {
            _stateController.text = res['state'].toString();
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
      if (_countryController.text.trim().isEmpty) {
        setState(() => _fieldErrors[_countryController] = 'Required');
        _showError('Please select your target country');
        return false;
      }
      if (_instituteController.text.trim().isEmpty) {
        setState(() => _fieldErrors[_instituteController] = 'Required');
        _showError('Please enter your target university');
        return false;
      }
      _validateUniversityLocation();
      if (_universityLocationWarning != null) {
        _showError(_universityLocationWarning!);
        return false;
      }
      final rawAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (rawAmount.isEmpty) {
        setState(() => _fieldErrors[_amountController] = 'Required');
        _showError('Please enter the desired loan amount');
        return false;
      }
      final amountVal = double.tryParse(rawAmount) ?? 0;
      if (amountVal <= 0) {
        setState(() => _fieldErrors[_amountController] = 'Enter positive amount');
        _showError('Please enter a valid loan amount');
        return false;
      }
      if (amountVal > 15000000) {
        setState(() => _fieldErrors[_amountController] = 'Max ₹1.5 Cr');
        _showError('Maximum loan amount allowed is ₹1.5 Crore (₹1,50,00,000)');
        return false;
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

  final List<String> _stepLabels = ['Personal', 'Address', 'Co-Applicant', 'Info', 'Review'];

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
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                        color: isActive ? const Color(0xFF311B92) : const Color(0xFF94A3B8),
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
            _buildSectionHeader("Personal Details", Icons.person_outline_rounded),
            _buildTextInput(
              hint: 'First Name',
              icon: Icons.person_outline,
              controller: _firstNameController,
              isRequired: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextInput(
              hint: 'Last Name',
              icon: Icons.person_outline,
              controller: _lastNameController,
              isRequired: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextInput(
              hint: 'Phone Number',
              icon: Icons.phone_outlined,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              isRequired: true,
            ),
            const SizedBox(height: 12),
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
            _buildSectionHeader("Residential Details", Icons.home_outlined),
            _buildTextInput(
              hint: 'Pincode / ZIP Code',
              icon: Icons.pin_drop_outlined,
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              isRequired: true,
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
                  : IconButton(
                      icon: const Icon(
                        Icons.my_location_outlined,
                        color: Color(0xFF311B92),
                        size: 20,
                      ),
                      tooltip: 'Auto-detect location',
                      onPressed: () {
                        final pin = _pincodeController.text.trim();
                        if (pin.isNotEmpty) {
                          _autoDetectCityCountry(pin);
                        }
                      },
                    ),
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
              hint: 'State / Province',
              icon: Icons.map_outlined,
              controller: _stateController,
              isRequired: false,
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
            _buildSectionHeader("Co-Applicant Details", Icons.people_outline_rounded),
            _buildTextInput(
              hint: 'Co-applicant Name',
              icon: Icons.person_outline,
              controller: _coApplicantNameController,
              isRequired: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextInput(
              hint: 'Relationship',
              icon: Icons.people_outline,
              controller: _coApplicantRelationController,
              readOnly: true,
              onTap: _showRelationSelection,
              isRequired: true,
            ),
            const SizedBox(height: 12),
            _buildTextInput(
              hint: 'Phone Number',
              icon: Icons.phone_outlined,
              controller: _coApplicantPhoneController,
              keyboardType: TextInputType.phone,
              isRequired: true,
            ),
            const SizedBox(height: 12),
            _buildTextInput(
              hint: 'Email Address',
              icon: Icons.email_outlined,
              controller: _coApplicantEmailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildTextInput(
              hint: 'Annual Income (INR)',
              icon: Icons.currency_rupee,
              controller: _coApplicantIncomeController,
              keyboardType: TextInputType.number,
              isRequired: true,
              onChanged: (val) => setState(() {}),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                IndianCurrencyFormatter(maxDigits: 8),
              ],
            ),
            RupeeAmountHelperCard(
              amountText: _coApplicantIncomeController.text,
              label: 'Annual Income',
            ),
          ],
        );
      case 3:
        return _buildStepContainer(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF311B92).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Color(0xFF311B92), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pledge Collateral / Security',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Property, Fixed Deposit, or Land',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _hasCollateral,
                    activeTrackColor: const Color(0xFF311B92),
                    onChanged: (val) => setState(() => _hasCollateral = val),
                  ),
                ],
              ),
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
            const SizedBox(height: 18),
            _buildSectionHeader('Education Information', Icons.school_outlined),
            _isManualCountryEntry
                ? _buildCountryManualInput()
                : _buildCountryReadOnlyInput(),
            const SizedBox(height: 12),
            if (_countryController.text.trim().isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF311B92).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF311B92).withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: Color(0xFF311B92)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please select your Target Country above to select your target university.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF311B92),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildTextInput(
                hint: 'Target University',
                icon: Icons.account_balance_outlined,
                controller: _instituteController,
                isRequired: true,
                onChanged: (val) {
                  setState(() {
                    _validateUniversityLocation();
                  });
                },
              ),
              if (_universityLocationWarning != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _universityLocationWarning!,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF991B1B),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 18),
            _buildSectionHeader('Financial Information', Icons.account_balance_wallet_outlined),
            _buildTextInput(
              hint: 'Desired Loan Amount (₹)',
              icon: Icons.currency_rupee,
              controller: _amountController,
              keyboardType: TextInputType.number,
              isRequired: true,
              onChanged: _updateAmountInLakhsLabel,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                IndianCurrencyFormatter(maxAmount: 15000000),
              ],
            ),
            if (_amountInLakhsLabel.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF311B92).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF311B92).withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF311B92)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _amountInLakhsLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF311B92),
                        ),
                      ),
                    ),
                  ],
                ),
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Back', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_validateStep(_currentStep)) {
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
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                _currentStep == 4
                    ? 'Submit Application'
                    : _currentStep == 3
                        ? 'Review Details'
                        : 'Continue',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
        // Premium summary banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF311B92), Color(0xFF6200EA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF311B92).withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'APPLICATION SUMMARY',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Ready to submit',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _instituteController.text.isEmpty ? 'Target University' : _instituteController.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Target Country: ${_countryController.text.isEmpty ? "Country" : _countryController.text}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white24, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LOAN AMOUNT REQUESTED',
                        style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _amountController.text.isEmpty ? '₹0' : '₹${_amountController.text}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'COLLATERAL OFFERED',
                        style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hasCollateral ? 'Yes' : 'No',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildReviewSection(
          'Personal Details',
          Icons.person_outline_rounded,
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
          Icons.family_restroom_rounded,
          [
            _buildReviewRow("Father's Name", _fatherNameController.text),
            _buildReviewRow("Father's Phone", _fatherPhoneController.text),
            _buildReviewRow("Mother's Name", _motherNameController.text),
            _buildReviewRow("Mother's Phone", _motherPhoneController.text),
            _buildReviewRow("Pincode / ZIP", _pincodeController.text),
            _buildReviewRow("City", _cityController.text),
            _buildReviewRow("State", _stateController.text.isEmpty ? 'N/A' : _stateController.text),
            _buildReviewRow("Country", _resCountryController.text),
          ],
          onEdit: () => setState(() => _currentStep = 1),
        ),
        const SizedBox(height: 16),
        _buildReviewSection(
          'Co-Applicant Details',
          Icons.people_outline_rounded,
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
          'Education & Loan Details',
          Icons.school_outlined,
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

  Widget _buildReviewSection(
    String title,
    IconData icon,
    List<Widget> children, {
    required VoidCallback onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF311B92).withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF311B92).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: const Color(0xFF311B92),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.mode_edit_outline_outlined, size: 18, color: Color(0xFF311B92)),
                onPressed: onEdit,
                tooltip: 'Edit Section',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF311B92).withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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

  void _updateAmountInLakhsLabel(String val) {
    setState(() {
      _amountInLakhsLabel = getRupeeAmountHelperText(val, label: 'Amount');
    });
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF311B92).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF311B92)),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
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
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
  }) {
    final errorText = _fieldErrors[controller];
    final hasError = errorText != null;
    final isPhoneField = keyboardType == TextInputType.phone || hint.toLowerCase().contains('phone');
    final isEmailField = keyboardType == TextInputType.emailAddress || hint.toLowerCase().contains('email');
    final effectiveFormatters = isPhoneField
        ? [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ]
        : isEmailField
            ? [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@.]')),
              ]
            : inputFormatters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: hasError
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFE2E8F0),
              width: hasError ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  readOnly: readOnly,
                  showCursor: !readOnly,
                  onTap: onTap,
                  maxLines: maxLines,
                  maxLength: isPhoneField ? 10 : null,
                  buildCounter: isPhoneField
                      ? (context, {required currentLength, required isFocused, maxLength}) => null
                      : null,
                  inputFormatters: effectiveFormatters,
                  onChanged: (val) {
                    if (hasError) {
                      setState(() => _fieldErrors[controller] = null);
                    }
                    if (onChanged != null) {
                      onChanged(val);
                    }
                  },
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: isRequired ? '$hint *' : hint,
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    prefixIcon: keyboardType == TextInputType.phone
                        ? Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+91',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  height: 16,
                                  width: 1,
                                  color: const Color(0xFFCBD5E1),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          )
                        : null,
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
              ),
              suffixIcon ??
                  Icon(
                    icon,
                    color: hasError
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF64748B),
                    size: 20,
                  ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText,
              style: GoogleFonts.outfit(
                color: const Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: hasError
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE2E8F0),
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                if (hasValue && flag.isNotEmpty) ...[
                  Text(flag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    hasValue ? _countryController.text : 'Target Country *',
                    style: GoogleFonts.outfit(
                      color: hasValue
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasError
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF64748B),
                  size: 20,
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
              style: GoogleFonts.outfit(
                color: const Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: hasError
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFE2E8F0),
              width: hasError ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: flag.isNotEmpty
                    ? Container(
                        key: ValueKey(flag),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF311B92).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(flag,
                            style: const TextStyle(fontSize: 16)),
                      )
                    : Container(
                        key: const ValueKey('globe'),
                        margin: const EdgeInsets.only(right: 8),
                        child: const Icon(
                          Icons.public,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
              ),
              Expanded(
                child: TextField(
                  controller: _countryController,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (_) {
                    if (hasError) {
                      setState(() => _fieldErrors[_countryController] = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter Target Country *',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
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
                  child: const Icon(
                    Icons.list_rounded,
                    size: 18,
                    color: Color(0xFF311B92),
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
  final double? maxAmount;
  final int? maxDigits;

  IndianCurrencyFormatter({this.maxAmount, this.maxDigits});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.isEmpty) return newValue.copyWith(text: '');

    if (maxDigits != null && text.length > maxDigits!) {
      text = text.substring(0, maxDigits!);
    }

    if (maxAmount != null) {
      final parsed = double.tryParse(text);
      if (parsed != null && parsed > maxAmount!) {
        text = maxAmount!.toInt().toString();
      }
    }

    String formatted = _formatIndianCurrency(text);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatIndianCurrency(String text) {
    if (text.length <= 3) return text;

    String lastThree = text.substring(text.length - 3);
    String remaining = text.substring(0, text.length - 3);

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

class LoanSuccessDialog extends StatefulWidget {
  final String applicationRef;
  final String universityName;
  final String amount;
  final VoidCallback onViewLoans;
  final VoidCallback onGoHome;

  const LoanSuccessDialog({
    super.key,
    required this.applicationRef,
    required this.universityName,
    required this.amount,
    required this.onViewLoans,
    required this.onGoHome,
  });

  @override
  State<LoanSuccessDialog> createState() => _LoanSuccessDialogState();
}

class _LoanSuccessDialogState extends State<LoanSuccessDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF311B92).withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Glowing Checkmark Icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'Application Submitted!',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your loan application for ${widget.universityName} has been successfully submitted.',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Summary Detail Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Application Ref:',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              widget.applicationRef,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF311B92),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Requested Amount:',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '₹${widget.amount}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status:',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Under Review',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: widget.onViewLoans,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF311B92),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'View My Loans',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: widget.onGoHome,
                      child: Text(
                        'Back to Dashboard',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
