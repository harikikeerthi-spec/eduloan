import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'pages/main_navigation.dart';
import 'pages/apply_loan_page.dart';
import 'pages/emi_calculator_page.dart';
import 'pages/ai_tools/ai_tools_page.dart';
import 'pages/ai_tools/eligibility_checker_page.dart';
import 'pages/ai_tools/grade_converter_page.dart';
import 'pages/ai_tools/customer_care_bot_page.dart';
import 'pages/university_compare_page.dart';
import 'pages/admit_predictor_page.dart';
import 'pages/sop_writer_page.dart';
import 'pages/mentors_page.dart';
import 'pages/events_page.dart';

void main() {
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduLoan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF311B92), // Deep Purple
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.transparent,
        cardColor: Colors.white,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        textTheme: const TextTheme(
          displayMedium: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Color(0xFF374151)),
        ),
      ),
      home: const AuthCheck(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainNavigation(),
        '/apply-loan': (context) => const ApplyLoanPage(),
        '/emi-calculator': (context) => const EmiCalculatorPage(),
        '/ai': (context) => const AiToolsPage(),
        '/ai/eligibility': (context) => const EligibilityCheckerPage(),
        '/ai/grade-converter': (context) => const GradeConverterPage(),
        '/ai/bot': (context) => const CustomerCareBotPage(),
        '/ai/university-compare': (context) => const UniversityComparePage(),
        '/university-compare': (context) =>
            const UniversityComparePage(), // Added alias for Community Page
        '/ai/admit-predictor': (context) => const AdmitPredictorPage(),
        '/ai/sop-writer': (context) => const SopWriterPage(),
        '/community/mentors': (context) => const MentorsPage(),
        '/community/events': (context) => const EventsPage(),
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // Simulate a short delay for splash effect
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
