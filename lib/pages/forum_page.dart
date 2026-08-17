import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../services/notification_service.dart';
import '../services/ai_logic_service.dart';
import '../widgets/mesh_background.dart';
import 'direct_chat_detail_page.dart';
import '../services/language_service.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final CommunityService _communityService = CommunityService();
  List<ForumPost> _posts = [];
  bool _isLoading = true;
  String? _error;
  Timer? _groupsPollingTimer;

  @override
  void initState() {
    super.initState();
    _groupsPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadSmartGroups();
    });
  }

  @override
  void dispose() {
    _groupsPollingTimer?.cancel();
    super.dispose();
  }

  int _selectedMainTab = 1; // Default to 1 (Smart Group Chat) as requested!
  int _smartSubTab = 0; // 0 = General Chat, 1 = Q&A, 2 = Polls, 3 = Announcements

  String _selectedCategory = 'General';
  String? _customTitle;
  int _membersCount = 0;
  int _discussionsCount = 0;
  String _selectedSort = 'newest';
  String? _hubDescription;
  bool _hasInitialLoaded = false;
  List<Map<String, dynamic>> _allHubs = [];
  bool _isLoadingHubs = true;

  // ─── Interactive Poll Data State ───────────────────────────────────────────
  // Polls expire 1 week after creation. Seed polls are pre-expired so the
  // empty state is shown until users create real polls.
  final List<Map<String, dynamic>> _polls = [
    {
      'id': 'poll_1',
      'question': 'Which country are you targeting for Fall 2026 / Spring 2027?',
      'author': 'VidyaLoan Community',
      'totalVotes': 348,
      'userVotedIndex': 0,
      // Backdated >7 days so this seed poll shows as expired
      'createdAt': DateTime.now().subtract(const Duration(days: 10)),
      'options': [
        {'text': '🇺🇸 USA', 'votes': 215},
        {'text': '🇬🇧 UK & Ireland', 'votes': 62},
        {'text': '🇩🇪 Germany & Europe', 'votes': 45},
        {'text': '🇨🇦 Canada & Australia', 'votes': 26},
      ],
    },
    {
      'id': 'poll_2',
      'question': 'What is your biggest blocker in the loan application process?',
      'author': 'Finance Advisory',
      'totalVotes': 210,
      'userVotedIndex': -1,
      'createdAt': DateTime.now().subtract(const Duration(days: 9)),
      'options': [
        {'text': '📄 Co-applicant income proof', 'votes': 98},
        {'text': '⏳ Bank sanction speed', 'votes': 64},
        {'text': '🏡 Collateral valuation', 'votes': 32},
        {'text': '🔣 Interest rate comparison', 'votes': 16},
      ],
    },
    {
      'id': 'poll_3',
      'question': 'Which AI tool helps you the most in your prep?',
      'author': 'AI Student Lounge',
      'totalVotes': 175,
      'userVotedIndex': 1,
      'createdAt': DateTime.now().subtract(const Duration(days: 8)),
      'options': [
        {'text': '📝 SOP Writer Tool', 'votes': 65},
        {'text': '🎯 Admit Predictor Tool', 'votes': 78},
        {'text': '📊 Grade Converter Tool', 'votes': 20},
        {'text': '💬 Customer Care AI Bot', 'votes': 12},
      ],
    },
  ];

  /// Returns polls that were created within the last 7 days (not expired).
  List<Map<String, dynamic>> get _activePolls {
    final now = DateTime.now();
    return _polls.where((p) {
      final createdAt = p['createdAt'];
      if (createdAt == null) return true; // no date → keep it
      return now.difference(createdAt as DateTime).inDays < 7;
    }).toList();
  }

  // ─── Announcements Data ────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _announcements = [
    {
      'id': 'ann_1',
      'title': '🚨 F-1 Visa Appointment Slots Released for Fall 2026!',
      'tag': 'VISA ALERT',
      'color': const Color(0xFFEF4444),
      'date': '24 July 2026',
      'content': 'US Embassies across New Delhi, Mumbai, and Hyderabad have opened bulk interview slots for June-August 2026. Book immediately on the official portal!',
      'action': 'Check Visa Simulator',
      'route': '/ai/visa-simulator',
    },
    {
      'id': 'ann_2',
      'title': '🎉 Special Interest Rate Drop on Unsecured Education Loans!',
      'tag': 'OFFICIAL NOTICE',
      'color': const Color(0xFF311B92),
      'date': '22 July 2026',
      'content': 'Partner banks Credila & Avanse have reduced ROI starting at 9.75% for top 100 global STEM programs. Existing applications automatically upgraded.',
      'action': 'Explore Offers',
      'route': '/ai/eligibility',
    },
    {
      'id': 'ann_3',
      'title': '🎓 Free SOP & LOR Review Webinar this Saturday at 6 PM',
      'tag': 'WEBINAR',
      'color': const Color(0xFF10B981),
      'date': '20 July 2026',
      'content': 'Join Ivy League alumni as they evaluate live SOP samples and share secrets to crack top university admissions.',
      'action': 'Use SOP Writer',
      'route': '/ai/sop-writer',
    },
  ];

  // ─── Smart Group Channels Data (Loaded dynamically from database) ───────
  List<Map<String, dynamic>> _smartGroups = [];

  Future<void> _loadSmartGroups() async {
    try {
      final groups = await _communityService.getGroups();
      if (mounted) {
        setState(() {
          _smartGroups = groups.map((g) {
            final iconName = g['iconName'] ?? g['icon'] ?? 'school_rounded';
            final colorHex = g['colorHex'] ?? g['color'] ?? '#311B92';
            return {
              ...g,
              'icon': _parseGroupIcon(iconName),
              'color': _parseGroupColor(colorHex),
              'members': g['members'] ?? 1,
              'online': g['online'] ?? 1,
              'badge': g['badge'] ?? 'General',
              'lastMsg': g['lastMsg'] ?? 'Active student channel',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading smart groups: $e');
    }
  }

  IconData _parseGroupIcon(dynamic icon) {
    if (icon is IconData) return icon;
    final str = icon.toString().toLowerCase();
    if (str.contains('verified')) return Icons.verified_user_rounded;
    if (str.contains('balance') || str.contains('account')) return Icons.account_balance_rounded;
    if (str.contains('public') || str.contains('global')) return Icons.public_rounded;
    return Icons.school_rounded;
  }

  Color _parseGroupColor(dynamic color) {
    if (color is Color) return color;
    if (color == null) return const Color(0xFF311B92);
    try {
      final str = color.toString().replaceAll('#', '');
      return Color(int.parse('FF$str', radix: 16));
    } catch (_) {
      return const Color(0xFF311B92);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _selectedCategory = args;
      } else if (args is Map<String, dynamic>) {
        if (args.containsKey('category')) {
          _selectedCategory = args['category'];
        }
        _customTitle = args['title'];
      }
      _loadPosts();
      _loadSmartGroups();
      _loadSavedPollVotes();
      _hasInitialLoaded = true;
    }
  }

  Future<void> _loadSavedPollVotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (var poll in _polls) {
        final pollId = poll['id'] as String;
        final savedIndex = prefs.getInt('poll_voted_$pollId');
        if (savedIndex != null && savedIndex >= 0) {
          setState(() {
            poll['userVotedIndex'] = savedIndex;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved poll votes: $e');
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _selectedCategory == 'General'
            ? _communityService.getForumPosts(
                category: 'General',
                sort: _selectedSort,
              )
            : _communityService.getHubPosts(
                topic: _selectedCategory,
                sort: _selectedSort,
              ),
        _communityService.getHubData(_selectedCategory),
        _communityService.getAllHubs(),
      ]);

      if (mounted) {
        setState(() {
          _posts = results[0] as List<ForumPost>;
          final hubData = results[1] as Map<String, dynamic>;
          final hub = hubData['hub'] ?? {};
          _membersCount = hub['stats']?['members'] ?? 0;
          _discussionsCount = hub['stats']?['discussions'] ?? 0;
          _hubDescription = hub['description'];
          _customTitle ??= hub['title'];
          _allHubs = (results[2] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _isLoading = false;
          _isLoadingHubs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingHubs = false;
        });
      }
    }
  }

  Future<void> _toggleLikePost(String postId) async {
    try {
      final result = await _communityService.likeForumPost(postId);
      if (result['success'] == true) {
        _loadPosts();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like post: $e')),
      );
    }
  }

  void _sharePost(ForumPost post) {
    final String text =
        'Check out this discussion on Vidya Loan: ${post.title}\n\n'
        '${post.content}\n\n'
        'Join the community at Vidya Loan!';

    Share.share(text, subject: post.title);
  }

  void _openGroupChatModal(Map<String, dynamic> group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SmartChatRoomModal(group: group),
    );
  }

  void _voteOnPoll(int pollIndex, int optionIndex) async {
    final poll = _polls[pollIndex];
    final pollId = poll['id'] as String;
    final previousVoted = poll['userVotedIndex'] as int;

    // Rule: Once selected, user CANNOT change their option!
    if (previousVoted != -1) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Poll vote locked! You cannot change your option after voting.',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF311B92),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      final List options = poll['options'] as List;
      options[optionIndex]['votes'] = (options[optionIndex]['votes'] as int) + 1;
      poll['totalVotes'] = (poll['totalVotes'] as int) + 1;
      poll['userVotedIndex'] = optionIndex;
    });

    try {
      await _communityService.submitPollVote(pollId, optionIndex);
    } catch (e) {
      debugPrint('Poll vote database sync info: $e');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text('Vote recorded! Poll results unlocked 📊'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: MeshBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildStickyNavbar(context),
                _buildMainTabToggle(),

                if (_selectedMainTab == 0) ...[
                  _buildCategorySelector(),
                  _buildHeroHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildFeedHeader(),
                        const SizedBox(height: 16),
                        _buildBody(),
                      ],
                    ),
                  ),
                ] else ...[
                  // ─── SMART GROUP CHAT CONTAINER ───────────────────────────
                  _buildSmartGroupChatSection(),
                ],

                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyNavbar(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (canPop)
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF311B92)),
              )
            else
              const SizedBox(width: 16),
            const Spacer(),
            Text(
              'Community Hub',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF311B92),
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            if (canPop) const SizedBox(width: 40) else const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMainTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedMainTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _selectedMainTab == 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFF311B92).withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.forum_rounded,
                      size: 17,
                      color: _selectedMainTab == 0
                          ? const Color(0xFF311B92)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Forum Feed',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: _selectedMainTab == 0
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: _selectedMainTab == 0
                            ? const Color(0xFF311B92)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMainTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedMainTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _selectedMainTab == 1
                      ? [
                          BoxShadow(
                            color: const Color(0xFF311B92).withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      size: 19,
                      color: _selectedMainTab == 1
                          ? const Color(0xFF311B92)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      LanguageService.tr('smart_groups'),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: _selectedMainTab == 1
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: _selectedMainTab == 1
                            ? const Color(0xFF311B92)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FORUM FEED SECTION WIDGETS ────────────────────────────────────────────

  Widget _buildCategorySelector() {
    if (_isLoadingHubs && _allHubs.isEmpty) {
      return const SizedBox(
        height: 50,
        child: Center(child: LinearProgressIndicator(color: Color(0xFF311B92))),
      );
    }

    final List<Map<String, dynamic>> displayHubs = [
      {'id': 'General', 'title': 'General'},
      ..._allHubs.where((h) => h['id'] != 'General'),
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: displayHubs.length,
        itemBuilder: (context, index) {
          final hub = displayHubs[index];
          final isSelected = _selectedCategory == hub['id'];
          final color = isSelected ? const Color(0xFF311B92) : Colors.grey[700];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(hub['title'] ?? hub['id']),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = hub['id'];
                    _customTitle = hub['title'];
                  });
                  _loadPosts();
                }
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF311B92).withValues(alpha: 0.12),
              labelStyle: GoogleFonts.inter(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF311B92)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF311B92).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _selectedCategory.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF311B92),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _customTitle ?? 'Community Forum',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1E293B),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hubDescription ??
                'Ask questions, share advice, and connect with fellow students navigating ${_selectedCategory.toLowerCase()}.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF1E293B).withValues(alpha: 0.65),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildStatCard('$_membersCount', 'MEMBERS'),
              const SizedBox(width: 12),
              _buildStatCard('$_discussionsCount', 'DISCUSSIONS'),
              const Spacer(),
              _buildNewPostButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewPostButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF311B92), Color(0xFF4527A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final result = await Navigator.pushNamed(
              context,
              '/community/forum/create',
              arguments: {'category': _selectedCategory},
            );

            if (result == true && mounted) {
              _loadPosts();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  'New Post',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF311B92),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B).withValues(alpha: 0.45),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedHeader() {
    return Row(
      children: [
        Text(
          'Discussion Feed',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF311B92),
            shape: BoxShape.circle,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildFilterToggle(
                'Latest',
                isSelected: _selectedSort == 'newest',
                value: 'newest',
              ),
              _buildFilterToggle(
                'Popular',
                isSelected: _selectedSort == 'popular',
                value: 'popular',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterToggle(
    String label, {
    required bool isSelected,
    required String value,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedSort = value;
          });
          _loadPosts();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF1E293B)
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF311B92)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          children: [
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadPosts, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Icon(Icons.forum_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No discussions found in this category yet.',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/community/forum/create',
                  arguments: {'category': _selectedCategory},
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Be the first to post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF311B92),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _posts.map((post) => _buildPostCard(post)).toList(),
    );
  }

  Widget _buildPostCard(ForumPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/community/forum/detail',
              arguments: post.id,
            );
          },
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF311B92).withValues(alpha: 0.1),
                      child: Text(
                        (post.userName != null && post.userName!.isNotEmpty)
                            ? post.userName![0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF311B92),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      post.userName != null && post.userName!.isNotEmpty
                          ? post.userName!
                          : 'Student User',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(post.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF1E293B).withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _buildStatAction(
                      post.liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      '${post.likes}',
                      color: post.liked ? const Color(0xFF311B92) : null,
                      onTap: () => _toggleLikePost(post.id),
                    ),
                    const SizedBox(width: 16),
                    _buildStatAction(
                      Icons.chat_bubble_outline_rounded,
                      '${post.commentCount} Answers',
                    ),
                    const SizedBox(width: 16),
                    _buildStatAction(
                      Icons.remove_red_eye_outlined,
                      '${post.views} Views',
                    ),
                    const Spacer(),
                    _buildStatAction(
                      Icons.share_outlined,
                      'Share',
                      onTap: () => _sharePost(post),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatAction(
    IconData icon,
    String value, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final activeColor = color ?? const Color(0xFF1E293B).withValues(alpha: 0.45);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 15, color: activeColor),
          const SizedBox(width: 5),
          if (value.isNotEmpty)
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: activeColor,
                fontWeight: color != null ? FontWeight.bold : FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  // ─── SMART GROUP CHAT CONTAINER & 4 SUB-TABS ───────────────────────────────

  Widget _buildSmartGroupChatSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Sub-Tab Switcher: General Chat | Polls | Announcements
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF311B92).withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildSubTabItem(0, '💬 Chat', Icons.chat_bubble_outline_rounded),
                _buildSubTabItem(1, '📊 Polls', Icons.poll_outlined),
                _buildSubTabItem(2, '📢 Alerts', Icons.campaign_outlined),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Render active Sub-Tab view
          if (_smartSubTab == 0) _buildGeneralChatView(),
          if (_smartSubTab == 1) _buildPollsView(),
          if (_smartSubTab == 2) _buildAnnouncementsView(),
        ],
      ),
    );
  }

  Widget _buildSubTabItem(int index, String title, IconData icon) {
    final bool isSelected = _smartSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _smartSubTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF311B92) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. GENERAL CHAT SUB-TAB
  Widget _buildGeneralChatView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF311B92), Color(0xFF4527A0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF311B92).withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Student Group Chats',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tap any channel to enter live group chat room',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE CHANNELS',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 1.0,
              ),
            ),
            GestureDetector(
              onTap: _showCreateGroupModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF311B92).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF311B92)),
                    const SizedBox(width: 4),
                    Text(
                      'Create Group',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF311B92),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Empty state when no groups exist ─────────────────────────────
        if (_smartGroups.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF311B92).withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF311B92).withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_outlined,
                    size: 40,
                    color: Color(0xFF311B92),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Groups Yet',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to create a student group!\nConnect with fellow aspirants around common goals.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _showCreateGroupModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF311B92),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Create First Group',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ..._smartGroups.map((group) => _buildGroupChannelTile(group)),
      ],
    );
  }


  Widget _buildGroupChannelTile(Map<String, dynamic> group) {
    final Color color = group['color'] as Color;
    final String groupId = group['id']?.toString() ?? '';
    final String? adminEmail = group['adminEmail']?.toString();

    return FutureBuilder<String>(
      future: CommunityService().getGroupMembershipStatus(groupId, adminEmail),
      builder: (context, snapshot) {
        final status = snapshot.data ?? 'NONE';
        final bool isAdmin = status == 'ADMIN';
        final bool isMember = status == 'APPROVED';
        final bool isPending = status == 'PENDING';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: isAdmin
                ? Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF311B92).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openGroupChatModal(group),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            group['icon'] as IconData,
                            color: color,
                            size: 24,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                        // 👑 Admin crown badge
                        if (isAdmin)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shield_rounded, size: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group['title'],
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Admin badge tag
                              if (isAdmin) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    'Admin',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  group['badge'],
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          // Show join status hint for non-admin
                          if (!isAdmin && !isMember)
                            Row(
                              children: [
                                Icon(
                                  isPending ? Icons.hourglass_top_rounded : Icons.lock_outline_rounded,
                                  size: 11,
                                  color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isPending ? 'Request pending approval' : 'Request to join',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              group['lastMsg'],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.people_alt_outlined, size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                '${group['members']} members',
                                style: GoogleFonts.inter(fontSize: 10.5, color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.circle, size: 7, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text(
                                '${group['online']} online',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isAdmin
                          ? Icons.manage_accounts_rounded
                          : Icons.arrow_forward_ios_rounded,
                      size: isAdmin ? 18 : 13,
                      color: isAdmin ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── CREATE GROUP CHANNEL MODAL ─────────────────────────────────────────────

  void _showCreateGroupModal() {
    final titleController = TextEditingController();
    final subController = TextEditingController();
    IconData selectedIcon = Icons.school_rounded;
    Color selectedColor = const Color(0xFF311B92);
    String selectedBadge = 'Custom Group';
    bool isAiVerifying = false;
    String? aiErrorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 16),
                  Text(
                    'Create Student Group Channel',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI Moderated: Groups must be related to study abroad, education, or loans.',
                    style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey[600]),
                  ),
                  if (aiErrorMsg != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              aiErrorMsg!,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'GROUP NAME',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Dallas Fall 2026 Aspirants',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'TOPIC / SUBTITLE',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: subController,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Housing, admit discussions & meetups',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CHOOSE ICON THEME',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIconChoice(
                        icon: Icons.school_rounded,
                        color: const Color(0xFF311B92),
                        badge: 'University',
                        selectedIcon: selectedIcon,
                        onTap: () {
                          setModalState(() {
                            selectedIcon = Icons.school_rounded;
                            selectedColor = const Color(0xFF311B92);
                            selectedBadge = 'University';
                          });
                        },
                      ),
                      _buildIconChoice(
                        icon: Icons.verified_user_rounded,
                        color: const Color(0xFF10B981),
                        badge: 'Visa',
                        selectedIcon: selectedIcon,
                        onTap: () {
                          setModalState(() {
                            selectedIcon = Icons.verified_user_rounded;
                            selectedColor = const Color(0xFF10B981);
                            selectedBadge = 'Visa';
                          });
                        },
                      ),
                      _buildIconChoice(
                        icon: Icons.account_balance_rounded,
                        color: const Color(0xFFF59E0B),
                        badge: 'Finance',
                        selectedIcon: selectedIcon,
                        onTap: () {
                          setModalState(() {
                            selectedIcon = Icons.account_balance_rounded;
                            selectedColor = const Color(0xFFF59E0B);
                            selectedBadge = 'Finance';
                          });
                        },
                      ),
                      _buildIconChoice(
                        icon: Icons.public_rounded,
                        color: const Color(0xFF3B82F6),
                        badge: 'Global',
                        selectedIcon: selectedIcon,
                        onTap: () {
                          setModalState(() {
                            selectedIcon = Icons.public_rounded;
                            selectedColor = const Color(0xFF3B82F6);
                            selectedBadge = 'Global';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isAiVerifying
                          ? null
                          : () async {
                              final title = titleController.text.trim();
                              final sub = subController.text.trim();
                              if (title.isEmpty) return;

                              setModalState(() {
                                isAiVerifying = true;
                                aiErrorMsg = null;
                              });

                              final verifyRes = await AiLogicService().verifyGroupTopic(title, sub);

                              if (verifyRes['isValid'] != true) {
                                setModalState(() {
                                  isAiVerifying = false;
                                  aiErrorMsg = verifyRes['reason'] ??
                                      'Group title/topic must be related to study abroad, education, or loans.';
                                });
                                return;
                              }

                              final iconName = selectedBadge == 'Visa'
                                  ? 'verified_user_rounded'
                                  : selectedBadge == 'Finance'
                                      ? 'account_balance_rounded'
                                      : selectedBadge == 'Global'
                                          ? 'public_rounded'
                                          : 'school_rounded';
                              final colorHex = '#${selectedColor.toARGB32().toRadixString(16).substring(2)}';

                              final prefs = await SharedPreferences.getInstance();
                              final userEmail = prefs.getString('user_email') ?? 'student@vidhyaloan.com';
                              final fname = prefs.getString('user_firstName') ?? '';
                              final lname = prefs.getString('user_lastName') ?? '';
                              final userName = '$fname $lname'.trim().isEmpty ? 'Group Admin' : '$fname $lname'.trim();
                              final newGroupId = 'group_${DateTime.now().millisecondsSinceEpoch}';

                              final newGroupData = {
                                'id': newGroupId,
                                'title': title,
                                'subtitle': sub.isEmpty ? 'Student discussion group' : sub,
                                'members': 1,
                                'online': 1,
                                'iconName': iconName,
                                'colorHex': colorHex,
                                'badge': selectedBadge,
                                'lastMsg': 'Group channel created just now!',
                                'adminEmail': userEmail,
                                'adminName': userName,
                              };

                              await _communityService.createGroup(newGroupData);
                              await _loadSmartGroups();

                              if (context.mounted) {
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Group Created Successfully! 🎉'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF311B92),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isAiVerifying
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '🤖 AI Verifying Relevance...',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Create Group Channel',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconChoice({
    required IconData icon,
    required Color color,
    required String badge,
    required IconData selectedIcon,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedIcon == icon;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey[100],
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  // 3. POLLS SUB-TAB (HIGH INTERACTION)
  Widget _buildPollsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LIVE COMMUNITY POLLS',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 1.0,
              ),
            ),
            GestureDetector(
              onTap: _showCreatePollModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFFEC4899)),
                    const SizedBox(width: 4),
                    Text(
                      'Create Poll',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEC4899),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Show active (non-expired) polls, or empty state ───────────────
        Builder(builder: (context) {
          final active = _activePolls;
          if (active.isEmpty) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.poll_outlined,
                      size: 40,
                      color: Color(0xFFEC4899),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Polls are Empty',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No active polls right now.\nPolls expire after 1 week — create one to get the community talking!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showCreatePollModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      'Create a Poll',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: List.generate(
              active.length,
              (i) => _buildPollCard(i, active[i]),
            ),
          );
        }),
      ],
    );
  }

  void _showCreatePollModal() {
    final qController = TextEditingController();
    final opt1Controller = TextEditingController();
    final opt2Controller = TextEditingController();
    final opt3Controller = TextEditingController();
    final opt4Controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
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
              const SizedBox(height: 16),
              Text(
                'Create Community Poll',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Student Community: Create a live poll and ask fellow students',
                style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey[600]),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: qController,
                decoration: InputDecoration(
                  labelText: 'Poll Question',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: opt1Controller,
                decoration: InputDecoration(
                  labelText: 'Option 1',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: opt2Controller,
                decoration: InputDecoration(
                  labelText: 'Option 2',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: opt3Controller,
                decoration: InputDecoration(
                  labelText: 'Option 3 (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: opt4Controller,
                decoration: InputDecoration(
                  labelText: 'Option 4 (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final q = qController.text.trim();
                    final o1 = opt1Controller.text.trim();
                    final o2 = opt2Controller.text.trim();
                    if (q.isEmpty || o1.isEmpty || o2.isEmpty) return;

                    final opts = [
                      {'text': o1, 'votes': 0},
                      {'text': o2, 'votes': 0},
                    ];
                    if (opt3Controller.text.trim().isNotEmpty) {
                      opts.add({'text': opt3Controller.text.trim(), 'votes': 0});
                    }
                    if (opt4Controller.text.trim().isNotEmpty) {
                      opts.add({'text': opt4Controller.text.trim(), 'votes': 0});
                    }

                    final newPoll = {
                      'id': 'poll_${DateTime.now().millisecondsSinceEpoch}',
                      'question': q,
                      'author': 'Student Poll',
                      'totalVotes': 0,
                      'userVotedIndex': -1,
                      'createdAt': DateTime.now(), // expiry = createdAt + 7 days
                      'options': opts,
                    };

                    setState(() {
                      _polls.insert(0, newPoll);
                    });

                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    // 🔔 Push Dual Notification (In-App Bell + Mobile Banner)
                    await NotificationService.pushNotification(
                      title: '📊 New Community Poll Published!',
                      message: q,
                      type: 'POLL',
                    );

                    nav.pop();

                    messenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '📊 New Community Poll Published!',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Saved to your VidyaLoan bell icon notifications',
                                    style: GoogleFonts.inter(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF311B92),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Publish Poll & Notify Users 🔔',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPollCard(int pollIndex, Map<String, dynamic> poll) {
    final int userVotedIndex = poll['userVotedIndex'] as int;
    final int totalVotes = poll['totalVotes'] as int;
    final List options = poll['options'] as List;
    final bool hasVoted = userVotedIndex != -1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: hasVoted
            ? Border.all(color: const Color(0xFF311B92).withValues(alpha: 0.15), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_rounded, color: Color(0xFF311B92), size: 18),
              const SizedBox(width: 6),
              Text(
                poll['author'],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF311B92),
                ),
              ),
              const Spacer(),
              Text(
                '$totalVotes total votes',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            poll['question'],
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          ...List.generate(options.length, (optIndex) {
            final opt = options[optIndex];
            final int votes = opt['votes'] as int;
            final double pct = totalVotes == 0 ? 0.0 : votes / totalVotes;
            final bool isSelected = userVotedIndex == optIndex;

            return GestureDetector(
              onTap: () => _voteOnPoll(pollIndex, optIndex),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background progress bar filling the container
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: hasVoted ? pct : 0.0,
                          backgroundColor: isSelected
                              ? const Color(0xFF311B92).withValues(alpha: 0.08)
                              : const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isSelected
                                ? const Color(0xFF311B92).withValues(alpha: 0.25)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                    // Option Text & Percentage centered vertically
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : (hasVoted
                                      ? Icons.circle_outlined
                                      : Icons.radio_button_unchecked_rounded),
                              size: 18,
                              color: isSelected
                                  ? const Color(0xFF311B92)
                                  : Colors.grey[500],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      opt['text'],
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xFF311B92)
                                            : const Color(0xFF334155),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF311B92),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Your Vote',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (hasVoted)
                              Text(
                                '${(pct * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFF311B92)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          if (hasVoted) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  'Vote locked • Poll results revealed',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 4. ANNOUNCEMENTS SUB-TAB
  Widget _buildAnnouncementsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OFFICIAL ANNOUNCEMENTS & ALERTS',
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF64748B),
            letterSpacing: 1.0,
          ),
        ),

        const SizedBox(height: 12),

        ..._announcements.map((ann) => _buildAnnouncementCard(ann)),
      ],
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> ann) {
    final Color color = ann['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.campaign_rounded, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      ann['tag'],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                ann['date'],
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ann['title'],
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ann['content'],
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF475569),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, ann['route']);
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 15),
              label: Text(
                ann['action'],
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── INTERACTIVE SMART GROUP CHAT ROOM MODAL ──────────────────────────────────

class _SmartChatRoomModal extends StatefulWidget {
  final Map<String, dynamic> group;

  const _SmartChatRoomModal({required this.group});

  @override
  State<_SmartChatRoomModal> createState() => _SmartChatRoomModalState();
}

class _SmartChatRoomModalState extends State<_SmartChatRoomModal> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingMessages = true;
  bool _isJoined = false;
  String _membershipStatus = 'NONE';
  List<Map<String, dynamic>> _pendingRequests = [];
  String _mySenderName = 'You';
  Timer? _chatPollingTimer;

  @override
  void initState() {
    super.initState();
    _loadUserAndMessages();
    _chatPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _pollNewMessages();
    });
  }

  Future<void> _pollNewMessages() async {
    final groupId = widget.group['id'] as String;
    final msgs = await CommunityService().getGroupMessages(groupId);
    if (!mounted) return;
    if (msgs.isEmpty && _messages.isNotEmpty) return;

    final parsed = msgs.map((m) {
      final sender = m['sender'] ?? 'Student';
      final colorHex = m['colorHex'] ?? '#311B92';
      Color color;
      try {
        color = Color(int.parse('FF${colorHex.toString().replaceAll('#', '')}', radix: 16));
      } catch (_) {
        color = const Color(0xFF311B92);
      }
      final isMe = sender == _mySenderName || m['isMe'] == true;
      return {
        'id': m['id'],
        'sender': sender,
        'avatarLetter': m['avatarLetter'] ?? (sender.isNotEmpty ? sender[0].toUpperCase() : 'S'),
        'color': color,
        'role': m['role'] ?? 'Student',
        'text': m['text'] ?? '',
        'time': m['time'] ?? 'Just now',
        'isMe': isMe,
      };
    }).toList();

    if (parsed.isNotEmpty && (parsed.length != _messages.length || _messages.isEmpty)) {
      setState(() {
        _messages = parsed;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _chatPollingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fname = prefs.getString('user_firstName') ?? '';
      final lname = prefs.getString('user_lastName') ?? '';
      final fullName = '$fname $lname'.trim();
      if (fullName.isNotEmpty) {
        _mySenderName = fullName;
      }
    } catch (_) {}

    final groupId = widget.group['id'] as String;
    final adminEmail = widget.group['adminEmail'] as String?;
    final status = await CommunityService().getGroupMembershipStatus(groupId, adminEmail);
    final isJoined = (status == 'ADMIN' || status == 'APPROVED');
    final msgs = await CommunityService().getGroupMessages(groupId);
    List<Map<String, dynamic>> pendingReqs = [];
    if (status == 'ADMIN') {
      pendingReqs = await CommunityService().getPendingJoinRequests(groupId);
    }

    if (mounted) {
      setState(() {
        _membershipStatus = status;
        _isJoined = isJoined;
        _pendingRequests = pendingReqs;
        _messages = msgs.map((m) {
          final sender = m['sender'] ?? 'Student';
          final colorHex = m['colorHex'] ?? '#311B92';
          Color color;
          try {
            color = Color(int.parse('FF${colorHex.toString().replaceAll('#', '')}', radix: 16));
          } catch (_) {
            color = const Color(0xFF311B92);
          }
          final isMe = sender == _mySenderName || m['isMe'] == true;
          return {
            'id': m['id'],
            'sender': sender,
            'avatarLetter': m['avatarLetter'] ?? (sender.isNotEmpty ? sender[0].toUpperCase() : 'S'),
            'color': color,
            'role': m['role'] ?? 'Student',
            'text': m['text'] ?? '',
            'time': m['time'] ?? 'Just now',
            'isMe': isMe,
          };
        }).toList();

        _isLoadingMessages = false;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  void _requestJoinGroup() async {
    final groupId = widget.group['id'] as String;
    final title = widget.group['title'] as String? ?? 'Group';
    final adminEmail = widget.group['adminEmail'] as String?;

    await CommunityService().requestGroupJoin(
      groupId: groupId,
      groupTitle: title,
      adminEmail: adminEmail,
    );

    if (mounted) {
      setState(() {
        _membershipStatus = 'PENDING';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.send_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '📩 Join request sent to Group Admin! Admin will receive mobile & in-app notifications.',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showAdminPendingRequestsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF311B92), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Group Admin: Join Requests',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Review and approve students who requested to join your group channel.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                if (_pendingRequests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No pending join requests right now.',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _pendingRequests.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, index) {
                        final req = _pendingRequests[index];
                        final name = req['applicantName'] ?? 'Student Applicant';
                        final email = req['applicantEmail'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF311B92).withValues(alpha: 0.1),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF311B92)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(email, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              // ── Approve button ──
                              GestureDetector(
                                onTap: () async {
                                  final groupId = widget.group['id'] as String;
                                  final messenger = ScaffoldMessenger.of(context);
                                  await CommunityService().approveGroupJoinRequest(
                                    groupId: groupId,
                                    requestId: req['id'] ?? '',
                                    applicantEmail: email,
                                    groupTitle: widget.group['title'] ?? 'Group',
                                  );
                                  setModalState(() => _pendingRequests.removeAt(index));
                                  setState(() {
                                    widget.group['members'] = (widget.group['members'] ?? 1) + 1;
                                  });
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('✅ $name approved and notified!'),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // ── Reject button ──
                              GestureDetector(
                                onTap: () async {
                                  final groupId = widget.group['id'] as String;
                                  final messenger = ScaffoldMessenger.of(context);
                                  await CommunityService().rejectGroupJoinRequest(
                                    groupId: groupId,
                                    requestId: req['id'] ?? '',
                                    applicantEmail: email,
                                    groupTitle: widget.group['title'] ?? 'Group',
                                  );
                                  setModalState(() => _pendingRequests.removeAt(index));
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('❌ $name\'s request rejected.'),
                                      backgroundColor: const Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    final groupId = widget.group['id'] as String;
    final now = DateTime.now();
    final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    final tempMsg = {
      'sender': _mySenderName,
      'avatarLetter': _mySenderName.isNotEmpty ? _mySenderName[0].toUpperCase() : 'Y',
      'color': const Color(0xFF311B92),
      'role': 'Student',
      'text': text,
      'time': timeStr,
      'isMe': true,
    };

    setState(() {
      _messages.add(tempMsg);
    });

    try {
      final msgPayload = {
        'sender': _mySenderName,
        'avatarLetter': tempMsg['avatarLetter'],
        'colorHex': '#311B92',
        'role': 'Student',
        'text': text,
        'time': timeStr,
      };
      await CommunityService().sendGroupMessage(groupId, msgPayload);
    } catch (e) {
      debugPrint('Error sending group chat message to DB: $e');
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = widget.group['color'] as Color;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: mainColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.group['icon'] as IconData,
                    color: mainColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.group['title'],
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.circle, size: 7, color: Color(0xFF10B981)),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.group['online']} Online • Live Group Chat',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_membershipStatus == 'ADMIN') ...[
                  GestureDetector(
                    onTap: _showAdminPendingRequestsModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mark_email_unread_rounded, size: 14, color: Color(0xFFDC2626)),
                          const SizedBox(width: 4),
                          Text(
                            'Requests (${_pendingRequests.length})',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: _isLoadingMessages
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF311B92)),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(18),
                      itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final bool isMe = msg['isMe'] == true;

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:
                            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            GestureDetector(
                              onTap: () => _openMemberDirectChatModal(context, msg),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: (msg['color'] as Color).withValues(alpha: 0.15),
                                child: Text(
                                  msg['avatarLetter'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: msg['color'] as Color,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          Flexible(
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  GestureDetector(
                                    onTap: () => _openMemberDirectChatModal(context, msg),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 2, bottom: 3),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            msg['sender'],
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF334155),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: (msg['color'] as Color).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              msg['role'],
                                              style: GoogleFonts.inter(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                                color: msg['color'] as Color,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Color(0xFF311B92)),
                                        ],
                                      ),
                                    ),
                                  ),

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe ? const Color(0xFF311B92) : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    msg['text'],
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      color: isMe ? Colors.white : const Color(0xFF1E293B),
                                      height: 1.4,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  msg['time'],
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          if (!_isJoined)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_membershipStatus == 'PENDING') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded, color: Color(0xFFC2410C), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Join Request Pending Approval',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFC2410C),
                                    ),
                                  ),
                                  Text(
                                    'Your join request has been sent to the group admin. You will receive mobile & app notifications when approved.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: const Color(0xFF7C2D12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Ask permission from the group admin to join and participate in this group.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _requestJoinGroup,
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        label: Text(
                          '📩 Request to Join Group',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF311B92),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _msgController,
                          style: GoogleFonts.inter(fontSize: 14),
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Type a message to the group...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: Colors.grey[500],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF311B92),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
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

  void _openMemberDirectChatModal(BuildContext context, Map<String, dynamic> msg) {
    final senderName = msg['sender'] as String? ?? 'Student Member';
    final role = msg['role'] as String? ?? 'Student';
    final avatarLetter = msg['avatarLetter'] as String? ?? senderName[0];
    final color = (msg['color'] as Color?) ?? const Color(0xFF311B92);
    final peerId = 'peer_${senderName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(
                avatarLetter,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              senderName,
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                role,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Color(0xFF311B92), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phone numbers are automatically masked as XXXXXXXXXX for safety.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF311B92),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(modalContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DirectChatDetailPage(
                      peerId: peerId,
                      peerName: senderName,
                      peerRole: role,
                      avatarLetter: avatarLetter,
                      colorValue: color.toARGB32(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
              label: const Text('Start Person-to-Person Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF311B92),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
