import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/mesh_background.dart';
import '../services/notification_service.dart';

class ReferAndEarnPage extends StatefulWidget {
  const ReferAndEarnPage({super.key});

  @override
  State<ReferAndEarnPage> createState() => _ReferAndEarnPageState();
}

class _ReferAndEarnPageState extends State<ReferAndEarnPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  final TextEditingController _emailController = TextEditingController();
  bool _isNotified = false;
  String? _savedEmail;
  bool _isSubmitting = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.elasticOut,
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    _animCtrl.forward();
    _loadSavedNotificationPref();
  }

  Future<void> _loadSavedNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('referral_notify_email');
    final userEmail = prefs.getString('user_email') ?? '';
    final isNotified = prefs.getBool('referral_notified') ?? false;

    if (mounted) {
      setState(() {
        _savedEmail = savedEmail ?? (userEmail.isNotEmpty ? userEmail : null);
        _emailController.text = _savedEmail ?? '';
        _isNotified = isNotified;
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleNotifyMe() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _emailError = 'Please enter a valid Gmail address (e.g. name@gmail.com)';
      });
      return;
    }

    setState(() {
      _emailError = null;
      _isSubmitting = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('referral_notify_email', email);
    await prefs.setBool('referral_notified', true);

    // Trigger Dual Notification (Bell Icon + System Banner + Email Alert)
    await NotificationService.pushNotification(
      title: '🎁 Refer & Earn VIP Subscription Confirmed!',
      message: 'We will notify $email as soon as Refer & Earn launches with rewards up to ₹3,000!',
      type: 'ALERT',
    );

    if (!mounted) return;

    setState(() {
      _isNotified = true;
      _savedEmail = email;
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VIP Access Reserved! 🎉',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'We will email $email as soon as Refer & Earn launches!',
                    style: GoogleFonts.inter(fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF311B92),
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Refer & Earn',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Animated Hero Badge with Lock Overlay
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF311B92), Color(0xFF6200EA)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF311B92).withValues(alpha: 0.35),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.card_giftcard_rounded,
                                color: Colors.white,
                                size: 54,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF97316),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Locked & Coming Soon Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF97316).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'LOCKED • COMING SOON',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          children: [
                            Text(
                              'Something Exciting\nis Coming!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'We are building an exclusive Refer & Earn program. Earn up to ₹3,000 for every friend who successfully gets their loan disbursed with Vidya Loan!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Locked Status Notice Box
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFFEDD5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF97316).withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF97316).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFC2410C), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Refer & Earn program is currently locked. Stay tuned for early VIP launch access!',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFC2410C),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Feature Teaser Cards
                            _buildFeatureCard(
                              icon: Icons.currency_rupee_rounded,
                              iconColor: const Color(0xFF10B981),
                              title: 'Earn Direct Cash Rewards',
                              description: 'Get rewarded directly in your bank account for every successful loan referral.',
                            ),
                            const SizedBox(height: 14),
                            _buildFeatureCard(
                              icon: Icons.emoji_events_rounded,
                              iconColor: const Color(0xFFF5821E),
                              title: 'Unlock Milestone Bonuses',
                              description: 'Level up your earnings with bonus cash tiers as you invite more classmates.',
                            ),
                            const SizedBox(height: 14),
                            _buildFeatureCard(
                              icon: Icons.insights_rounded,
                              iconColor: const Color(0xFF311B92),
                              title: 'Real-Time Referral Tracker',
                              description: 'Track your referrals, pending payouts, and earnings live from your dashboard.',
                            ),
                            const SizedBox(height: 32),

                            // Notification Card with Gmail Input Field
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEA4335).withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.mark_email_unread_rounded,
                                          color: Color(0xFFEA4335),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Get Launch Email Alert ✉️',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Enter your Gmail address to get notified directly on your inbox when Refer & Earn launches.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: const Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Gmail Input Field
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: !_isNotified || _isSubmitting,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your Gmail address (e.g. name@gmail.com)',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                        color: Color(0xFF311B92),
                                        size: 20,
                                      ),
                                      filled: true,
                                      fillColor: _isNotified ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: _emailError != null ? Colors.red : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF311B92),
                                          width: 1.5,
                                        ),
                                      ),
                                      errorText: _emailError,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  if (_isNotified && _savedEmail != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '✓ VIP Launch Alert Reserved!',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF047857),
                                                  ),
                                                ),
                                                Text(
                                                  'We will email $_savedEmail on launch day.',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11.5,
                                                    color: const Color(0xFF065F46),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _isNotified = false;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                              ),
                                              child: Text(
                                                'Edit Gmail',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF047857),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isSubmitting ? null : _handleNotifyMe,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF311B92),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: _isSubmitting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.notifications_active_rounded,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Notify Me on Launch 🔔',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
