import 'package:flutter/material.dart';
import '../widgets/mesh_background.dart';
import '../services/blog_service.dart';
import '../models/blog.dart';
import 'blog_detail_page.dart';

class BlogsPage extends StatefulWidget {
  const BlogsPage({super.key});

  @override
  State<BlogsPage> createState() => _BlogsPageState();
}

class _BlogsPageState extends State<BlogsPage> {
  final BlogService _blogService = BlogService();
  late Future<List<Blog>> _blogsFuture;
  List<Blog> _allBlogs = [];
  List<Blog> _filteredBlogs = [];
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Education Loans',
    'Study Abroad',
    'Financial Tips',
    'Success Stories',
  ];

  @override
  void initState() {
    super.initState();
    _blogsFuture = _blogService.getAllBlogs();
    _loadBlogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBlogs() async {
    try {
      final blogs = await _blogService.getAllBlogs();
      setState(() {
        _allBlogs = blogs;
        _filteredBlogs = blogs;
      });
    } catch (e) {
      // Error handling is done in FutureBuilder
    }
  }

  void _filterBlogs() {
    setState(() {
      _filteredBlogs = _allBlogs.where((blog) {
        // Filter by category
        bool matchesCategory =
            _selectedCategory == null ||
            _selectedCategory == 'All' ||
            blog.category == _selectedCategory;

        // Filter by search query
        bool matchesSearch =
            _searchQuery.isEmpty ||
            blog.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            blog.excerpt.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            blog.category.toLowerCase().contains(_searchQuery.toLowerCase());

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _filterByCategory(String? category) {
    _selectedCategory = category;
    _filterBlogs();
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _filterBlogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildSearchBar(),
              _buildCategoryChips(),
              Expanded(
                child: FutureBuilder<List<Blog>>(
                  future: _blogsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No blogs found.'));
                    }

                    // Use filtered blogs instead of all blogs
                    final blogsToDisplay =
                        _filteredBlogs.isEmpty && _selectedCategory != null
                        ? []
                        : _filteredBlogs;

                    if (blogsToDisplay.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No blogs found in this category',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: blogsToDisplay.length,
                      itemBuilder: (context, index) {
                        final blog = blogsToDisplay[index];
                        return _buildBlogCard(context, blog);
                      },
                    );
                  },
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
            'Blogs & Stories',
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search blogs by title, category...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF311B92)),
            suffixIcon:
                _searchQuery.isNotEmpty ||
                    (_selectedCategory != null && _selectedCategory != 'All')
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _searchQuery = '';
                      _filterByCategory('All');
                    },
                    color: Colors.grey[600],
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected =
              _selectedCategory == category ||
              (_selectedCategory == null && category == 'All');

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                _filterByCategory(selected ? category : 'All');
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF311B92).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF311B92),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF311B92) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF311B92)
                    : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 1.5 : 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlogCard(BuildContext context, Blog blog) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BlogDetailPage(blog: blog)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (blog.featuredImage != null && blog.featuredImage!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: blog.featuredImage!.startsWith('http')
                  ? Image.network(
                  blog.featuredImage!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF311B92).withValues(alpha: 0.1),
                            const Color(0xFF7E57C2).withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 48,
                              color: Color(0xFF311B92),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Blog Image',
                              style: TextStyle(
                                color: Color(0xFF311B92),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
                  : Image.asset(
                  blog.featuredImage!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF311B92).withValues(alpha: 0.1),
                            const Color(0xFF7E57C2).withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 48,
                              color: Color(0xFF311B92),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Blog Image',
                              style: TextStyle(
                                color: Color(0xFF311B92),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF311B92),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blog.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blog.excerpt,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: blog.authorImage != null
                            ? NetworkImage(blog.authorImage!)
                            : null,
                        child: blog.authorImage == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        blog.authorName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${blog.readTime} min read',
                        style: TextStyle(
                          fontSize: 12,
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
      ),
    );
  }
}
