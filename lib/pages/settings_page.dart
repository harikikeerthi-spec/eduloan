import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/avatar_selection_dialog.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/language_service.dart';
import '../services/user_service.dart';
import '../services/secure_storage_service.dart';
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
    setState(() {
      _email = prefs.getString('user_email') ?? '';
      final firstName = prefs.getString('user_firstName') ?? '';
      final lastName = prefs.getString('user_lastName') ?? '';
      _userName = '$firstName $lastName'.trim();
      if (_userName.isEmpty) _userName = 'User';
      _profileImage = prefs.getString('user_profileImage');
      _selectedLanguage = prefs.getString('app_language') ?? 'English (IN)';
      _pushNotifications = prefs.getBool('push_notifications_enabled') ?? true;
    });
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

      await prefs.remove('user_dob');
      await prefs.remove('user_name');
      await prefs.remove('onboarding_shown');
      await prefs.remove('has_registered');
      await prefs.remove('is_onboarded');
      await SecureStorageService.clearAll();
      try {
        await GoogleAuthService().signOut();
      } catch (e) {
        debugPrint('Error during Google/Firebase sign out: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    // â”€â”€â”€ 1. Check if a document is currently uploading â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (UserService.isUploading) {
      final docName = UserService.currentUploadingDoc ?? 'document';
      final waitAndProceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Upload in Progress',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please wait for a sec because your $docName is currently uploading.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Once the upload process completes, your account deletion will proceed safely.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF311B92)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Uploading $docName...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF311B92),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
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
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                elevation: 0,
              ),
              child: Text(
                'Wait & Delete',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (waitAndProceed != true) return;
    }

    if (!mounted) return;

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

      // If document is uploading, wait for it to finish gracefully before deleting
      if (UserService.isUploading) {
        await UserService.waitForCurrentUpload();
      }

      final result = await AuthService.deleteAccount(_email);

      if (mounted) {
        setState(() => _isLoading = false);
        // Clear any global upload snackbars
        ScaffoldMessenger.of(context).clearSnackBars();
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
      {'name': 'Telugu', 'native': 'à°¤à±†à°²à±à°—à±', 'code': 'te'},
      {'name': 'Tamil', 'native': 'à®¤à®®à®¿à®´à¯', 'code': 'ta'},
      {'name': 'Kannada', 'native': 'à²•à²¨à³à²¨à²¡', 'code': 'kn'},
      {'name': 'Malayalam', 'native': 'à´®à´²à´¯à´¾à´³à´‚', 'code': 'ml'},
      {'name': 'Hindi', 'native': 'à¤¹à¤¿à¤‚à¤¦à¥€', 'code': 'hi'},
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
      backgroundColor: const Color(0xFFF0F2FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C2BD9)))
          : CustomScrollView(
              slivers: [
                // â”€â”€ Gradient Hero Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: const Color(0xFF6C2BD9),
                  leading: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4A00C8), Color(0xFF8B3DFF), Color(0xFFAB5BFF)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -40,
                            right: -30,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -20,
                            left: -50,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.25),
                                        ),
                                        child: _buildProfileAvatarWidget(initialLetter),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _userName,
                                              style: GoogleFonts.outfit(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _email,
                                              style: GoogleFonts.inter(
                                                fontSize: 12.5,
                                                color: Colors.white.withValues(alpha: 0.8),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 13),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Active',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF34D399),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  title: Text(
                    'Settings',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // â”€â”€ Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats Row
                        Row(
                          children: [
                            _buildStatChip(Icons.tune_rounded, 'Preferences', const Color(0xFF6C2BD9)),
                            const SizedBox(width: 10),
                            _buildStatChip(Icons.shield_rounded, 'Secured', const Color(0xFF10B981)),
                            const SizedBox(width: 10),
                            _buildStatChip(Icons.language_rounded, _selectedLanguage.split(' ').first, const Color(0xFFF59E0B)),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Section: Preferences
                        _buildSectionHeader('âš™ï¸  App Preferences', const Color(0xFF6C2BD9)),
                        const SizedBox(height: 12),
                        _buildCard([
                          _buildTile(
                            icon: Icons.notifications_active_rounded,
                            gradientColors: [const Color(0xFF6C2BD9), const Color(0xFF9B59B6)],
                            title: 'Push Notifications',
                            subtitle: 'Loan status, updates & alerts',
                            trailing: Transform.scale(
                              scale: 0.88,
                              child: Switch.adaptive(
                                value: _pushNotifications,
                                activeThumbColor: Colors.white,
                                activeTrackColor: const Color(0xFF6C2BD9),
                                inactiveTrackColor: const Color(0xFFE2E8F0),
                                onChanged: (val) async {
                                  setState(() => _pushNotifications = val);
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setBool('push_notifications_enabled', val);
                                },
                              ),
                            ),
                          ),
                          _buildDivider(),
                          _buildTile(
                            icon: Icons.language_rounded,
                            gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
                            title: LanguageService.tr('app_language'),
                            subtitle: _selectedLanguage,
                            onTap: _showLanguageSelectionDialog,
                          ),
                        ]),

                        const SizedBox(height: 28),

                        // Section: Support & Legal
                        _buildSectionHeader('ðŸ›¡ï¸  Support & Legal', const Color(0xFF8B5CF6)),
                        const SizedBox(height: 12),
                        _buildCard([
                          _buildTile(
                            icon: Icons.help_rounded,
                            gradientColors: [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
                            title: LanguageService.tr('help_center'),
                            subtitle: 'FAQs, guides & loan support',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFB923C), Color(0xFFF97316)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Soon',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.construction_rounded, color: Colors.white, size: 18),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildTile(
                            icon: Icons.description_rounded,
                            gradientColors: [const Color(0xFFEC4899), const Color(0xFFDB2777)],
                            title: LanguageService.tr('terms_policy'),
                            subtitle: 'Privacy policy, terms & conditions',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LegalPage(initialTab: 0)),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildTile(
                            icon: Icons.info_rounded,
                            gradientColors: [const Color(0xFF64748B), const Color(0xFF475569)],
                            title: 'Vidyaloans App',
                            subtitle: 'Version 1.0.4 (Latest Release)',
                          ),
                        ]),

                        const SizedBox(height: 28),

                        // Section: Account Actions
                        _buildSectionHeader('ðŸ‘¤  Account Actions', const Color(0xFFEF4444)),
                        const SizedBox(height: 12),

                        // Sign Out
                        GestureDetector(
                          onTap: _handleLogout,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF6C2BD9).withValues(alpha: 0.15)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C2BD9).withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6C2BD9), Color(0xFF9B59B6)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sign Out',
                                        style: GoogleFonts.outfit(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                      Text(
                                        'Safely sign out from this device',
                                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C2BD9).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF6C2BD9), size: 14),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Delete Account
                        GestureDetector(
                          onTap: _handleDeleteAccount,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFF5F5), Color(0xFFFEE2E2)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.7)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Delete Account',
                                        style: GoogleFonts.outfit(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFDC2626),
                                        ),
                                      ),
                                      Text(
                                        'Permanently erase all data & profile',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFFB91C1C).withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFDC2626), size: 14),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Vidyaloans â€¢ Made with â¤ï¸ in India',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'v1.0.4',
                                style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFFCBD5E1)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF334155),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.3)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF334155),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C2BD9).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 68, endIndent: 16, color: Color(0xFFF1F5F9));
  }

  Widget _buildTile({
    required IconData icon,
    required List<Color> gradientColors,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  (onTap != null
                      ? const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 14)
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }


}
