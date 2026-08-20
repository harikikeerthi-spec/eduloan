import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/blog.dart';
import 'api_config.dart';

class BlogService {
  static final List<Blog> _fallbackBlogs = [
    Blog(
      id: 'blog_1',
      title:
          'Complete Guide to Collateral vs Non-Collateral Study Loans in 2026',
      slug: 'collateral-vs-non-collateral-loans-2026',
      excerpt:
          'Understand key differences between secured loans with property collateral and unsecured education loans from top banks and NBFCs.',
      content:
          'Choosing the right education loan model is a critical milestone for study abroad aspirants. Collateral loans (secured) typically offer lower interest rates (starting at 8.55%) with higher loan amounts up to ₹1.5 Crores. Non-collateral loans (unsecured) rely heavily on co-applicant income, GRE scores, and university ranking, offering hassle-free processing without property pledge.\n\nKey Highlights:\n- Government Banks (SBI, Union Bank) require collateral for loans above ₹7.5 Lakhs.\n- Private NBFCs (HDFC Credila, Auxilo, Avanse) offer non-collateral loans up to ₹75 Lakhs for STEM programs.\n- Consider processing fees, margin money, and moratorium repayment structures before deciding.',
      category: 'Education Loans',
      authorName: 'Priya Sharma',
      authorRole: 'Senior Financial Advisor',
      featuredImage:
          'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=800',
      readTime: 6,
      views: 1240,
      featured: true,
      published: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      hashtags: ['EducationLoan', 'Collateral', 'StudyAbroad'],
    ),
    Blog(
      id: 'blog_2',
      title: 'US F-1 Visa Interview Questions & Expert Preparation Tips',
      slug: 'us-f1-visa-interview-tips-2026',
      excerpt:
          'Master your F-1 student visa interview with real officer questions, financial proof documentation, and mock interview practice.',
      content:
          'The US F-1 visa interview lasts between 2 to 3 minutes, but thorough preparation makes all the difference. Visa officers focus on three primary pillars: Intent to Study, Financial Capability, and Ties to Home Country.\n\nTop Questions Asked:\n1. Why did you choose this specific university in the US?\n2. Who is funding your education and what is their annual income?\n3. How do you plan to repay your education loan after graduation?\n\nTip: Be confident, concise, and ensure your I-20 details match your loan sanction letter exactly.',
      category: 'Study Abroad',
      authorName: 'Vikram Malhotra',
      authorRole: 'Study Abroad Specialist',
      featuredImage:
          'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800',
      readTime: 8,
      views: 2850,
      featured: true,
      published: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      hashtags: ['F1Visa', 'USAdmissions', 'InterviewTips'],
    ),
    Blog(
      id: 'blog_3',
      title: 'How to Save Up to ₹2 Lakhs on FX Rates & Remittance Fees',
      slug: 'save-fx-rates-remittance-fees',
      excerpt:
          'Learn smart international money transfer hacks, forex cards, and zero-markup transfer methods for university tuition deposits.',
      content:
          'Paying international tuition fees through traditional wire transfers can incur hidden bank markups ranging from 1.5% to 3.5%. By utilizing pre-negotiated Forex rate locks, Education Loan direct transfers, and GST tax rebates (TCS refund under Section 206C), students can save up to ₹2,00,000 across their entire degree.\n\nSmart Tips:\n- Use VidyaLoan FX partner portals for guaranteed lower exchange rates.\n- Claim Tax Collected at Source (TCS) during annual Income Tax Return filing.\n- Use forex student multi-currency travel cards for initial campus arrival expenses.',
      category: 'Financial Tips',
      authorName: 'Ananya Roy',
      authorRole: 'Forex & Remittance Analyst',
      featuredImage:
          'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?w=800',
      readTime: 5,
      views: 940,
      featured: false,
      published: true,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      hashtags: ['Forex', 'Remittance', 'StudentSavings'],
    ),
    Blog(
      id: 'blog_4',
      title: 'From Tier-3 College to MS in Computer Science at UT Dallas',
      slug: 'success-story-ut-dallas-ms-cs',
      excerpt:
          'Read Rahul’s journey of securing a ₹45 Lakh 100% non-collateral loan and securing a STEM assistantship in Texas.',
      content:
          'Rahul came from a tier-3 engineering college with high ambitions to pursue MS in CS in the United States. Without collateral property, obtaining loan approval seemed challenging. Through VidyaLoan AI profile evaluator, Rahul was matched with an NBFC that recognized his 320 GRE score and offered a ₹45 Lakh loan sanction in just 4 days.\n\n"VidyaLoan simplified the entire process — from loan approval to visa prep. I am now working as a Teaching Assistant at UT Dallas!" says Rahul.',
      category: 'Success Stories',
      authorName: 'Rahul Verma',
      authorRole: 'VidyaLoan Alumni & UT Dallas MS CS',
      featuredImage:
          'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=800',
      readTime: 7,
      views: 3400,
      featured: true,
      published: true,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      hashtags: ['SuccessStory', 'UTDallas', 'EducationLoan'],
    ),
    Blog(
      id: 'blog_5',
      title:
          'Section 80E Tax Deduction: Maximize Education Loan Interest Relief',
      slug: 'section-80e-tax-deduction-guide',
      excerpt:
          'Everything you need to know about claiming 100% tax deduction on education loan interest payments under Income Tax Act.',
      content:
          'Under Section 80E of the Indian Income Tax Act, education loan borrowers or their parent co-applicants can claim 100% deduction on the interest paid towards higher education loans. There is NO upper ceiling limit on the deductible interest amount, making education loans significantly more tax-efficient than liquidating personal savings.',
      category: 'Education Loans',
      authorName: 'CA Rajesh Nambiar',
      authorRole: 'Tax & Education Loan Consultant',
      featuredImage:
          'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800',
      readTime: 4,
      views: 1120,
      featured: false,
      published: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      hashtags: ['TaxSavings', 'Section80E', 'Eduloan'],
    ),
  ];

  Future<List<Blog>> getAllBlogs() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await ApiClient.get(Uri.parse('$baseUrl/blogs'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];
          final list = data.map((json) => Blog.fromJson(json)).toList();
          if (list.isNotEmpty) return list;
        }
      }
    } catch (e) {
      debugPrint('Error fetching blogs from API: $e');
    }
    return _fallbackBlogs;
  }

  Future<List<Blog>> getFeaturedBlogs({int limit = 5}) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await ApiClient.get(
        Uri.parse('$baseUrl/blogs?featured=true&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];
          final blogs = data.map((json) => Blog.fromJson(json)).toList();
          if (blogs.isNotEmpty) return blogs;
        }
      }
    } catch (e) {
      debugPrint('Error fetching featured blogs: $e');
    }
    final all = await getAllBlogs();
    return all.where((b) => b.featured).take(limit).toList();
  }

  Future<Blog> getBlogBySlug(String slug) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await ApiClient.get(
        Uri.parse('$baseUrl/blogs/slug/$slug'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Blog.fromJson(responseData['data']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching blog slug: $e');
    }
    return _fallbackBlogs.firstWhere(
      (b) => b.slug == slug,
      orElse: () => _fallbackBlogs[0],
    );
  }

  Future<Comment> addComment(
    String blogId,
    String content,
    String authorName,
  ) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await ApiClient.post(
        Uri.parse('$baseUrl/blogs/$blogId/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': content, 'author': authorName}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Comment.fromJson(responseData['data']);
        } else {
          throw Exception('Failed to add comment: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding comment: $e');
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await ApiClient.delete(
        Uri.parse('$baseUrl/blogs/comments/$commentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(
        'Error deleting comment: $e',
      ); // Corrected from 'Error posting comment'
      rethrow;
    }
  }

  // Like or unlike a comment
  Future<Map<String, dynamic>> toggleCommentLike(
    String commentId,
    String userId,
  ) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await ApiClient.post(
        Uri.parse('$baseUrl/blogs/comments/$commentId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to toggle like');
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      rethrow;
    }
  }

  // Get comments liked by a user
  Future<List<String>> getLikedComments(String userId) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await ApiClient.get(
        Uri.parse('$baseUrl/blogs/comments/likes/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching likes: $e');
      return [];
    }
  }

  // Add a reply to a comment
  Future<Comment> addReplyToComment(
    String commentId,
    String author,
    String content,
  ) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await ApiClient.post(
        Uri.parse('$baseUrl/blogs/comments/$commentId/replies'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'author': author, 'content': content}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Comment.fromJson(data['data']);
      } else {
        throw Exception('Failed to add reply');
      }
    } catch (e) {
      debugPrint('Error adding reply: $e');
      rethrow;
    }
  }
}
