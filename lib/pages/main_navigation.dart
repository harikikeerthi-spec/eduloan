import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_tab.dart';
import 'my_loans_page.dart';
import 'profile_page.dart';
import 'apply_loan_page.dart';
import 'emi_calculator_page.dart';
import 'sop_writer_page.dart';
import 'university_compare_page.dart';
import 'admit_predictor_page.dart';
import 'study_abroad_page.dart';
import 'blogs_page.dart';
import 'forum_page.dart';
import 'ai_tools/ai_tools_page.dart';
import 'ai_tools/eligibility_checker_page.dart';
import 'ai_tools/grade_converter_page.dart';
import '../services/loan_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  static MainNavigationState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainNavigationState>();

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();
  bool _hasAppliedForLoan = false;

  @override
  void initState() {
    super.initState();
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
    } catch (e) {
      // Ignore
    }
  }

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return HomeTab(key: _homeTabKey);
      case 1:
        return const MyLoansPage();
      case 2:
        return const ProfilePage();
      default:
        return HomeTab(key: _homeTabKey);
    }
  }

  Widget _buildDrawerLink(
    BuildContext context, {
    required String imagePath,
    required String title,
    required Widget destination,
    Color? iconColor,
  }) {
    final effectiveColor = iconColor ?? const Color(0xFF673AB7);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Image.asset(
        imagePath,
        width: 42,
        height: 42,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: Colors.grey[400],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      hoverColor: effectiveColor.withValues(alpha: 0.05),
      splashColor: effectiveColor.withValues(alpha: 0.1),
      onTap: () async {
        Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
        if (mounted) {
          _homeTabKey.currentState?.refreshData();
          _checkLoanStatus();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 260,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF311B92), Color(0xFF5E35B1)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Transform.translate(
                              offset: const Offset(2.5, 0),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vidyaloan',
                        style: GoogleFonts.urbanist(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildDrawerLink(
              context,
              imagePath: 'assets/icons/3d/sop_writer.png',
              title: 'Sop writer',
              destination: const SopWriterPage(),
              iconColor: const Color(0xFFE91E63),
            ),
            _buildDrawerLink(
              context,
              imagePath: 'assets/icons/3d/university_compare.png',
              title: 'University compare',
              destination: const UniversityComparePage(),
              iconColor: const Color(0xFF00BCD4),
            ),
            _buildDrawerLink(
              context,
              imagePath: 'assets/icons/3d/admit_predictor.png',
              title: 'Admit predictor',
              destination: const AdmitPredictorPage(),
              iconColor: const Color(0xFFFF5722),
            ),
            _buildDrawerLink(
              context,
              imagePath: 'assets/icons/3d/grade_converter.png',
              title: 'Grade converter',
              destination: const GradeConverterPage(),
              iconColor: const Color(0xFFF59E0B),
            ),
            _buildDrawerLink(
              context,
              imagePath: 'assets/icons/3d/study_abroad.png',
              title: 'Study abroad',
              destination: const StudyAbroadPage(),
              iconColor: const Color(0xFF009688),
            ),
            _buildDrawerLink(
              context,
              imagePath: 'assets/icons/3d/blogs.png',
              title: 'Blogs',
              destination: const BlogsPage(),
              iconColor: const Color(0xFF3F51B5),
            ),
            _buildDrawerLink(
              context,
              imagePath: 'assets/icons/3d/community.png',
              title: 'Community',
              destination: const ForumPage(),
              iconColor: const Color(0xFF4CAF50),
            ),
            _buildDrawerLink(
              context,
              imagePath: 'assets/icons/3d/loan_eligibility.png',
              title: 'Loan eligibility checker',
              destination: const EligibilityCheckerPage(),
              iconColor: const Color(0xFF2196F3),
            ),
            _buildDrawerLink(
              context,
              imagePath: 'assets/icons/3d/ai_tools_hub.png',
              title: 'AI Tools Hub',
              destination: const AiToolsPage(),
              iconColor: const Color(0xFF9C27B0),
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFEEEEEE), height: 1, thickness: 1, indent: 24, endIndent: 24),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 8),
              child: Text(
                'Financial Tools',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 1.0,
                ),
              ),
            ),
            if (!_hasAppliedForLoan)
              _buildDrawerLink(
                context,
                imagePath: 'assets/icons/3d/apply_loan.png',
                title: 'Apply for Loan',
                destination: const ApplyLoanPage(),
                iconColor: const Color(0xFF10B981),
              ),
            _buildDrawerLink(
              context,
              imagePath: 'assets/icons/3d/emi_calculator.png',
              title: 'EMI Calculator',
              destination: const EmiCalculatorPage(),
              iconColor: const Color(0xFFF43F5E),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Version 1.0.0',
                style: GoogleFonts.urbanist(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) {
              _homeTabKey.currentState?.refreshData();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          selectedItemColor: const Color(0xFF311B92),
          unselectedItemColor: Colors.black.withValues(alpha: 0.4),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              activeIcon: Icon(Icons.home, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined, size: 28),
              activeIcon: Icon(Icons.account_balance_wallet, size: 28),
              label: 'My Loans',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 28),
              activeIcon: Icon(Icons.person, size: 28),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
