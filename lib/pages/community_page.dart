import 'package:flutter/material.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../widgets/institute_selection_modal.dart';
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
  List<Mentor> _mentors = [];
  List<CommunityResource> _resources = [];
  bool _isLoading = true;
  String? _error;

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
      ]);

      if (mounted) {
        setState(() {
          _stories = results[0] as List<SuccessStory>;
          _mentors = results[1] as List<Mentor>;
          _resources = results[2] as List<CommunityResource>;
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Browse Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryScroll(context),
                      const SizedBox(height: 32),
                      _buildFeaturedHeader(
                        'Success Stories',
                        () => _showStoriesModal(context),
                      ),
                      const SizedBox(height: 16),
                      _buildSuccessStoriesList(),
                      const SizedBox(height: 32),
                      _buildFeaturedHeader(
                        'Featured Mentors',
                        () =>
                            Navigator.pushNamed(context, '/community/mentors'),
                      ),
                      const SizedBox(height: 16),
                      _buildMentorsList(),
                      const SizedBox(height: 32),
                      _buildFeaturedHeader(
                        'Popular Resources',
                        () => _showResourcesModal(context),
                      ),
                      const SizedBox(height: 16),
                      _buildResourcesList(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
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
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            padding: EdgeInsets.zero,
          ),
          const Spacer(),
          const Text(
            'Community Hub',
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

  Widget _buildCategoryScroll(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _buildCategoryCard(
            context,
            title: 'Finance',
            subtitle: 'Loans & EMI',
            icon: Icons.account_balance_wallet,
            color: const Color(0xFF10B981),
            onTap: () => Navigator.pushNamed(context, '/apply-loan'),
          ),
          const SizedBox(width: 16),
          _buildCategoryCard(
            context,
            title: 'Universities',
            subtitle: 'Compare & Rank',
            icon: Icons.school,
            color: const Color(0xFF311B92),
            onTap: () => Navigator.pushNamed(context, '/university-compare'),
          ),
          const SizedBox(width: 16),
          _buildCategoryCard(
            context,
            title: 'Mentorship',
            subtitle: 'Connect w/ Alumni',
            icon: Icons.people,
            color: const Color(0xFFF59E0B),
            onTap: () => Navigator.pushNamed(context, '/community/mentors'),
          ),
          const SizedBox(width: 16),
          _buildCategoryCard(
            context,
            title: 'Resources',
            subtitle: 'Guides & Tools',
            icon: Icons.folder_open,
            color: const Color(0xFFE91E63),
            onTap: () => _showResourcesModal(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'See All',
            style: TextStyle(
              color: const Color(0xFF311B92),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStoriesList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_stories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _stories.length > 5 ? 5 : _stories.length,
        itemBuilder: (context, index) {
          final story = _stories[index];
          return _buildStoryCard(story);
        },
      ),
    );
  }

  Widget _buildStoryCard(SuccessStory story) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
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
          Expanded(
            child: Text(
              story.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStoriesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Success Stories',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _stories.length,
                itemBuilder: (context, index) =>
                    _buildStoryCard(_stories[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorsList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_mentors.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _mentors.length,
        itemBuilder: (context, index) {
          final mentor = _mentors[index];
          return _buildMentorCard(mentor);
        },
      ),
    );
  }

  Widget _buildMentorCard(Mentor mentor) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(18),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF311B92).withOpacity(0.15),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF311B92).withOpacity(0.1),
              child: Text(
                mentor.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF311B92),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  mentor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  mentor.role,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF311B92).withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      mentor.rating.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${mentor.studentsMentored})',
                      style: TextStyle(
                        fontSize: 11,
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

  Widget _buildResourcesList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_resources.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _resources.length,
        itemBuilder: (context, index) {
          final resource = _resources[index];
          return _buildResourceCard(resource);
        },
      ),
    );
  }

  Widget _buildResourceCard(CommunityResource resource) {
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
      width: 300,
      margin: const EdgeInsets.only(right: 16),
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

  void _showResourcesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Library Resources',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _resources.length,
                itemBuilder: (context, index) =>
                    _buildResourceCard(_resources[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
