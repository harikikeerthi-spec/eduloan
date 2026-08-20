import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/community_service.dart';
import '../widgets/mesh_background.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _hashtagController = TextEditingController();
  final _hashtagFocusNode = FocusNode();
  final CommunityService _communityService = CommunityService();

  String _selectedCategory = 'General';
  bool _isSubmitting = false;
  bool _isCheckingContent = false;
  final List<String> _hashtags = [];
  String? _moderationError;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // These must match the allowedCategories list in the backend controller exactly
  final List<String> _categories = [
    'General',
    'Education Loans',
    'Universities',
    'Courses',
    'Exams',
    'GRE / GMAT',
    'IELTS / TOEFL',
    'Scholarship',
    'Visa & Immigration',
    'Career & Jobs',
  ];

  // Suggested hashtags per category
  static const Map<String, List<String>> _suggestedTags = {
    'General': ['studentlife', 'question', 'help'],
    'Education Loans': ['loan', 'interest', 'emi', 'collateral', 'bank'],
    'Universities': ['admission', 'rankings', 'campus', 'application'],
    'Courses': ['mba', 'ms', 'engineering', 'medical', 'arts'],
    'Exams': ['prep', 'scores', 'registration', 'results'],
    'GRE / GMAT': ['gre', 'gmat', 'quantitative', 'verbal', 'awa'],
    'IELTS / TOEFL': ['ielts', 'toefl', 'speaking', 'writing', 'listening'],
    'Scholarship': ['scholarship', 'grants', 'merit', 'needbased'],
    'Visa & Immigration': ['visa', 'f1', 'studypermit', 'immigration'],
    'Career & Jobs': ['career', 'internship', 'resume', 'placement', 'opt'],
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          if (args.containsKey('title')) {
            _titleController.text = args['title'] as String;
          }
          if (args.containsKey('content')) {
            _contentController.text = args['content'] as String;
          }
          if (args.containsKey('category')) {
            final cat = args['category'] as String;
            if (_categories.contains(cat)) _selectedCategory = cat;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _hashtagController.dispose();
    _hashtagFocusNode.dispose();
    super.dispose();
  }

  // ── Hashtag handling ──────────────────────────────────────────────────────

  void _addHashtag(String raw) {
    String tag = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (tag.isEmpty || _hashtags.contains(tag) || _hashtags.length >= 5) return;
    setState(() {
      _hashtags.add(tag);
      _hashtagController.clear();
    });
  }

  void _removeHashtag(String tag) => setState(() => _hashtags.remove(tag));

  List<String> get _currentSuggestions {
    final all = _suggestedTags[_selectedCategory] ?? [];
    return all.where((t) => !_hashtags.contains(t)).take(4).toList();
  }

  // ── Duplicate / Relevance check ───────────────────────────────────────────

  Future<Map<String, dynamic>?> _checkDuplicateWithAI() async {
    try {
      final result = await _communityService.checkDuplicateQuestion(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
      );
      if (result['success'] == true && result['isDuplicate'] == true) {
        return result;
      }
    } catch (e) {
      debugPrint('Error checking duplicate with AI: $e');
    }
    return null;
  }

  // ── Submission ─────────────────────────────────────────────────────────────

  Future<void> _submitPost({bool skipSimilarityCheck = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _moderationError = null;
    });

    try {
      // 1. Duplicate check
      if (!skipSimilarityCheck) {
        setState(() => _isCheckingContent = true);
        final duplicateResult = await _checkDuplicateWithAI();
        setState(() => _isCheckingContent = false);

        if (duplicateResult != null && mounted) {
          setState(() => _isSubmitting = false);

          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF6605C7)),
                  SizedBox(width: 10),
                  Text('Similar Question Found'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A similar question has already been asked: '
                    '"${duplicateResult['similarPostTitle']}"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (duplicateResult['similarPostContent'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6605C7).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        duplicateResult['similarPostContent'],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'Would you like to view it instead of posting a new one?',
                  ),
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
                    Navigator.pushReplacementNamed(
                      context,
                      '/community/forum/detail',
                      arguments: duplicateResult['similarPostId'],
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

      // 2. Create post (backend will AI-moderate content)
      await _communityService.createForumPost(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        tags: _hashtags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Post published successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF6605C7),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      final errStr = e.toString();
      // Check if it's a content moderation rejection
      if (errStr.contains('CONTENT_NOT_RELEVANT') ||
          errStr.contains('off-topic') ||
          errStr.contains('not published because')) {
        // Extract the human-readable message
        final msgMatch = RegExp(r'"message":"([^"]+)"').firstMatch(errStr);
        setState(() {
          _moderationError =
              msgMatch?.group(1) ??
              'Your post appears to be off-topic for this platform. '
                  'Please post about education, loans, universities, scholarships, or study abroad.';
          _isSubmitting = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tip banner
                          _buildTipBanner(),
                          const SizedBox(height: 20),

                          // Title
                          _buildLabel('Title', Icons.title),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _titleController,
                            hint: "What's on your mind?",
                            maxLines: 1,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter a title'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Description
                          _buildLabel('Description', Icons.notes),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _contentController,
                            hint: 'Share more details about your question...',
                            maxLines: 5,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter a description'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Category
                          _buildLabel('Category', Icons.category_outlined),
                          const SizedBox(height: 8),
                          _buildCategoryDropdown(),
                          const SizedBox(height: 20),

                          // Hashtags
                          _buildLabel('Hashtags', Icons.tag, optional: true),
                          const SizedBox(height: 4),
                          Text(
                            'Add up to 5 tags to help others find your post',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildHashtagInput(),
                          if (_hashtags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildHashtagChips(),
                          ],
                          if (_currentSuggestions.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildSuggestedTags(),
                          ],
                          const SizedBox(height: 24),

                          // Moderation error
                          if (_moderationError != null) _buildModerationError(),

                          // Submit
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 22),
          ),
          const Expanded(
            child: Text(
              'New Discussion',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTipBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6605C7).withValues(alpha: 0.08),
            const Color(0xFF311B92).withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6605C7).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF6605C7), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI-Powered Community',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6605C7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Posts are AI-reviewed before publishing. Keep discussions relevant to education, loans, universities, scholarships, or study abroad.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.55),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, IconData icon, {bool optional = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6605C7)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Text(
            '(optional)',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.3),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6605C7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButton<String>(
        value: _selectedCategory,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF6605C7),
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
        items: _categories.map((cat) {
          return DropdownMenuItem(value: cat, child: Text(cat));
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _selectedCategory = val;
              // Clear hashtags when category changes so suggestions update
            });
          }
        },
      ),
    );
  }

  Widget _buildHashtagInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6605C7).withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _hashtagController,
                    focusNode: _hashtagFocusNode,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9_]'),
                      ),
                      LengthLimitingTextInputFormatter(30),
                    ],
                    decoration: InputDecoration(
                      hintText: 'type a tag and press Add',
                      hintStyle: TextStyle(
                        color: Colors.black.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _addHashtag,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            if (_hashtagController.text.trim().isNotEmpty) {
              _addHashtag(_hashtagController.text);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF6605C7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Add',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHashtagChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _hashtags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6605C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#$tag',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _removeHashtag(tag),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSuggestedTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested',
          style: TextStyle(
            fontSize: 11,
            color: Colors.black.withValues(alpha: 0.4),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _currentSuggestions
              .map(
                (tag) => GestureDetector(
                  onTap: () => _addHashtag(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6605C7).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF6605C7).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 12,
                          color: const Color(0xFF6605C7).withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '#$tag',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6605C7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildModerationError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.block, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Post Not Allowed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _moderationError!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _moderationError = null),
            child: const Icon(Icons.close, size: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_isSubmitting || _isCheckingContent) ? null : _submitPost,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6605C7),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(
            0xFF6605C7,
          ).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting || _isCheckingContent
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isCheckingContent
                        ? 'Checking for duplicates...'
                        : 'Publishing...',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Analyze & Publish',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
