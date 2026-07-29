import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnim;
  late Animation<double> _floatAnim;

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      gradient: [Color(0xFF1A0A5E), Color(0xFF311B92), Color(0xFF4527A0)],
      accentColor: Color(0xFFB39DDB),
      glowColor: Color(0xFF7C4DFF),
      badge: '🎓',
      title: 'Welcome to\nVidyaLoans',
      subtitle:
          'Your smart companion for education financing. We bridge the gap between your dreams and the world\'s best universities.',
      features: [
        _Feature('✦', 'AI-Powered Platform', 'Smart decisions for your future'),
        _Feature('✦', 'Trusted by thousands', '10,000+ students funded'),
        _Feature('✦', 'End-to-end support', 'From application to disbursement'),
      ],
    ),
    _OnboardingSlide(
      gradient: [Color(0xFF0D2137), Color(0xFF1565C0), Color(0xFF283593)],
      accentColor: Color(0xFF90CAF9),
      glowColor: Color(0xFF448AFF),
      badge: '🚀',
      title: 'Smart Loans\n& AI Tools',
      subtitle:
          'Apply for education loans in minutes. Use our powerful AI tools to plan every step of your study abroad journey.',
      features: [
        _Feature('◈', 'Loan Application', 'Multi-step guided workflow'),
        _Feature('◈', 'Eligibility Checker', 'Know your chances instantly'),
        _Feature('◈', 'SOP Writer & Visa Prep', 'AI-assisted success tools'),
      ],
    ),
    _OnboardingSlide(
      gradient: [Color(0xFF0A1F2E), Color(0xFF004D40), Color(0xFF00695C)],
      accentColor: Color(0xFF80CBC4),
      glowColor: Color(0xFF1DE9B6),
      badge: '🌍',
      title: 'Community &\nSuccess Stories',
      subtitle:
          'Join a thriving community of students. Learn from those who made it, get guidance from mentors, and celebrate together.',
      features: [
        _Feature('❋', 'Peer Community', 'Connect with fellow dreamers'),
        _Feature('❋', 'Expert Mentors', 'Real guidance from real people'),
        _Feature('❋', 'You\'re all set!', 'Your journey starts now 🎉'),
      ],
      isLast: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < _slides.length - 1) {
      _fadeController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      _fadeController.forward();
    }
  }

  Future<void> _getStarted() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_shown', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Page view
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _fadeController.reset();
              _fadeController.forward();
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return _buildSlide(_slides[index]);
            },
          ),

          // Bottom controls overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.gradient,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          ..._buildDecorativeElements(slide),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Badge / Emoji orb
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: child,
                      ),
                      child: _buildBadge(slide),
                    ),

                    const SizedBox(height: 36),

                    // Title
                    Text(
                      slide.title,
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Accent line
                    Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: slide.accentColor,
                        boxShadow: [
                          BoxShadow(
                            color: slide.glowColor.withValues(alpha: 0.8),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Subtitle
                    Text(
                      slide.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.65,
                        letterSpacing: 0.1,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Feature rows
                    ...slide.features.map(
                      (f) => _buildFeatureRow(f, slide.accentColor,
                          slide.glowColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDecorativeElements(_OnboardingSlide slide) {
    return [
      // Large background glow circle top-right
      Positioned(
        top: -80,
        right: -80,
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                slide.glowColor.withValues(alpha: 0.25),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Small glow bottom-left
      Positioned(
        bottom: 120,
        left: -60,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                slide.accentColor.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Grid dots pattern
      Positioned.fill(
        child: CustomPaint(
          painter: _DotGridPainter(
            dotColor: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ),
      // Diagonal lines deco
      Positioned(
        right: -20,
        top: 150,
        child: Transform.rotate(
          angle: -math.pi / 6,
          child: Container(
            width: 3,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  slide.accentColor.withValues(alpha: 0.0),
                  slide.accentColor.withValues(alpha: 0.4),
                  slide.accentColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildBadge(_OnboardingSlide slide) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: slide.accentColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: slide.glowColor.withValues(alpha: 0.5),
            blurRadius: 36,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Text(
          slide.badge,
          style: const TextStyle(fontSize: 44),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
      _Feature feature, Color accentColor, Color glowColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accentColor.withValues(alpha: 0.2),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                feature.symbol,
                style: TextStyle(
                  fontSize: 15,
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final slide = _slides[_currentPage];
    final bool isLast = _currentPage == _slides.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            slide.gradient.last.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _currentPage ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i == _currentPage
                      ? slide.accentColor
                      : Colors.white.withValues(alpha: 0.25),
                  boxShadow: i == _currentPage
                      ? [
                          BoxShadow(
                            color: slide.glowColor.withValues(alpha: 0.6),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Button
          if (isLast)
            // GET STARTED button
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _getStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [slide.glowColor, slide.accentColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: slide.glowColor.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            // NEXT button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip
                TextButton(
                  onPressed: _getStarted,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),

                // Next circular button
                GestureDetector(
                  onTap: _goNext,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          slide.glowColor,
                          slide.accentColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: slide.glowColor.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class _OnboardingSlide {
  final List<Color> gradient;
  final Color accentColor;
  final Color glowColor;
  final String badge;
  final String title;
  final String subtitle;
  final List<_Feature> features;
  final bool isLast;

  const _OnboardingSlide({
    required this.gradient,
    required this.accentColor,
    required this.glowColor,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.features,
    this.isLast = false,
  });
}

class _Feature {
  final String symbol;
  final String title;
  final String subtitle;

  const _Feature(this.symbol, this.title, this.subtitle);
}

// ─── Painters ─────────────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  final Color dotColor;

  _DotGridPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.dotColor != dotColor;
}
