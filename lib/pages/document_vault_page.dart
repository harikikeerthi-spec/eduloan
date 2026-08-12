import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_document.dart';
import '../services/user_service.dart';
import '../services/loan_service.dart';
import '../services/notification_service.dart';
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
  String? _coApplicantRelation;

  final Map<String, String> _uploadedFileFingerprints = {};
  final Map<String, String> _uploadedDocNames = {};

  Map<String, List<Map<String, String>>> _customDocs = {
    'Student': [],
    'Co-Applicant': [],
    'Parents': [],
  };

  // Document Categories based on user request
  final Map<String, List<Map<String, String>>> _studentDocs = {
    'KYC': [
      {'name': 'Passport (Front & Back)', 'type': 'student_passport'},
      {'name': 'Aadhar Card', 'type': 'student_aadhar'},
      {'name': 'PAN Card', 'type': 'student_pan'},
    ],
    'Academics': [
      {'name': '10th Marksheet', 'type': 'student_10th_marksheet'},
      {'name': '12th Marksheet', 'type': 'student_12th_marksheet'},
      {'name': 'Degree Marksheet', 'type': 'student_degree_marksheet'},
    ],
  };

  final Map<String, List<Map<String, String>>> _coApplicantDocs = {
    'KYC': [
      {'name': 'Co-applicant PAN Card', 'type': 'coapp_pan'},
      {'name': 'Co-applicant Aadhar Card', 'type': 'coapp_aadhar'},
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

  Future<void> _loadCustomDocs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'anonymous';
      final String? jsonStr = prefs.getString('custom_vault_docs_$userId');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        _customDocs = {
          'Student': List<Map<String, String>>.from(
              (decoded['Student'] ?? []).map((x) => Map<String, String>.from(x))),
          'Co-Applicant': List<Map<String, String>>.from(
              (decoded['Co-Applicant'] ?? []).map((x) => Map<String, String>.from(x))),
          'Parents': List<Map<String, String>>.from(
              (decoded['Parents'] ?? []).map((x) => Map<String, String>.from(x))),
        };
      } else {
        _customDocs = {
          'Student': [],
          'Co-Applicant': [],
          'Parents': [],
        };
      }
    } catch (e) {
      debugPrint('Error loading custom vault docs: $e');
    }
  }

  Future<void> _saveCustomDocs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'anonymous';
      await prefs.setString('custom_vault_docs_$userId', jsonEncode(_customDocs));
    } catch (e) {
      debugPrint('Error saving custom vault docs: $e');
    }
  }

  Future<String> _getFileFingerprint(File file) async {
    final length = await file.length();
    final name = file.path.split(RegExp(r'[/\\]')).last.toLowerCase();
    try {
      final raf = await file.open();
      final sampleSize = length < 2048 ? length : 2048;
      final sample = Uint8List(sampleSize);
      await raf.readInto(sample);
      await raf.close();
      final sampleString = sample.sublist(0, sampleSize > 100 ? 100 : sampleSize).join('_');
      return '${length}_${name}_$sampleString';
    } catch (_) {
      return '${length}_$name';
    }
  }

  Future<void> _loadFingerprints() async {
    _uploadedFileFingerprints.clear();
    _uploadedDocNames.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'anonymous';
      final fpPrefix = 'fingerprint_${userId}_';
      final dnPrefix = 'docname_${userId}_';

      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith(fpPrefix)) {
          final docType = key.replaceFirst(fpPrefix, '');
          final fp = prefs.getString(key);
          if (fp != null) _uploadedFileFingerprints[docType] = fp;
        }
        if (key.startsWith(dnPrefix)) {
          final docType = key.replaceFirst(dnPrefix, '');
          final dn = prefs.getString(key);
          if (dn != null) _uploadedDocNames[docType] = dn;
        }
      }
    } catch (e) {
      debugPrint('Error loading fingerprints: $e');
    }
  }

  Future<void> _saveFingerprint(String docType, String docName, String fingerprint) async {
    _uploadedFileFingerprints[docType] = fingerprint;
    _uploadedDocNames[docType] = docName;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'anonymous';
      await prefs.setString('fingerprint_${userId}_$docType', fingerprint);
      await prefs.setString('docname_${userId}_$docType', docName);
    } catch (e) {
      debugPrint('Error saving fingerprint: $e');
    }
  }

  Future<void> _deleteFingerprint(String docType) async {
    _uploadedFileFingerprints.remove(docType);
    _uploadedDocNames.remove(docType);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'anonymous';
      await prefs.remove('fingerprint_${userId}_$docType');
      await prefs.remove('docname_${userId}_$docType');
      await prefs.remove('ocr_number_${userId}_$docType');
    } catch (e) {
      debugPrint('Error deleting fingerprint for $docType: $e');
    }
  }

  Future<void> _extractAndStoreOcrNumber(File file, String docType) async {
    try {
      final bytes = await file.readAsBytes();
      final sampleLen = bytes.length > 50000 ? 50000 : bytes.length;
      final rawString = String.fromCharCodes(bytes.sublist(0, sampleLen));
      
      String? extractedNumber;

      final typeLower = docType.toLowerCase();
      if (typeLower.contains('pan')) {
        final match = RegExp(r'\b[A-Z]{5}[0-9]{4}[A-Z]\b').firstMatch(rawString.toUpperCase());
        if (match != null) extractedNumber = match.group(0);
      } else if (typeLower.contains('aadhar') || typeLower.contains('aadhaar')) {
        final match = RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b').firstMatch(rawString);
        if (match != null) extractedNumber = match.group(0);
      } else if (typeLower.contains('passport')) {
        final match = RegExp(r'\b[A-Z][0-9]{7}\b').firstMatch(rawString.toUpperCase());
        if (match != null) extractedNumber = match.group(0);
      }

      if (extractedNumber != null && extractedNumber.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId') ?? 'anonymous';
        await prefs.setString('ocr_number_${userId}_$docType', extractedNumber);
      }
    } catch (e) {
      debugPrint('Error extracting OCR number locally: $e');
    }
  }

  Future<String?> _validateDocumentTypeMismatch(File file, String targetDocType, String targetDocName) async {
    final pathLower = file.path.toLowerCase();
    String contentText = pathLower;

    try {
      final bytes = await file.readAsBytes();
      final sampleLen = bytes.length > 30000 ? 30000 : bytes.length;
      final rawString = String.fromCharCodes(bytes.sublist(0, sampleLen)).toLowerCase();
      contentText = '$pathLower $rawString';
    } catch (_) {}

    final typeLower = targetDocType.toLowerCase();

    // Keywords for Aadhaar Card
    final isAadhaarContent = contentText.contains('unique identification') ||
        contentText.contains('aadhaar') ||
        contentText.contains('aadhar') ||
        contentText.contains('uidai') ||
        RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b').hasMatch(contentText);

    // Keywords for PAN Card
    final isPanContent = contentText.contains('income tax') ||
        contentText.contains('permanent account') ||
        contentText.contains('tax department') ||
        RegExp(r'[a-z]{5}[0-9]{4}[a-z]{1}').hasMatch(contentText);

    // Keywords for Passport
    final isPassportContent = contentText.contains('passport') ||
        contentText.contains('republic of india') ||
        contentText.contains('p<ind') ||
        contentText.contains('mrz');

    // 1. Target slot is Aadhaar Card
    if (typeLower.contains('aadhar') || typeLower.contains('aadhaar')) {
      if (isPanContent && !isAadhaarContent) {
        return 'You are uploading a PAN Card in the Aadhar Card slot. Please change it and upload your Aadhar Card.';
      }
      if (isPassportContent && !isAadhaarContent) {
        return 'You are uploading a Passport in the Aadhar Card slot. Please change it and upload your Aadhar Card.';
      }
    }

    // 2. Target slot is PAN Card
    if (typeLower.contains('pan')) {
      if (isAadhaarContent && !isPanContent) {
        return 'You are uploading an Aadhar Card in the PAN Card slot. Please change it and upload your PAN Card.';
      }
      if (isPassportContent && !isPanContent) {
        return 'You are uploading a Passport in the PAN Card slot. Please change it and upload your PAN Card.';
      }
    }

    // 3. Target slot is Passport
    if (typeLower.contains('passport')) {
      if (isAadhaarContent && !isPassportContent) {
        return 'You are uploading an Aadhar Card in the Passport slot. Please change it and upload your Passport.';
      }
      if (isPanContent && !isPassportContent) {
        return 'You are uploading a PAN Card in the Passport slot. Please change it and upload your Passport.';
      }
    }

    return null;
  }

  Future<void> _fetchDocuments() async {
    setState(() => _isLoading = true);
    await _loadCustomDocs();
    await _loadFingerprints();

    final prefs = await SharedPreferences.getInstance();
    _coApplicantRelation = prefs.getString('co_applicant_relation');

    try {
      final loans = await LoanService().getUserLoans();
      if (loans.isNotEmpty) {
        final lastLoan = loans.first;
        if (lastLoan.coApplicantRelation != null && lastLoan.coApplicantRelation!.isNotEmpty) {
          _coApplicantRelation = lastLoan.coApplicantRelation;
          await prefs.setString('co_applicant_relation', _coApplicantRelation!);
        }
      }
    } catch (e) {
      debugPrint('Error fetching user loans for relation filter: $e');
    }

    final docs = await UserService.getUserDocuments();

    // Auto-discover backend uploaded custom documents
    for (var doc in docs) {
      if (doc.docType.startsWith('custom_')) {
        String cat = 'Student';
        if (doc.docType.contains('co_applicant') || doc.docType.contains('coapp')) {
          cat = 'Co-Applicant';
        } else if (doc.docType.contains('parents') || doc.docType.contains('father') || doc.docType.contains('mother')) {
          cat = 'Parents';
        }
        final existingList = _customDocs[cat] ?? [];
        if (!existingList.any((item) => item['type'] == doc.docType)) {
          existingList.add({
            'name': doc.displayName.isNotEmpty ? doc.displayName : 'Custom Document',
            'type': doc.docType,
          });
          _customDocs[cat] = existingList;
        }
      }
    }
    await _saveCustomDocs();

    if (mounted) {
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  UserDocument? _findDoc(String type) {
    if (_documents.isEmpty) return null;
    final targetClean = type.trim().toLowerCase().replaceAll('-', '_');

    // 1. Direct case-insensitive match
    try {
      return _documents.firstWhere(
        (doc) => doc.docType.trim().toLowerCase().replaceAll('-', '_') == targetClean,
      );
    } catch (_) {}

    // 2. Fuzzy alias matching between website docType and app docType
    try {
      return _documents.firstWhere((doc) {
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

  /// Detects if a PDF is password-protected by scanning raw bytes for /Encrypt.
  Future<bool> _isPdfPasswordProtected(File file) async {
    try {
      if (!file.path.toLowerCase().endsWith('.pdf')) return false;
      final int fileSize = await file.length();
      final int readSize = fileSize < 65536 ? fileSize : 65536;
      final RandomAccessFile raf = await file.open();
      final Uint8List headBytes = Uint8List(readSize);
      await raf.readInto(headBytes);
      await raf.close();
      Uint8List tailBytes = Uint8List(0);
      if (fileSize > readSize) {
        final int tailSize = fileSize < 4096 ? fileSize : 4096;
        final RandomAccessFile raf2 = await file.open();
        await raf2.setPosition(fileSize - tailSize);
        tailBytes = Uint8List(tailSize);
        await raf2.readInto(tailBytes);
        await raf2.close();
      }
      final String combined =
          '${String.fromCharCodes(headBytes)} ${String.fromCharCodes(tailBytes)}';
      return combined.contains('/Encrypt');
    } catch (e) {
      debugPrint('PDF password check error: $e');
      return false;
    }
  }

  /// Secure password dialog for password-protected documents.
  /// Returns the entered password or null if cancelled.
  Future<String?> _showPasswordDialog(String docName) async {
    final TextEditingController passCtrl = TextEditingController();
    bool obscure = true;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF311B92).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_rounded, color: Color(0xFF311B92), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Document Password',
                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('"$docName" is password protected.',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
              const SizedBox(height: 4),
              Text('Enter the document password to proceed with upload.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: obscure,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter document password',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.vpn_key_rounded, size: 18, color: Color(0xFF311B92)),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 18, color: Colors.grey),
                    onPressed: () => setSt(() => obscure = !obscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF311B92), width: 1.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Used only to unlock the document for verification.',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                final pwd = passCtrl.text.trim();
                if (pwd.isEmpty) return;
                Navigator.pop(ctx, pwd);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF311B92),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text('Upload', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocument(String type, String name) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'heif', 'doc', 'docx', 'webp'],
    );

    if (result == null || result.files.single.path == null) return;

    File file = File(result.files.single.path!);

    // ─── DUPLICATE DOCUMENT CHECK ─────────────────────────────────────────
    final String fingerprint = await _getFileFingerprint(file);
    String? duplicateDocName;

    _uploadedFileFingerprints.forEach((existingType, existingFp) {
      if (existingType != type && existingFp == fingerprint) {
        duplicateDocName = _uploadedDocNames[existingType] ?? existingType;
      }
    });

    if (duplicateDocName != null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Text(
                  'Duplicate Document',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF311B92),
                  ),
                ),
              ],
            ),
            content: Text(
              'This document is already uploaded under "$duplicateDocName".\n\nEach document can only be uploaded once. If you want to move it here, please delete it from "$duplicateDocName" first.',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF311B92),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }
    // ──────────────────────────────────────────────────────────────────────

    // ─── DOCUMENT TYPE MISMATCH PRE-CHECK ──────────────────────────────────
    final String? mismatchError = await _validateDocumentTypeMismatch(file, type, name);
    if (mismatchError != null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Text(
                  'Wrong Document Type',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF311B92),
                  ),
                ),
              ],
            ),
            content: Text(
              mismatchError,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF311B92),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }
    // ──────────────────────────────────────────────────────────────────────

    String? docPassword;

    // ── Password Protection Check ──────────────────────────────────────────
    final bool isProtected = await _isPdfPasswordProtected(file);
    if (isProtected) {
      if (!mounted) return;
      docPassword = await _showPasswordDialog(name);
      // If user cancelled the password dialog, abort upload
      if (docPassword == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload of "$name" cancelled.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }
    // ────────────────────────────────────────────────────────────────────────

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Uploading $name${isProtected ? ' (unlocking...)' : ''}...'),
            ],
          ),
          duration: const Duration(minutes: 2),
        ),
      );
    }

    String? errorMessage = await UserService.uploadDocument(
      file,
      type,
      password: docPassword,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (errorMessage == null) {
        _saveFingerprint(type, name, fingerprint);
        await _extractAndStoreOcrNumber(file, type);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name uploaded${isProtected ? ' ✓ Unlocked' : ''}'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
          ),
        );
        _fetchDocuments();
      } else {
        // Push dual notification: system heads-up push banner + Bell Icon badge
        NotificationService.pushNotification(
          title: '❌ Document Rejected: $name',
          message: 'Your $name was rejected: $errorMessage. Please re-upload a clear copy.',
          type: 'DOCUMENT_REJECTED',
        );

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Text(
                  'Wrong Document Type',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF311B92),
                  ),
                ),
              ],
            ),
            content: Text(
              errorMessage,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF311B92),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name upload rejected: $errorMessage'),
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

  Map<String, List<Map<String, String>>> _getCombinedDocs(
    String category,
    Map<String, List<Map<String, String>>> baseDocs,
  ) {
    final Map<String, List<Map<String, String>>> combined = Map.from(baseDocs);

    if (category == 'Parents' && _coApplicantRelation != null) {
      final relLower = _coApplicantRelation!.trim().toLowerCase();
      if (relLower == 'father' || relLower.contains('father')) {
        combined.remove('Father');
      } else if (relLower == 'mother' || relLower.contains('mother')) {
        combined.remove('Mother');
      }
    }

    final customList = _customDocs[category];
    if (customList != null && customList.isNotEmpty) {
      combined['Additional Documents'] = List.from(customList);
    }
    return combined;
  }

  void _showAddCustomDocDialog() {
    String selectedCategory = 'Student';
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF311B92).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_task_rounded, color: Color(0xFF311B92)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Custom Document',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF311B92),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Category:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF311B92)),
                        items: ['Student', 'Co-Applicant', 'Parents'].map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedCategory = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Document Name:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g. University Offer Letter',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF311B92), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(ctx);
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a document name'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final String slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                    final String catPrefix = selectedCategory.toLowerCase().replaceAll('-', '_');
                    final String docType = 'custom_${catPrefix}_${slug}_${DateTime.now().millisecondsSinceEpoch}';

                    setState(() {
                      _customDocs[selectedCategory] ??= [];
                      _customDocs[selectedCategory]!.add({
                        'name': name,
                        'type': docType,
                      });
                    });

                    await _saveCustomDocs();
                    nav.pop();

                    // Switch tab to the selected category tab
                    int tabIndex = 0;
                    if (selectedCategory == 'Co-Applicant') tabIndex = 1;
                    if (selectedCategory == 'Parents') tabIndex = 2;
                    _tabController.animateTo(tabIndex);

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('"$name" added under $selectedCategory! Tap to upload.'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF311B92),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Add Document'),
                ),
              ],
            );
          },
        );
      },
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
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF311B92).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFF311B92), size: 24),
            ),
            tooltip: 'Add Custom Document',
            onPressed: _showAddCustomDocDialog,
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
    return _buildSectionList(_getCombinedDocs('Student', _studentDocs));
  }

  Widget _buildCoApplicantTab() {
    return _buildSectionList(_getCombinedDocs('Co-Applicant', _coApplicantDocs));
  }

  Widget _buildParentsTab() {
    return _buildSectionList(_getCombinedDocs('Parents', _parentsDocs));
  }

  Widget _buildSectionList(Map<String, List<Map<String, String>>> sections) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchDocuments,
      color: const Color(0xFF311B92),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }

  Widget _buildDocCard(String name, String type, UserDocument? doc) {
    bool isFromDigilocker = (doc?.isDigilocker ?? false) || doc?.status == 'available_in_digilocker';
    bool hasFile = doc?.filePath != null && doc!.filePath!.isNotEmpty;
    bool isVerified = doc?.status == 'verified';
    bool isRejected = doc != null && (doc.status == 'rejected' || doc.status == 'requires_resubmission');
    
    bool isAvailable = doc != null && (isFromDigilocker || hasFile);
    bool isUploaded = (isAvailable || isVerified) && !isRejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRejected
              ? const Color(0xFFEF5350).withValues(alpha: 0.25)
              : isVerified
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.25)
                  : isUploaded 
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
                  color: isRejected
                      ? const Color(0xFFFFEBEE)
                      : isVerified
                          ? const Color(0xFFE8F5E9)
                          : isUploaded
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isRejected
                      ? Icons.cancel_rounded
                      : isVerified
                          ? Icons.verified_user_rounded
                          : isUploaded
                              ? Icons.verified_user_rounded
                              : Icons.file_present_rounded,
                  color: isRejected
                      ? const Color(0xFFC62828)
                      : isVerified
                          ? const Color(0xFF2E7D32)
                          : isUploaded
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF6200EA),
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
                            color: isRejected
                                ? const Color(0xFFFFEBEE)
                                : isVerified
                                    ? const Color(0xFFE8F5E9)
                                    : isUploaded
                                        ? const Color(0xFFE8F5E9)
                                        : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isRejected
                                ? 'Rejected'
                                : isVerified
                                    ? 'Approved'
                                    : isUploaded 
                                        ? (isFromDigilocker ? 'DigiLocker' : 'Uploaded')
                                        : 'Pending',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isRejected
                                  ? const Color(0xFFC62828)
                                  : isVerified
                                      ? const Color(0xFF2E7D32)
                                      : isUploaded 
                                          ? const Color(0xFF2E7D32) 
                                          : const Color(0xFFE65100),
                            ),
                          ),
                        ),
                        if (isUploaded && doc?.uploadedAt != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            doc!.uploadedAt!.toIso8601String().split('T')[0],
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),
                    if (isRejected && doc.rejectionReason != null && doc.rejectionReason!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Reason: ${doc.rejectionReason}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFC62828),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action Buttons
              if (isRejected)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasFile) ...[
                      _buildCompactActionButton(
                        icon: Icons.visibility_rounded,
                        color: const Color(0xFF1E88E5),
                        onTap: () async {
                          final token = await _getToken();
                          final targetType = doc.docType;
                          final url = await UserService.getDocumentViewUrl(targetType);
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
                    ],
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
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text(
                        'Re-upload',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              else if (isUploaded)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactActionButton(
                      icon: Icons.visibility_rounded,
                      color: const Color(0xFF1E88E5),
                      onTap: () async {
                        final token = await _getToken();
                        final targetType = doc?.docType ?? type;
                        final url = await UserService.getDocumentViewUrl(targetType);
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
                          await _deleteFingerprint(type);
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
