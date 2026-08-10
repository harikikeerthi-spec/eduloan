import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static final ValueNotifier<String> activeLanguageNotifier = ValueNotifier<String>('en');

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'dashboard': 'Dashboard',
      'community': 'Community',
      'my_loans': 'My Loans',
      'apply': 'Apply',
      'explore': 'Explore',
      'profile': 'Profile',
      'settings': 'Settings',
      'app_language': 'App Language',
      'logout': 'Logout',
      'refer_earn': 'Refer & Earn',
      'edit_profile': 'Edit Profile',
      'document_vault': 'Document Vault',
      'emi_calculator': 'EMI Calculator',
      'loan_eligibility': 'Loan Eligibility',
      'welcome_back': 'Welcome Back',
      'support_legal': 'SUPPORT & LEGAL',
      'help_center': 'Help Center & FAQ',
      'terms_policy': 'Terms & Privacy Policy',
      'version': 'Version 1.0.4 (Latest Release)',
    },
    'te': {
      'dashboard': 'డ్యాష్‌బోర్డ్',
      'community': 'కమ్యూనిటీ',
      'my_loans': 'నా రుణాలు',
      'apply': 'దరఖాస్తు',
      'explore': 'ఎక్స్‌ప్లోర్',
      'profile': 'ప్రొఫైల్',
      'settings': 'సెట్టింగ్‌లు',
      'app_language': 'యాప్ భాష',
      'logout': 'లాగ్‌అవుట్',
      'refer_earn': 'రెఫర్ & ఎర్న్',
      'edit_profile': 'ప్రొఫైల్ సవరించండి',
      'document_vault': 'డాక్యుమెంట్ వాల్ట్',
      'emi_calculator': 'ఈఎమ్‌ఐ క్యాలిక్యులేటర్',
      'loan_eligibility': 'రుణ అర్హత పరి పరిశీలన',
      'welcome_back': 'స్వాగతం',
      'support_legal': 'సహాయం & నిబంధనలు',
      'help_center': 'సహాయ కేంద్రం & తరచుగా అడిగే ప్రశ్నలు',
      'terms_policy': 'నిబంధనలు & గోప్యతా విధానం',
      'version': 'వెర్షన్ 1.0.4 (తాజా విడుదల)',
    },
    'ta': {
      'dashboard': 'டேஷ்போர்டு',
      'community': 'சமூகம்',
      'my_loans': 'என் கடன்கள்',
      'apply': 'விண்ணப்பி',
      'explore': 'ஆராய்க',
      'profile': 'சுயவிவரம்',
      'settings': 'அமைப்புகள்',
      'app_language': 'பயன்பாட்டு மொழி',
      'logout': 'வெளியேறு',
      'refer_earn': 'பரிந்துரைத்து சம்பாதிக்க',
      'edit_profile': 'சுயவிவரத்தை திருத்து',
      'document_vault': 'ஆவண பெட்டகம்',
      'emi_calculator': 'EMI கணக்கிடி',
      'loan_eligibility': 'கடன் தகுதி',
      'welcome_back': 'மீண்டும் வருக',
      'support_legal': 'ஆதரவு & சட்டபூர்வம்',
      'help_center': 'உதவி மையம் & கேள்விகள்',
      'terms_policy': 'விதிகள் & தனியுரிமைக் கொள்கை',
      'version': 'பதிப்பு 1.0.4',
    },
    'kn': {
      'dashboard': 'ಡ್ಯಾಶ್‌ಬೋರ್ಡ್',
      'community': 'ಕಮ್ಯುನಿಟಿ',
      'my_loans': 'ನನ್ನ ಸಾಲಗಳು',
      'apply': 'ಅರ್ಜಿ ಸಲ್ಲಿಸಿ',
      'explore': 'ಅನ್ವೇಷಿಸಿ',
      'profile': 'ಪ್ರೊಫೈಲ್',
      'settings': 'ಸಂಯೋಜನೆಗಳು',
      'app_language': 'ಆಪ್ ಭಾಷೆ',
      'logout': 'ಲಾಗ್‌ಔಟ್',
      'refer_earn': 'ರೆಫರ್ & ಗಳಿಸಿ',
      'edit_profile': 'ಪ್ರೊಫೈಲ್ ಸಂಪಾದಿಸಿ',
      'document_vault': 'ದಾಖಲೆ ಕಣಜ',
      'emi_calculator': 'ಇಎಮ್‌ಐ ಕ್ಯಾಲ್ಕುಲೇಟರ್',
      'loan_eligibility': 'ಸಾಲದ ಅರ್ಹತೆ',
      'welcome_back': 'ಸುಸ್ವಾಗತ',
      'support_legal': 'ಬೆಂಬಲ & ಕಾನೂನು',
      'help_center': 'ಸಹಾಯ ಕೇಂದ್ರ & FAQ',
      'terms_policy': 'ನಿಯಮಗಳು & ಗೌಪ್ಯತಾ ನೀತಿ',
      'version': 'ಆವೃತ್ತಿ 1.0.4',
    },
    'ml': {
      'dashboard': 'ഡാഷ്‌ബോർഡ്',
      'community': 'കമ്മ്യൂണിറ്റി',
      'my_loans': 'എന്റെ വായ്പകൾ',
      'apply': 'അപേക്ഷിക്കുക',
      'explore': 'എക്സ്പ്ലോർ',
      'profile': 'പ്രൊഫൈൽ',
      'settings': 'ക്രമീകരണങ്ങൾ',
      'app_language': 'ആപ്പ് ഭാഷ',
      'logout': 'ലോഗ്ഔട്ട്',
      'refer_earn': 'റെഫർ & സമ്പാദിക്കുക',
      'edit_profile': 'പ്രൊഫൈൽ തിരുത്തുക',
      'document_vault': 'ഡോക്യുമെന്റ് വോൾട്ട്',
      'emi_calculator': 'ഇഎംഐ കാൽക്കുലേറ്റർ',
      'loan_eligibility': 'വായ്പ യോഗ്യത',
      'welcome_back': 'വീണ്ടും സ്വാഗതം',
      'support_legal': 'സഹായം & നിയമപരം',
      'help_center': 'സഹായ കേന്ദ്രം & ചോദ്യങ്ങൾ',
      'terms_policy': 'വ്യവസ്ഥകളും സ്വകാര്യതാ നയവും',
      'version': 'പതിപ്പ് 1.0.4',
    },
    'hi': {
      'dashboard': 'डैशबोर्ड',
      'community': 'कम्युनिटी',
      'my_loans': 'मेरे ऋण',
      'apply': 'आवेदन',
      'explore': 'एक्सप्लोर',
      'profile': 'प्रोफाइल',
      'settings': 'सेटिंग्स',
      'app_language': 'ऐप भाषा',
      'logout': 'लॉगआउट',
      'refer_earn': 'रेफर और कमाएं',
      'edit_profile': 'प्रोफाइल संपादित करें',
      'document_vault': 'दस्तावेज वॉल्ट',
      'emi_calculator': 'ईएमआई कैलकुलेटर',
      'loan_eligibility': 'ऋण पात्रता',
      'welcome_back': 'स्वागत है',
      'support_legal': 'सहायता और नियम',
      'help_center': 'सहायता केंद्र और एफएक्यू',
      'terms_policy': 'नियम और गोपनीयता नीति',
      'version': 'संस्करण 1.0.4',
    },
  };

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language');
    if (saved != null) {
      final code = _nameToCode(saved);
      activeLanguageNotifier.value = code;
    }
  }

  static String _nameToCode(String nameOrDisplayName) {
    if (nameOrDisplayName.contains('Telugu') || nameOrDisplayName.contains('తెలుగు')) return 'te';
    if (nameOrDisplayName.contains('Tamil') || nameOrDisplayName.contains('தமிழ்')) return 'ta';
    if (nameOrDisplayName.contains('Kannada') || nameOrDisplayName.contains('ಕನ್ನಡ')) return 'kn';
    if (nameOrDisplayName.contains('Malayalam') || nameOrDisplayName.contains('മലയാളം')) return 'ml';
    if (nameOrDisplayName.contains('Hindi') || nameOrDisplayName.contains('हिंदी')) return 'hi';
    return 'en';
  }

  static Future<void> setLanguageFromDisplayName(String displayName) async {
    final code = _nameToCode(displayName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', displayName);
    await prefs.setString('app_language_code', code);
    activeLanguageNotifier.value = code;
  }

  static String tr(String key) {
    final currentCode = activeLanguageNotifier.value;
    final langMap = _translations[currentCode] ?? _translations['en']!;
    return langMap[key] ?? _translations['en']![key] ?? key;
  }

  static String get currentCode => activeLanguageNotifier.value;
}
