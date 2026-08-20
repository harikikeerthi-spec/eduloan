import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/mesh_background.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _LegalSection {
  final String number;
  final String title;
  final String tag;
  final IconData icon;
  final Color accentColor;
  final String body;
  final List<String>? highlights;

  const _LegalSection({
    required this.number,
    required this.title,
    required this.tag,
    required this.icon,
    required this.accentColor,
    required this.body,
    this.highlights,
  });
}

final _termsSections = [
  const _LegalSection(
    number: '01',
    title: 'Acceptance of Terms',
    tag: 'Agreement',
    icon: Icons.handshake_rounded,
    accentColor: Color(0xFF6366F1),
    body:
        'By accessing or using the website, mobile applications, interface panels, dynamic calculators, or backend services of VidyaLoans, you agree to comply with and be legally bound by these Terms & Conditions.\n\n'
        'If you do not accept these Service Terms in their entirety, you must immediately terminate usage of this application and discontinue applying for education loans through our system.',
    highlights: [
      'Binding legal contract between applicant and VidyaLoans',
      'Applies to mobile app, web portal, and API services',
    ],
  ),
  const _LegalSection(
    number: '02',
    title: 'Student Eligibility',
    tag: 'Eligibility',
    icon: Icons.school_rounded,
    accentColor: Color(0xFF3B82F6),
    body:
        'To register an active account, create matched profiles, and utilize the education loan acceleration features of VidyaLoans:\n\n'
        '• You must be a citizen of India or a legally recognized resident of an eligible jurisdiction.\n'
        '• You must be applying for studies at a qualified global university or accredited domestic institution.\n'
        '• You must have a qualified co-applicant who meets baseline credit rating scores and has verified income sources under local taxation laws.',
    highlights: [
      'Indian citizenship / eligible residency required',
      'Accredited global or domestic university admission',
      'Credit-worthy co-applicant with verified income',
    ],
  ),
  const _LegalSection(
    number: '03',
    title: 'Scope of Platform Services',
    tag: 'Platform Scope',
    icon: Icons.account_balance_rounded,
    accentColor: Color(0xFF8B5CF6),
    body:
        'VidyaLoans acts as a centralized matching, comparison, and application consolidation helper platform:\n\n'
        '• We consolidate interest rates, banking fees, and lending conditions based on bank specifications. Matching scores represent estimations, not final commitments from banking partners.\n'
        '• Lenders reserve ultimate discretionary authority to sanction, approve, reject, or modify loan terms. VidyaLoans is not a direct banking institution or primary capital provider.\n'
        '• All interactive software instruments, including the Grade Converter, EMI calculator, and Admit Predictor, are designed to assist estimation efforts. They do not constitute certified academic or financial counseling guarantees.',
    highlights: [
      'Centralized loan discovery & matching platform',
      'Final sanctions subject to bank discretion',
      'Calculators & tools provided for estimation purposes',
    ],
  ),
  const _LegalSection(
    number: '04',
    title: 'User Submissions & Integrity',
    tag: 'Integrity',
    icon: Icons.verified_user_rounded,
    accentColor: Color(0xFFEC4899),
    body:
        'Students assume absolute responsibility for the integrity and legitimacy of all files submitted via the portal:\n\n'
        '• You guarantee that all academic scorecards, identification cards, co-applicant salaries, and asset declarations are true, accurate, and completely unedited.\n'
        '• Submitting forged documents, falsified bank records, or misleading credentials constitutes a severe violation of service terms and may lead to instant account termination and legal reporting to partner banks.',
    highlights: [
      'Zero tolerance for falsified or tampered documents',
      'Automatic fraud detection via OCR & DigiLocker',
    ],
  ),
  const _LegalSection(
    number: '05',
    title: 'Intellectual Property Rights',
    tag: 'IP Rights',
    icon: Icons.copyright_rounded,
    accentColor: Color(0xFFF59E0B),
    body:
        'The software architectures, layout interfaces, algorithms, logo styles, source code, data trackers, and dynamic content on VidyaLoans are the sole property of VidyaLoan Inc. and are protected by domestic and global intellectual property laws.\n\n'
        'You agree not to reverse engineer, duplicate, crawl, extract, or scrape any software modules or database contents without written permission from VidyaLoan Inc.',
    highlights: [
      'Proprietary matching algorithms & UI designs',
      'Unauthorized scraping & crawling strictly prohibited',
    ],
  ),
  const _LegalSection(
    number: '06',
    title: 'Limitation of Liability',
    tag: 'Liability',
    icon: Icons.shield_outlined,
    accentColor: Color(0xFFEF4444),
    body:
        'VidyaLoans and its executives, directors, or banking developers shall not be liable for any indirect, incidental, special, or consequential damages resulting from:\n\n'
        '• The denial, rejection, or delay of a loan application by any bank or NBFC.\n'
        '• Temporary system outages, technical maintenance downtime, or database access failures.\n'
        '• Any financial choices, interest rate fluctuations, or repayment commitments students finalize with external banks.',
    highlights: [
      'No liability for external bank decisions or delays',
      'Independent loan agreement between borrower & bank',
    ],
  ),
  const _LegalSection(
    number: '07',
    title: 'Governing Law & Jurisdiction',
    tag: 'Jurisdiction',
    icon: Icons.gavel_rounded,
    accentColor: Color(0xFF10B981),
    body:
        'These Terms & Conditions are governed and constructed in accordance with the laws of the Republic of India.\n\n'
        'Any legal disputes, claims, or regulatory arguments concerning VidyaLoans operations shall be submitted to the exclusive jurisdiction of the competent courts of Hyderabad, Telangana, India.',
    highlights: [
      'Governed by the laws of India',
      'Exclusive jurisdiction in Hyderabad, Telangana',
    ],
  ),
];

final _privacySections = [
  const _LegalSection(
    number: '01',
    title: 'Introduction & Scope',
    tag: 'Overview',
    icon: Icons.lock_rounded,
    accentColor: Color(0xFF6366F1),
    body:
        'Welcome to VidyaLoans ("we," "our," or "us"). We are committed to protecting your personal information and ensuring absolute privacy transparency. This Privacy Policy details how we gather, utilize, protect, and handle your data when you interact with our website, platforms, application features, and integrated lending software.\n\n'
        'By accessing or using VidyaLoans, you agree to the collection and use of information in accordance with this policy. If you do not agree with any terms within this document, please refrain from submitting information or completing active loan profiles.',
    highlights: [
      'Bank-grade privacy standards',
      'Complete transparency in data handling',
    ],
  ),
  const _LegalSection(
    number: '02',
    title: 'Information We Collect',
    tag: 'Collection',
    icon: Icons.folder_shared_rounded,
    accentColor: Color(0xFF3B82F6),
    body:
        'To evaluate your loan application profile and provide automated matching services, we collect several categories of information:\n\n'
        '📋 Personal Identifiers:\nLegal names, date of birth, contact numbers, active email addresses, permanent address, and PAN card / Aadhaar details.\n\n'
        '🎓 Academic Details:\nIntended university of study, global country selection, GRE/IELTS/TOEFL test scores, academic marksheets, and university offer letters.\n\n'
        '💰 Co-Applicant & Financial Data:\nIncome records, salary slips, active bank statements, income tax returns (ITRs), and overall family asset/liability profiles.\n\n'
        '📊 Device & Usage Statistics:\nLog files, IP addresses, browser specifications, operating system versions, and page interaction timestamps.',
    highlights: [
      'Personal, academic & financial documentation',
      'Automated fetch through DigiLocker with user consent',
    ],
  ),
  const _LegalSection(
    number: '03',
    title: 'How We Use Your Data',
    tag: 'Data Usage',
    icon: Icons.data_usage_rounded,
    accentColor: Color(0xFF8B5CF6),
    body:
        'We utilize your personal information strictly to deliver, optimize, and evaluate our student education loan services, specifically for:\n\n'
        '• Matching your unique student profile with eligible educational lenders and public/private banking partners.\n'
        '• Verifying documents automatically through OCR and DigiLocker systems to fast-track bank review.\n'
        '• Assisting you with automated tools (e.g., dynamic SOP suggestions, EMI calculators, and stress testing simulators).\n'
        '• Sending alerts regarding active loan application status updates, counseling details, and verification stages.\n'
        '• Preventing fraud, mitigating operational risks, and fulfilling legal/regulatory obligations.',
    highlights: [
      'Strict purpose-bound loan processing',
      'Instant application status notifications',
    ],
  ),
  const _LegalSection(
    number: '04',
    title: 'Information Sharing & Disclosure',
    tag: 'Third Parties',
    icon: Icons.share_location_rounded,
    accentColor: Color(0xFFEC4899),
    body:
        'VidyaLoans does not sell or lease student database records to third-party marketing companies. We share information only under the following situations:\n\n'
        '🏦 With Banking Partners:\nWe transmit your profiles and uploaded documents directly to partner banks and NBFCs only after you explicitly select and authorize application submissions.\n\n'
        '🔧 With Service Providers:\nTo facilitate specialized features such as secure document fetching, SMS notification updates, and automated OCR processing.\n\n'
        '⚖️ For Legal Compliance:\nWhen compelled by active judicial orders, public regulations, or governmental laws to prevent potential fraud or financial crimes.',
    highlights: [
      'Zero commercial sale of user data',
      'Transmitted to banks only upon explicit user consent',
    ],
  ),
  const _LegalSection(
    number: '05',
    title: 'Data Security & Encryption',
    tag: 'Encryption',
    icon: Icons.security_rounded,
    accentColor: Color(0xFF10B981),
    body:
        'We enforce industry-leading security measures to keep your data protected. All transmission pipelines use secure TLS 1.3/HTTPS protocols and AES-256 data encryption schemes. Documents retrieved through our integration channels are held within high-security cloud firewalls.\n\n'
        'Sensitive authentication credentials (JWT tokens, refresh keys) are stored within hardware-backed Keystore / Keychain environments on your device. We maintain 24/7 security auditing and automated intrusion detection systems.',
    highlights: [
      'AES-256 encryption at rest & TLS 1.3 in transit',
      'Hardware-backed Keystore & Keychain credential storage',
    ],
  ),
  const _LegalSection(
    number: '06',
    title: 'Your Rights & Controls',
    tag: 'User Rights',
    icon: Icons.manage_accounts_rounded,
    accentColor: Color(0xFFF59E0B),
    body:
        'As a student applying through our platform, you have comprehensive control over your personal data:\n\n'
        '👁 Access & Review:\nYou can review all elements of your application, co-applicant details, and uploaded files inside your student profile dashboard.\n\n'
        '✏️ Update & Rectify:\nYou can correct incomplete entries directly or contact support to request swift changes.\n\n'
        '🗑 Data Deletion:\nYou can request complete termination of your active loan profile and deletion of stored records from our archives, subject to active legal or lending auditing mandates.',
    highlights: [
      'Full profile review & update privileges',
      'Right to account deletion and data purge',
    ],
  ),
  const _LegalSection(
    number: '07',
    title: 'Contact Data Protection Officer',
    tag: 'Grievance',
    icon: Icons.support_agent_rounded,
    accentColor: Color(0xFF06B6D4),
    body:
        'If you have questions, comments, or data handling concerns regarding this Privacy Policy, please reach out to our dedicated Data Privacy & Grievance Officer:\n\n'
        '📧 Email: support@Vidyaloans.in\n'
        '📞 Phone: +91 8143797779\n'
        '📍 Address: VidyaLoans Towers, Nuzvid, Andhra Pradesh, India - 521201',
    highlights: [
      'Direct grievance redressal within 48 hours',
      'Official email & phone channels available',
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

class LegalPage extends StatefulWidget {
  /// Pass [initialTab] 0 for Terms, 1 for Privacy Policy.
  final int initialTab;
  const LegalPage({super.key, this.initialTab = 0});

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _expandedTerms = {0}; // Start with 1st section open
  final Set<int> _expandedPrivacy = {0};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleAll(bool isPrivacy, bool expand) {
    setState(() {
      if (isPrivacy) {
        if (expand) {
          _expandedPrivacy.addAll(
            List.generate(_privacySections.length, (i) => i),
          );
        } else {
          _expandedPrivacy.clear();
        }
      } else {
        if (expand) {
          _expandedTerms.addAll(List.generate(_termsSections.length, (i) => i));
        } else {
          _expandedTerms.clear();
        }
      }
    });
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF311B92).withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Nav Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(
                            0xFF311B92,
                          ).withValues(alpha: 0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF311B92,
                            ).withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF311B92),
                        size: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Legal & Compliance',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF059669),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Terms of service & privacy standards',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search toggle button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearchOpen = !_isSearchOpen;
                        if (!_isSearchOpen) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isSearchOpen
                            ? const Color(0xFF311B92)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isSearchOpen
                              ? const Color(0xFF311B92)
                              : const Color(0xFF311B92).withValues(alpha: 0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF311B92,
                            ).withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isSearchOpen
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        color: _isSearchOpen
                            ? Colors.white
                            : const Color(0xFF311B92),
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar Input (when toggled open)
            if (_isSearchOpen)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF311B92).withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF311B92).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search clauses, terms, privacy topics...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF311B92),
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            }),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 14,
                    ),
                  ),
                ),
              ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF311B92).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF311B92).withValues(alpha: 0.08),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF311B92), Color(0xFF5E35B1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF311B92).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: const EdgeInsets.symmetric(vertical: 2),
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF475569),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('Terms & Conditions'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('Privacy Policy'),
                      ],
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

  // ── HERO HERO CARD ──────────────────────────────────────────────────────────

  Widget _buildHeroCard({
    required String title,
    required String subtitle,
    required String version,
    required String lastUpdated,
    required IconData icon,
    required Color accentColor,
    required bool isPrivacy,
  }) {
    final isAllExpanded = isPrivacy
        ? _expandedPrivacy.length == _privacySections.length
        : _expandedTerms.length == _termsSections.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1B4B),
            const Color(0xFF311B92),
            const Color(0xFF4C1D95),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient glowing orb
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withValues(alpha: 0.15),
              ),
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  'VERSION $version',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                lastUpdated,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Action Bar: Quick Expand/Collapse & Section Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.article_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${isPrivacy ? _privacySections.length : _termsSections.length} Key Clauses',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _toggleAll(isPrivacy, !isAllExpanded),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAllExpanded
                                  ? Icons.unfold_less_rounded
                                  : Icons.unfold_more_rounded,
                              size: 15,
                              color: const Color(0xFF311B92),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isAllExpanded ? 'Collapse All' : 'Expand All',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF311B92),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TRUST HIGHLIGHTS PILLS ──────────────────────────────────────────────────

  Widget _buildTrustHighlights() {
    final highlights = [
      {
        'icon': Icons.lock_outline_rounded,
        'title': '256-Bit SSL',
        'desc': 'Bank-grade security',
      },
      {
        'icon': Icons.account_balance_outlined,
        'title': 'RBI Partners',
        'desc': 'Regulated lenders',
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Zero Reselling',
        'desc': 'Private database',
      },
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: highlights.map((h) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF311B92).withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF311B92).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    h['icon'] as IconData,
                    size: 18,
                    color: const Color(0xFF311B92),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    h['title'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    h['desc'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── SECTION ACCORDION CARD ──────────────────────────────────────────────────

  Widget _buildSectionCard({
    required _LegalSection section,
    required int index,
    required Set<int> expandedSet,
    required void Function(int) onToggle,
  }) {
    final isOpen = expandedSet.contains(index);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen
              ? section.accentColor.withValues(alpha: 0.35)
              : const Color(0xFF311B92).withValues(alpha: 0.08),
          width: isOpen ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isOpen
                ? section.accentColor.withValues(alpha: 0.08)
                : const Color(0xFF311B92).withValues(alpha: 0.04),
            blurRadius: isOpen ? 18 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onToggle(index),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row of Clause
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Badge
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: isOpen
                            ? LinearGradient(
                                colors: [
                                  section.accentColor,
                                  section.accentColor.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isOpen
                            ? null
                            : section.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          section.icon,
                          size: 19,
                          color: isOpen ? Colors.white : section.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Tag
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: section.accentColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'SECTION ${section.number} • ${section.tag.toUpperCase()}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: section.accentColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            section.title,
                            style: GoogleFonts.outfit(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: isOpen
                                  ? const Color(0xFF1E1B4B)
                                  : const Color(0xFF1E293B),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow Icon
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 240),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? section.accentColor.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isOpen
                              ? section.accentColor
                              : const Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                // Expandable Body Content
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 1,
                          color: section.accentColor.withValues(alpha: 0.12),
                        ),
                        const SizedBox(height: 12),

                        // Key Highlights Pill Box (if available)
                        if (section.highlights != null &&
                            section.highlights!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: section.accentColor.withValues(
                                alpha: 0.05,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: section.accentColor.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: section.accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'KEY TAKEAWAYS',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: section.accentColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ...section.highlights!.map(
                                  (h) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '✓  ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: section.accentColor,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            h,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF334155),
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
                          const SizedBox(height: 12),
                        ],

                        // Main Text Body
                        Text(
                          section.body,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: const Color(0xFF334155),
                            height: 1.65,
                          ),
                        ),

                        const SizedBox(height: 12),
                        // Copy Clause Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(
                                  text: '${section.title}\n\n${section.body}',
                                ),
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Copied "${section.title}" to clipboard',
                                  ),
                                  backgroundColor: const Color(0xFF311B92),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: Color(0xFF311B92),
                            ),
                            label: Text(
                              'Copy Clause',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF311B92),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              backgroundColor: const Color(
                                0xFF311B92,
                              ).withValues(alpha: 0.06),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: isOpen
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 240),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── CONTACT & GRIEVANCE CARD ────────────────────────────────────────────────

  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF311B92), Color(0xFF4C1D95)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.verified_user_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
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
                          Text(
                            'Legal & Grievance Desk',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Our compliance team is ready to assist you',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _contactRow(
                  Icons.email_outlined,
                  'support@Vidyaloans.in',
                  'Email Support',
                ),
                const SizedBox(height: 8),
                _contactRow(
                  Icons.phone_outlined,
                  '+91 8143797779',
                  'Call Helpline',
                ),
                const SizedBox(height: 8),
                _contactRow(
                  Icons.location_on_outlined,
                  'Nuzvid, Andhra Pradesh, India - 521201',
                  'Official Address',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: text));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied "$text" to clipboard'),
              backgroundColor: const Color(0xFF311B92),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      text,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.copy_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TAB CONTENT BUILDERS ────────────────────────────────────────────────────

  Widget _buildTermsTab() {
    final filtered = _searchQuery.isEmpty
        ? _termsSections
        : _termsSections.where((s) {
            return s.title.toLowerCase().contains(_searchQuery) ||
                s.body.toLowerCase().contains(_searchQuery) ||
                s.tag.toLowerCase().contains(_searchQuery);
          }).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeroCard(
          title: 'Terms & Conditions of Service',
          subtitle:
              'Essential legal agreement covering eligibility, loan match estimation, and documentation requirements.',
          version: '1.8',
          lastUpdated: 'Updated Aug 2026',
          icon: Icons.gavel_rounded,
          accentColor: const Color(0xFF6366F1),
          isPrivacy: false,
        ),
        _buildTrustHighlights(),
        if (filtered.isEmpty)
          Container(
            margin: const EdgeInsets.all(30),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 42,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 10),
                Text(
                  'No matching clauses found',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try searching for terms like "eligibility", "OCR", or "liability"',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...filtered.asMap().entries.map(
            (e) => _buildSectionCard(
              section: e.value,
              index: e.key,
              expandedSet: _expandedTerms,
              onToggle: (idx) => setState(() {
                if (_expandedTerms.contains(idx)) {
                  _expandedTerms.remove(idx);
                } else {
                  _expandedTerms.add(idx);
                }
              }),
            ),
          ),
        _buildContactCard(),
      ],
    );
  }

  Widget _buildPrivacyTab() {
    final filtered = _searchQuery.isEmpty
        ? _privacySections
        : _privacySections.where((s) {
            return s.title.toLowerCase().contains(_searchQuery) ||
                s.body.toLowerCase().contains(_searchQuery) ||
                s.tag.toLowerCase().contains(_searchQuery);
          }).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeroCard(
          title: 'Privacy Policy & Data Shield',
          subtitle:
              'How we collect, encrypt, and safeguard your personal and financial credentials with bank-grade standards.',
          version: '2.1',
          lastUpdated: 'Updated Aug 2026',
          icon: Icons.shield_rounded,
          accentColor: const Color(0xFF10B981),
          isPrivacy: true,
        ),
        _buildTrustHighlights(),
        if (filtered.isEmpty)
          Container(
            margin: const EdgeInsets.all(30),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 42,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 10),
                Text(
                  'No matching privacy topics found',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try searching for terms like "encryption", "DigiLocker", or "deletion"',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...filtered.asMap().entries.map(
            (e) => _buildSectionCard(
              section: e.value,
              index: e.key,
              expandedSet: _expandedPrivacy,
              onToggle: (idx) => setState(() {
                if (_expandedPrivacy.contains(idx)) {
                  _expandedPrivacy.remove(idx);
                } else {
                  _expandedPrivacy.add(idx);
                }
              }),
            ),
          ),
        _buildContactCard(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: MeshBackground(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildTermsTab(), _buildPrivacyTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
