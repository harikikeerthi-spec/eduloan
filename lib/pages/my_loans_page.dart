import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'apply_loan_page.dart';
import 'document_vault_page.dart';
import '../widgets/mesh_background.dart';
import '../models/loan.dart';
import '../services/loan_service.dart';
import 'digilocker_auth_page.dart';
import '../services/digilocker_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';
import '../services/pdf_generator_service.dart';
import '../services/language_service.dart';

class MyLoansPage extends StatefulWidget {
  const MyLoansPage({super.key});

  @override
  State<MyLoansPage> createState() => _MyLoansPageState();
}

class _MyLoansPageState extends State<MyLoansPage> {
  final LoanService _loanService = LoanService();
  List<Loan> _loans = [];
  bool _isLoading = true;

  Future<void> _launchEmail(String rawEmail) async {
    final String email = rawEmail.trim();
    if (email.isEmpty) return;
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    try {
      bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        launched = await launchUrl(emailUri);
      }
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: email));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email address copied to clipboard: $email'),
            backgroundColor: const Color(0xFF311B92),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: email));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email address copied to clipboard: $email'),
          backgroundColor: const Color(0xFF311B92),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _launchPhone(String rawPhone) async {
    final String phone = rawPhone.trim();
    if (phone.isEmpty) return;

    final granted = await PermissionService.requestPhonePermission();
    if (!granted) {
      final isPermanent = await PermissionService.isPermanentlyDenied(
        Permission.phone,
      );
      if (isPermanent && mounted) {
        PermissionService.showSettingsDialog(
          context: context,
          title: 'Phone Calls Access Required',
          description:
              'Please grant Phone Call permissions in Settings to contact our customer support team directly.',
          icon: Icons.phone_callback_rounded,
          themeColor: const Color(0xFF311B92),
        );
      }
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    try {
      bool launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        launched = await launchUrl(phoneUri);
      }
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: phone));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone number copied to clipboard: $phone'),
            backgroundColor: const Color(0xFF311B92),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number copied to clipboard: $phone'),
          backgroundColor: const Color(0xFF311B92),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _getBankLogoPath(String bankName) {
    final lower = bankName.toLowerCase();
    if (lower.contains('avanse')) return 'assets/images/avanse_logo_final.png';
    if (lower.contains('auxilo')) return 'assets/images/auxilo_logo_final.png';
    if (lower.contains('credila') || lower.contains('hdfc credila'))
      return 'assets/images/credila_logo_final.png';
    if (lower.contains('idfc')) return 'assets/images/idfc_logo.png';
    if (lower.contains('poonawalla'))
      return 'assets/images/poonawalla_logo_final.jpg';
    return null;
  }

  bool _hasUploadedDocs = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final loans = await _loanService.getUserLoans();
      final bool allDocsAcceptedByStaff =
          await PdfGeneratorService.isEveryDocumentUploaded();

      // Check if backend loan status indicates staff has verified/accepted documents
      final bool loanDocsVerifiedByStaff = loans.any((loan) {
        final st = loan.status.toLowerCase().trim();
        final sg = loan.stage.toLowerCase().trim();
        return st == 'documents_verified' ||
            st == 'staff_verified' ||
            st == 'submitted_to_bank' ||
            st == 'file_logged' ||
            st == 'under_bank_review' ||
            st == 'query_raised' ||
            st == 'sanctioned' ||
            st == 'approved' ||
            st == 'disbursed' ||
            st == 'disbursement_confirmed' ||
            sg == 'documents_verified' ||
            sg == 'documents_approved' ||
            sg == 'submitted_to_bank';
      });

      final bool isAllDocsComplete =
          allDocsAcceptedByStaff || loanDocsVerifiedByStaff;

      if (mounted) {
        setState(() {
          _loans = loans;
          _hasUploadedDocs = isAllDocsComplete;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Do not clear auth_token on API error to keep persistent user session

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  int get _activeApplicationsCount => _loans
      .where(
        (loan) =>
            loan.status.toLowerCase() != 'rejected' &&
            loan.status.toLowerCase() != 'disbursed',
      )
      .length;

  double get _totalLoanAmount =>
      _loans.fold(0.0, (sum, loan) => sum + loan.amount);

  int get _documentsProgress {
    if (_loans.isEmpty) return 0;
    final totalProgress = _loans.fold(
      0,
      (sum, loan) =>
          sum + loan.getEffectiveProgress(hasUploadedDocs: _hasUploadedDocs),
    );
    return (totalProgress / _loans.length).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchLoans,
            color: const Color(0xFF311B92),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF311B92),
                          ),
                        )
                      : _error != null
                      ? _buildErrorState()
                      : _loans.isEmpty
                      ? _buildEmptyState()
                      : _buildLoansContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF311B92).withValues(alpha: 0.15),
            const Color(0xFF311B92).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF311B92).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LanguageService.tr('welcome_back'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Here\'s an overview of your loan applications.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final bool isVaultLocked = _loans.isEmpty;
                    if (isVaultLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please complete a loan application first to access the Document Vault.',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DocumentVaultPage(),
                      ),
                    );
                    _fetchLoans();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _loans.isEmpty
                        ? Colors.grey.shade600
                        : const Color(0xFF311B92),
                    side: BorderSide(
                      color: _loans.isEmpty
                          ? Colors.grey.shade400
                          : const Color(0xFF311B92),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    _loans.isEmpty
                        ? Icons.lock_outline
                        : Icons.folder_shared_outlined,
                    size: 16,
                  ),
                  label: Text(
                    _loans.isEmpty ? 'Doc Vault (Locked)' : 'Doc Vault',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (_loans.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Generating loan application PDF...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      try {
                        await PdfGeneratorService.downloadApplicationPdf(
                          _loans.first,
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to download PDF: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text(
                      'Download PDF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              if (_loans.isEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ApplyLoanPage(onLoanSubmitted: _fetchLoans),
                        ),
                      );
                      _fetchLoans();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF281C9D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      LanguageService.tr('apply_loan'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoansContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticsCards(),
          // const SizedBox(height: 20),
          // _buildDigilockerProminentCard(),
          const SizedBox(height: 24),
          ..._loans.map((loan) => _buildLoanCard(loan)),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            LanguageService.tr('active').toUpperCase(),
            _activeApplicationsCount.toString().padLeft(2, '0'),
            Icons.description,
            const Color(0xFF311B92),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'TOTAL',
            '₹${(_totalLoanAmount / 100000).toStringAsFixed(1)}L',
            Icons.currency_rupee,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'DOCS',
            '$_documentsProgress%',
            Icons.description_outlined,
            const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: color.withValues(alpha: 0.7), size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(Loan loan) {
    return InkWell(
      onTap: () => _showLoanDetailsDialog(loan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressStepper(loan),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildLoanDetails(loan),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ─── Assigned Staff by Round Robin ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE9D5FF), width: 1.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B21A8), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF7C3AED,
                          ).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ASSIGNED LOAN SPECIALIST',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C3AED),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          loan.assignedStaffDisplayName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loan.assignedStaffPhone,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (loan.hasAssignedStaff) {
                            _launchPhone(loan.assignedStaffPhone);
                          } else {
                            _launchPhone('+919240209000');
                          }
                        },
                        tooltip: loan.hasAssignedStaff
                            ? 'Call Specialist'
                            : 'Call Support',
                        icon: const Icon(
                          Icons.phone_in_talk_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () {
                          if (loan.hasAssignedStaff) {
                            _launchEmail(loan.assignedStaffEmail);
                          } else {
                            _launchEmail('support@vidyaloans.in');
                          }
                        },
                        tooltip: loan.hasAssignedStaff
                            ? 'Email Specialist'
                            : 'Email Support',
                        icon: const Icon(
                          Icons.mail_rounded,
                          color: Color(0xFF7C3AED),
                          size: 18,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (loan.status.toLowerCase() == 'rejected' ||
                loan.stage.toLowerCase() == 'rejected') ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ApplyLoanPage(
                          initialUniversity: loan.universityName,
                          initialCourse: loan.courseName,
                          initialCountry: loan.targetCountry,
                          onLoanSubmitted: _fetchLoans,
                        ),
                      ),
                    );
                    _fetchLoans();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626), // Red accent
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Re-apply Loan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLoanDetailsDialog(Loan loan) {
    final logoPath = _getBankLogoPath(loan.bank);
    final bool hasLogo =
        logoPath != null && loan.displayBank != 'Matching Lenders...';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        hasLogo
                            ? Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Image.asset(
                                  logoPath,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFF9C4,
                                  ), // Light yellow
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.school,
                                  color: Color(0xFFFBC02D), // Darker yellow
                                  size: 24,
                                ),
                              ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Education Loan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              loan.displayBank,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9C4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    loan.statusDisplay,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFBC02D),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOAN AMOUNT',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${loan.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'APPLIED ON',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(loan.date),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'APPLICATION ID',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loan.applicationNumber ?? loan.id,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Assigned Staff Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE9D5FF),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6B21A8), Color(0xFF7C3AED)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ASSIGNED LOAN SPECIALIST',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF7C3AED),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              loan.assignedStaffDisplayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loan.assignedStaffPhone,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (loan.hasAssignedStaff) {
                                _launchPhone(loan.assignedStaffPhone);
                              } else {
                                _launchPhone('+919240209000');
                              }
                            },
                            tooltip: loan.hasAssignedStaff
                                ? 'Call Specialist'
                                : 'Call Support',
                            icon: const Icon(
                              Icons.phone_in_talk_rounded,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () {
                              if (loan.hasAssignedStaff) {
                                _launchEmail(loan.assignedStaffEmail);
                              } else {
                                _launchEmail('support@vidyaloans.in');
                              }
                            },
                            tooltip: loan.hasAssignedStaff
                                ? 'Email Specialist'
                                : 'Email Support',
                            icon: const Icon(
                              Icons.mail_rounded,
                              color: Color(0xFF7C3AED),
                              size: 18,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context); // Close details dialog
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DocumentVaultPage(),
                            ),
                          );
                          _fetchLoans();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF311B92),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                        ),
                        icon: const Icon(
                          Icons.folder_shared_outlined,
                          size: 18,
                        ),
                        label: const Text(
                          'Doc Vault',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Generating loan application PDF...',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          try {
                            await PdfGeneratorService.downloadApplicationPdf(
                              loan,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to download PDF: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                        ),
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Download PDF',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (loan.status.toLowerCase() == 'rejected' ||
                    loan.stage.toLowerCase() == 'rejected') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF5350).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFC62828),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This application was rejected. You can re-apply to another bank or submit updated details.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFC62828),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context); // Close details dialog
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApplyLoanPage(
                              initialUniversity: loan.universityName,
                              initialCourse: loan.courseName,
                              initialCountry: loan.targetCountry,
                              onLoanSubmitted: _fetchLoans,
                            ),
                          ),
                        );
                        _fetchLoans();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFDC2626,
                        ), // Red Re-apply accent
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text(
                        'Re-apply Loan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF311B92,
                      ), // Primary Deep Purple
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyWithDigilocker({String? loanId}) async {
    debugPrint('DEBUG: _verifyWithDigilocker called with loanId: $loanId');
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const DigilockerAuthPage()));

    if (result != null && result is Map) {
      final String code = result['code'];
      final String verifier = result['code_verifier'];

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF311B92)),
        ),
      );

      try {
        final service = DigilockerService();
        final result = await service.verifyDigilocker(
          code,
          loanId: loanId,
          codeVerifier: verifier,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (result['success'] == true) {
          final count = result['attachedCount'] ?? 0;
          final List<dynamic> attachedDocs = result['attachedDocs'] ?? [];
          final docsList = attachedDocs.join(', ');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                count > 0
                    ? '$count documents successfully fetched: $docsList'
                    : 'DigiLocker verification successful (No new documents found).',
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 4),
            ),
          );
          _fetchLoans();
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog

          String errorMsg = e.toString();
          if (errorMsg.contains('{')) {
            try {
              final jsonStart = errorMsg.indexOf('{');
              final jsonStr = errorMsg.substring(jsonStart);
              final errorJson = jsonDecode(jsonStr);
              errorMsg =
                  errorJson['detail'] ?? errorJson['message'] ?? errorMsg;
            } catch (_) {}
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification failed: $errorMsg'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${localDate.day} ${months[localDate.month - 1]} ${localDate.year}';
  }

  String _formatDateTime(DateTime date) {
    final localDate = date.toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = localDate.hour == 0
        ? 12
        : (localDate.hour > 12 ? localDate.hour - 12 : localDate.hour);
    final period = localDate.hour >= 12 ? 'PM' : 'AM';
    final min = localDate.minute.toString().padLeft(2, '0');
    return '${months[localDate.month - 1]} ${localDate.day}\n${hour.toString().padLeft(2, '0')}:$min $period';
  }

  Widget _buildProgressStepper(Loan loan) {
    final stages = [
      {'label': 'CREATED', 'icon': Icons.check_rounded},
      {'label': 'SUBMITTED', 'icon': Icons.check_rounded},
      {'label': 'DOCUMENTS', 'icon': Icons.verified_rounded},
      {'label': 'SUBMIT TO BANK', 'icon': Icons.account_balance_rounded},
      {'label': 'CREDIT CHECK', 'icon': Icons.credit_card_rounded},
      {'label': 'REVIEW', 'icon': Icons.edit_note_rounded},
      {'label': 'SANCTION', 'icon': Icons.assignment_turned_in_rounded},
      {'label': 'DISBURSED', 'icon': Icons.payments_rounded},
    ];

    final int currentStageIndex = loan.getEffectiveStageIndex(
      hasUploadedDocs: _hasUploadedDocs,
    );
    final int currentProgress = loan.getEffectiveProgress(
      hasUploadedDocs: _hasUploadedDocs,
    );
    final String currentStage = loan.currentStageLabel(
      hasUploadedDocs: _hasUploadedDocs,
    );

    const primaryPurple = Color(0xFF7C3AED);
    const deepPurple = Color(0xFF6B21A8);
    const completedGreen = Color(0xFF10B981);
    const completedGreenText = Color(0xFF059669);
    const inactiveBorder = Color(0xFFE2E8F0);
    const inactiveIcon = Color(0xFF94A3B8);
    const inactiveText = Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Top Stage Header ───────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF3E8FF), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENT STAGE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9333EA),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentStage,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1B4B),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: primaryPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryPurple.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '$currentProgress%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: primaryPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Horizontal 8-Stage Progress Stepper (Matching User Design) ─────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(stages.length, (index) {
                final bool isCompleted = index < currentStageIndex;
                final bool isCurrent = index == currentStageIndex;
                final stage = stages[index];
                final IconData iconData = stage['icon'] as IconData;
                final String label = stage['label'] as String;
                final bool isLast = index == stages.length - 1;

                const double nodeWidth = 98.0;
                const double circleSize = 46.0;

                return SizedBox(
                  width: nodeWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Node Circle with Left/Right Connecting Line segments
                      SizedBox(
                        width: nodeWidth,
                        height: circleSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Left connecting line
                            if (index > 0)
                              Positioned(
                                left: 0,
                                right: nodeWidth / 2,
                                top: (circleSize - 3) / 2,
                                child: Container(
                                  height: 3,
                                  color: index <= currentStageIndex
                                      ? (index < currentStageIndex
                                            ? completedGreen
                                            : primaryPurple)
                                      : inactiveBorder,
                                ),
                              ),
                            // Right connecting line
                            if (!isLast)
                              Positioned(
                                left: nodeWidth / 2,
                                right: 0,
                                top: (circleSize - 3) / 2,
                                child: Container(
                                  height: 3,
                                  color: index < currentStageIndex
                                      ? (index + 1 == currentStageIndex
                                            ? primaryPurple
                                            : completedGreen)
                                      : inactiveBorder,
                                ),
                              ),
                            // Circle Badge
                            Container(
                              width: circleSize,
                              height: circleSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? completedGreen
                                    : (isCurrent
                                          ? Colors.white
                                          : const Color(0xFFF8FAFC)),
                                border: Border.all(
                                  color: isCompleted
                                      ? completedGreen
                                      : (isCurrent
                                            ? deepPurple
                                            : inactiveBorder),
                                  width: isCurrent
                                      ? 2.5
                                      : (isCompleted ? 2.0 : 1.5),
                                ),
                                boxShadow: isCompleted
                                    ? [
                                        BoxShadow(
                                          color: completedGreen.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : (isCurrent
                                          ? [
                                              BoxShadow(
                                                color: primaryPurple.withValues(
                                                  alpha: 0.35,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : null),
                              ),
                              child: Center(
                                child: Icon(
                                  isCompleted ? Icons.check_rounded : iconData,
                                  size: isCompleted
                                      ? 24
                                      : (isCurrent ? 23 : 20),
                                  color: isCompleted
                                      ? Colors.white
                                      : (isCurrent ? deepPurple : inactiveIcon),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Label text below circle
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: (isCompleted || isCurrent)
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isCompleted
                              ? completedGreenText
                              : (isCurrent ? deepPurple : inactiveText),
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                      ),

                      // Subtitle: timestamp for active stage
                      if (isCurrent) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(loan.updatedAt),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoanDetails(Loan loan) {
    final logoPath = _getBankLogoPath(loan.bank);
    final bool hasLogo =
        logoPath != null && loan.displayBank != 'Matching Lenders...';

    return Column(
      children: [
        _buildDetailRow('Application ID', loan.applicationNumber ?? loan.id),
        _buildDetailRow('University', loan.universityName ?? 'N/A'),
        _buildDetailRow(
          'Amount',
          '₹${(loan.amount / 100000).toStringAsFixed(1)}L',
        ),
        _buildDetailRow(
          'Bank',
          loan.displayBank,
          prefixWidget: hasLogo
              ? Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade200, width: 0.5),
                  ),
                  child: Image.asset(
                    logoPath,
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                )
              : null,
        ),
        _buildDetailRow('Status', loan.statusDisplay),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Widget? prefixWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (prefixWidget != null) ...[
                  prefixWidget,
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF281C9D).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_add,
                size: 44,
                color: Color(0xFF281C9D),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No active applications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have not submitted any loan applications yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ApplyLoanPage(onLoanSubmitted: _fetchLoans),
                  ),
                );
                _fetchLoans();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF281C9D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Apply for Loan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final bool isUnauthorized =
        (_error?.contains('401') ?? false) ||
        (_error?.toLowerCase().contains('session expired') ?? false);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnauthorized ? Icons.lock_clock_outlined : Icons.error_outline,
              size: 64,
              color: isUnauthorized ? Colors.orange : Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              isUnauthorized ? 'Session Expired' : 'Error loading loans',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUnauthorized
                  ? 'Your session has expired. Please log in again to continue.'
                  : (_error ?? 'Unknown error'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            if (isUnauthorized)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF311B92),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.login),
                label: const Text(
                  'Log In Again',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _fetchLoans,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF311B92),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDigilockerProminentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF311B92),
            const Color(0xFF311B92).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cloud_done_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify with DigiLocker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Instant document verification',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Get your Aadhaar, PAN, and Academic certificates directly from DigiLocker for faster loan processing.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                debugPrint('DEBUG: Prominent DigiLocker card tapped');
                _verifyWithDigilocker(
                  loanId: _loans.isNotEmpty ? _loans[0].id : null,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF311B92),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Fetch Documents Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
