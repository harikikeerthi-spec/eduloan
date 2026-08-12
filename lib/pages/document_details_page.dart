import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_document.dart';
import '../services/user_service.dart';
import '../widgets/mesh_background.dart';

class DocumentDetailsPage extends StatefulWidget {
  const DocumentDetailsPage({super.key});

  @override
  State<DocumentDetailsPage> createState() => _DocumentDetailsPageState();
}

class _DocumentDetailsPageState extends State<DocumentDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<UserDocument> _userDocs = [];
  String? _coApplicantRelation;
  final Map<String, String> _localOcrNumbers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'anonymous';
      _coApplicantRelation = prefs.getString('co_applicant_relation_$userId') ?? prefs.getString('co_applicant_relation');

      // Load local OCR cached numbers for this specific user
      final keys = prefs.getKeys();
      final prefix = 'ocr_number_${userId}_';
      for (var k in keys) {
        if (k.startsWith(prefix)) {
          final type = k.replaceFirst(prefix, '');
          final val = prefs.getString(k);
          if (val != null && val.isNotEmpty) {
            _localOcrNumbers[type] = val;
          }
        } else if (k.startsWith('ocr_number_') && !k.contains('_user_') && !k.contains('_anon_')) {
          // Legacy fallback
          final type = k.replaceFirst('ocr_number_', '');
          final val = prefs.getString(k);
          if (val != null && val.isNotEmpty) {
            _localOcrNumbers[type] = val;
          }
        }
      }

      final docs = await UserService.getUserDocuments();
      if (mounted) {
        setState(() {
          _userDocs = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading document details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  UserDocument? _findDocInDetails(String type) {
    if (_userDocs.isEmpty) return null;
    final targetClean = type.trim().toLowerCase().replaceAll('-', '_');

    try {
      return _userDocs.firstWhere(
        (doc) => doc.docType.trim().toLowerCase().replaceAll('-', '_') == targetClean,
      );
    } catch (_) {}

    try {
      return _userDocs.firstWhere((doc) {
        final dt = doc.docType.trim().toLowerCase().replaceAll('-', '_');
        if (targetClean.contains('pan')) {
          if (targetClean.startsWith('father') && dt.contains('father') && dt.contains('pan')) return true;
          if (targetClean.startsWith('mother') && dt.contains('mother') && dt.contains('pan')) return true;
          if (targetClean.startsWith('coapp') && (dt.contains('coapp') || dt.contains('co_applicant')) && dt.contains('pan')) return true;
          if (targetClean.startsWith('student') && dt.contains('pan') && !dt.contains('father') && !dt.contains('mother') && !dt.contains('coapp')) return true;
          if (dt == 'pan' || dt == 'pan_card') return true;
        }
        if (targetClean.contains('aadhar') || targetClean.contains('aadhaar')) {
          if (targetClean.startsWith('father') && dt.contains('father') && (dt.contains('aadhar') || dt.contains('aadhaar'))) return true;
          if (targetClean.startsWith('mother') && dt.contains('mother') && (dt.contains('aadhar') || dt.contains('aadhaar'))) return true;
          if (targetClean.startsWith('coapp') && (dt.contains('coapp') || dt.contains('co_applicant')) && (dt.contains('aadhar') || dt.contains('aadhaar'))) return true;
          if (targetClean.startsWith('student') && (dt.contains('aadhar') || dt.contains('aadhaar')) && !dt.contains('father') && !dt.contains('mother') && !dt.contains('coapp')) return true;
          if (dt == 'aadhar' || dt == 'aadhaar' || dt == 'aadhar_card' || dt == 'aadhaar_card') return true;
        }
        if (targetClean.contains('passport')) {
          if (targetClean.contains('front') && (dt.contains('front') || dt == 'passport' || dt == 'student_passport')) return true;
          if (targetClean.contains('back') && dt.contains('back')) return true;
          if (dt == 'passport' || dt == 'student_passport') return true;
        }
        if (targetClean.contains('10th') && dt.contains('10th')) return true;
        if (targetClean.contains('12th') && dt.contains('12th')) return true;
        if (targetClean.contains('degree') && dt.contains('degree')) return true;
        return false;
      });
    } catch (_) {}

    return null;
  }

  String? _getExtractedNumberForDoc(String type) {
    final doc = _findDocInDetails(type);
    if (doc != null && doc.extractedNumber != null && doc.extractedNumber!.trim().isNotEmpty) {
      return doc.extractedNumber!.trim();
    }
    return _localOcrNumbers[type];
  }

  bool _isDocUploaded(String type) {
    final doc = _findDocInDetails(type);
    if (doc != null) {
      final s = doc.status.toLowerCase();
      return doc.uploaded || s == 'uploaded' || s == 'verified' || s == 'approved' || s == 'completed' || (doc.filePath != null && doc.filePath!.isNotEmpty);
    }
    return _localOcrNumbers.containsKey(type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF311B92)),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStudentTab(),
                          _buildCoApplicantTab(),
                          _buildParentsTab(),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF311B92), size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Details',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                Text(
                  'AI OCR Extracted Identifiers',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.refresh_rounded, color: Color(0xFF311B92), size: 20),
            ),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF311B92).withValues(alpha: 0.1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF311B92),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF311B92),
        indicatorWeight: 3,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Student'),
          Tab(text: 'Co-Applicant'),
          Tab(text: 'Parents'),
        ],
      ),
    );
  }

  Widget _buildStudentTab() {
    final List<Map<String, dynamic>> items = [
      {
        'type': 'student_passport',
        'label': 'Student Passport Number',
        'icon': Icons.flight_takeoff_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'type': 'student_aadhar',
        'label': 'Student Aadhar Number',
        'icon': Icons.fingerprint_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'type': 'student_pan',
        'label': 'Student PAN Number',
        'icon': Icons.badge_outlined,
        'color': const Color(0xFF311B92),
      },
      {
        'type': 'student_10th_marksheet',
        'label': '10th Marksheet Roll No',
        'icon': Icons.school_outlined,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'type': 'student_12th_marksheet',
        'label': '12th Marksheet Roll No',
        'icon': Icons.school_outlined,
        'color': const Color(0xFFEC4899),
      },
      {
        'type': 'student_degree_marksheet',
        'label': 'Degree Marksheet Reg No',
        'icon': Icons.school_outlined,
        'color': const Color(0xFFF59E0B),
      },
    ];
    return _buildDocList(items);
  }

  Widget _buildCoApplicantTab() {
    final List<Map<String, dynamic>> items = [
      {
        'type': 'coapp_pan',
        'label': 'Co-applicant PAN Number',
        'icon': Icons.badge_outlined,
        'color': const Color(0xFF0284C7),
      },
      {
        'type': 'coapp_aadhar',
        'label': 'Co-applicant Aadhar Number',
        'icon': Icons.fingerprint_rounded,
        'color': const Color(0xFF059669),
      },
    ];
    return _buildDocList(items);
  }

  Widget _buildParentsTab() {
    final List<Map<String, dynamic>> items = [];
    final relLower = (_coApplicantRelation ?? '').trim().toLowerCase();

    if (!relLower.contains('father')) {
      items.add({
        'type': 'father_pan',
        'label': 'Father PAN Number',
        'icon': Icons.badge_outlined,
        'color': const Color(0xFF475569),
      });
      items.add({
        'type': 'father_aadhar',
        'label': 'Father Aadhar Number',
        'icon': Icons.fingerprint_rounded,
        'color': const Color(0xFF475569),
      });
    }

    if (!relLower.contains('mother')) {
      items.add({
        'type': 'mother_pan',
        'label': 'Mother PAN Number',
        'icon': Icons.badge_outlined,
        'color': const Color(0xFF475569),
      });
      items.add({
        'type': 'mother_aadhar',
        'label': 'Mother Aadhar Number',
        'icon': Icons.fingerprint_rounded,
        'color': const Color(0xFF475569),
      });
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Parents documents are listed under Co-Applicant as per your application.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
          ),
        ),
      );
    }

    return _buildDocList(items);
  }

  Widget _buildDocList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final String type = item['type'];
        final String label = item['label'];
        final IconData icon = item['icon'];
        final Color color = item['color'];

        final String? extractedVal = _getExtractedNumberForDoc(type);
        final bool isUploaded = _isDocUploaded(type);
        final bool hasNumber = extractedVal != null && extractedVal.isNotEmpty;

        String displayVal = 'Not Uploaded Yet';
        if (hasNumber) {
          displayVal = extractedVal;
        } else if (isUploaded) {
          displayVal = 'Uploaded (AI Verified)';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUploaded
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF311B92).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUploaded) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF10B981)),
                                const SizedBox(width: 3),
                                Text(
                                  'AI Verified',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayVal,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isUploaded ? const Color(0xFF1E1B4B) : Colors.grey,
                        fontWeight: isUploaded ? FontWeight.w700 : FontWeight.w400,
                        letterSpacing: hasNumber ? 0.5 : 0.0,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasNumber)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF311B92).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF311B92)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: displayVal));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$label copied to clipboard!',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: const Color(0xFF311B92),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
