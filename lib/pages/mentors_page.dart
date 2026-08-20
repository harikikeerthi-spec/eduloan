import 'package:flutter/material.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../widgets/mesh_background.dart';

class MentorsPage extends StatefulWidget {
  const MentorsPage({super.key});

  @override
  State<MentorsPage> createState() => _MentorsPageState();
}

class _MentorsPageState extends State<MentorsPage> {
  final CommunityService _communityService = CommunityService();
  List<Mentor> _mentors = [];
  List<ForumPost> _mentorPosts = [];
  final TextEditingController _mentorTitleController = TextEditingController();
  bool _isLoading = true;
  bool _isMentorForumExpanding = false;
  bool _isMentorForumSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _communityService.getAllMentors(),
        _communityService.getHubPosts(topic: 'mentors'),
      ]);

      if (mounted) {
        setState(() {
          _mentors = results[0] as List<Mentor>;
          _mentorPosts = results[1] as List<ForumPost>;
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

  Future<void> _submitMentorPost() async {
    final title = _mentorTitleController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _isMentorForumSubmitting = true;
    });

    try {
      final result = await _communityService.createHubPost(
        topic: 'mentors',
        title: title,
        content: '', // Title-only
      );

      if (result['success'] == true && mounted) {
        _mentorTitleController.clear();
        setState(() {
          _isMentorForumExpanding = false;
        });
        _loadAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post question: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMentorForumSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            padding: EdgeInsets.zero,
          ),
          const Spacer(),
          const Text(
            'Connect with Mentors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAll, child: const Text('Try Again')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMentorForumInputBox(),
          const SizedBox(height: 24),
          const Text(
            'Verified Mentors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ..._mentors.map((mentor) => _buildMentorCard(mentor)),
          const SizedBox(height: 32),
          const Text(
            'Latest Questions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          if (_mentorPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No questions asked yet.')),
            ),
          ..._mentorPosts.map((post) => _buildMiniForumPostCard(post)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMentorForumInputBox() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF311B92).withValues(alpha: 0.1),
                child: const Text(
                  'Q',
                  style: TextStyle(color: Color(0xFF311B92)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _mentorTitleController,
                  onTap: () {
                    if (!_isMentorForumExpanding) {
                      setState(() => _isMentorForumExpanding = true);
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Ask mentors a question...',
                    hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          if (_isMentorForumExpanding)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 56),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isMentorForumExpanding = false;
                        _mentorTitleController.clear();
                      });
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isMentorForumSubmitting
                        ? null
                        : _submitMentorPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF311B92),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isMentorForumSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Ask Question'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniForumPostCard(ForumPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/community/forum/detail',
            arguments: post.id,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount} Answers',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(post.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  Widget _buildMentorCard(Mentor mentor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: mentor.imageUrl != null && mentor.imageUrl!.isNotEmpty
                    ? Image.network(
                        mentor.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: const Color(
                              0xFF311B92,
                            ).withValues(alpha: 0.1),
                            child: Center(
                              child: Text(
                                mentor.name.isNotEmpty
                                    ? mentor.name[0].toUpperCase()
                                    : 'M',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Color(0xFF311B92),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: const Color(0xFF311B92).withValues(alpha: 0.1),
                        child: Center(
                          child: Text(
                            mentor.name.isNotEmpty
                                ? mentor.name[0].toUpperCase()
                                : 'M',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Color(0xFF311B92),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentor.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      mentor.role,
                      style: TextStyle(
                        color: const Color(0xFF311B92).withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (mentor.university != null)
                      Text(
                        mentor.university!,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      mentor.rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            mentor.bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.7),
              height: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: mentor.expertise
                .take(3)
                .map((exp) => _buildExpertiseChip(exp))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mentor.hourlyRate > 0)
                    Text(
                      '₹${mentor.hourlyRate.toStringAsFixed(0)}/hr',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  if (mentor.hourlyRate == 0)
                    const Text(
                      'Free Session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  Text(
                    '${mentor.studentsMentored} students',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking functionality coming soon!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF311B92),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Book Session'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpertiseChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF311B92).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF311B92).withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF311B92),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
