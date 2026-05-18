import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../widgets/mesh_background.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();

  List<SuccessStory> _stories = [];
  List<CommunityResource> _resources = [];
  List<Mentor> _mentors = [];
  List<ForumPost> _mentorPosts = [];
  bool _isLoading = true;
  String? _error;
  String? _activeCategory;

  List<Map<String, dynamic>> _hubs = [];
  final TextEditingController _mentorTitleController = TextEditingController();
  bool _isMentorForumExpanding = false;
  bool _isMentorForumSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _communityService.getAllStories(limit: 5),
        _communityService.getAllMentors(limit: 3),
        _communityService.getPopularResources(limit: 4),
        _communityService.getAllHubs(),
        _communityService.getHubPosts(topic: 'mentors'),
      ]);

      if (mounted) {
        setState(() {
          _stories = results[0] as List<SuccessStory>;
          _mentors = results[1] as List<Mentor>;
          _resources = results[2] as List<CommunityResource>;
          _hubs = results[3] as List<Map<String, dynamic>>;
          _mentorPosts = results[4] as List<ForumPost>;
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

  void _shareStory(SuccessStory story) {
    final String text =
        'Check out ${story.studentName}\'s success story on VidyaLoan!\n\n'
        'Student: ${story.studentName}\n'
        'University: ${story.university}\n'
        'Loan Amount: ₹${story.loanAmount}\n\n'
        'Story: ${story.content}\n\n'
        'Join the community at VidyaLoan!';

    Share.share(text, subject: 'Success Story: ${story.studentName}');
  }

  Future<void> _loadMentorPosts() async {
    try {
      final posts = await _communityService.getHubPosts(topic: 'mentors');
      if (mounted) {
        setState(() {
          _mentorPosts = posts;
        });
      }
    } catch (e) {
      debugPrint('Error loading mentor posts: $e');
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
        _loadMentorPosts();
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
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _activeCategory == null
                    ? _buildGridBody()
                    : _buildCategoryView(_activeCategory!),
              ),
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
            onPressed: () {
              if (_activeCategory != null) {
                setState(() => _activeCategory = null);
              } else {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            padding: EdgeInsets.zero,
          ),
          const Spacer(),
          Text(
            _activeCategory ?? 'Community Hub',
            style: const TextStyle(
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

  Widget _buildGridBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final List<Map<String, dynamic>> items = _hubs
        .map(
          (hub) => {
            'id': hub['id'],
            'title': hub['title'] ?? hub['id'],
            'desc': hub['description'] ?? '',
            'icon': _getIconData(hub['icon']),
            'imagePath': 'assets/icons/3d_community/${hub['id']}.png',
            'color': _getHubColor(hub['id']),
            'isExternalRoute': hub['isExternalRoute'] ?? false,
            'isSpecialRoute': hub['isSpecialRoute'] ?? false,
            'route': hub['route'],
          },
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.68, // Even taller for long content
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildCategoryGridCard(items[index]);
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore Categories',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF311B92),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a category to dive deep into discussions and resources.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.5),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGridCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        if (category['isExternalRoute'] == true) {
          Navigator.pushNamed(context, category['route']);
        } else if (category['isSpecialRoute'] == true) {
          setState(() {
            _activeCategory = category['title'];
          });
        } else {
          Navigator.pushNamed(
            context,
            '/community/forum',
            arguments: {'category': category['id'], 'title': category['title']},
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16), // Reduced padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF311B92).withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (category['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                category['imagePath'],
                width: 36,
                height: 36,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(category['icon'], color: category['color'], size: 28),
              ),
            ),
            const SizedBox(height: 12), // Fixed spacing instead of Spacer
            Text(
              category['title'],
              style: const TextStyle(
                fontSize: 15, // Slightly smaller title
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category['desc'],
              style: TextStyle(
                fontSize: 11,
                color: Colors.black.withValues(alpha: 0.4),
                height: 1.3,
              ),
              maxLines: 2, // Reduced from 3 to ensure fit
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Explore Section',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: category['color'],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 12, color: category['color']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryView(String categoryTitle) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (categoryTitle == 'Success Stories') {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: ListView.builder(
          itemCount: _stories.length,
          itemBuilder: (context, index) =>
              _buildStoryCard(_stories[index], isHorizontal: false),
        ),
      );
    } else if (categoryTitle == 'Alumni & Mentors') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: RefreshIndicator(
          onRefresh: () => Future.wait([_loadData(), _loadMentorPosts()]),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              _buildMentorForumInputBox(),
              const SizedBox(height: 24),
              const Text(
                'Verified Alumni & Mentors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ..._mentors.map((m) => _buildMentorCard(m)),
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
              ..._mentorPosts.map((p) => _buildMiniForumPostCard(p)),
            ],
          ),
        ),
      );
    } else if (categoryTitle == 'Resources') {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: ListView.builder(
          itemCount: _resources.length,
          itemBuilder: (context, index) =>
              _buildResourceCard(_resources[index]),
        ),
      );
    } else if (categoryTitle == 'Events & AMAs') {
      return const Center(child: Text('Events & AMAs coming soon!'));
    }
    return Center(child: Text('Viewing $categoryTitle'));
  }

  Widget _buildResourceCard(
    CommunityResource resource, {
    bool isHorizontal = false,
  }) {
    IconData icon;
    Color color;

    switch (resource.type.toLowerCase()) {
      case 'guide':
        icon = Icons.menu_book;
        color = const Color(0xFF10B981);
        break;
      case 'template':
        icon = Icons.description;
        color = const Color(0xFF3B82F6);
        break;
      case 'checklist':
        icon = Icons.checklist;
        color = const Color(0xFFF59E0B);
        break;
      case 'video':
        icon = Icons.play_circle_outline;
        color = const Color(0xFFE91E63);
        break;
      default:
        icon = Icons.folder;
        color = const Color(0xFF311B92);
    }

    return Container(
      margin: EdgeInsets.only(
        right: isHorizontal ? 16 : 0,
        bottom: isHorizontal ? 0 : 16,
      ),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  resource.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.download,
                      size: 15,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${resource.downloads} downloads',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.5),
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
  }

  Widget _buildMentorCard(Mentor mentor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF311B92).withValues(alpha: 0.1),
                backgroundImage: mentor.imageUrl != null
                    ? NetworkImage(mentor.imageUrl!)
                    : null,
                child: mentor.imageUrl == null
                    ? Text(
                        mentor.name[0],
                        style: const TextStyle(
                          color: Color(0xFF311B92),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
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
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
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
                  color: const Color(0xFF311B92).withValues(alpha: 0.1),
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
                        fontSize: 14,
                        color: Color(0xFF311B92),
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
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mentor.expertise
                .map(
                  (skill) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF311B92).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF311B92),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(SuccessStory story, {bool isHorizontal = false}) {
    return GestureDetector(
      onTap: () => _showStoryDetailsModal(context, story),
      child: Container(
        margin: EdgeInsets.only(
          right: isHorizontal ? 16 : 0,
          bottom: isHorizontal ? 0 : 16,
        ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  backgroundImage: story.imageUrl != null
                      ? NetworkImage(story.imageUrl!)
                      : null,
                  child: story.imageUrl == null
                      ? Text(
                          story.studentName[0],
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        story.university,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '₹${story.loanAmount}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF311B92),
                  ),
                ),
                const Spacer(),
                Text(
                  story.country,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              story.content,
              maxLines: isHorizontal ? 3 : 10,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.7),
                height: 1.4,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _shareStory(story),
                  icon: Icon(
                    Icons.share_outlined,
                    size: 18,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryDetailsModal(BuildContext context, SuccessStory story) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          backgroundImage: story.imageUrl != null
                              ? NetworkImage(story.imageUrl!)
                              : null,
                          child: story.imageUrl == null
                              ? Text(
                                  story.studentName[0],
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.studentName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '${story.course} @ ${story.university}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      'Country',
                      story.country,
                    ),
                    _buildDetailRow(
                      Icons.account_balance_outlined,
                      'Bank',
                      story.bank,
                    ),
                    _buildDetailRow(
                      Icons.payments_outlined,
                      'Loan Amount',
                      '₹${story.loanAmount}',
                    ),
                    if (story.interestRate != null)
                      _buildDetailRow(
                        Icons.percent_outlined,
                        'Interest Rate',
                        story.interestRate!,
                      ),
                    const SizedBox(height: 32),
                    const Text(
                      'Success Story',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      story.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black.withValues(alpha: 0.7),
                        height: 1.6,
                      ),
                    ),
                    if (story.tips != null && story.tips!.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const Text(
                        '💡 My Tips for You',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        story.tips!,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black.withValues(alpha: 0.7),
                          height: 1.6,
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(
                                  context,
                                  '/community/forum/create',
                                  arguments: {
                                    'title':
                                        'Question about ${story.studentName}\'s story at ${story.university}',
                                    'category': 'Loans',
                                    'content':
                                        'I read ${story.studentName}\'s success story and had a few questions regarding the loan process at ${story.bank}...\n\n(Ask your question here)',
                                  },
                                );
                              },
                              icon: const Icon(Icons.help_outline),
                              label: const Text(
                                'Ask Question',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF311B92),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF311B92).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            onPressed: () => _shareStory(story),
                            icon: const Icon(
                              Icons.share_outlined,
                              color: Color(0xFF311B92),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF311B92).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF311B92)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school_outlined;
      case 'payments':
        return Icons.account_balance_wallet_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'groups':
        return Icons.groups_outlined;
      case 'card_membership':
        return Icons.card_membership_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'edit_note':
        return Icons.edit_note_outlined;
      case 'event':
        return Icons.event_outlined;
      case 'flight':
        return Icons.flight_outlined;
      case 'smart_toy':
        return Icons.smart_toy_outlined;
      case 'folder_open':
        return Icons.folder_open_outlined;
      default:
        return Icons.hub_outlined;
    }
  }

  Color _getHubColor(String id) {
    switch (id) {
      case 'loans':
        return const Color(0xFF10B981);
      case 'universities':
        return const Color(0xFF311B92);
      case 'courses':
        return const Color(0xFF6366F1);
      case 'stories':
        return const Color(0xFFF59E0B);
      case 'mentors':
        return const Color(0xFF8B5CF6);
      case 'scholarships':
        return const Color(0xFF14B8A6);
      case 'accommodation':
        return const Color(0xFFEF4444);
      case 'testprep':
        return const Color(0xFF0EA5E9);
      case 'events':
        return const Color(0xFFF97316);
      case 'visa':
        return const Color(0xFF3B82F6);
      case 'aitools':
        return const Color(0xFFEC4899);
      case 'resources':
        return const Color(0xFFD946EF);
      default:
        return const Color(0xFF311B92);
    }
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
}
