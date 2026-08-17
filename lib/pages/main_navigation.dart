import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'home_tab.dart';
import 'community_page.dart';
import 'my_loans_page.dart';
import 'ai_tools/ai_tools_page.dart';
import 'profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
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
// Premium dark-highlighted button for the Loans tab.
// Neat, clean, bold dark circular badge with big crisp icon and subtle elegant glow.

class _HighlightedApplyIcon extends StatefulWidget {
  final bool isActive;
  const _HighlightedApplyIcon({required this.isActive});

  @override
  State<_HighlightedApplyIcon> createState() => _HighlightedApplyIconState();
}

class _HighlightedApplyIconState extends State<_HighlightedApplyIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isActive) {
      return const Icon(
        Icons.account_balance_rounded,
        color: Colors.white,
        size: 28,
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF311B92), // Deep Purple
                  Color(0xFF1E1B4B), // Dark Indigo
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF311B92).withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.20),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.account_balance_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}
