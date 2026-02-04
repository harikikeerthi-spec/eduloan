import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/login_page.dart';
import 'pages/main_navigation.dart';
import 'pages/apply_loan_page.dart';
import 'pages/emi_calculator_page.dart';
import 'pages/ai_tools/ai_tools_page.dart';
import 'pages/ai_tools/eligibility_checker_page.dart';
import 'pages/ai_tools/grade_converter_page.dart';
import 'pages/ai_tools/customer_care_bot_page.dart';

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
      title: 'Edu Loan',
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
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainNavigation(),
        '/apply-loan': (context) => const ApplyLoanPage(),
        '/emi-calculator': (context) => const EmiCalculatorPage(),
        '/ai': (context) => const AiToolsPage(),
        '/ai/eligibility': (context) => const EligibilityCheckerPage(),
        '/ai/grade-converter': (context) => const GradeConverterPage(),
        '/ai/bot': (context) => const CustomerCareBotPage(),
      },
    );
  }
}
