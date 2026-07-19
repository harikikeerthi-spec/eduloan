import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'document_vault_page.dart';
import '../widgets/mesh_background.dart';
import '../models/loan.dart';
import '../services/loan_service.dart';
import 'apply_loan_page.dart';
import 'digilocker_auth_page.dart';
import '../services/digilocker_service.dart';
import 'main_navigation.dart';
import 'package:url_launcher/url_launcher.dart';

class MyLoansPage extends StatefulWidget {
  const MyLoansPage({super.key});

  @override
  State<MyLoansPage> createState() => _MyLoansPageState();
}

class _MyLoansPageState extends State<MyLoansPage> {
  final LoanService _loanService = LoanService();
  List<Loan> _loans = [];
  bool _isLoading = true;
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
      if (mounted) {
        setState(() {
          _loans = loans;
          _isLoading = false;
        });
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('401') || errorStr.toLowerCase().contains('session expired')) {
        // Token expired or invalid, clear it
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
      }

      if (mounted) {
        setState(() {
          _error = errorStr;
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
    final totalProgress = _loans.fold(0, (sum, loan) => sum + loan.progress);
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
      padding: const EdgeInsets.all(24),
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
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
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
          const Text(
            'Welcome back!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Here\'s an overview of your loan applications.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_loans.isEmpty) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ApplyLoanPage(
                            onLoanSubmitted: () {
                              MainNavigation.of(context)?.checkLoanStatus();
                            },
                          ),
                        ),
                      ).then((_) => _fetchLoans());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF311B92),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Apply Loan',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DocumentVaultPage(),
                      ),
                    );
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    _loans.isEmpty
                        ? Icons.lock_outline
                        : Icons.folder_shared_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _loans.isEmpty ? 'Doc Vault (Locked)' : 'Doc Vault',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
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
            'ACTIVE',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Application Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${loan.progress}%',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF311B92),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressStepper(loan),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildLoanDetails(loan),
            if (loan.counselorName != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5), // Soft purple background
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFAB47BC).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF311B92),
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
                            'Assigned Counselor',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF311B92),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loan.counselorName!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (loan.counselorPhone != null)
                      IconButton(
                        onPressed: () async {
                          final Uri url = Uri.parse('tel:${loan.counselorPhone}');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        icon: const Icon(
                          Icons.phone_in_talk_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLoanDetailsDialog(Loan loan) {
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
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9C4), // Light yellow
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
                              loan.bank,
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close details dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DocumentVaultPage(),
                      ),
                    );
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
                  icon: const Icon(Icons.folder_shared_outlined, size: 20),
                  label: const Text(
                    'Document Vault',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Confirm delete
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Application?'),
                            content: const Text(
                              'Are you sure you want to delete this application? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                    try {
                                      await _loanService.deleteLoan(loan.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Application deleted successfully',
                                            ),
                                          ),
                                        );
                                        _fetchLoans();
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text('Delete Application'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAB47BC), // Purple
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
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
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DigilockerAuthPage(),
      ),
    );

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
              content: Text(count > 0 
                ? '$count documents successfully fetched: $docsList' 
                : 'DigiLocker verification successful (No new documents found).'),
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
              errorMsg = errorJson['detail'] ?? errorJson['message'] ?? errorMsg;
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
    // Simple formatter, can use intl package if available
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildProgressStepper(Loan loan) {
    final stages = [
      {
        'key': 'application_submitted',
        'label': 'Submitted',
        'icon': Icons.description,
      },
      {
        'key': 'documents_uploaded',
        'label': 'Documents',
        'icon': Icons.upload_file,
      },
      {'key': 'under_review', 'label': 'Review', 'icon': Icons.rate_review},
      {'key': 'sanctioned', 'label': 'Sanctioned', 'icon': Icons.verified},
      {'key': 'disbursed', 'label': 'Disbursed', 'icon': Icons.payments},
    ];

    final stageLower = loan.stage.toLowerCase();
    final statusLower = loan.status.toLowerCase();

    int currentStageIndex = 0;
    if (statusLower == 'pending') {
      currentStageIndex = 0;
    } else if (statusLower == 'docs_received' ||
        statusLower == 'staff_verified' ||
        stageLower == 'document_verification' ||
        stageLower == 'documents_uploaded') {
      currentStageIndex = 1;
    } else if (statusLower == 'submitted_to_bank' ||
        statusLower == 'file_logged' ||
        statusLower == 'under_bank_review' ||
        statusLower == 'query_raised' ||
        stageLower == 'credit_check' ||
        stageLower == 'bank_review' ||
        stageLower == 'under_review' ||
        stageLower == 'submitted' ||
        stageLower == 'verification') {
      currentStageIndex = 2;
    } else if (statusLower == 'conditional_sanction' ||
        statusLower == 'partial_sanction' ||
        statusLower == 'counter_offer' ||
        statusLower == 'approved' ||
        statusLower == 'sanctioned' ||
        stageLower == 'sanction' ||
        stageLower == 'sanctioned') {
      currentStageIndex = 3;
    } else if (statusLower == 'disbursement_confirmed' ||
        statusLower == 'closed' ||
        stageLower == 'disbursement' ||
        stageLower == 'disbursed') {
      currentStageIndex = 4;
    }

    return Column(
      children: [
        Row(
          children: List.generate(stages.length, (index) {
            final isCompleted = index < currentStageIndex;
            final isCurrent = index == currentStageIndex;
            final stage = stages[index];

            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? const Color(0xFF311B92)
                                : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? const Color(0xFF311B92)
                              : Colors.grey.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          stage['icon'] as IconData,
                          color: isCompleted || isCurrent
                              ? Colors.white
                              : Colors.grey.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ),
                      if (index < stages.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? const Color(0xFF311B92)
                                : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stage['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCompleted || isCurrent
                          ? const Color(0xFF311B92)
                          : Colors.grey.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLoanDetails(Loan loan) {
    return Column(
      children: [
        _buildDetailRow('Application ID', loan.applicationNumber ?? loan.id),
        _buildDetailRow('University', loan.universityName ?? 'N/A'),
        _buildDetailRow('Course', loan.courseName ?? 'N/A'),
        _buildDetailRow(
          'Amount',
          '₹${(loan.amount / 100000).toStringAsFixed(1)}L',
        ),
        _buildDetailRow('Bank', loan.bank),
        _buildDetailRow('Status', loan.statusDisplay),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF311B92).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 64,
                color: Color(0xFF311B92),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No active applications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start a new application to track your progress',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApplyLoanPage(
                        onLoanSubmitted: () {
                          MainNavigation.of(context)?.checkLoanStatus();
                        },
                      ),
                    ),
                  ).then((_) => _fetchLoans());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF311B92),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF311B92).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Apply for Loan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final bool isUnauthorized = (_error?.contains('401') ?? false) ||
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
                child: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 28),
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
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
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
                _verifyWithDigilocker(loanId: _loans.isNotEmpty ? _loans[0].id : null);
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
