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
}
