import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/mesh_background.dart';
import '../widgets/avatar_selection_dialog.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/language_service.dart';
import 'legal_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _email = '';
  String _userName = '';
  String? _profileImage;
  String _selectedLanguage = 'English (IN)';
  bool _isLoading = false;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final first = prefs.getString('user_firstName') ?? prefs.getString('user_name') ?? '';
    final last = prefs.getString('user_lastName') ?? prefs.getString('user_last_name') ?? '';
    final email = prefs.getString('user_email') ?? 'student@vidhyaloan.com';
    final profileImg = prefs.getString('user_profileImage');
    final savedLang = prefs.getString('app_language') ?? 'English (IN)';

    setState(() {
      _email = email;
      _profileImage = profileImg;
      _selectedLanguage = savedLang;
      _userName = '$first $last'.trim();
      if (_userName.isEmpty) {
        _userName = email.contains('@') ? email.split('@')[0] : 'Student Account';
      }
    });

    // Also fetch latest profile image from backend if email is available
    if (email.isNotEmpty && email != 'student@vidhyaloan.com') {
      try {
        final profile = await AuthService.getUserDashboard(email);
        if (profile['success'] == true && profile['user'] != null) {
          final user = profile['user'];
          if (user['profileImage'] != null) {
            await prefs.setString('user_profileImage', user['profileImage']);
            if (mounted) {
              setState(() {
                _profileImage = user['profileImage'];
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching profile in SettingsPage: $e');
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF311B92).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFF311B92), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Confirm Logout',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your VidhyaLoan account on this device?',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF311B92),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
            ),
            child: Text(
              'Yes, Logout',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
      await prefs.remove('userId');
      await prefs.remove('user_email');
      await prefs.remove('user_firstName');
      await prefs.remove('user_lastName');
      await prefs.remove('user_phone');
      await prefs.remove('user_profileImage');
      await prefs.remove('latest_ai_recommendations');

      // Preserve flags so the 3 slides are never shown again in their lifetime
      await prefs.setBool('onboarding_shown', true);
      await prefs.setBool('has_registered', true);
      try {
        await GoogleAuthService().signOut();
      } catch (e) {
        debugPrint('Error during Google/Firebase sign out: $e');
      }
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Delete Account?',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete your account? All loan applications, document vault files, and profile details will be permanently removed.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              elevation: 0,
            ),
            child: Text(
              'Delete Permanently',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final result = await AuthService.deleteAccount(_email);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          try {
            await GoogleAuthService().signOut();
          } catch (e) {
            debugPrint('Error during Google/Firebase sign out: $e');
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Your account has been deleted successfully.'),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to delete account. Please try again later.'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  void _showLanguageSelectionDialog() {
    final languages = [
      {'name': 'English (IN)', 'native': 'English', 'code': 'en'},
      {'name': 'Telugu', 'native': 'తెలుగు', 'code': 'te'},
      {'name': 'Tamil', 'native': 'தமிழ்', 'code': 'ta'},
      {'name': 'Kannada', 'native': 'ಕನ್ನಡ', 'code': 'kn'},
      {'name': 'Malayalam', 'native': 'മലയാളം', 'code': 'ml'},
      {'name': 'Hindi', 'native': 'हिंदी', 'code': 'hi'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.translate_rounded, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Select App Language',
                    style: GoogleFonts.outfit(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: languages.length,
                  separatorBuilder: (ctx, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, index) {
                    final lang = languages[index];
                    final displayName = '${lang['name']} (${lang['native']})';
                    final isSelected = _selectedLanguage == displayName || (_selectedLanguage.contains(lang['name']!) && lang['name'] != 'English (IN)');

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      title: Text(
                        lang['name']!,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF311B92) : const Color(0xFF0F172A),
                        ),
                      ),
                      subtitle: Text(
                        lang['native']!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      trailing: isSelected
                          ? Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF311B92),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 16),
                            )
                          : null,
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(ctx);
                        await LanguageService.setLanguageFromDisplayName(displayName);
                        setState(() {
                          _selectedLanguage = displayName;
                        });
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('App language changed to $displayName'),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatarWidget(String initialLetter) {
    if (_profileImage != null && _profileImage!.isNotEmpty) {
      if (_profileImage!.startsWith('data:image/')) {
        try {
          final base64Str = _profileImage!.split(',').last;
          final bytes = base64Decode(base64Str);
          return Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7C4DFF), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.memory(
                bytes,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
              ),
            ),
          );
        } catch (e) {
          debugPrint('Error decoding base64 image in SettingsPage: $e');
        }
      }

      final avatarData = AvatarSelectionDialog.avatars.firstWhere(
        (a) => a['name'] == _profileImage,
        orElse: () => <String, dynamic>{},
      );

      if (avatarData.isNotEmpty && avatarData['icon'] != null) {
        return Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (avatarData['color'] as Color).withValues(alpha: 0.15),
            border: Border.all(color: (avatarData['color'] as Color).withValues(alpha: 0.5), width: 2),
          ),
          child: Icon(
            avatarData['icon'] as IconData,
            size: 28,
            color: avatarData['color'] as Color,
          ),
        );
      }
    }

    return CircleAvatar(
      radius: 27,
      backgroundColor: const Color(0xFF311B92),
      child: Text(
        initialLetter,
        style: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String initialLetter = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'V';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MeshBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF311B92)))
              : Column(
                  children: [
                    // Top App Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFF1E293B),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LanguageService.tr('settings'),
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                LanguageService.tr('manage_preferences'),
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main Scrollable Body
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          // User Profile Summary Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF311B92).withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _buildProfileAvatarWidget(initialLetter),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userName,
                                        style: GoogleFonts.outfit(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _email,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          color: const Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        LanguageService.tr('active'),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section 1: Preferences
                          _buildSectionTitle(LanguageService.tr('app_preferences')),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF311B92).withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildSettingItem(
                                  icon: Icons.notifications_active_outlined,
                                  iconBgColor: const Color(0xFF311B92).withValues(alpha: 0.08),
                                  iconColor: const Color(0xFF311B92),
                                  title: LanguageService.tr('push_notifications'),
                                  subtitle: LanguageService.tr('loan_status_updates'),
                                  trailing: Switch.adaptive(
                                    value: _pushNotifications,
                                    activeTrackColor: const Color(0xFF311B92),
                                    onChanged: (val) => setState(() => _pushNotifications = val),
                                  ),
                                ),
                                const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
                                _buildSettingItem(
                                  icon: Icons.language_rounded,
                                  iconBgColor: const Color(0xFF10B981).withValues(alpha: 0.08),
                                  iconColor: const Color(0xFF10B981),
                                  title: LanguageService.tr('app_language'),
                                  subtitle: _selectedLanguage,
                                  onTap: _showLanguageSelectionDialog,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section 2: Support & Info
                          _buildSectionTitle(LanguageService.tr('support_legal')),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF311B92).withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                 _buildSettingItem(
                                   icon: Icons.help_outline_rounded,
                                   iconBgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                                   iconColor: const Color(0xFF8B5CF6),
                                   title: LanguageService.tr('help_center'),
                                   subtitle: LanguageService.tr('support_coming_soon'),
                                   trailing: Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                     decoration: BoxDecoration(
                                       color: const Color(0xFFF97316).withValues(alpha: 0.12),
                                       borderRadius: BorderRadius.circular(12),
                                       border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
                                     ),
                                     child: Text(
                                       LanguageService.tr('coming_soon'),
                                       style: GoogleFonts.outfit(
                                         fontSize: 11,
                                         fontWeight: FontWeight.bold,
                                         color: const Color(0xFFC2410C),
                                       ),
                                     ),
                                   ),
                                   onTap: () {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(
                                         content: Row(
                                           children: [
                                             const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                                             const SizedBox(width: 10),
                                             Expanded(
                                               child: Text(
                                                 LanguageService.tr('help_center_coming_soon'),
                                                 style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                               ),
                                             ),
                                           ],
                                         ),
                                         backgroundColor: const Color(0xFFF97316),
                                         behavior: SnackBarBehavior.floating,
                                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                       ),
                                     );
                                   },
                                 ),
                                const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
                                _buildSettingItem(
                                  icon: Icons.description_outlined,
                                  iconBgColor: const Color(0xFFEC4899).withValues(alpha: 0.08),
                                  iconColor: const Color(0xFFEC4899),
                                  title: LanguageService.tr('terms_policy'),
                                  subtitle: LanguageService.tr('legal_guidelines'),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LegalPage(initialTab: 0),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
                                _buildSettingItem(
                                  icon: Icons.info_outline_rounded,
                                  iconBgColor: const Color(0xFF64748B).withValues(alpha: 0.08),
                                  iconColor: const Color(0xFF64748B),
                                  title: 'VidhyaLoan App',
                                  subtitle: 'Version 1.0.4 (Latest Release)',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section 3: Account Actions (Logout & Delete)
                          _buildSectionTitle('ACCOUNT ACTIONS'),
                          const SizedBox(height: 8),

                          // Logout Button Card
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleLogout,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF311B92).withValues(alpha: 0.15)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF311B92).withValues(alpha: 0.04),
                                      blurRadius: 14,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF311B92).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.logout_rounded,
                                        color: Color(0xFF311B92),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Logout',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF311B92),
                                            ),
                                          ),
                                          Text(
                                            'Sign out of your account safely',
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              color: const Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFF311B92),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Delete Account Button Card
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleDeleteAccount,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.6)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.04),
                                      blurRadius: 14,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.delete_forever_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Delete Account',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFDC2626),
                                            ),
                                          ),
                                          Text(
                                            'Permanently remove profile & loan data',
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              color: const Color(0xFF991B1B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF64748B),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          color: const Color(0xFF64748B),
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 15)
              : null),
    );
  }
}
