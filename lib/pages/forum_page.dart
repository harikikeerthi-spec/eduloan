import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/community.dart';
import '../services/community_service.dart';
import '../widgets/mesh_background.dart';

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
  String _selectedCategory = 'General';
  String? _customTitle;
  int _membersCount = 0;
  int _discussionsCount = 0;
  String _selectedSort = 'newest';
  String? _hubDescription;
  bool _hasInitialLoaded = false;

  @override
  void dispose() {
    super.dispose();
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
      _hasInitialLoaded = true;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch stats and posts in parallel
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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLikePost(String postId) async {
    try {
      final result = await _communityService.likeForumPost(postId);
      if (result['success'] == true) {
        _loadPosts(); // Refresh the list
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to like post: $e')));
    }
  }

  void _sharePost(ForumPost post) {
    final String text =
        'Check out this discussion on VidhyaLoan: ${post.title}\n\n'
        '${post.content}\n\n'
        'Join the community at VidhyaLoan!';

    Share.share(text, subject: post.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Optional, for full screen effect if needed
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/community/forum/create',
            arguments: {'category': _selectedCategory},
          );

          if (result == true && mounted) {
            _loadPosts(); // Refresh if a post was created
          }
        },
        backgroundColor: const Color(0xFF311B92),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: MeshBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildStickyNavbar(context),
                _buildHeroHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildFeedHeader(),
                      const SizedBox(height: 16),
                      _buildBody(),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyNavbar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
            const Spacer(),
            Image.network(
              'https://vidhyaloan.com/assets/images/logo.png',
              height: 24,
              errorBuilder: (_, _, _) => const Text(
                'VidhyaLoan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF311B92),
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6605C7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _selectedCategory.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6605C7),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _customTitle ?? 'Community Forum',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _hubDescription ??
                'Navigate the complexities of ${_selectedCategory.toLowerCase()} and community planning.',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF1E293B).withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard('$_membersCount', 'MEMBERS'),
              const SizedBox(width: 16),
              _buildStatCard('$_discussionsCount', 'DISCUSSIONS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6605C7),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B).withValues(alpha: 0.4),
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
        const Text(
          'Discussion Feed',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF6605C7),
            shape: BoxShape.circle,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(4),
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
          borderRadius: BorderRadius.circular(8),
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      return const Center(child: CircularProgressIndicator());
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
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No posts found in this category.'),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF6605C7).withValues(alpha: 0.1),
                      child: const Text(
                        'U',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6605C7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(post.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatAction(
                      post.liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      '${post.likes}',
                      color: post.liked ? const Color(0xFF6605C7) : null,
                      onTap: () => _toggleLikePost(post.id),
                    ),
                    const SizedBox(width: 16),
                    _buildStatAction(
                      Icons.chat_bubble_outline,
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
    final activeColor = color ?? const Color(0xFF1E293B).withValues(alpha: 0.4);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: activeColor),
          const SizedBox(width: 6),
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
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
}
