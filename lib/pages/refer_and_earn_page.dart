import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class ReferAndEarnPage extends StatefulWidget {
  const ReferAndEarnPage({super.key});

  @override
  State<ReferAndEarnPage> createState() => _ReferAndEarnPageState();
}

class _ReferAndEarnPageState extends State<ReferAndEarnPage>
    with SingleTickerProviderStateMixin {
  String _referralCode = '';
  bool _isLoading = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  final List<bool> _faqOpen = [false, false, false, false];

  static const _orange = Color(0xFFF5821E);
  static const _deepPurple = Color(0xFF1E1B4B);

  static const _faqs = [
    {
      'q': 'How much can I earn per referral?',
      'a': 'You earn â‚¹3,000 for every friend whose education loan is successfully disbursed through Vidya Loans.',
    },
    {
      'q': 'When do I receive my referral bonus?',
      'a': 'Your bonus is credited within 7 working days after your referred friend\'s loan is fully disbursed.',
    },
    {
      'q': 'Is there a limit to how many people I can refer?',
      'a': 'No limit at all! The more you refer, the more you earn. There are also milestone bonuses for hitting 3, 5, 10, 25, and 50 referrals.',
    },
    {
      'q': 'What if my referral\'s loan is rejected?',
      'a': 'Only successful disbursements qualify for the referral bonus. Rejected applications do not count.',
    },
  ];

  static const _milestones = [
    {'count': '3', 'reward': 'â‚¹500', 'label': 'Trio bonus'},
    {'count': '5', 'reward': 'â‚¹10k', 'label': 'Silver bonus'},
    {'count': '10', 'reward': 'â‚¹25k', 'label': 'Pro bonus'},
    {'count': '25', 'reward': 'â‚¹75k', 'label': 'Super bonus'},
    {'count': '50', 'reward': 'â‚¹2L', 'label': 'Legend status'},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _fetchReferralCode();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email != null) {
        final result = await AuthService.getUserDashboard(email);
        if (result['success'] == true) {
          final user = result['user'];
          String? code;
          if (user is Map) {
            code = user['referralCode'] as String?;
            if (code == null) {
              final data = user['data'];
              if (data is Map) {
                final nested = data['user'];
                if (nested is Map) code = nested['referralCode'] as String?;
              }
            }
          }
          if (mounted && code != null && code.isNotEmpty) {
            setState(() => _referralCode = code!);
          }
        }
      }
    } catch (e) {
      debugPrint('Referral fetch error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animCtrl.forward();
      }
    }
  }

  void _copyCode() {
    if (_referralCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Code "$_referralCode" copied!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: _orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _copyLink() {
    final link =
        'https://vidyaloans.in/signup?ref=${_referralCode.isNotEmpty ? _referralCode : ''}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Referral link copied!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: _deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _orange))
                  : FadeTransition(
                      opacity: _fadeIn,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeroSection(),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildReferralCard(),
                                  const SizedBox(height: 20),
                                  _buildStatsRow(),
                                  const SizedBox(height: 28),
                                  _buildHowItWorks(),
                                  const SizedBox(height: 28),
                                ],
                              ),
                            ),
                            _buildMilestoneSection(),
                            const SizedBox(height: 28),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildFaqSection(),
                            ),
                            const SizedBox(height: 28),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildCtaBanner(),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ AppBar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: _deepPurple),
          ),
          Text(
            'Refer & Earn',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _deepPurple,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Earn â‚¹3,000 / referral',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _orange,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // â”€â”€ Hero â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeroSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'âœ¦  REFERRAL PROGRAM',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _orange,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                  fontSize: 30, fontWeight: FontWeight.w900, color: _deepPurple, height: 1.2),
              children: [
                const TextSpan(text: 'Share & Earn '),
                TextSpan(
                  text: 'â‚¹3,000',
                  style: GoogleFonts.inter(
                      fontSize: 30, fontWeight: FontWeight.w900, color: _orange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Help your friends fund their education abroad and\nearn rewards for every successful referral.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Referral code card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildReferralCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5821E), Color(0xFFFFC56B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                'YOUR REFERRAL CODE',
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85), letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _copyCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Copy',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _orange)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Code display
          GestureDetector(
            onTap: _copyCode,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _referralCode.isNotEmpty ? _referralCode : 'LOADING...',
                    style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Share link
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SHARE YOUR LINK',
                  style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500, letterSpacing: 1.2,
                  )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'https://vidyaloans.in/signup?ref=${_referralCode.isNotEmpty ? _referralCode : '...'}',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _copyLink,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _deepPurple, borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Copy Link',
                          style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _shareChip(Icons.message_rounded, 'WhatsApp', const Color(0xFF25D366)),
                    const SizedBox(width: 8),
                    _shareChip(Icons.send_rounded, 'Telegram', const Color(0xFF229ED9)),
                    const SizedBox(width: 8),
                    _shareChip(Icons.email_rounded, 'Email', const Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    _shareChip(Icons.more_horiz_rounded, 'More', _deepPurple),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareChip(IconData icon, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sharing via $label coming soon!',
                  style: GoogleFonts.inter()),
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(label,
              style: GoogleFonts.inter(
                fontSize: 9, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
    );
  }

  // â”€â”€ Stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildStatsRow() {
    final stats = [
      {'icon': Icons.ads_click_rounded, 'value': '0', 'label': 'Link Clicks'},
      {'icon': Icons.group_add_rounded, 'value': '0', 'label': 'Registered'},
      {'icon': Icons.check_circle_rounded, 'value': '0', 'label': 'Successful'},
      {'icon': Icons.hourglass_empty_rounded, 'value': '0', 'label': 'Pending'},
      {'icon': Icons.currency_rupee_rounded, 'value': 'â‚¹0', 'label': 'Earned'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((s) {
          final bool isEarned = s['label'] == 'Earned';
          return Column(children: [
            Icon(s['icon'] as IconData,
              color: isEarned ? _orange : Colors.grey.shade400, size: 22),
            const SizedBox(height: 6),
            Text(s['value'] as String,
              style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: isEarned ? _orange : _deepPurple)),
            const SizedBox(height: 2),
            Text(s['label'] as String,
              style: GoogleFonts.inter(
                fontSize: 9, fontWeight: FontWeight.w600,
                color: Colors.grey.shade500, letterSpacing: 0.4)),
          ]);
        }).toList(),
      ),
    );
  }

  // â”€â”€ How It Works â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How It Works',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: _deepPurple)),
        const SizedBox(height: 4),
        Text('Three simple steps to start earning',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 20),
        Row(children: [
          _howStep('1', Icons.share_rounded, 'Share Your Code',
              'Send your unique referral code to friends planning to study abroad'),
          _stepConnector(),
          _howStep('2', Icons.description_rounded, 'Friend Applies',
              'Your friend signs up and applies for an education loan using your code'),
          _stepConnector(),
          _howStep('3', Icons.account_balance_wallet_rounded, 'Earn Rewards',
              'Get â‚¹3,000 when their loan is successfully disbursed'),
        ]),
      ],
    );
  }

  Widget _stepConnector() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 36),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_orange.withValues(alpha: 0.3), _orange.withValues(alpha: 0.7)]),
        ),
      ),
    );
  }

  Widget _howStep(String number, IconData icon, String title, String desc) {
    return Expanded(
      child: Column(children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5821E), Color(0xFFFFC56B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _orange.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _deepPurple,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(number,
                style: GoogleFonts.inter(
                  fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _deepPurple)),
        const SizedBox(height: 4),
        Text(desc,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500, height: 1.4)),
      ]),
    );
  }

  // â”€â”€ Milestones â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildMilestoneSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _deepPurple, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MILESTONE REWARDS',
            style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: _orange, letterSpacing: 1.4)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text('Unlock Bonus\nRewards',
                  style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2)),
              ),
              Expanded(
                child: Text(
                  'The more you refer, the more you earn. Hit milestones for extra bonuses.',
                  style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.white.withValues(alpha: 0.6), height: 1.4)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _milestones.asMap().entries.map((e) {
                final isLast = e.key == _milestones.length - 1;
                return Row(children: [
                  _milestoneCard(e.value, isLast),
                  if (!isLast) const SizedBox(width: 10),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneCard(Map<String, String> m, bool highlight) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? _orange : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? _orange : Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${m['count']} REFERRALS',
            style: GoogleFonts.inter(
              fontSize: 8, fontWeight: FontWeight.w700,
              color: highlight ? Colors.white : Colors.grey.shade500, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Text(m['reward']!,
            style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w900,
              color: highlight ? Colors.white : _orange)),
          const SizedBox(height: 4),
          Text(m['label']!,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: highlight ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade400)),
        ],
      ),
    );
  }

  // â”€â”€ FAQ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Common Questions',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: _deepPurple)),
        const SizedBox(height: 4),
        Text('Everything you need to know about our referral program',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 16),
        ...List.generate(_faqs.length, _faqItem),
      ],
    );
  }

  Widget _faqItem(int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ExpansionTile(
          onExpansionChanged: (v) => setState(() => _faqOpen[i] = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          trailing: AnimatedRotation(
            turns: _faqOpen[i] ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _faqOpen[i] ? _orange : Colors.grey.shade400,
            ),
          ),
          title: Text(_faqs[i]['q']!,
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: _deepPurple)),
          children: [
            Text(_faqs[i]['a']!,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, height: 1.5)),
          ],
        ),
      ),
    );
  }

  // â”€â”€ CTA banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildCtaBanner() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5821E), Color(0xFFFFC56B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text('Start Earning Today',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            'Share your referral code with friends and\nstart building your passive income stream.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white.withValues(alpha: 0.85), height: 1.5)),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _copyLink,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Text('Copy Referral Link',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _orange)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  child: Text('View Dashboard',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
