import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/login_page.dart';
import 'pages/main_navigation.dart';
import 'pages/video_splash_screen.dart';
import 'pages/apply_loan_page.dart';
import 'pages/emi_calculator_page.dart';
import 'pages/ai_tools/ai_tools_page.dart';
import 'pages/ai_tools/eligibility_checker_page.dart';
import 'pages/ai_tools/grade_converter_page.dart';
import 'pages/ai_tools/customer_care_bot_page.dart';
import 'pages/university_compare_page.dart';
import 'pages/admit_predictor_page.dart';
import 'pages/sop_writer_page.dart';
import 'pages/ai_tools/university_shortlisting_page.dart';
import 'pages/ai_tools/visa_interview_page.dart';
import 'pages/mentors_page.dart';
import 'pages/events_page.dart';
import 'pages/forum_page.dart';
import 'pages/forum_post_detail_page.dart';
import 'pages/create_post_page.dart';
import 'pages/notifications_page.dart';
import 'pages/blogs_page.dart';
import 'pages/onboarding_page.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
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
      title: 'Vidyaloan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF311B92), // Deep Purple
        fontFamily: GoogleFonts.outfit().fontFamily,
        scaffoldBackgroundColor: Colors.white,
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
            fontSize: 28,
          ),
          titleLarge: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          titleMedium: TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
          bodyLarge: TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF374151),
            fontSize: 12,
          ),
          bodySmall: TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(0.82),
          ),
          child: child!,
        );
      },
      home: const VideoSplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/onboarding': (context) => const OnboardingPage(),
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
        '/ai/university-shortlist': (context) =>
            const UniversityShortlistingPage(),
        '/ai/visa-simulator': (context) => const VisaInterviewPage(),
        '/master-plan': (context) => const UniversityShortlistingPage(),
        '/ai/recommendations': (context) =>
            const UniversityShortlistingPage(initialFlow: 'recommendations'),
        '/community/mentors': (context) => const MentorsPage(),
        '/community/events': (context) => const EventsPage(),
        '/community/forum': (context) => const ForumPage(),
        '/community/forum/create': (context) => const CreatePostPage(),
        '/community/forum/detail': (context) => const ForumPostDetailPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/blogs': (context) => const BlogsPage(),
      },
    );
  }
}
