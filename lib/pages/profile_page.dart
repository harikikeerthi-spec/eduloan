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
import '../services/language_service.dart';
import 'document_details_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String _name = '';
  String _email = '';
  String _phone = '';
  String _dob = '';
  String _userId = '';
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
    _loadCachedData();
    _fetchProfile();
  }

  /// Instantly loads cached profile from SharedPreferences so data is shown
  /// immediately without waiting for the backend API call.
  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final firstName = prefs.getString('user_firstName') ?? '';
    final lastName = prefs.getString('user_lastName') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final phone = prefs.getString('user_phone') ?? '';
    String dob = prefs.getString('user_dob') ?? '';
    final userId = prefs.getString('userId') ?? '';
    final cached = _sanitizeProfileImage(prefs.getString('user_profileImage'));

    // Format DOB if stored in ISO format (YYYY-MM-DD)
    if (dob.contains('-') && !dob.contains('/')) {
      final parts = dob.split('T')[0].split('-');
      if (parts.length == 3 && parts[0].length == 4) {
        dob = '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }

    setState(() {
      _name = '$firstName $lastName'.trim();
      _email = email;
      _phone = phone;
      _dob = dob;
      _userId = userId;
      if (cached != null) _profileImage = cached;
      // Show data immediately from cache; keep _isLoading true until backend
      // responds so the full profile card animates in.
      if (_name.isNotEmpty || _email.isNotEmpty) _isLoading = false;
    });
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
            final user =
                nestedData['user'] ?? responseData['user'] ?? responseData;

            final String fname =
                (user['firstName']?.toString() ?? '').trim().isNotEmpty
                ? user['firstName'].toString().trim()
                : (prefs.getString('user_firstName') ?? '');
            final String lname =
                (user['lastName']?.toString() ?? '').trim().isNotEmpty
                ? user['lastName'].toString().trim()
                : (prefs.getString('user_lastName') ?? '');
            final String phone =
                (user['phoneNumber']?.toString() ?? '').trim().isNotEmpty
                ? user['phoneNumber'].toString().trim()
                : (prefs.getString('user_phone') ?? '');
            final String dob =
                (user['dateOfBirth']?.toString() ??
                        user['dob']?.toString() ??
                        '')
                    .trim()
                    .isNotEmpty
                ? (user['dateOfBirth']?.toString() ??
                          user['dob']?.toString() ??
                          '')
                      .trim()
                : (prefs.getString('user_dob') ?? '');

            if (fname.isNotEmpty) prefs.setString('user_firstName', fname);
            if (lname.isNotEmpty) prefs.setString('user_lastName', lname);
            if (phone.isNotEmpty) prefs.setString('user_phone', phone);
            if (dob.isNotEmpty) prefs.setString('user_dob', dob);
            if (user['profileImage'] != null) {
              prefs.setString('user_profileImage', user['profileImage']);
            }

            setState(() {
              _name = '$fname $lname'.trim();
              if (_name.isEmpty) _name = 'Student User';

              _email = user['email'] ?? email;
              _phone = phone.isNotEmpty ? phone : 'Not set';
              _dob = dob.isNotEmpty ? dob : 'Not set';
              _userId = user['id']?.toString() ?? cachedUserId;

              if (_dob.contains('-') && !_dob.contains('/')) {
                final parts = _dob.split('T')[0].split('-');
                if (parts.length == 3 && parts[0].length == 4) {
                  _dob = '${parts[2]}/${parts[1]}/${parts[0]}';
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

    if (result == 'REMOVE_PHOTO') {
      await _deleteProfilePhoto();
      return;
    }

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

  void _viewProfilePhoto() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                  maxHeight: 520,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                      blurRadius: 35,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_circle_rounded,
                              color: Color(0xFF7C4DFF),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Profile Photo',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.8,
                            maxScale: 4.0,
                            child: Center(child: _buildEnlargedProfilePhoto()),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Close'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (_profileImage != null &&
                            _profileImage!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _deleteProfilePhoto();
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              label: const Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _changeAvatar();
                            },
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('Change'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C4DFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnlargedProfilePhoto() {
    if (_profileImage != null && _profileImage!.startsWith('data:image/')) {
      try {
        final base64Str = _profileImage!.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
      }
    }

    final avatarData = AvatarSelectionDialog.avatars.firstWhere(
      (a) => a['name'] == _profileImage,
      orElse: () => AvatarSelectionDialog.avatars[0],
    );

    return Container(
      padding: const EdgeInsets.all(40),
      color: (avatarData['color'] as Color).withValues(alpha: 0.15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(avatarData['icon'], size: 140, color: avatarData['color']),
          const SizedBox(height: 16),
          Text(
            avatarData['label'] ?? 'Avatar',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfilePhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Profile Photo',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.visibility_rounded,
                    color: Color(0xFF7C4DFF),
                  ),
                ),
                title: Text(
                  'View Profile Photo',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'View full size photo with zoom',
                  style: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _viewProfilePhoto();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: Color(0xFF00E676),
                  ),
                ),
                title: Text(
                  'Change Profile Photo',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Upload a new picture or choose avatar',
                  style: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeAvatar();
                },
              ),
              if (_profileImage != null && _profileImage!.isNotEmpty) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                  title: Text(
                    'Delete Profile Photo',
                    style: GoogleFonts.outfit(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Remove profile photo and reset to default',
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteProfilePhoto();
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteProfilePhoto() async {
    if (_profileImage == null || _profileImage!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No profile photo to delete.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Delete Photo',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove your profile photo?',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profileImage');

      await AuthService.updateUserDetails(
        _email,
        _name.split(' ')[0],
        _name.contains(' ') ? _name.split(' ').sublist(1).join(' ') : '',
        _phone,
        _dob,
        profileImage: '',
      );

      if (mounted) {
        setState(() {
          _profileImage = null;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile photo deleted successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete photo: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
            child: CircularProgressIndicator(color: Color(0xFF311B92)),
          ),
        ),
      );
    }

    final isEditEnabled =
        !(_email == 'Loading...' ||
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
                              color: const Color(
                                0xFF311B92,
                              ).withValues(alpha: 0.1),
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
                        Color(0xFF0F172A),
                        Color(0xFF1E1B4B),
                        Color(0xFF311B92),
                        Color(0xFF4C1D95),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF311B92).withValues(alpha: 0.4),
                        blurRadius: 28,
                        spreadRadius: -4,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        // Decorative glowing ambient shapes
                        Positioned(
                          right: -40,
                          top: -40,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(
                                    0xFF7C4DFF,
                                  ).withValues(alpha: 0.35),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -50,
                          bottom: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(
                                    0xFF00E676,
                                  ).withValues(alpha: 0.2),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 24,
                          ),
                          child: Column(
                            children: [
                              // Top ID bar inside card
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.badge_outlined,
                                          color: Color(0xFFB39DDB),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'STUDENT PASS',
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFD1C4E9),
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF00E676,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF00E676,
                                        ).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF00E676),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'ACTIVE',
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF00E676),
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // Avatar with glowing neon rings
                              GestureDetector(
                                onTap: _showProfilePhotoOptions,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF7C4DFF),
                                            Color(0xFF00E676),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF7C4DFF,
                                            ).withValues(alpha: 0.45),
                                            blurRadius: 22,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3.5),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF0F172A),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              48,
                                            ),
                                            child: Builder(
                                              builder: (context) {
                                                if (_profileImage != null) {
                                                  if (_profileImage!.startsWith(
                                                    'data:image/',
                                                  )) {
                                                    try {
                                                      final base64Str =
                                                          _profileImage!
                                                              .split(',')
                                                              .last;
                                                      final bytes =
                                                          base64Decode(
                                                            base64Str,
                                                          );
                                                      return Image.memory(
                                                        bytes,
                                                        width: 96,
                                                        height: 96,
                                                        fit: BoxFit.cover,
                                                      );
                                                    } catch (e) {
                                                      debugPrint(
                                                        'Error decoding base64 image: $e',
                                                      );
                                                    }
                                                  }

                                                  final avatarData =
                                                      AvatarSelectionDialog
                                                          .avatars
                                                          .firstWhere(
                                                            (a) =>
                                                                a['name'] ==
                                                                _profileImage,
                                                            orElse: () =>
                                                                AvatarSelectionDialog
                                                                    .avatars[0],
                                                          );
                                                  return Center(
                                                    child: Icon(
                                                      avatarData['icon'],
                                                      size: 48,
                                                      color:
                                                          avatarData['color'],
                                                    ),
                                                  );
                                                }

                                                return const Center(
                                                  child: Icon(
                                                    Icons.person_rounded,
                                                    size: 50,
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
                                        onTap: _showProfilePhotoOptions,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF7C4DFF),
                                                Color(0xFF651FFF),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.35,
                                                ),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              // View Photo Action Button
                              InkWell(
                                onTap: _viewProfilePhoto,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF7C4DFF,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF7C4DFF,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.visibility_rounded,
                                        size: 14,
                                        color: Color(0xFFB39DDB),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'View Photo',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFB39DDB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Name
                              Text(
                                _name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Email
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 13,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _email,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // Bottom Info Strip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.verified_user_rounded,
                                          color: Color(0xFF00E676),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Verified Account',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 1,
                                      height: 16,
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: isEditEnabled
                                          ? () async {
                                              final updated =
                                                  await Navigator.push<bool>(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          UserDetailsPage(
                                                            email: _email,
                                                            isEdit: true,
                                                            currentName: _name,
                                                            currentPhone:
                                                                _phone,
                                                            currentDob: _dob,
                                                          ),
                                                    ),
                                                  );
                                              if (updated == true) {
                                                _fetchProfile();
                                              }
                                            }
                                          : null,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.edit_note_rounded,
                                            color: Color(0xFFB39DDB),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Edit Details',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFD1C4E9),
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ─── PERSONAL INFORMATION CARD ──────────────────────────────
                _buildSectionHeader(
                  'PERSONAL DETAILS',
                  Icons.person_pin_rounded,
                ),
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
                        icon: Icons.document_scanner_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'Document Details (AI OCR)',
                        subtitle:
                            'View extracted PAN, Aadhar, Passport & Marksheet numbers',
                        isEnabled: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DocumentDetailsPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
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
                                    _loadCachedData();
                                    _fetchProfile();
                                  }
                                });
                              },
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      _buildActionTile(
                        icon: Icons.card_giftcard_rounded,
                        iconColor: const Color(0xFFEC4899),
                        title: LanguageService.tr('refer_earn'),
                        subtitle: 'Share VidyaLoans & earn rewards',
                        badge: '🔒 Coming Soon',
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
                        title: LanguageService.tr('settings'),
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
                        title: LanguageService.tr('help_center'),
                        subtitle: 'FAQs, contact us & feedback',
                        isEnabled: true,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Help & Support coming soon!',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                ),
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
              icon: const Icon(
                Icons.copy_rounded,
                size: 18,
                color: Color(0xFF311B92),
              ),
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
    String? badge,
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
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1B4B),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF5821E,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF5821E),
                              ),
                            ),
                          ),
                        ],
                      ],
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
