import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
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
  final Map<String, TextEditingController> _replyControllers = {};
  bool _isSubmitting = false;
  String _authorName = 'Guest User';
  String _deviceId = '';
  Set<String> _likedComments = {};
  String? _replyingToCommentId;

  @override
  void dispose() {
    _commentController.dispose();
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDeviceId();
    // Fetch fresh data including content using the slug
    _blogFuture = _blogService.getBlogBySlug(widget.blog.slug);
  }

  Future<void> _loadDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId == null) {
      // Generate a simple device ID based on timestamp
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('device_id', deviceId);
    }

    setState(() {
      _deviceId = deviceId!;
    });

    if (mounted) {
      final likes = await _blogService.getLikedComments(_deviceId);
      setState(() {
        _likedComments = likes.toSet();
      });
    }
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
                                            .withValues(alpha: 0.05),
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
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
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
                                const Divider(thickness: 1),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.comment_outlined,
                                      color: Color(0xFF311B92),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Comments (${blog.comments.length})',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF311B92),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Add Comment Section
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF311B92,
                                        ).withValues(alpha: 0.05),
                                        const Color(
                                          0xFF7E57C2,
                                        ).withValues(alpha: 0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF311B92,
                                      ).withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: const Color(
                                              0xFF311B92,
                                            ),
                                            child: Text(
                                              _authorName.isNotEmpty
                                                  ? _authorName[0].toUpperCase()
                                                  : 'G',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Share your thoughts',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                'Posting as $_authorName',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          controller: _commentController,
                                          decoration: InputDecoration(
                                            hintText: 'Write your thoughts...',
                                            hintStyle: TextStyle(
                                              color: Colors.grey[400],
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 14,
                                                ),
                                          ),
                                          maxLines: 4,
                                          minLines: 3,
                                        ),
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
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 2,
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
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.send, size: 18),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Post Comment',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (blog.comments.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            size: 64,
                                            color: Colors.grey[300],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No comments yet',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Be the first to share your thoughts!',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ...blog.comments
                                      .where(
                                        (comment) => comment.parentId == null,
                                      )
                                      .map(
                                        (comment) => Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.withValues(
                                                alpha: 0.2,
                                              ),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.03,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 20,
                                                    backgroundColor:
                                                        const Color(
                                                          0xFF311B92,
                                                        ).withValues(
                                                          alpha: 0.1,
                                                        ),
                                                    child: Text(
                                                      comment
                                                              .authorName
                                                              .isNotEmpty
                                                          ? comment
                                                                .authorName[0]
                                                                .toUpperCase()
                                                          : '?',
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF311B92,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          comment.authorName,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 15,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.access_time,
                                                              size: 12,
                                                              color: Colors
                                                                  .grey[500],
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              '${comment.createdAt.day}/${comment.createdAt.month}/${comment.createdAt.year}',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .grey[600],
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Delete button - only show for user's own comments
                                                  if (comment.authorName ==
                                                      _authorName)
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                        size: 20,
                                                      ),
                                                      color: Colors.red[400],
                                                      onPressed: () =>
                                                          _deleteComment(
                                                            blog.id,
                                                            comment.id,
                                                          ),
                                                      tooltip: 'Delete comment',
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.withValues(
                                                    alpha: 0.05,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  comment.content,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    height: 1.5,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              // Like and Reply buttons
                                              Row(
                                                children: [
                                                  // Like button
                                                  InkWell(
                                                    onTap: () => _toggleLike(
                                                      blog.id,
                                                      comment.id,
                                                      comment.likes,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          _likedComments
                                                                  .contains(
                                                                    comment.id,
                                                                  )
                                                              ? Icons.favorite
                                                              : Icons
                                                                    .favorite_border,
                                                          size: 18,
                                                          color:
                                                              _likedComments
                                                                  .contains(
                                                                    comment.id,
                                                                  )
                                                              ? Colors.red
                                                              : Colors
                                                                    .grey[600],
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '${comment.likes}',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  // Reply button
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        if (_replyingToCommentId ==
                                                            comment.id) {
                                                          _replyingToCommentId =
                                                              null;
                                                        } else {
                                                          _replyingToCommentId =
                                                              comment.id;
                                                          _replyControllers[comment
                                                                  .id] ??=
                                                              TextEditingController();
                                                        }
                                                      });
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.reply,
                                                          size: 18,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          'Reply',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Reply input field
                                              if (_replyingToCommentId ==
                                                  comment.id)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 12,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextField(
                                                          controller:
                                                              _replyControllers[comment
                                                                  .id],
                                                          decoration: InputDecoration(
                                                            hintText:
                                                                'Reply to ${comment.authorName}...',
                                                            hintStyle: TextStyle(
                                                              color: Colors
                                                                  .grey[400],
                                                            ),
                                                            filled: true,
                                                            fillColor:
                                                                Colors.grey[50],
                                                            border: OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              borderSide:
                                                                  BorderSide
                                                                      .none,
                                                            ),
                                                            contentPadding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 8,
                                                                ),
                                                          ),
                                                          maxLines: 2,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      IconButton(
                                                        onPressed: () =>
                                                            _submitReply(
                                                              comment.id,
                                                            ),
                                                        icon: const Icon(
                                                          Icons.send,
                                                        ),
                                                        color: const Color(
                                                          0xFF311B92,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              // Display nested replies
                                              if (comment.replies.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 16,
                                                        top: 12,
                                                      ),
                                                  child: Column(
                                                    children: comment.replies.map((
                                                      reply,
                                                    ) {
                                                      return Container(
                                                        margin:
                                                            const EdgeInsets.only(
                                                              bottom: 8,
                                                            ),
                                                        padding:
                                                            const EdgeInsets.all(
                                                              12,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors.grey[100],
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                CircleAvatar(
                                                                  radius: 12,
                                                                  backgroundColor:
                                                                      const Color(
                                                                        0xFF311B92,
                                                                      ),
                                                                  child: Text(
                                                                    reply
                                                                        .authorName[0]
                                                                        .toUpperCase(),
                                                                    style: const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          10,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        reply
                                                                            .authorName,
                                                                        style: const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              12,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        'Replying to @${comment.authorName}',
                                                                        style: const TextStyle(
                                                                          fontSize:
                                                                              11,
                                                                          color: Color(
                                                                            0xFF311B92,
                                                                          ),
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                // Delete button for user's own replies
                                                                if (reply
                                                                        .authorName ==
                                                                    _authorName)
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .delete_outline,
                                                                      size: 16,
                                                                    ),
                                                                    color: Colors
                                                                        .red[400],
                                                                    onPressed: () =>
                                                                        _deleteComment(
                                                                          blog.id,
                                                                          reply
                                                                              .id,
                                                                        ),
                                                                    tooltip:
                                                                        'Delete reply',
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    constraints:
                                                                        const BoxConstraints(),
                                                                  ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              reply.content,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
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
      // If this is a local fallback blog (no backend entry), simulate comment locally
      if (blogId.startsWith('blog_') || blogId.length < 20) {
        await Future.delayed(const Duration(milliseconds: 500));
        final newComment = Comment(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          content: content,
          authorName: _authorName,
          createdAt: DateTime.now(),
          likes: 0,
        );
        final currentBlog = await _blogFuture;
        final updatedComments = [...currentBlog.comments, newComment];
        final updatedBlog = Blog(
          id: currentBlog.id,
          title: currentBlog.title,
          slug: currentBlog.slug,
          excerpt: currentBlog.excerpt,
          content: currentBlog.content,
          category: currentBlog.category,
          authorName: currentBlog.authorName,
          authorImage: currentBlog.authorImage,
          authorRole: currentBlog.authorRole,
          featuredImage: currentBlog.featuredImage,
          readTime: currentBlog.readTime,
          views: currentBlog.views,
          featured: currentBlog.featured,
          published: currentBlog.published,
          publishedAt: currentBlog.publishedAt,
          createdAt: currentBlog.createdAt,
          hashtags: currentBlog.hashtags,
          comments: updatedComments,
        );
        setState(() {
          _blogFuture = Future.value(updatedBlog);
          _commentController.clear();
          _isSubmitting = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment posted!')),
          );
        }
        return;
      }

      await _blogService.addComment(
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

  Future<void> _deleteComment(String blogId, String commentId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _blogService.deleteComment(commentId);

      // Refresh the blog data to remove the deleted comment
      final updatedBlog = await _blogService.getBlogBySlug(widget.blog.slug);

      setState(() {
        _blogFuture = Future.value(updatedBlog);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting comment: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleLike(
    String blogId,
    String commentId,
    int currentLikes,
  ) async {
    if (_deviceId.isEmpty) return;

    // Optimistically update UI immediately
    final bool wasLiked = _likedComments.contains(commentId);
    setState(() {
      if (wasLiked) {
        _likedComments.remove(commentId);
      } else {
        _likedComments.add(commentId);
      }
    });

    try {
      await _blogService.toggleCommentLike(commentId, _deviceId);

      // Refresh blog data to get updated like counts from server
      final updatedBlog = await _blogService.getBlogBySlug(widget.blog.slug);
      setState(() {
        _blogFuture = Future.value(updatedBlog);
      });
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        if (wasLiked) {
          _likedComments.add(commentId);
        } else {
          _likedComments.remove(commentId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling like: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitReply(String commentId) async {
    final controller = _replyControllers[commentId];
    if (controller == null || controller.text.trim().isEmpty) return;

    try {
      await _blogService.addReplyToComment(
        commentId,
        _authorName,
        controller.text.trim(),
      );

      controller.clear();
      setState(() {
        _replyingToCommentId = null;
      });

      // Refresh blog data to show new reply
      final updatedBlog = await _blogService.getBlogBySlug(widget.blog.slug);
      setState(() {
        _blogFuture = Future.value(updatedBlog);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding reply: ${e.toString()}')),
        );
      }
    }
  }

  void _shareBlog() {
    final blogTitle = widget.blog.title;
    final blogExcerpt = widget.blog.excerpt;
    final shareText =
        '''
Check out this blog: $blogTitle

$blogExcerpt

Read more on VidyaLoan app!
''';
    Share.share(shareText);
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
            onPressed: _shareBlog,
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
    );
  }
}
