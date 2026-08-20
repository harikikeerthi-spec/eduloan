import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../widgets/mesh_background.dart';

class ForumPostDetailPage extends StatefulWidget {
  const ForumPostDetailPage({super.key});

  @override
  State<ForumPostDetailPage> createState() => _ForumPostDetailPageState();
}

class _ForumPostDetailPageState extends State<ForumPostDetailPage> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _commentController = TextEditingController();

  ForumPost? _post;
  bool _isLoading = true;
  String? _error;
  String? _replyingToCommentId;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_post == null) {
      final postId = ModalRoute.of(context)!.settings.arguments as String;
      _loadPost(postId);
    }
  }

  // ... (existing methods)

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await _communityService.deleteForumComment(commentId);
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
        }
        _loadPost(_post!.id); // Reload to remove comment
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
      }
    }
  }

  Widget _buildCommentTile(ForumComment comment, {int depth = 0}) {
    final isAuthor =
        _currentUserId != null && comment.authorId == _currentUserId;

    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[200],
                child: Text(
                  comment.authorName.isNotEmpty
                      ? comment.authorName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(comment.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                        ),
                        if (isAuthor) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _deleteComment(comment.id),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleLikeComment(comment.id),
                          child: Row(
                            children: [
                              Icon(
                                comment.liked
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                size: 14,
                                color: comment.liked
                                    ? const Color(0xFF6605C7)
                                    : Colors.black.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likes}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: comment.liked
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: comment.liked
                                      ? const Color(0xFF6605C7)
                                      : Colors.black.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _replyingToCommentId = comment.id;
                            });
                          },
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(
                                0xFF6605C7,
                              ).withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty)
            ...comment.replies.map(
              (reply) => _buildCommentTile(reply, depth: depth + 1),
            ),
        ],
      ),
    );
  }

  Future<void> _loadPost(String id) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final post = await _communityService.getForumPostById(id);
      if (mounted) {
        setState(() {
          _post = post;
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

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final result = await _communityService.addForumComment(
        postId: _post!.id,
        content: _commentController.text.trim(),
        parentId: _replyingToCommentId,
      );

      if (result['success'] == true) {
        _commentController.clear();
        setState(() {
          _replyingToCommentId = null;
        });
        _loadPost(_post!.id); // Reload to show new comment
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post comment: $e')));
      }
    }
  }

  Future<void> _toggleLikePost() async {
    if (_post == null) return;
    try {
      final result = await _communityService.likeForumPost(_post!.id);
      if (result['success'] == true) {
        _loadPost(_post!.id); // Reload to update like count
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to like post: $e')));
      }
    }
  }

  Future<void> _toggleLikeComment(String commentId) async {
    try {
      final result = await _communityService.likeForumComment(commentId);
      if (result['success'] == true) {
        _loadPost(_post!.id); // Reload to update like count
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to like comment: $e')));
      }
    }
  }

  void _sharePost() {
    if (_post == null) return;

    final String text =
        'Check out this discussion on Vidya Loan: ${_post!.title}\n\n'
        '${_post!.content}\n\n'
        'Join the community at Vidya Loan!';

    Share.share(text, subject: _post!.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(child: _buildBody()),
              _buildCommentInput(),
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
          Container(
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
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          const Text(
            'Discussion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_post == null) return const Center(child: Text('Post not found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPostHeader(),
                const SizedBox(height: 16),
                Text(
                  _post!.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _post!.content,
                  style: TextStyle(
                    fontSize: 15,
                    color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildActionItem(
                      _post!.liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      '${_post!.likes}',
                      color: _post!.liked ? const Color(0xFF6605C7) : null,
                      onTap: _toggleLikePost,
                    ),
                    const SizedBox(width: 24),
                    _buildActionItem(
                      Icons.chat_bubble_outline,
                      '${_post!.commentCount}',
                    ),
                    const SizedBox(width: 24),
                    _buildActionItem(
                      Icons.share_outlined,
                      'Share',
                      onTap: _sharePost,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Discussion',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6605C7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_post!.commentCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6605C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._post!.comments.map((comment) => _buildCommentTile(comment)),
          const SizedBox(height: 100), // Space for input field
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF6605C7).withValues(alpha: 0.1),
          child: Text(
            (_post!.userName?.isNotEmpty ?? false)
                ? _post!.userName![0].toUpperCase()
                : 'U',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6605C7),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _post!.userName ?? 'Anonymous',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              _formatDate(_post!.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6605C7).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _post!.category,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6605C7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToCommentId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    'Replying to comment',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _replyingToCommentId = null),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: const Color(0xFF6605C7),
                child: IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
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

  Widget _buildActionItem(
    IconData icon,
    String label, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final activeColor = color ?? Colors.black.withValues(alpha: 0.6);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: activeColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: activeColor,
              fontWeight: color != null ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
