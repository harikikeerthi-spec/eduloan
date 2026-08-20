import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/mesh_background.dart';
import '../widgets/avatar_selection_dialog.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
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
  bool _isLoading = false;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _email = prefs.getString('user_email') ?? '';
        final firstName = prefs.getString('user_firstName') ?? '';
        final lastName = prefs.getString('user_lastName') ?? '';
        _userName = '$firstName $lastName'.trim();
        if (_userName.isEmpty) _userName = 'User';
        _profileImage = prefs.getString('user_profileImage');
        _pushNotifications =
            prefs.getBool('push_notifications_enabled') ?? true;
      });
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
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF311B92),
                size: 20,
              ),
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
          'Are you sure you want to sign out of your Vidyaloans account on this device?',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF311B92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
            ),
            child: Text(
              'Yes, Logout',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
    // 1. Check if a document is currently uploading
    if (UserService.isUploading) {
      final docName = UserService.currentUploadingDoc ?? 'document';
      final waitAndProceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF311B92),
                      ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                elevation: 0,
              ),
              child: Text(
                'Wait & Delete',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              elevation: 0,
            ),
            child: Text(
              'Delete Permanently',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
        ScaffoldMessenger.of(context).clearSnackBars();
        if (result['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          await SecureStorageService.clearAll();
          try {
            await GoogleAuthService().signOut();
          } catch (e) {
            debugPrint('Error during Google/Firebase sign out: $e');
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Your account has been deleted successfully.',
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    'Failed to delete account. Please try again later.',
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildProfileAvatarWidget(String initialLetter) {
    if (_profileImage != null && _profileImage!.isNotEmpty) {
      if (_profileImage!.startsWith('data:image/')) {
        try {
          final base64Str = _profileImage!.split(',').last;
          final bytes = base64Decode(base64Str);
          return Container(
            width: 52,
            height: 52,
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
                width: 52,
                height: 52,
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (avatarData['color'] as Color).withValues(alpha: 0.15),
            border: Border.all(
              color: (avatarData['color'] as Color).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Icon(
            avatarData['icon'] as IconData,
            size: 26,
            color: avatarData['color'] as Color,
          ),
        );
      }
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFF311B92),
      child: Text(
        initialLetter,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String initialLetter = _userName.isNotEmpty
        ? _userName[0].toUpperCase()
        : 'V';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MeshBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF311B92)),
                )
              : Column(
                  children: [
                    // Top App Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                                    color: Colors.black.withValues(alpha: 0.05),
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
                                'Settings',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Manage preferences & account',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main Scrollable Content
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                        children: [
                          // User Profile Summary Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF311B92,
                                  ).withValues(alpha: 0.06),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: Color(0xFF10B981),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Active',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11.5,
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

                          const SizedBox(height: 16),

                          // Quick Status Badges
                          Row(
                            children: [
                              _buildStatChip(
                                Icons.notifications_active_rounded,
                                _pushNotifications ? 'Alerts On' : 'Alerts Off',
                                const Color(0xFF6C2BD9),
                              ),
                              const SizedBox(width: 10),
                              _buildStatChip(
                                Icons.shield_rounded,
                                'Protected',
                                const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 10),
                              _buildStatChip(
                                Icons.verified_user_rounded,
                                'v1.0.4',
                                const Color(0xFFF59E0B),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Section 1: Preferences
                          _buildSectionHeader(
                            'PREFERENCES',
                            const Color(0xFF6C2BD9),
                          ),
                          const SizedBox(height: 10),
                          _buildCard([
                            _buildTile(
                              icon: Icons.notifications_active_rounded,
                              gradientColors: [
                                const Color(0xFF6C2BD9),
                                const Color(0xFF9B59B6),
                              ],
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
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool(
                                      'push_notifications_enabled',
                                      val,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 24),

                          // Section 2: Support & Legal
                          _buildSectionHeader(
                            'SUPPORT & LEGAL',
                            const Color(0xFF8B5CF6),
                          ),
                          const SizedBox(height: 10),
                          _buildCard([
                            _buildTile(
                              icon: Icons.help_rounded,
                              gradientColors: [
                                const Color(0xFF8B5CF6),
                                const Color(0xFFA78BFA),
                              ],
                              title: 'Connect with Support',
                              subtitle: 'FAQs, guides & loan assistance',
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFB923C),
                                      Color(0xFFF97316),
                                    ],
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
                                        const Icon(
                                          Icons.support_agent_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Help Center & live support is coming soon!',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFFF97316),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildTile(
                              icon: Icons.description_rounded,
                              gradientColors: [
                                const Color(0xFFEC4899),
                                const Color(0xFFDB2777),
                              ],
                              title: 'Terms & Privacy Policy',
                              subtitle: 'Privacy policy, terms & conditions',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const LegalPage(initialTab: 0),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildTile(
                              icon: Icons.info_rounded,
                              gradientColors: [
                                const Color(0xFF64748B),
                                const Color(0xFF475569),
                              ],
                              title: 'Vidyaloans App',
                              subtitle: 'Version 1.0.4 (Latest Release)',
                            ),
                          ]),

                          const SizedBox(height: 24),

                          // Section 3: Account Actions
                          _buildSectionHeader(
                            'ACCOUNT ACTIONS',
                            const Color(0xFFEF4444),
                          ),
                          const SizedBox(height: 10),

                          // Sign Out
                          GestureDetector(
                            onTap: _handleLogout,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFF6C2BD9,
                                  ).withValues(alpha: 0.15),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6C2BD9,
                                    ).withValues(alpha: 0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6C2BD9),
                                          Color(0xFF9B59B6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6C2BD9,
                                      ).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFF6C2BD9),
                                      size: 14,
                                    ),
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
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFF5F5),
                                    Color(0xFFFEE2E2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFCA5A5,
                                  ).withValues(alpha: 0.7),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withValues(alpha: 0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFDC2626),
                                          Color(0xFFEF4444),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.delete_forever_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            color: const Color(
                                              0xFFB91C1C,
                                            ).withValues(alpha: 0.75),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // App Footer
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Vidyaloans • Made with ❤️ in India',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'v1.0.4',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10.5,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
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
              color: color.withValues(alpha: 0.1),
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
                fontSize: 11,
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
          height: 16,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.3)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF475569),
            letterSpacing: 0.8,
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
            color: const Color(0xFF6C2BD9).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 68,
      endIndent: 16,
      color: Color(0xFFF1F5F9),
    );
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
                      color: gradientColors.first.withValues(alpha: 0.25),
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
                      ? const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFFCBD5E1),
                          size: 14,
                        )
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}
