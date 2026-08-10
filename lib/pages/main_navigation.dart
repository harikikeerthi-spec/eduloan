import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'home_tab.dart';
import 'community_page.dart';
import 'my_loans_page.dart';
import 'ai_tools/ai_tools_page.dart';
import 'profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
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
          // 2 - Loans (Center notch active item - MAIN FEATURE HIGHLIGHTED)
          BottomBarItem(
            inActiveItem: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF311B92), Color(0xFF673AB7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF311B92).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            activeItem: const Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: 26,
            ),
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
