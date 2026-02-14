import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community.dart';
import '../services/community_service.dart';

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
  String _selectedCategory = 'All';
  String? _customTitle;
  int _membersCount = 0;
  int _discussionsCount = 0;
  String _selectedSort = 'newest';
  String? _hubDescription;
  String? _hubIcon;
  File? _selectedImage;

  final List<String> _categories = [
    'All',
    'General',
    'Admissions',
    'Loans',
    'Visa',
    'Accommodation',
  ];

  bool _hasInitialLoaded = false;
  bool _isExpanding = false;
  bool _isSubmitting = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && _categories.contains(args)) {
        _selectedCategory = args;
      } else if (args is Map<String, dynamic>) {
        if (args.containsKey('category') &&
            _categories.contains(args['category'])) {
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
        _selectedCategory == 'All'
            ? _communityService.getForumPosts(sort: _selectedSort)
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
          _hubIcon = hub['icon'];
          if (_customTitle == null) {
            _customTitle = hub['title'];
          }
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

  double _calculateSimilarity(String s1, String s2) {
    final words1 = s1
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((e) => e.length > 2)
        .toSet();
    final words2 = s2
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((e) => e.length > 2)
        .toSet();
    if (words1.isEmpty || words2.isEmpty) return 0.0;
    final intersection = words1.intersection(words2);
    return intersection.length / ((words1.length + words2.length) / 2);
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<ForumPost?> _findSimilarPost() async {
    try {
      final newTitle = _titleController.text.trim();
      ForumPost? bestMatch;
      double maxSimilarity = 0.0;

      for (var post in _posts) {
        final similarity = _calculateSimilarity(newTitle, post.title);
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
          bestMatch = post;
        }
      }

      if (maxSimilarity > 0.6) return bestMatch;
    } catch (e) {
      print('Error checking similarity: $e');
    }
    return null;
  }

  Future<void> _submitPost({bool skipSimilarityCheck = false}) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      }
      return;
    }
    if (content.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your discussion content')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null && mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to post a discussion')),
        );
        Navigator.pushNamed(context, '/login');
        return;
      }

      if (!skipSimilarityCheck) {
        final similarPost = await _findSimilarPost();
        if (similarPost != null && mounted) {
          setState(() => _isSubmitting = false);

          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF311B92)),
                  SizedBox(width: 10),
                  Text('Similar Question Found'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('A similar question has already been asked:'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF311B92).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      similarPost.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Would you like to view it instead?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Post Anyway',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                    Navigator.pushNamed(
                      context,
                      '/community/forum/detail',
                      arguments: similarPost.id,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6605C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Existing'),
                ),
              ],
            ),
          );

          if (proceed != true) return;
          setState(() => _isSubmitting = true);
        }
      }

      if (_selectedCategory == 'All') {
        await _communityService.createForumPost(
          title: title,
          content: content,
          category: 'General',
        );
      } else {
        await _communityService.createHubPost(
          topic: _selectedCategory,
          title: title,
          content: content,
        );
      }

      if (mounted) {
        _titleController.clear();
        _contentController.clear();
        setState(() {
          _isExpanding = false;
          _isSubmitting = false;
          _selectedImage = null;
        });
        _loadPosts(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStickyNavbar(context),
            _buildHeroHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildStartDiscussionBox(),
                  const SizedBox(height: 32),
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
              errorBuilder: (_, __, ___) => const Text(
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
              color: const Color(0xFF6605C7).withOpacity(0.1),
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
              color: const Color(0xFF1E293B).withOpacity(0.6),
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
            color: Colors.black.withOpacity(0.03),
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
              color: const Color(0xFF1E293B).withOpacity(0.4),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartDiscussionBox() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: _isExpanding
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF311B92).withOpacity(0.1),
                child: const Text(
                  'A',
                  style: TextStyle(color: Color(0xFF311B92)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isExpanding
                    ? _buildExpandedInput()
                    : _buildCollapsedInput(),
              ),
            ],
          ),
          if (_isExpanding) _buildExpandedActions(),
        ],
      ),
    );
  }

  Widget _buildCollapsedInput() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanding = true),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Start a discussion...',
          style: TextStyle(color: Colors.black26, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildExpandedInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          autofocus: true,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Title of your discussion',
            hintStyle: TextStyle(
              color: Colors.black26,
              fontWeight: FontWeight.normal,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contentController,
          maxLines: null,
          style: const TextStyle(fontSize: 14, height: 1.5),
          decoration: const InputDecoration(
            hintText: 'Share more details...',
            hintStyle: TextStyle(color: Colors.black26),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildExpandedActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 56),
      child: Row(
        children: [
          IconButton(
            onPressed: _pickImage,
            icon: Icon(
              Icons.image_outlined,
              size: 20,
              color: _selectedImage != null
                  ? const Color(0xFF6605C7)
                  : const Color(0xFF6605C7).withOpacity(0.5),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    setState(() {
                      _isExpanding = false;
                      _titleController.clear();
                      _contentController.clear();
                      _selectedImage = null;
                    });
                  },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submitPost(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6605C7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                    color: Colors.black.withOpacity(0.05),
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
            color: Colors.black.withOpacity(0.04),
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
                      backgroundColor: const Color(0xFF6605C7).withOpacity(0.1),
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
                        color: const Color(0xFF1E293B).withOpacity(0.4),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF1E293B).withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatAction(
                      Icons.thumb_up_outlined,
                      '${post.likes}',
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

  Widget _buildStatAction(IconData icon, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1E293B).withOpacity(0.4)),
          const SizedBox(width: 6),
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF1E293B).withOpacity(0.4),
                fontWeight: FontWeight.w500,
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
