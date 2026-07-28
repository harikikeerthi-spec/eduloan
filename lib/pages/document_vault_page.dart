import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_document.dart';
import '../services/user_service.dart';
import '../widgets/mesh_background.dart';

class DocumentVaultPage extends StatefulWidget {
  const DocumentVaultPage({super.key});

  @override
  State<DocumentVaultPage> createState() => _DocumentVaultPageState();
}

class _DocumentVaultPageState extends State<DocumentVaultPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<UserDocument> _documents = [];
  String? _coApplicantType; // 'Salaried' or 'Self Employed' or null

  // Document Categories based on user request
  final Map<String, List<Map<String, String>>> _studentDocs = {
    'KYC': [
      {'name': 'PAN Card', 'type': 'student_pan'},
      {'name': 'Aadhar Card', 'type': 'student_aadhar'},
      {'name': 'Passport Copy', 'type': 'student_passport'},
    ],
    'Academics': [
      {'name': '10th Marksheet', 'type': 'student_10th_marksheet'},
      {'name': '12th Marksheet', 'type': 'student_12th_marksheet'},
      {'name': 'Degree Marksheet', 'type': 'student_degree_marksheet'},
      {'name': 'Test Score Card', 'type': 'student_test_score'},
      {'name': 'University Offer Letter', 'type': 'student_offer_letter'},
    ],
  };

  final Map<String, List<Map<String, String>>> _coApplicantSalariedDocs = {
    'KYC': [
      {'name': 'Co-applicant PAN Card', 'type': 'coapp_pan'},
      {'name': 'Co-applicant Aadhar Card', 'type': 'coapp_aadhar'},
      {'name': 'Latest Electricity Bill', 'type': 'coapp_electricity_bill'},
    ],
    'Financials': [
      {'name': 'Last 3 Months Salary Slip', 'type': 'coapp_salary_slip'},
      {
        'name': 'Last 6 Months Bank Statement (Salary)',
        'type': 'coapp_bank_statement_salary',
      },
      {'name': 'Last 1 Year Form 16 / ITR', 'type': 'coapp_form16_itr'},
    ],
  };

  final Map<String, List<Map<String, String>>> _coApplicantSelfEmployedDocs = {
    'KYC': [
      {'name': 'Co-applicant PAN Card', 'type': 'coapp_pan'},
      {'name': 'Co-applicant Aadhar Card', 'type': 'coapp_aadhar'},
      {'name': 'Latest Electricity Bill', 'type': 'coapp_electricity_bill'},
    ],
    'Financials': [
      {
        'name': 'Last 2 Years ITR with Computation',
        'type': 'coapp_itr_computation',
      },
      {
        'name': 'Balance Sheet & P&L Account',
        'type': 'coapp_balance_sheet_pnl',
      },
      {
        'name': 'Business Registration Proof (GST/Others)',
        'type': 'coapp_business_proof',
      },
      {
        'name': 'Last 1 Year Bank Statement (Current & Saving)',
        'type': 'coapp_bank_statement_business',
      },
    ],
  };

  final Map<String, List<Map<String, String>>> _parentsDocs = {
    'Father': [
      {'name': 'Father PAN Card', 'type': 'father_pan'},
      {'name': 'Father Aadhar Card', 'type': 'father_aadhar'},
    ],
    'Mother': [
      {'name': 'Mother PAN Card', 'type': 'mother_pan'},
      {'name': 'Mother Aadhar Card', 'type': 'mother_aadhar'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() => _isLoading = true);

    // Load persisted co-applicant type
    final prefs = await SharedPreferences.getInstance();
    _coApplicantType = prefs.getString('co_applicant_type');

    final docs = await UserService.getUserDocuments();
    if (mounted) {
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCoApplicantType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('co_applicant_type', type);
    setState(() {
      _coApplicantType = type;
    });
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  UserDocument? _findDoc(String type) {
    try {
      return _documents.firstWhere((doc) => doc.docType == type);
    } catch (e) {
      return null;
    }
  }

  Future<void> _uploadDocument(String type, String name) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Uploading $name...')));
      }

      String? errorMessage = await UserService.uploadDocument(file, type);

      if (mounted) {
        if (errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload successful!'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchDocuments();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStudentTab(),
                    _buildCoApplicantTab(),
                    _buildParentsTab(), // Placeholder for Parents if needed, currently reusing logic
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF311B92)),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Document Vault',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF311B92),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF311B92).withValues(alpha: 0.1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF311B92),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF311B92),
        indicatorWeight: 3,
        overlayColor: WidgetStateProperty.all(
          const Color(0xFF311B92).withValues(alpha: 0.1),
        ),
        tabs: const [
          Tab(text: 'Student'),
          Tab(text: 'Co-Applicant'),
          Tab(text: 'Parents'),
        ],
      ),
    );
  }

  Widget _buildStudentTab() {
    return _buildSectionList(_studentDocs);
  }

  Widget _buildCoApplicantTab() {
    if (_coApplicantType == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_alt_outlined,
                size: 64,
                color: Color(0xFF311B92),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose Co-Applicant Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF311B92),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select the employment type of your co-applicant. This selection will be locked once chosen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveCoApplicantType('Salaried'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF311B92),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Salaried'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveCoApplicantType('Self Employed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF311B92),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Self Employed'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        // Toggle Switch (Locked)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              _buildToggleOption('Salaried'),
              _buildToggleOption('Self Employed'),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 12, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                'Type is locked after selection',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildSectionList(
            _coApplicantType == 'Salaried'
                ? _coApplicantSalariedDocs
                : _coApplicantSelfEmployedDocs,
          ),
        ),
      ],
    );
  }

  Widget _buildParentsTab() {
    return _buildSectionList(_parentsDocs);
  }

  Widget _buildToggleOption(String text) {
    bool isSelected = _coApplicantType == text;
    // Type is locked, so no onTap
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF311B92) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionList(Map<String, List<Map<String, String>>> sections) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: sections.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF311B92),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF311B92),
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map((docDef) {
              final existingDoc = _findDoc(docDef['type']!);
              return _buildDocCard(
                docDef['name']!,
                docDef['type']!,
                existingDoc,
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDocCard(String name, String type, UserDocument? doc) {
    bool isFromDigilocker = (doc?.isDigilocker ?? false) || doc?.status == 'available_in_digilocker';
    bool hasFile = doc?.filePath != null && doc!.filePath!.isNotEmpty;
    bool isVerified = doc?.status == 'verified';
    
    bool isAvailable = doc != null && (isFromDigilocker || hasFile);
    bool isUploaded = isAvailable;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUploaded 
              ? Colors.green.withValues(alpha: 0.15) 
              : const Color(0xFF311B92).withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Icon Indicator
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isUploaded
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isUploaded ? Icons.verified_user_rounded : Icons.file_present_rounded,
                  color: isUploaded ? const Color(0xFF2E7D32) : const Color(0xFF6200EA),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Document Name and Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isUploaded
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isUploaded 
                                ? (isFromDigilocker ? 'DigiLocker' : (isVerified ? 'Verified' : 'Uploaded'))
                                : 'Pending',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isUploaded 
                                  ? const Color(0xFF2E7D32) 
                                  : const Color(0xFFE65100),
                            ),
                          ),
                        ),
                        if (isUploaded && doc.uploadedAt != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            doc.uploadedAt!.toIso8601String().split('T')[0],
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action Buttons
              if (isUploaded)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactActionButton(
                      icon: Icons.visibility_rounded,
                      color: const Color(0xFF1E88E5),
                      onTap: () async {
                        final token = await _getToken();
                        final url = await UserService.getDocumentViewUrl(type);
                        final uri = Uri.parse('$url?token=$token');

                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open document')),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildCompactActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFE53935),
                      onTap: () async {
                        bool? confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Delete Document'),
                            content: Text('Are you sure you want to delete $name?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              TextButton(
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          setState(() => _isLoading = true);
                          await UserService.deleteDocument(type);
                          _fetchDocuments();
                        }
                      },
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: () => _uploadDocument(type, name),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF311B92),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    'Upload',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
