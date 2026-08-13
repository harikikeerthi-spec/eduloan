import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'home_tab.dart';
import 'community_page.dart';
import 'my_loans_page.dart';
import 'ai_tools/ai_tools_page.dart';
import 'profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'onboarding_page.dart';
import 'complete_profile_page.dart';
import '../services/loan_service.dart';
import '../services/language_service.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 2});

  static MainNavigationState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainNavigationState>();

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  // Index mapping: 0=Dashboard, 1=Community, 2=Loans(notch), 3=Explore, 4=Profile
  late int _currentIndex;
  bool _hasAppliedForLoan = false;
  bool _initialRouteChecked = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();

  late final NotchBottomBarController _notchController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _notchController = NotchBottomBarController(index: _currentIndex);
    _checkOnboarding();
    _checkLoanStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialRouteChecked) {
      _initialRouteChecked = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('initialIndex')) {
        final int targetIndex = args['initialIndex'] as int;
        if (_currentIndex != targetIndex) {
          setState(() {
            _currentIndex = targetIndex;
          });
          _notchController.jumpTo(targetIndex);
        }
      }
    }
  }

  Future<void> _checkLoanStatus() async {
    try {
      final loans = await LoanService().getUserLoans();
      if (mounted) {
        setState(() {
          _hasAppliedForLoan = loans.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _notchController.dispose();
    super.dispose();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final String firstName = prefs.getString('user_firstName') ?? '';
    final String email = prefs.getString('user_email') ?? '';

    if (firstName.isEmpty) {
      if (mounted) {
        if (email.isNotEmpty) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => CompleteProfilePage(
                email: email,
                isNewUser: false,
              ),
            ),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      }
      return;
    }

    final bool onboardingShown = prefs.getBool('onboarding_shown') ?? false;
    if (!onboardingShown) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
          (route) => false,
        );
      }
      return;
    }
  }

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void switchToTab(int index) {
    _checkLoanStatus();
    setState(() {
      _currentIndex = index;
    });
    _notchController.jumpTo(index);
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return HomeTab(key: _homeTabKey);
      case 1:
        return const CommunityPage();
      case 2:
        return const MyLoansPage();
      case 3:
        return const AiToolsPage();
      case 4:
        return const ProfilePage();
      default:
        return HomeTab(key: _homeTabKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: _buildBody(),
      extendBody: true,
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _notchController,
        color: Colors.white, // White bar background
        showLabel: true,
        showShadow: true,
        showBlurBottomBar: false,
        blurOpacity: 0.0,
        blurFilterX: 0.0,
        blurFilterY: 0.0,
        notchColor: const Color(0xFF311B92), // Solid Deep Purple moving circle
        kIconSize: 24.0,
        kBottomRadius: 28.0,
        removeMargins: false,
        bottomBarHeight: 62,
        durationInMilliSeconds: 300,
        elevation: 8,
        itemLabelStyle: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9E9E9E),
          letterSpacing: 0.2,
        ),
        onTap: (index) {
          _checkLoanStatus();
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            _homeTabKey.currentState?.refreshData();
          }
        },
        bottomBarItems: [
          // 0 - Dashboard
          BottomBarItem(
            inActiveItem: const Icon(
              Icons.dashboard_outlined,
              color: Color(0xFF9E9E9E),
              size: 24,
            ),
            activeItem: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 26,
            ),
            itemLabel: LanguageService.tr('dashboard'),
          ),
          // 1 - Community
          BottomBarItem(
            inActiveItem: const Icon(
              Icons.people_outline_rounded,
              color: Color(0xFF9E9E9E),
              size: 24,
            ),
            activeItem: const Icon(
              Icons.people_rounded,
              color: Colors.white,
              size: 26,
            ),
            itemLabel: LanguageService.tr('community'),
          ),
          // 2 - Loans (Center notch active item - BEAUTIFULLY HIGHLIGHTED & PULSING)
          BottomBarItem(
            inActiveItem: const _HighlightedApplyIcon(isActive: false),
            activeItem: const _HighlightedApplyIcon(isActive: true),
            itemLabel: _hasAppliedForLoan ? LanguageService.tr('my_loans') : LanguageService.tr('apply'),
          ),
          // 3 - Explore (AI Tools)
          BottomBarItem(
            inActiveItem: const Icon(
              Icons.auto_awesome_outlined,
              color: Color(0xFF9E9E9E),
              size: 24,
            ),
            activeItem: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
            itemLabel: LanguageService.tr('explore'),
          ),
          // 4 - Profile
          BottomBarItem(
            inActiveItem: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF9E9E9E),
              size: 24,
            ),
            activeItem: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 26,
            ),
            itemLabel: LanguageService.tr('profile'),
          ),
        ],
      ),
    );
  }
}


// ─── Highlighted Loans Icon ───────────────────────────────────────────────────
// Premium multi-ring glowing animation for the Loans tab button.
// Dual staggered pulse rings + gradient orb glow + icon scale bounce.

class _HighlightedApplyIcon extends StatefulWidget {
  final bool isActive;
  const _HighlightedApplyIcon({required this.isActive});

  @override
  State<_HighlightedApplyIcon> createState() => _HighlightedApplyIconState();
}

class _HighlightedApplyIconState extends State<_HighlightedApplyIcon>
    with TickerProviderStateMixin {
  late final AnimationController _ring1Controller;
  late final AnimationController _ring2Controller;
  late final AnimationController _bounceController;

  late final Animation<double> _ring1Scale;
  late final Animation<double> _ring1Opacity;
  late final Animation<double> _ring2Scale;
  late final Animation<double> _ring2Opacity;
  late final Animation<double> _iconScale;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    // Ring 1 — fast gold pulse
    _ring1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Ring 2 — slightly delayed purple pulse
    _ring2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Bounce / breathe of the icon
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _ring1Scale = Tween<double>(begin: 0.55, end: 2.0).animate(
      CurvedAnimation(parent: _ring1Controller, curve: Curves.easeOut),
    );
    _ring1Opacity = Tween<double>(begin: 0.85, end: 0.0).animate(
      CurvedAnimation(parent: _ring1Controller, curve: Curves.easeOut),
    );

    _ring2Scale = Tween<double>(begin: 0.5, end: 2.4).animate(
      CurvedAnimation(parent: _ring2Controller, curve: Curves.easeOut),
    );
    _ring2Opacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _ring2Controller, curve: Curves.easeOut),
    );

    _iconScale = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0.45, end: 0.85).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ring1Controller.dispose();
    _ring2Controller.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isActive) {
      return const Icon(
        Icons.account_balance_rounded,
        color: Colors.white,
        size: 26,
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_ring1Controller, _ring2Controller, _bounceController]),
      builder: (context, _) {
        return SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // ── Ring 2 (outer purple) ──────────────────────────────────────
              Transform.scale(
                scale: _ring2Scale.value,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7C3AED)
                          .withValues(alpha: _ring2Opacity.value),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // ── Ring 1 (inner gold) ────────────────────────────────────────
              Transform.scale(
                scale: _ring1Scale.value,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFCC00)
                          .withValues(alpha: _ring1Opacity.value),
                      width: 2.0,
                    ),
                  ),
                ),
              ),

              // ── Glowing orb background ─────────────────────────────────────
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFCC00).withValues(alpha: _glowOpacity.value * 0.35),
                      const Color(0xFF311B92).withValues(alpha: _glowOpacity.value * 0.20),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFCC00).withValues(alpha: _glowOpacity.value * 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: const Color(0xFF311B92).withValues(alpha: _glowOpacity.value * 0.25),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // ── Icon with subtle scale bounce ──────────────────────────────
              Transform.scale(
                scale: _iconScale.value,
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF311B92),
                  size: 24,
                ),
              ),

              // ── Hot badge dot at top-right ─────────────────────────────────
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.6),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
