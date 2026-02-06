import 'package:flutter/material.dart';
import '../widgets/mesh_background.dart';
import '../services/auth_service.dart';
import 'user_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      print('DEBUG: ProfilePage fetching for email: $email');

      if (email != null && email.isNotEmpty) {
        final result = await AuthService.getUserDashboard(email);
        if (mounted) {
          if (result['success'] == true) {
            // Handle potentially nested user object
            final data = result['user'];
            final user = data['user'] ?? data;

            setState(() {
              final fname = user['firstName'] ?? '';
              final lname = user['lastName'] ?? '';
              _name = '$fname $lname'.trim();
              if (_name.isEmpty) _name = 'User';

              _email = user['email'] ?? email;
              _phone = user['phoneNumber'] ?? 'Not set';
              // Check for dateOfBirth or dob
              _dob = user['dateOfBirth'] ?? user['dob'] ?? 'Not set';
              // If it's a full ISO string, might want to take just date part
              if (_dob.contains('T')) {
                _dob = _dob.split('T')[0];
              }
              _isLoading = false;
            });
          } else {
            print('DEBUG: getUserDashboard failed: ${result['message']}');
            _handleError(result['message']);
          }
        }
      } else {
        print('DEBUG: user_email not found in SharedPreferences');
        _handleError('User email not found. Please log in.');
      }
    } catch (e) {
      print('DEBUG: Error in _fetchProfile: $e');
      _handleError('Error: $e');
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF311B92).withValues(alpha: 0.12),
                        const Color(0xFF311B92).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFF311B92).withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF311B92),
                        ),
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
                        'Settings',
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
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        onTap: () {},
                      ),
                      const SizedBox(height: 12),

                      _buildSettingItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {},
                      ),
                      const SizedBox(height: 12),

                      _buildSettingItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {},
                      ),
                      const SizedBox(height: 24),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pushNamedAndRemoveUntil('/', (route) => false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
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
