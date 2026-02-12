class Mentor {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? degree;
  final String? country;
  final String? loanBank;
  final String? loanAmount;
  final String? interestRate;
  final String? loanType;
  final String? category;
  final String? linkedIn;
  final String? imageUrl;
  final List<String> expertise;
  final String bio;
  final double hourlyRate;
  final double rating;
  final int totalSessions;
  final int studentsMentored;
  final String? university;
  final bool isApproved;
  final bool isActive;

  Mentor({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.degree,
    this.country,
    this.loanBank,
    this.loanAmount,
    this.interestRate,
    this.loanType,
    this.category,
    this.linkedIn,
    this.imageUrl,
    required this.expertise,
    required this.bio,
    required this.hourlyRate,
    required this.rating,
    required this.totalSessions,
    required this.studentsMentored,
    this.university,
    required this.isApproved,
    required this.isActive,
  });

  factory Mentor.fromJson(Map<String, dynamic> json) {
    return Mentor(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'MENTOR',
      degree: json['degree'],
      country: json['country'],
      loanBank: json['loanBank'],
      loanAmount: json['loanAmount'],
      interestRate: json['interestRate'],
      loanType: json['loanType'],
      category: json['category'],
      linkedIn: json['linkedIn'],
      imageUrl: json['imageUrl'],
      expertise: List<String>.from(json['expertise'] ?? []),
      bio: json['bio'] ?? '',
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalSessions: json['totalSessions'] ?? 0,
      studentsMentored: json['studentsMentored'] ?? 0,
      university: json['university'],
      isApproved: json['isApproved'] ?? false,
      isActive: json['isActive'] ?? true,
    );
  }
}

class CommunityEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String type;
  final String? imageUrl;
  final String organizer;
  final int? maxAttendees;
  final int attendeesCount;
  final double price;
  final bool isOnline;
  final String? meetingLink;

  CommunityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.type,
    this.imageUrl,
    required this.organizer,
    this.maxAttendees,
    required this.attendeesCount,
    required this.price,
    required this.isOnline,
    this.meetingLink,
  });

  factory CommunityEvent.fromJson(Map<String, dynamic> json) {
    return CommunityEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      location: json['location'] ?? 'Online',
      type: json['type'],
      imageUrl:
          json['imageUrl'] ??
          'https://via.placeholder.com/150', // Default image
      organizer: json['organizer'] ?? 'EduLoan',
      maxAttendees: json['maxAttendees'],
      attendeesCount: json['attendeesCount'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isOnline: json['isOnline'] ?? true,
      meetingLink: json['meetingLink'],
    );
  }
}

class SuccessStory {
  final String id;
  final String studentName;
  final String university;
  final String course;
  final String? imageUrl;
  final String? videoUrl;
  final String content;
  final double? loanAmount;
  final bool isFeatured;

  SuccessStory({
    required this.id,
    required this.studentName,
    required this.university,
    required this.course,
    this.imageUrl,
    this.videoUrl,
    required this.content,
    this.loanAmount,
    required this.isFeatured,
  });

  factory SuccessStory.fromJson(Map<String, dynamic> json) {
    return SuccessStory(
      id: json['id'],
      studentName: json['name'] ?? 'Student', // Mapped from 'name'
      university: json['university'],
      course: json['degree'] ?? 'Degree', // Mapped from 'degree'
      imageUrl: json['image'], // Mapped from 'image'
      videoUrl: json['videoUrl'],
      content: json['story'] ?? '', // Mapped from 'story'
      // Parse loanAmount string "4000000" to double safely
      loanAmount: json['loanAmount'] != null
          ? double.tryParse(json['loanAmount'].toString())
          : null,
      isFeatured: json['isFeatured'] ?? false,
    );
  }
}

class ForumPost {
  final String id;
  final String authorId;
  final String? userName;
  final String? userImage;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final bool isMentorOnly;
  final int views;
  final int likes;
  final bool isSolved;
  final DateTime createdAt;
  final int commentCount;

  ForumPost({
    required this.id,
    required this.authorId,
    this.userName,
    this.userImage,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.isMentorOnly,
    required this.views,
    required this.likes,
    required this.isSolved,
    required this.createdAt,
    this.commentCount = 0,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'],
      authorId: json['authorId'],
      userName: json['userName'],
      userImage: json['userImage'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      isMentorOnly: json['isMentorOnly'] ?? false,
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      isSolved: json['isSolved'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      commentCount:
          json['commentCount'] ?? 0, // Often returned by backend aggregations
    );
  }
}

class CommunityResource {
  final String id;
  final String title;
  final String description;
  final String type; // guide, template, checklist, video
  final String category;
  final String? fileUrl;
  final String? downloadUrl;
  final String? thumbnailUrl;
  final int downloads;
  final bool isFeatured;
  final DateTime createdAt;

  CommunityResource({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    this.fileUrl,
    this.downloadUrl,
    this.thumbnailUrl,
    required this.downloads,
    required this.isFeatured,
    required this.createdAt,
  });

  factory CommunityResource.fromJson(Map<String, dynamic> json) {
    return CommunityResource(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      category: json['category'],
      fileUrl: json['fileUrl'],
      downloadUrl: json['downloadUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      downloads: json['downloads'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
