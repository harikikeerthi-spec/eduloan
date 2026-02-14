import 'package:flutter/material.dart';
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
import 'community_page.dart';
import 'ai_tools/ai_tools_page.dart';
import 'ai_tools/eligibility_checker_page.dart';
import 'ai_tools/grade_converter_page.dart';

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

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _pages = [
    const HomeTab(),
    const MyLoansPage(),
    const ProfilePage(),
  ];

  Widget _buildDrawerLink(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget destination,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
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
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF311B92), Color(0xFF5E35B1)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school, color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'VidhyaLoan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildDrawerLink(
              context,
              icon: Icons.edit_note,
              title: 'Sop writer',
              destination: const SopWriterPage(),
            ),
            _buildDrawerLink(
              context,
              icon: Icons.compare_arrows,
              title: 'University compare',
              destination: const UniversityComparePage(),
            ),
            _buildDrawerLink(
              context,
              icon: Icons.auto_graph,
              title: 'Admit predictor',
              destination: const AdmitPredictorPage(),
            ),
            _buildDrawerLink(
              context,
              icon: Icons.grade,
              title: 'Grade converter',
              destination: const GradeConverterPage(),
            ),
            _buildDrawerLink(
              context,
              icon: Icons.flight_takeoff,
              title: 'Study abroad',
              destination: const StudyAbroadPage(),
            ),
            _buildDrawerLink(
              context,
              icon: Icons.article_outlined,
              title: 'Blogs',
              destination: const BlogsPage(),
            ),
            _buildDrawerLink(
              context,
              icon: Icons.groups_outlined,
              title: 'Community',
              destination: const CommunityPage(),
            ),
            _buildDrawerLink(
              context,
              icon: Icons.fact_check_outlined,
              title: 'Loan eligibility checker',
              destination: const EligibilityCheckerPage(),
            ),
            _buildDrawerLink(
              context,
              icon: Icons.smart_toy_outlined,
              title: 'AI Tools Hub',
              destination: const AiToolsPage(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Apply for Loan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApplyLoanPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('EMI Calculator'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmiCalculatorPage(),
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
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
