import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blog.dart';
import '../services/blog_service.dart';
import '../widgets/mesh_background.dart';

class BlogDetailPage extends StatefulWidget {
  final Blog blog;

  const BlogDetailPage({super.key, required this.blog});

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  late Future<Blog> _blogFuture;
  final BlogService _blogService = BlogService();
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String _authorName = 'Guest User';

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Fetch fresh data including content using the slug
    _blogFuture = _blogService.getBlogBySlug(widget.blog.slug);
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = prefs.getString('user_firstName');
    final lastName = prefs.getString('user_lastName');

    if (firstName != null && firstName.isNotEmpty) {
      setState(() {
        _authorName = '$firstName ${lastName ?? ''}'.trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: FutureBuilder<Blog>(
            future: _blogFuture,
            initialData: widget.blog,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // In production, we should probably show a retry button or snackbar
                debugPrint('Error loading blog content: ${snapshot.error}');
              }
              // Even if error, we can show widget.blog (which has initial data)
              final blog = snapshot.data ?? widget.blog;

              return Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (blog.featuredImage != null)
                            Image.network(
                              blog.featuredImage!,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox(
                                    height: 250,
                                    child: Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF311B92,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    blog.category,
                                    style: const TextStyle(
                                      color: Color(0xFF311B92),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  blog.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (blog.hashtags.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: blog.hashtags.map((tag) {
                                      return Chip(
                                        label: Text('#$tag'),
                                        backgroundColor: Colors.deepPurple
                                            .withOpacity(0.05),
                                        labelStyle: const TextStyle(
                                          color: Colors.deepPurple,
                                          fontSize: 12,
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      );
                                    }).toList(),
                                  ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: blog.authorImage != null
                                          ? NetworkImage(blog.authorImage!)
                                          : null,
                                      child: blog.authorImage == null
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          blog.authorName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${blog.readTime} min read',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                // Show loading if waiting AND content is empty
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    blog.content.isEmpty)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else
                                  Html(
                                    data: blog.content,
                                    style: {
                                      "body": Style(
                                        fontSize: FontSize(16),
                                        lineHeight: LineHeight(1.6),
                                        color: Colors.black87,
                                      ),
                                      "h2": Style(
                                        fontSize: FontSize(20),
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF311B92),
                                        margin: Margins.only(
                                          top: 24,
                                          bottom: 12,
                                        ),
                                      ),
                                      "p": Style(
                                        margin: Margins.only(bottom: 16),
                                      ),
                                    },
                                  ),
                                const SizedBox(height: 32),
                                const Divider(),
                                const SizedBox(height: 16),
                                Text(
                                  'Comments (${blog.comments.length})',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Add Comment Section
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Leave a comment',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _commentController,
                                        decoration: const InputDecoration(
                                          hintText: 'Write your thoughts...',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                        ),
                                        maxLines: 3,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : () => _submitComment(blog.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF311B92,
                                          ),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: _isSubmitting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Text('Post Comment'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (blog.comments.isEmpty)
                                  const Text(
                                    'No comments yet. Be the first to comment!',
                                    style: TextStyle(color: Colors.grey),
                                  )
                                else
                                  ...blog.comments.map(
                                    (comment) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                child: Text(
                                                  comment.authorName.isNotEmpty
                                                      ? comment.authorName[0]
                                                            .toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                comment.authorName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${comment.createdAt.day}/${comment.createdAt.month}/${comment.createdAt.year}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 40,
                                            ),
                                            child: Text(comment.content),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submitComment(String blogId) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final newComment = await _blogService.addComment(
        blogId,
        content,
        _authorName,
      );

      // Refresh the blog data to show the new comment
      final updatedBlog = await _blogService.getBlogBySlug(widget.blog.slug);

      setState(() {
        _blogFuture = Future.value(updatedBlog);
        _commentController.clear();
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
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
          IconButton(
            onPressed: () {
              // Share functionality placeholder
            },
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
    );
  }
}
