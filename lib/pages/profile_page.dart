import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/mesh_background.dart';
import '../services/auth_service.dart';
import 'user_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/avatar_selection_dialog.dart';
import 'refer_and_earn_page.dart';
import 'package:flutter/services.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String _name = 'Loading...';
  String _email = 'Loading...';
  String _phone = 'Loading...';
  String _dob = 'Loading...';
  String _userId = 'Loading...';
  String? _profileImage;

  /// Only accept images explicitly set by the user.
  String? _sanitizeProfileImage(dynamic raw) {
    if (raw == null) return null;
    final v = raw.toString().trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http://') || v.startsWith('https://')) return null;
    return v;
  }

  @override
  void initState() {
    super.initState();
    _loadCachedProfileImage();
    _fetchProfile();
  }

  Future<void> _loadCachedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = _sanitizeProfileImage(prefs.getString('user_profileImage'));
    if (cached != null && mounted) {
      setState(() {
        _profileImage = cached;
      });
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      final cachedUserId = prefs.getString('userId') ?? 'Not set';

      if (email != null && email.isNotEmpty) {
        final result = await AuthService.getUserDashboard(email);
        if (mounted) {
          if (result['success'] == true) {
            final responseData = result['user'] ?? {};
            final nestedData = responseData['data'] ?? {};
            final user = nestedData['user'] ?? responseData['user'] ?? responseData;

            final fname = user['firstName'] ?? '';
            final lname = user['lastName'] ?? '';

            prefs.setString('user_firstName', fname);
            prefs.setString('user_lastName', lname);
            if (user['phoneNumber'] != null) {
              prefs.setString('user_phone', user['phoneNumber']);
            }
            if (user['dateOfBirth'] != null) {
              prefs.setString('user_dob', user['dateOfBirth']);
            } else if (user['dob'] != null) {
              prefs.setString('user_dob', user['dob']);
            }
            if (user['profileImage'] != null) {
              prefs.setString('user_profileImage', user['profileImage']);
            }

            setState(() {
              _name = '$fname $lname'.trim();
              if (_name.isEmpty) _name = 'Student User';

              _email = user['email'] ?? email;
              _phone = user['phoneNumber'] ?? 'Not set';
              _dob = user['dateOfBirth'] ?? user['dob'] ?? 'Not set';
              _userId = user['id']?.toString() ?? cachedUserId;

              if (_dob.contains('-')) {
                final parts = _dob.split('T')[0].split('-');
                if (parts.length == 3 && parts[0].length == 4) {
                  _dob = '${parts[2]}-${parts[1]}-${parts[0]}';
                }
              }
              _profileImage = _sanitizeProfileImage(
                user['profileImage'] ?? prefs.getString('user_profileImage'),
              );
              _isLoading = false;
            });
          } else {
            _handleError(result['message']);
          }
        }
      } else {
        _handleError('User email not found. Please log in.');
      }
    } catch (e) {
      _handleError('Error: $e');
    }
  }

  Future<void> _changeAvatar() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarSelectionDialog(currentAvatar: _profileImage),
    );

    if (result != null && mounted) {
      setState(() => _isLoading = true);
      final updateResult = await AuthService.updateUserDetails(
        _email,
        _name.split(' ')[0],
        _name.contains(' ') ? _name.split(' ').sublist(1).join(' ') : '',
        _phone,
        _dob,
        profileImage: result,
      );

      if (mounted) {
        if (updateResult['success'] == true) {
          await _fetchProfile();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Avatar updated successfully!'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          }
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                updateResult['message'] ?? 'Failed to update avatar',
              ),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  void _handleError([String? message]) {
    if (mounted) {
      setState(() {
        _name = 'Session Expired';
        _email = message ?? 'Please Log Out & Log In again';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: MeshBackground(
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF311B92),
            ),
          ),
        ),
      );
    }

    final isEditEnabled = !(_email == 'Loading...' ||
        _email == 'Could not load profile' ||
        _email.contains('Log Out') ||
        !_email.contains('@') ||
        _email.isEmpty);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── App Bar Title ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1B4B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF311B92).withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: Color(0xFF311B92),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ─── HERO HEADER CARD ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1A0A5E),
                        Color(0xFF311B92),
                        Color(0xFF4527A0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF311B92).withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative background glow
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -40,
                        bottom: -40,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Avatar + Edit badge
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFB39DDB), Color(0xFF7C4DFF)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.5),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF1A0A5E),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(45),
                                        child: Builder(
                                          builder: (context) {
                                            if (_profileImage != null) {
                                              if (_profileImage!.startsWith('data:image/')) {
                                                try {
                                                  final base64Str = _profileImage!.split(',').last;
                                                  final bytes = base64Decode(base64Str);
                                                  return Image.memory(
                                                    bytes,
                                                    width: 90,
                                                    height: 90,
                                                    fit: BoxFit.cover,
                                                  );
                                                } catch (e) {
                                                  debugPrint('Error decoding base64 image: $e');
                                                }
                                              }

                                              final avatarData = AvatarSelectionDialog.avatars.firstWhere(
                                                (a) => a['name'] == _profileImage,
                                                orElse: () => AvatarSelectionDialog.avatars[0],
                                              );
                                              return Center(
                                                child: Icon(
                                                  avatarData['icon'],
                                                  size: 46,
                                                  color: avatarData['color'],
                                                ),
                                              );
                                            }

                                            return const Center(
                                              child: Icon(
                                                Icons.person_rounded,
                                                size: 48,
                                                color: Color(0xFFB39DDB),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _changeAvatar,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C4DFF),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Name
                            Text(
                              _name,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Email
                            Text(
                              _email,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Badge Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Color(0xFF00E676),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Verified Student Account',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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

                const SizedBox(height: 24),

                // ─── PERSONAL INFORMATION CARD ──────────────────────────────
                _buildSectionHeader('PERSONAL DETAILS', Icons.person_pin_rounded),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF311B92).withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoTile(
                        icon: Icons.badge_outlined,
                        iconColor: const Color(0xFF311B92),
                        label: 'User ID',
                        value: _userId,
                        showCopy: true,
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      _buildInfoTile(
                        icon: Icons.phone_android_rounded,
                        iconColor: const Color(0xFF10B981),
                        label: 'Phone Number',
                        value: _phone,
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      _buildInfoTile(
                        icon: Icons.alternate_email_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        label: 'Email Address',
                        value: _email,
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      _buildInfoTile(
                        icon: Icons.cake_outlined,
                        iconColor: const Color(0xFFF59E0B),
                        label: 'Date of Birth',
                        value: _dob,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── QUICK ACTIONS CARD ──────────────────────────────────────
                _buildSectionHeader('QUICK ACTIONS', Icons.bolt_rounded),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF311B92).withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildActionTile(
                        icon: Icons.edit_note_rounded,
                        iconColor: const Color(0xFF311B92),
                        title: 'Edit Profile Details',
                        subtitle: 'Update name, phone number, DOB',
                        isEnabled: isEditEnabled,
                        onTap: !isEditEnabled
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserDetailsPage(
                                      email: _email,
                                      isEdit: true,
                                      currentName: _name,
                                      currentPhone: _phone,
                                      currentDob: _dob,
                                    ),
                                  ),
                                ).then((val) {
                                  if (val == true) {
                                    _fetchProfile();
                                  }
                                });
                              },
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildActionTile(
                        icon: Icons.card_giftcard_rounded,
                        iconColor: const Color(0xFFEC4899),
                        title: 'Refer & Earn',
                        subtitle: 'Share VidyaLoans & earn rewards',
                        isEnabled: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReferAndEarnPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildActionTile(
                        icon: Icons.settings_outlined,
                        iconColor: const Color(0xFF6366F1),
                        title: 'App Settings',
                        subtitle: 'Notifications, account & security',
                        isEnabled: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildActionTile(
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF14B8A6),
                        title: 'Help & Support',
                        subtitle: 'FAQs, contact us & feedback',
                        isEnabled: true,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Help & Support coming soon!',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                              ),
                              backgroundColor: const Color(0xFF311B92),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF311B92)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF64748B),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool showCopy = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF1E1B4B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (showCopy)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF311B92)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'User ID copied to clipboard!',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: const Color(0xFF311B92),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
