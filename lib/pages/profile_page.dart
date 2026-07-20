import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/mesh_background.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
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
  /// Reject http/https URLs (Google/Firebase profile photos) so that
  /// no photo shows until the user manually picks one.
  String? _sanitizeProfileImage(dynamic raw) {
    if (raw == null) return null;
    final v = raw.toString().trim();
    if (v.isEmpty) return null;
    // Block any remote URL — these come from Google/Firebase, not from user
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

      debugPrint('DEBUG: ProfilePage fetching for email: $email');

        if (email != null && email.isNotEmpty) {
        final result = await AuthService.getUserDashboard(email);
        if (mounted) {
          if (result['success'] == true) {
            // Extract user from nested response: result['user'] -> data -> user
            final responseData = result['user'] ?? {};
            final nestedData = responseData['data'] ?? {};
            final user = nestedData['user'] ?? responseData['user'] ?? responseData;

            final fname = user['firstName'] ?? '';
            final lname = user['lastName'] ?? '';

            // Save to SharedPreferences so other pages stay in sync
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
              if (_name.isEmpty) _name = 'User';

              _email = user['email'] ?? email;
              _phone = user['phoneNumber'] ?? 'Not set';
              _dob = user['dateOfBirth'] ?? user['dob'] ?? 'Not set';
              _userId = user['id']?.toString() ?? cachedUserId;
              
              // Standardize DOB format to DD-MM-YYYY
              if (_dob.contains('-')) {
                final parts = _dob.split('T')[0].split('-');
                if (parts.length == 3) {
                  // If format is YYYY-MM-DD, convert to DD-MM-YYYY
                  if (parts[0].length == 4) {
                    _dob = '${parts[2]}-${parts[1]}-${parts[0]}';
                  } 
                  // If it's already DD-MM-YYYY, keep it as is
                }
              }
              _profileImage = _sanitizeProfileImage(
                user['profileImage'] ?? prefs.getString('user_profileImage'),
              );
              _isLoading = false;
            });
          } else {
            debugPrint('DEBUG: getUserDashboard failed: ${result['message']}');
            _handleError(result['message']);
          }
        }
      } else {
        debugPrint('DEBUG: user_email not found in SharedPreferences');
        _handleError('User email not found. Please log in.');
      }
    } catch (e) {
      debugPrint('DEBUG: Error in _fetchProfile: $e');
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
                backgroundColor: Colors.green,
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
              backgroundColor: Colors.red,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header with Profile Info
                Container(
                  padding: const EdgeInsets.all(24),
                  // Removed glass gradient decoration
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Builder(
                              builder: (context) {
                                if (_profileImage != null) {
                                  // Check if it's a custom photo (Base64 string)
                                  if (_profileImage!.startsWith('data:image/')) {
                                    try {
                                      final base64Str = _profileImage!.split(',').last;
                                      final bytes = base64Decode(base64Str);
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: Image.memory(
                                          bytes,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint('Error decoding base64 image: $e');
                                    }
                                  }

                                  // Standard predefined avatar
                                  final avatarData = AvatarSelectionDialog.avatars.firstWhere(
                                    (a) => a['name'] == _profileImage,
                                    orElse: () => AvatarSelectionDialog.avatars[0],
                                  );
                                  return Center(
                                    child: Icon(
                                      avatarData['icon'],
                                      size: 50,
                                      color: avatarData['color'],
                                    ),
                                  );
                                }

                                // Fallback icon
                                return const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xFF311B92),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _changeAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF311B92),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Profile Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildInfoCard(
                        icon: Icons.badge_outlined,
                        title: 'User ID',
                        value: _userId,
                        showCopyButton: true,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.phone_outlined,
                        title: 'Phone Number',
                        value: _phone,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        value: _email,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'Date of Birth',
                        value: _dob,
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildSettingItem(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profile',
                        onTap:
                            (_email == 'Loading...' ||
                                _email == 'Could not load profile' ||
                                _email.contains('Log Out') ||
                                !_email.contains('@') ||
                                _email.isEmpty)
                            ? null // Disable if email is invalid
                            : () {
                                // Navigate to Edit Profile (UserDetailsPage in edit mode)
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
                                    _fetchProfile(); // Refresh on return
                                  }
                                });
                              },
                      ),
                      const SizedBox(height: 12),

                      _buildSettingItem(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildSettingItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Help & Support coming soon!'),
                              backgroundColor: Color(0xFF311B92),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildSettingItem(
                        icon: Icons.stars_rounded,
                        title: 'Refer & Earn',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReferAndEarnPage(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    bool showCopyButton = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF311B92).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF311B92), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          if (showCopyButton)
            IconButton(
              icon: const Icon(Icons.copy_all_rounded, color: Color(0xFF311B92), size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User ID copied to clipboard!'),
                    backgroundColor: Color(0xFF311B92),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    // If onTap is null, assume disabled state
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF311B92).withValues(alpha: 0.08),
                blurRadius: 24,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF311B92), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
