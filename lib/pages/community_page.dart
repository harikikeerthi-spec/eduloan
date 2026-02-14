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
  bool _isLoading = true;
  String? _error;
  String? _activeCategory;

  List<Map<String, dynamic>> _hubs = [];

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
      ]);

      if (mounted) {
        setState(() {
          _stories = results[0] as List<SuccessStory>;
          _resources = results[2] as List<CommunityResource>;
          _hubs = results[3] as List<Map<String, dynamic>>;
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
        'Check out ${story.studentName}\'s success story on VidhyaLoan!\n\n'
        'Student: ${story.studentName}\n'
        'University: ${story.university}\n'
        'Loan Amount: ₹${story.loanAmount}\n\n'
        'Story: ${story.content}\n\n'
        'Join the community at VidhyaLoan!';

    Share.share(text, subject: 'Success Story: ${story.studentName}');
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

    final List<Map<String, dynamic>> items = [
      ..._hubs.map(
        (hub) => {
          'title': hub['title'] ?? hub['id'],
          'desc': hub['description'] ?? '',
          'icon': _getIconData(hub['icon']),
          'color': _getHubColor(hub['id']),
          'route': '/community/forum',
          'argument': {
            'category': hub['id'],
            'title': hub['title'],
            'hideFilters': false,
          },
        },
      ),
      {
        'title': 'Success Stories',
        'desc': 'Real student journeys, mistakes, and triumph reports.',
        'icon': Icons.auto_stories_outlined,
        'color': const Color(0xFFEC4899),
        'action': 'stories',
      },
      {
        'title': 'Events & AMAs',
        'desc': 'Live sessions with banks, alumni, and industry experts.',
        'icon': Icons.calendar_today_outlined,
        'color': const Color(0xFFF97316),
        'action': 'events',
      },
      {
        'title': 'Resources',
        'desc': 'Download free guides, checklists, and templates.',
        'icon': Icons.folder_outlined,
        'color': const Color(0xFF64748B),
        'action': 'resources',
      },
    ];

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
            color: Colors.black.withOpacity(0.5),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGridCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        if (category.containsKey('route')) {
          Navigator.pushNamed(
            context,
            category['route'],
            arguments: category['argument'],
          );
        } else if (category.containsKey('action')) {
          setState(() {
            _activeCategory = category['title'];
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16), // Reduced padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF311B92).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (category['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(category['icon'], color: category['color'], size: 28),
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
                color: Colors.black.withOpacity(0.4),
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
            color: const Color(0xFF311B92).withOpacity(0.08),
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
              color: color.withOpacity(0.1),
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
                      color: Colors.black.withOpacity(0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${resource.downloads} downloads',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.5),
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
              color: const Color(0xFF311B92).withOpacity(0.08),
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
                  backgroundColor: Colors.green.withOpacity(0.1),
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
                          color: Colors.black.withOpacity(0.6),
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
                    color: Colors.black.withOpacity(0.5),
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
                color: Colors.black.withOpacity(0.7),
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
                    color: Colors.black.withOpacity(0.4),
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
                          backgroundColor: Colors.green.withOpacity(0.1),
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
                                  color: Colors.black.withOpacity(0.6),
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
                        color: Colors.black.withOpacity(0.7),
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
                          color: Colors.black.withOpacity(0.7),
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
                            color: const Color(0xFF311B92).withOpacity(0.05),
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
              color: const Color(0xFF311B92).withOpacity(0.05),
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
                  color: Colors.black.withOpacity(0.5),
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
      case 'assignment':
        return Icons.assignment_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'airplanemode_active':
        return Icons.airplanemode_active_outlined;
      case 'psychology':
        return Icons.psychology_outlined;
      default:
        return Icons.hub_outlined;
    }
  }

  Color _getHubColor(String id) {
    switch (id) {
      case 'eligibility':
        return const Color(0xFF10B981);
      case 'universities':
        return const Color(0xFF311B92);
      case 'courses':
        return const Color(0xFF6366F1);
      case 'visa':
        return const Color(0xFF0EA5E9);
      case 'testprep':
        return const Color(0xFF3B82F6);
      case 'accommodation':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF311B92);
    }
  }
}
