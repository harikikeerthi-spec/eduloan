import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/institute_selection_modal.dart';
import '../widgets/mesh_background.dart';
import '../services/loan_service.dart';
import '../models/loan.dart';
import '../services/ai_logic_service.dart';
import '../services/notification_service.dart';
import 'ai_tools/university_detail_page.dart';
import '../services/blog_service.dart';
import '../models/blog.dart';
import 'blog_detail_page.dart';

import 'essential_service_page.dart';
import '../services/direct_chat_service.dart';
import 'main_navigation.dart';
import '../widgets/avatar_selection_dialog.dart';
import '../services/language_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  HomeTabState createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  final LoanService _loanService = LoanService();
  List<Loan> _activeLoans = [];
  bool _hasAppliedForLoan = false;
  String? _userProfileImage;
  List<UniversityRecommendation> _aiRecommendations = [];
  List<UniversityRecommendation> _savedRecommendations = [];
  bool _hasSearchedUniversityShortlist = false;
  String _activeRecommendationTab = 'All'; // 'All' or 'Saved'
  final AiLogicService _aiService = AiLogicService();
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  int _directChatUnreadCount = 0;

  // Auto-scroll logic for recommendations
  final ScrollController _aiScrollController = ScrollController();
  Timer? _aiScrollTimer;

  // Caches for AI recommendation images to prevent FutureBuilder recreation on scroll
  final Map<String, String?> _logoCache = {};
  final Map<String, String?> _bgCache = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfileImage();
    _loadActiveLoans();
    _loadRecommendations();
    _loadNotificationCount();
    _loadDirectChatUnreadCount();
  }

  @override
  void dispose() {
    _aiScrollTimer?.cancel();
    _aiScrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (_aiRecommendations.length > 1) {
      _aiScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!_aiScrollController.hasClients) return;

        final double maxScroll = _aiScrollController.position.maxScrollExtent;
        final double currentScroll = _aiScrollController.position.pixels;
        // Approximate width of a card plus padding
        final double cardWidth = MediaQuery.of(context).size.width - 64 + 16;

        if (currentScroll >= maxScroll - 10) {
          // Jump back to start if at the end
          _aiScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        } else {
          // Scroll one card forward
          _aiScrollController.animateTo(
            currentScroll + cardWidth,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void refreshData() {
    setState(() {
      _bgCache.clear();
    });
    _loadUserProfileImage();
    _loadRecommendations();
    _loadSavedRecommendations();
    _loadActiveLoans();
    _loadNotificationCount();
    _loadDirectChatUnreadCount();
  }

  Future<void> _loadUserProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final img = prefs.getString('user_profileImage');
      if (mounted) {
        setState(() {
          _userProfileImage = img;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile image: $e');
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _unreadCount = notifications.where((n) => !n.isRead).length;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification count: $e');
    }
  }

  Future<void> _loadDirectChatUnreadCount() async {
    try {
      final count = await DirectChatService().getTotalUnreadCount();
      if (mounted) {
        setState(() {
          _directChatUnreadCount = count;
        });
      }
    } catch (e) {
      debugPrint('Error loading direct chat count: $e');
    }
  }

  Future<void> _loadSavedRecommendations() async {
    final saved = await _aiService.getSavedUniversities();
    if (mounted) {
      setState(() {
        _savedRecommendations = saved;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    _loadSavedRecommendations(); // Load saved in parallel
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasSearched = prefs.getBool('has_searched_university_shortlist') ?? false;
      final String? cachedRecs = prefs.getString('latest_ai_recommendations');
      final String? userId = prefs.getString('userId');

      // Top recommendations should show on dashboard ONLY if user has searched shortlisting page
      final bool userHasSearched = hasSearched || (cachedRecs != null && cachedRecs.isNotEmpty);

      if (mounted) {
        setState(() {
          _hasSearchedUniversityShortlist = userHasSearched;
        });
      }

      if (!userHasSearched) {
        return; // User has not searched university shortlisting page yet -> keep hidden
      }

      if (userId != null) {
        final backendRecs = await _aiService.getSavedAiRecommendations(userId);
        if (backendRecs.isNotEmpty) {
          if (mounted) {
            setState(() {
              _aiRecommendations = backendRecs;
            });
            _startAutoScroll();
          }
          return;
        }
      }

      if (cachedRecs != null && cachedRecs.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedRecs);
        if (mounted) {
          setState(() {
            _aiRecommendations = decoded
                .map(
                  (e) => UniversityRecommendation.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList();
          });

          if (_aiRecommendations.isNotEmpty) {
            _startAutoScroll();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load AI recommendations: $e');
    }
  }

  Future<void> _loadActiveLoans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      if (userId.isNotEmpty) {
        final loans = await _loanService.getUserLoans();
        setState(() {
          _hasAppliedForLoan = loans.isNotEmpty;
          _activeLoans = loans
              .where(
                (loan) =>
                    loan.status != 'rejected' && loan.status != 'completed',
              )
              .toList();
        });
      } else {
        setState(() {});
      }
    } catch (e) {
      setState(() {});
    }
  }

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: () {
        MainNavigation.of(context)?.switchToTab(4);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFF311B92).withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF311B92).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Builder(
            builder: (context) {
              if (_userProfileImage != null && _userProfileImage!.isNotEmpty) {
                if (_userProfileImage!.startsWith('data:image/')) {
                  try {
                    final base64Str = _userProfileImage!.split(',').last;
                    final bytes = base64Decode(base64Str);
                    return Image.memory(
                      bytes,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    );
                  } catch (e) {
                    debugPrint('Error decoding profile avatar: $e');
                  }
                }

                final avatarData = AvatarSelectionDialog.avatars.firstWhere(
                  (a) => a['name'] == _userProfileImage,
                  orElse: () => <String, dynamic>{},
                );
                if (avatarData.isNotEmpty && avatarData['icon'] != null) {
                  return Container(
                    color: (avatarData['color'] as Color).withValues(alpha: 0.1),
                    child: Icon(
                      avatarData['icon'] as IconData,
                      size: 24,
                      color: avatarData['color'] as Color,
                    ),
                  );
                }
              }

              return Container(
                color: const Color(0xFF311B92).withValues(alpha: 0.08),
                child: const Icon(
                  Icons.person_rounded,
                  size: 24,
                  color: Color(0xFF311B92),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  // Removed glass gradient decoration
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildProfileAvatar(),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/direct-chats').then((_) {
                                    _loadDirectChatUnreadCount();
                                  });
                                },
                                icon: _directChatUnreadCount > 0
                                    ? Badge(
                                        label: Text('$_directChatUnreadCount'),
                                        backgroundColor: const Color(0xFF311B92),
                                        child: const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          color: Colors.black54,
                                          size: 25,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        color: Colors.black54,
                                        size: 25,
                                      ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/notifications').then((_) {
                                    _loadNotificationCount();
                                  });
                                },
                                icon: _unreadCount > 0
                                    ? Badge(
                                        label: Text('$_unreadCount'),
                                        child: const Icon(
                                          Icons.notifications_outlined,
                                          color: Colors.black54,
                                          size: 28,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.black54,
                                        size: 28,
                                      ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        LanguageService.tr('welcome_to'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'VidyaLoans',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Solid black
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Stats Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF311B92,
                              ).withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              LanguageService.tr('active_loans'),
                              '${_activeLoans.length}',
                              Icons.account_balance,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                            _buildStatItem(
                              LanguageService.tr('total_amount'),
                              '₹${_activeLoans.fold<double>(0, (sum, loan) => sum + loan.amount).toStringAsFixed(0)}',
                              Icons.currency_rupee,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),



                // Active Loans Section
                if (_activeLoans.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Loans',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._activeLoans.map((loan) => _buildLoanCard(loan)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                // ── Featured Blogs ──────────────────────────────────────
                _buildFeaturedBlogsSection(),
                const SizedBox(height: 20),

                // ── AI Recommendations (Only shown after user searches on University Shortlisting page) ──
                if (_hasSearchedUniversityShortlist && !_hasAppliedForLoan && (_aiRecommendations.isNotEmpty || _savedRecommendations.isNotEmpty)) ...[
                  _buildAiRecommendations(),
                  const SizedBox(height: 28),
                ],

                // Lending Partners
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSparkleIcon(isLeft: true),
                              const SizedBox(width: 8),
                              Text(
                                LanguageService.tr('lending_partners'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3436),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildSparkleIcon(isLeft: false),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Multiple lenders to choose from',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          _buildRectangularPartner(
                            'AUXILO',
                            assetPath: 'assets/images/auxilo_logo_final.png',
                          ),
                          const SizedBox(width: 14),
                          _buildRectangularPartner(
                            'AVANSE',
                            assetPath: 'assets/images/avanse_logo_final.png',
                          ),
                          const SizedBox(width: 14),
                          _buildRectangularPartner(
                            'Credila',
                            assetPath: 'assets/images/credila_logo_final.png',
                          ),
                          const SizedBox(width: 14),
                          _buildRectangularPartner(
                            'IDFC FIRST Bank',
                            assetPath: 'assets/images/idfc_logo.png',
                          ),
                          const SizedBox(width: 14),
                          _buildRectangularPartner(
                            'Poonawalla Fincorp',
                            assetPath:
                                'assets/images/poonawalla_logo_final.jpg',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),

                // Essential Services (Value Add)
                _buildValueAddServices(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSparkleIcon({required bool isLeft}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: isLeft ? -0.5 : 0.5,
          child: Icon(
            Icons.auto_awesome,
            size: 20,
            color: isLeft ? const Color(0xFF311B92) : const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildRectangularPartner(String name, {String? assetPath}) {
    return Container(
      width: 160, // Increased width
      height: 90, // Increased height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Reduced padding
          child: assetPath != null
              ? Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPartnerFallback(name, Colors.grey),
                )
              : _buildPartnerFallback(name, Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPartnerFallback(String name, Color accentColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.account_balance,
          size: 20,
          color: accentColor.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF311B92), size: 22), // Darker icon
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Solid black
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.black.withValues(alpha: 0.6), // Darker for clarity
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildActionCard({
    required String imagePath,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF311B92).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Image.asset(imagePath, width: 60, height: 60, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.black.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(Loan loan) {
    Color statusColor;
    switch (loan.status.toLowerCase()) {
      case 'approved':
        statusColor = const Color(0xFF10B981);
        break;
      case 'processing':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusColor = const Color(0xFF6B7280);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF311B92).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Color(0xFF311B92),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.universityName ?? 'Educational Loan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loan.courseName ?? 'General Course',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  loan.statusDisplay,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${loan.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF311B92),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    '${loan.progress}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF311B92),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: loan.progress / 100,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF311B92),
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _showResourcesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const InstituteSelectionModal(),
    );
  }

  // ── Featured Blogs Section ───────────────────────────────────────────────

  Widget _buildFeaturedBlogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Blogs & Insights',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/blogs'),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Color(0xFF311B92),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Banner card that leads to blogs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/blogs'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF311B92), Color(0xFF6605C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF311B92).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'LATEST INSIGHTS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Education Loan Tips, Study Abroad Guides & More',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text(
                              'Read Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.article_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Scrollable mini blog cards
        FutureBuilder<List<Blog>>(
          future: BlogService().getFeaturedBlogs(limit: 5),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            final blogs = snapshot.data!;
            return SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: blogs.length,
                itemBuilder: (context, index) {
                  final blog = blogs[index];
                  return _buildMiniBlogCard(blog);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniBlogCard(Blog blog) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BlogDetailPage(blog: blog)),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF311B92).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF311B92).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                blog.category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF311B92),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              blog.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.3,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor:
                      const Color(0xFF311B92).withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person,
                    size: 12,
                    color: Color(0xFF311B92),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    blog.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Text(
                  '${blog.readTime}m',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiRecommendations() {
    if (_hasAppliedForLoan) {
      return const SizedBox.shrink();
    }

    final bool isSavedMode = _activeRecommendationTab == 'Saved';
    final recommendations = isSavedMode
        ? _savedRecommendations
        : _aiRecommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Recommendations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  _buildFilterChip('All', !isSavedMode),
                  const SizedBox(width: 8),
                  _buildFilterChip('Saved', isSavedMode),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isSavedMode && recommendations.isEmpty)
          _buildEmptySavedState()
        else
          SizedBox(
            height: 260,
            child: ListView.builder(
              controller: _aiScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final uni = recommendations[index];
                return _buildAiRecommendationCard(uni, context);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeRecommendationTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6200EA) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6200EA)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySavedState() {
    return Container(
      width: double.infinity,
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_outline, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Nothing saved yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Save universities to see them here',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }



  Widget _buildAiRecommendationCard(
    UniversityRecommendation uni,
    BuildContext context,
  ) {
    // 24 padding on both sides, and 16 spacing = 64 total horizontal offset
    double cardWidth = MediaQuery.of(context).size.width - 64;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UniversityDetailPage(university: uni),
              ),
            );
          },
          child: Stack(
            children: [
              // Background Image Fetcher
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child:
                      _bgCache.containsKey(uni.name) &&
                          _bgCache[uni.name] != null
                      ? Image.network(
                          _bgCache[uni.name]!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultBg(uni.name),
                        )
                      : _buildDefaultBg(uni.name), // Loading or fallback
                ),
              ),

              // Super smooth gradient overlay (Dark bottom, transparent top)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.2),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Card Content Overlay
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // University Logo Space
                        Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: _buildLogoIcon(uni),
                        ),
                        const SizedBox(width: 16),
                        // Top Right Pill
                        Expanded(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                uni.programName.isNotEmpty
                                    ? uni.programName
                                    : uni.type,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // University Details (Bottom)
                    Text(
                      uni.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black54,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            uni.location,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                    const SizedBox(height: 16),

                    // Admit Chance Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admit Chance',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              uni.chance,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(
                                  0xFF34D399,
                                ), // Bright emerald green for dark bg
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  Widget _buildValueAddServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Essential Services',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildServiceCard(
                title: 'US Credit Card',
                subtitle:
                    'Build your US credit score from day one with a student credit card',
                primaryIcon: Icons.credit_card,
                bgColor: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF6366F1),
                topTrailing: const Icon(
                  Icons.credit_score,
                  size: 36,
                  color: Color(0xFFC7D2FE),
                ),
                width: 220,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EssentialServicePage(
                        serviceTitle: 'US Credit Card',
                        serviceSubtitle:
                            'Build your US credit score from day one with a student credit card. Enjoy zero foreign transaction fees and exclusive student rewards.',
                        primaryIcon: Icons.credit_card_rounded,
                        themeColor: Color(0xFF6366F1),
                        serviceKey: 'essential_us_credit',
                        features: [
                          {
                            'title': 'No SSN Required Initially',
                            'desc': 'Apply before landing in the US with zero prior credit history required.',
                          },
                          {
                            'title': 'Build Credit Score Early',
                            'desc': 'Start building your US FICO score from your first campus semester.',
                          },
                          {
                            'title': '0% Foreign Transaction Fees',
                            'desc': 'Enjoy student cashback on textbooks, groceries, and dining.',
                          },
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildServiceCard(
                title: 'German BA',
                subtitle:
                    'Open your mandatory blocked account hassle-free for Germany',
                primaryIcon: Icons.account_balance_wallet,
                bgColor: const Color(0xFFFFFBEB),
                iconColor: const Color(0xFFD97706),
                topTrailing: const Icon(
                  Icons.euro,
                  size: 36,
                  color: Color(0xFFFDE68A),
                ),
                width: 220,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EssentialServicePage(
                        serviceTitle: 'German Blocked Account (BA)',
                        serviceSubtitle:
                            'Open your official embassy-approved Sperrkonto blocked account for your German student visa application.',
                        primaryIcon: Icons.account_balance_wallet_rounded,
                        themeColor: Color(0xFFD97706),
                        serviceKey: 'essential_german_ba',
                        features: [
                          {
                            'title': 'Embassy Approved Sperrkonto',
                            'desc': '100% recognized by German Foreign Office & Ausländerbehörde.',
                          },
                          {
                            'title': '24-Hour Digital Certificate',
                            'desc': 'Receive your official blocked account confirmation certificate fast.',
                          },
                          {
                            'title': 'Health Insurance Combo',
                            'desc': 'Free TK / DAK German public health insurance package integration.',
                          },
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildServiceCard(
                title: 'Forex Card',
                subtitle:
                    'Multi-currency forex card with the best exchange rates',
                primaryIcon: Icons.currency_exchange,
                bgColor: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF10B981),
                topTrailing: const Icon(
                  Icons.public,
                  size: 36,
                  color: Color(0xFFA7F3D0),
                ),
                width: 220,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EssentialServicePage(
                        serviceTitle: 'Student Forex Card',
                        serviceSubtitle:
                            'Multi-currency travel card with zero markup exchange rates and free ATM withdrawals worldwide.',
                        primaryIcon: Icons.currency_exchange_rounded,
                        themeColor: Color(0xFF10B981),
                        serviceKey: 'essential_forex',
                        features: [
                          {
                            'title': 'Zero Forex Markup Rates',
                            'desc': 'Lock in live interbank exchange rates with zero hidden markups.',
                          },
                          {
                            'title': 'Multi-Currency Smart Chip',
                            'desc': 'Hold USD, GBP, EUR, CAD, AUD on a single contactless card.',
                          },
                          {
                            'title': 'Emergency Cash Replacement',
                            'desc': 'Free global replacement & 24/7 emergency card block assistance.',
                          },
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildServiceCard(
                title: 'UK Bank Account',
                subtitle:
                    'Pre-arrival UK bank account opening for Indian students',
                primaryIcon: Icons.account_balance,
                bgColor: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF8B5CF6),
                topTrailing: const Icon(
                  Icons.currency_pound,
                  size: 36,
                  color: Color(0xFFDDD6FE),
                ),
                width: 220,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EssentialServicePage(
                        serviceTitle: 'UK Bank Account',
                        serviceSubtitle:
                            'Get your UK Sort Code & Account Number before leaving India for seamless tuition & rent payments.',
                        primaryIcon: Icons.account_balance_rounded,
                        themeColor: Color(0xFF8B5CF6),
                        serviceKey: 'essential_uk_bank',
                        features: [
                          {
                            'title': 'Pre-Arrival Account Opening',
                            'desc': 'Obtain your UK Sort Code & Account Number before flying out.',
                          },
                          {
                            'title': 'Contactless Debit Card',
                            'desc': 'Ready to tap on arrival for TfL London transit and campus shops.',
                          },
                          {
                            'title': 'Zero Monthly Maintenance Fees',
                            'desc': 'Enjoy fee-free student banking throughout your UK degree.',
                          },
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required IconData primaryIcon,
    required Color bgColor,
    required Color iconColor,
    required Widget topTrailing,
    required double width,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(primaryIcon, color: iconColor, size: 24),
                ),
                topTrailing,
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDefaultBg(String seed) {
    final List<String> defaultImages = [
      'https://images.unsplash.com/photo-1492538356227-3eb926ca0b51?q=80&w=2070&auto=format&fit=crop', // Ivy building
      'https://images.unsplash.com/photo-1562774053-701939374585?q=80&w=2086&auto=format&fit=crop', // Tech Building
      'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?q=80&w=2070&auto=format&fit=crop', // Building facade
      'https://images.unsplash.com/photo-1592280771190-3e2e4d571952?q=80&w=2070&auto=format&fit=crop', // Red brick university
      'https://images.unsplash.com/photo-1541829070764-84a7d30dee70?q=80&w=1974&auto=format&fit=crop', // Modern campus
      'https://images.unsplash.com/photo-1461354464878-ad92f492a5a0?q=80&w=2070&auto=format&fit=crop', // Library
      'https://images.unsplash.com/photo-1519074063912-cc2f0e5ece58?q=80&w=2070&auto=format&fit=crop', // Classic Hall
      'https://images.unsplash.com/photo-1622397333309-30b1a27bb21d?q=80&w=2070&auto=format&fit=crop', // Architecture
      'https://images.unsplash.com/photo-1525921472407-c59f2ea325f5?q=80&w=2070&auto=format&fit=crop', // Modern Library
      'https://images.unsplash.com/photo-1590402494587-44b71d7772f6?q=80&w=2070&auto=format&fit=crop', // Campus quad
    ];
    // Use hashCode for better distribution than length
    int idx = seed.hashCode.abs() % defaultImages.length;
    return Image.network(
      defaultImages[idx],
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Container(color: Colors.grey[800]),
    );
  }

  Widget _buildLogoIcon(UniversityRecommendation uni) {
    String logoUrl = '';
    if (_logoCache.containsKey(uni.name) && _logoCache[uni.name] != null) {
      logoUrl = _logoCache[uni.name]!;
    }

    if (logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            final domain = minExtractDomain(uni);
            if (domain.isNotEmpty) {
              return Image.network(
                "https://www.google.com/s2/favicons?sz=64&domain=$domain",
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    _buildMonogramFallback(uni),
              );
            }
            return _buildMonogramFallback(uni);
          },
        ),
      );
    }

    // Fallback if loading or no logo URL
    return _buildFallbackContent(uni);
  }

  String minExtractDomain(UniversityRecommendation uni) {
    if (uni.websiteUrl.isNotEmpty) {
      String domain = uni.websiteUrl.replaceAll(RegExp(r'^https?://'), '');
      return domain.split('/').first.split('?').first;
    }
    if (uni.logoUrl.isNotEmpty) {
      return uni.logoUrl.split('/').last.split('?').first;
    }
    return "";
  }

  Widget _buildFallbackContent(UniversityRecommendation uni) {
    if (!_logoCache.containsKey(uni.name)) {
      // Still loading
      return const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Loaded but no logo found, try favicon directly
    final domain = minExtractDomain(uni);
    if (domain.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          "https://www.google.com/s2/favicons?sz=64&domain=$domain",
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _buildMonogramFallback(uni),
        ),
      );
    }

    return _buildMonogramFallback(uni);
  }

  Widget _buildMonogramFallback(UniversityRecommendation uni) {
    String monogram = '';
    if (uni.name.isNotEmpty) {
      final parts = uni.name.split(' ');
      if (parts.length >= 2) {
        monogram = (parts[0][0] + parts[1][0]).toUpperCase();
      } else if (parts[0].isNotEmpty) {
        monogram = parts[0][0].toUpperCase();
      }
    }
    return Center(
      child: monogram.isNotEmpty
          ? Text(
              monogram,
              style: const TextStyle(
                color: Color(0xFF6200EA),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : const Icon(
              Icons.account_balance,
              color: Color(0xFF6200EA),
              size: 24,
            ),
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.22);
    path.lineTo(size.width * 0.9, size.height * 0.22);
    path.lineTo(size.width * 0.5, size.height * 0.88);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
