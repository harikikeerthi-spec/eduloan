import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/mesh_background.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────────────────────────────────────

class _LegalSection {
  final String number;
  final String title;
  final String body;
  const _LegalSection(this.number, this.title, this.body);
}

final _termsSections = [
  _LegalSection(
    '1',
    'Acceptance of Terms',
    'By accessing or using the website, interface panels, dynamic web modules, or backend services of VidyaLoans, you agree to comply with and be legally bound by these Terms & Conditions.\n\n'
        'If you do not accept these Service Terms in their entirety, you must immediately terminate usage of this website and discontinue applying for education loans through our system.',
  ),
  _LegalSection(
    '2',
    'Student Eligibility',
    'To register an active account, create matched profiles, and utilize the education loan acceleration features of VidyaLoans:\n\n'
        '• You must be a citizen of India or a legally recognized resident of an eligible jurisdiction.\n'
        '• You must be applying for studies at a qualified global university or domestic institution.\n'
        '• You must have a co-applicant who meets baseline credit rating scores and has verified income sources under local taxation laws.',
  ),
  _LegalSection(
    '3',
    'Scope of Platform Services',
    'VidyaLoans acts as a centralized matching and application consolidation helper platform:\n\n'
        '• We consolidate interest rates, banking fees, and lending conditions based on bank specifications. Matching scores represent estimations, not final commitments from banking partners.\n'
        '• Lenders reserve ultimate discretionary authority to sanction, approve, reject, or modify loan terms. VidyaLoans is not a direct banking institution or primary capital provider.\n'
        '• All interactive software instruments, including the Grade Converter, EMI calculator, and Admit Predictor, are designed to assist estimation efforts. They do not constitute certified academic or financial counseling guarantees.',
  ),
  _LegalSection(
    '4',
    'User Submissions & Integrity',
    'Students assume absolute responsibility for the integrity and legitimacy of all files submitted via the portal:\n\n'
        '• You guarantee that all academic scorecards, identification cards, co-applicant salaries, and asset declarations are true, accurate, and completely unedited.\n'
        '• Submitting forged documents, falsified bank records, or misleading credentials constitutes a severe violation of service terms and may lead to instant account termination and legal reporting to partner banks.',
  ),
  _LegalSection(
    '5',
    'Intellectual Property Rights',
    'The software architectures, layout interfaces, algorithms, logo styles, source code, data trackers, and dynamic content on VidyaLoans are the sole property of VidyaLoan Inc. and are protected by domestic and global intellectual property laws.\n\n'
        'You agree not to reverse engineer, duplicate, crawl, extract, or scrape any software modules or database contents without written permission from VidyaLoan Inc.',
  ),
  _LegalSection(
    '6',
    'Limitation of Liability',
    'VidyaLoans and its executives, directors, or banking developers shall not be liable for any indirect, incidental, special, or consequential damages resulting from:\n\n'
        '• The denial, rejection, or delay of a loan application by any bank or NBFC.\n'
        '• Temporary system outages, technical maintenance downtime, or database access failures.\n'
        '• Any financial choices, interest rate fluctuations, or repayment commitments students finalize with external banks.',
  ),
  _LegalSection(
    '7',
    'Governing Law & Jurisdiction',
    'These Terms & Conditions are governed and constructed in accordance with the laws of the Republic of India.\n\n'
        'Any legal disputes, claims, or regulatory arguments concerning VidyaLoans operations shall be submitted to the exclusive jurisdiction of the competent courts of Hyderabad, Telangana, India.',
  ),
];

final _privacySections = [
  _LegalSection(
    '1',
    'Introduction',
    'Welcome to VidyaLoans ("we," "our," or "us"). We are highly committed to protecting your personal information and ensuring absolute privacy transparency. This Privacy Policy details how we gather, utilize, protect, and handle your data when you interact with our website, platforms, application features, and integrated lending software.\n\n'
        'By accessing or using VidyaLoans, you agree to the collection and use of information in accordance with this policy. If you do not agree with any terms within this document, please refrain from submitting information or completing active loan profiles.',
  ),
  _LegalSection(
    '2',
    'Information We Collect',
    'To evaluate your loan application profile and provide high-fidelity automated matching services, we collect several categories of information:\n\n'
        '📋 Personal Identifiers:\nLegal names, date of birth, contact numbers, active email addresses, permanent address, and PAN card / Aadhaar details.\n\n'
        '🎓 Academic Details:\nIntended university of study, global country selection, GRE/IELTS/TOEFL test scores, academic marksheets, and university offer letters.\n\n'
        '💰 Co-Applicant & Financial Data:\nIncome records, salary slips, active bank statements, income tax returns (ITRs), and overall family asset/liability profiles.\n\n'
        '📊 Device & Usage Statistics:\nLog files, IP addresses, browser specifications, operating system versions, and page interaction timestamps.',
  ),
  _LegalSection(
    '3',
    'How We Use Your Data',
    'We utilize your personal information strictly to deliver, optimize, and evaluate our student education loan services, specifically for:\n\n'
        '• Matching your unique student profile with eligible educational lenders and public/private banking partners.\n'
        '• Verifying documents automatically through OCR and DigiLocker systems to fast-track bank review.\n'
        '• Assisting you with automated tools (e.g., dynamic SOP suggestions, EMI calculators, and stress testing simulators).\n'
        '• Sending alerts regarding active loan application status updates, counseling details, and verification stages.\n'
        '• Preventing fraud, mitigating operational risks, and fulfilling legal/regulatory obligations.',
  ),
  _LegalSection(
    '4',
    'Information Sharing & Disclosure',
    'VidyaLoans does not sell or lease student database records to third-party marketing companies. We share information only under the following situations:\n\n'
        '🏦 With Banking Partners:\nWe transmit your profiles and uploaded documents directly to partner banks and NBFCs only after you explicitly select and authorize application submissions.\n\n'
        '🔧 With Service Providers:\nTo facilitate specialized features such as secure document fetching, SMS notification updates, and automated OCR processing.\n\n'
        '⚖️ For Legal Compliance:\nWhen compelled by active judicial orders, public regulations, or governmental laws to prevent potential fraud or financial crimes.',
  ),
  _LegalSection(
    '5',
    'Data Security & Storage',
    'We enforce cutting-edge industry security measures to keep your data secure. All transmission pipelines use secure HTTPS protocols and AES-256 data encryption schemes. Documents retrieved through our integration channels are held within high-security cloud firewalls.\n\n'
        'Although we leverage enterprise-grade security tools, no platform transmission over the public internet can be guaranteed 100% secure. You are highly encouraged to safeguard your login details and active profile tokens.',
  ),
  _LegalSection(
    '6',
    'Your Rights & Choices',
    'As a student applying through our platform, you have specific control features over your personal data:\n\n'
        '👁 Access & Review:\nYou can review all elements of your application, co-applicant details, and uploaded files inside your student profile dashboard.\n\n'
        '✏️ Update & Rectify:\nYou can correct incomplete entries directly or contact support to request swift changes.\n\n'
        '🗑 Data Deletion:\nYou can request complete termination of your active loan profile and deletion of stored records from our archives, subject to active legal or lending auditing mandates.',
  ),
  _LegalSection(
    '7',
    'Contact Data Privacy Officer',
    'If you have questions, comments, or data handling complaints regarding this Privacy Policy, please reach out to our dedicated Data Privacy Team:\n\n'
        '📧 Email: support@Vidyaloans.in\n'
        '📞 Phone: +91 8143797779\n'
        '📍 Address: Nuzvid, Andhra Pradesh, India',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class LegalPage extends StatefulWidget {
  /// Pass [initialTab] 0 for Terms, 1 for Privacy Policy.
  final int initialTab;
  const LegalPage({super.key, this.initialTab = 0});

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _expandedTerms = {};
  final Set<int> _expandedPrivacy = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── UI helpers ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Back row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF311B92).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF311B92).withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF311B92), size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Legal',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab bar
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF311B92).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: EdgeInsets.zero,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
                labelColor: const Color(0xFF311B92),
                unselectedLabelColor: Colors.black.withValues(alpha: 0.6),
                tabs: const [
                  Tab(text: '📜  Terms & Conditions'),
                  Tab(text: '🔒  Privacy Policy'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(String version) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF311B92).withValues(alpha: 0.06),
            const Color(0xFF5E35B1).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF311B92).withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF311B92).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFF311B92), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Version $version',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF311B92),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Active',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTocCard(List<_LegalSection> sections, Set<int> expanded) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt_rounded, size: 16, color: Color(0xFF311B92)),
              const SizedBox(width: 8),
              Text(
                'TABLE OF CONTENTS',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...sections.asMap().entries.map((e) {
            final idx = e.key;
            final sec = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF311B92).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sec.number,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF311B92),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sec.title,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF0F172A),
                        fontWeight: expanded.contains(idx) ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAccordionSection(
    _LegalSection section,
    int idx,
    Set<int> expanded,
    void Function(int) onToggle,
  ) {
    final isOpen = expanded.contains(idx);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOpen
              ? const Color(0xFF311B92).withValues(alpha: 0.2)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: isOpen
                ? const Color(0xFF311B92).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isOpen ? 18 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onToggle(idx),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: isOpen
                            ? const LinearGradient(
                                colors: [Color(0xFF311B92), Color(0xFF5E35B1)],
                              )
                            : null,
                        color: isOpen ? null : const Color(0xFF311B92).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        section.number,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isOpen ? Colors.white : const Color(0xFF311B92),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        section.title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isOpen ? const Color(0xFF311B92) : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isOpen ? const Color(0xFF311B92) : const Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(height: 0),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 1,
                          color: const Color(0xFF311B92).withValues(alpha: 0.08),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          section.body,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: const Color(0xFF334155),
                            height: 1.65,
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 260),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0050), Color(0xFF311B92)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                'Questions or Concerns?',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _contactRow(Icons.email_outlined, 'support@Vidyaloans.in'),
          const SizedBox(height: 8),
          _contactRow(Icons.phone_outlined, '+91 8143797779'),
          const SizedBox(height: 8),
          _contactRow(Icons.location_on_outlined, 'Nuzvid, Andhra Pradesh, India'),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied "$text" to clipboard'),
            backgroundColor: const Color(0xFF311B92),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(
              Icons.copy_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsTab() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildIntroCard('1.8'),
        _buildTocCard(_termsSections, _expandedTerms),
        const SizedBox(height: 16),
        ..._termsSections.asMap().entries.map((e) => _buildAccordionSection(
              e.value,
              e.key,
              _expandedTerms,
              (idx) => setState(() {
                if (_expandedTerms.contains(idx)) {
                  _expandedTerms.remove(idx);
                } else {
                  _expandedTerms.add(idx);
                }
              }),
            )),
        _buildContactCard(),
      ],
    );
  }

  Widget _buildPrivacyTab() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildIntroCard('2.1'),
        _buildTocCard(_privacySections, _expandedPrivacy),
        const SizedBox(height: 16),
        ..._privacySections.asMap().entries.map((e) => _buildAccordionSection(
              e.value,
              e.key,
              _expandedPrivacy,
              (idx) => setState(() {
                if (_expandedPrivacy.contains(idx)) {
                  _expandedPrivacy.remove(idx);
                } else {
                  _expandedPrivacy.add(idx);
                }
              }),
            )),
        _buildContactCard(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: MeshBackground(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTermsTab(),
                  _buildPrivacyTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
