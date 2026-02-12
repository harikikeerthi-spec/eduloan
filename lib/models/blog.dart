class Blog {
  final String id;
  final String title;
  final String slug;
  final String excerpt;
  final String content;
  final String category;
  final String authorName;
  final String? authorImage;
  final String? authorRole;
  final String? featuredImage;
  final int readTime;
  final int views;
  final bool featured;
  final bool published;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final List<String> hashtags;
  final List<Comment> comments;

  Blog({
    required this.id,
    required this.title,
    required this.slug,
    required this.excerpt,
    required this.content,
    required this.category,
    required this.authorName,
    this.authorImage,
    this.authorRole,
    this.featuredImage,
    required this.readTime,
    required this.views,
    required this.featured,
    required this.published,
    this.publishedAt,
    required this.createdAt,
    this.hashtags = const [],
    this.comments = const [],
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      excerpt: json['excerpt'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'General',
      authorName: json['authorName'] ?? 'EduLoan Team',
      authorImage: json['authorImage'],
      authorRole: json['authorRole'],
      featuredImage: json['featuredImage'],
      readTime: json['readTime'] ?? 5,
      views: json['views'] ?? 0,
      featured: json['isFeatured'] ?? json['featured'] ?? false,
      published: json['isPublished'] ?? json['published'] ?? false,
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      hashtags:
          (json['hashtags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      comments:
          (json['comments'] as List<dynamic>?)
              ?.map((e) => Comment.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Comment {
  final String id;
  final String content;
  final String authorName;
  final DateTime createdAt;
  final String? parentId;
  final int likes;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.content,
    required this.authorName,
    required this.createdAt,
    this.parentId,
    this.likes = 0,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['content'],
      authorName: json['author'] ?? json['authorName'] ?? 'Anonymous',
      createdAt: DateTime.parse(json['createdAt']),
      parentId: json['parentId'],
      likes: json['likes'] ?? 0,
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map((e) => Comment.fromJson(e))
              .toList() ??
          [],
    );
  }
}
