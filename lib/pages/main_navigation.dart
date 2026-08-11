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
import '../services/loan_service.dart';
import '../services/language_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  static MainNavigationState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainNavigationState>();

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  // Index mapping: 0=Dashboard, 1=Community, 2=Loans(notch), 3=Explore, 4=Profile
  int _currentIndex = 0;
  bool _hasAppliedForLoan = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();

  late final NotchBottomBarController _notchController;

  @override
  void initState() {
    super.initState();
    _notchController = NotchBottomBarController(index: _currentIndex);
    _checkOnboarding();
    _checkLoanStatus();
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

    final firstName = prefs.getString('user_firstName') ?? '';
    if (firstName.isEmpty) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
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


// ─── Highlighted Apply / Loans Icon ──────────────────────────────────────────
// Shows a clean animated ring-ripple around the account_balance icon.
// No dot. No mismatched aura. Just a smooth, premium pulse ring.

class _HighlightedApplyIcon extends StatefulWidget {
  final bool isActive;
  const _HighlightedApplyIcon({required this.isActive});

  @override
  State<_HighlightedApplyIcon> createState() => _HighlightedApplyIconState();
}

class _HighlightedApplyIconState extends State<_HighlightedApplyIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // Ring expands outward from 0.6x to 1.8x and fades out
    _ringScale = Tween<double>(begin: 0.6, end: 1.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _ringOpacity = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When the notch is active (user tapped this tab), just show plain white icon
    if (widget.isActive) {
      return const Icon(
        Icons.account_balance_rounded,
        color: Colors.white,
        size: 26,
      );
    }

    // Inactive state — show the animated ripple ring
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // ── Expanding ripple ring ──────────────────────────────────────
              Transform.scale(
                scale: _ringScale.value,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD700)   // gold ring
                          .withValues(alpha: _ringOpacity.value),
                      width: 2.2,
                    ),
                  ),
                ),
              ),

              // ── Clean icon — NO extra background circle ────────────────────
              const Icon(
                Icons.account_balance_rounded,
                color: Color(0xFF311B92),   // uses app primary, fits the bar
                size: 24,
              ),
            ],
          ),
        );
      },
    );
  }
}
