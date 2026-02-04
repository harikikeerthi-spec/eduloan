import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/blog.dart';

class BlogService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<List<Blog>> getAllBlogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/blogs'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];
          return data.map((json) => Blog.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load blogs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching blogs: $e');
    }
  }

  Future<Blog> getBlogBySlug(String slug) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/blogs/slug/$slug'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Blog.fromJson(responseData['data']);
        } else {
          throw Exception('Blog not found or invalid format');
        }
      } else {
        throw Exception('Failed to load blog');
      }
    } catch (e) {
      throw Exception('Error fetching blog: $e');
    }
  }

  Future<Comment> addComment(
    String blogId,
    String content,
    String authorName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/blogs/$blogId/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': content, 'authorName': authorName}),
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
      final response = await http.delete(
        Uri.parse('$baseUrl/blogs/comments/$commentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      print(
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
      final response = await http.post(
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
      print('Error toggling like: $e');
      rethrow;
    }
  }

  // Get comments liked by a user
  Future<List<String>> getLikedComments(String userId) async {
    try {
      final response = await http.get(
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
      print('Error fetching likes: $e');
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
      final response = await http.post(
        Uri.parse('$baseUrl/blogs/comments/$commentId/replies'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'authorName': author, 'content': content}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Comment.fromJson(data['data']);
      } else {
        throw Exception('Failed to add reply');
      }
    } catch (e) {
      print('Error adding reply: $e');
      rethrow;
    }
  }
}
