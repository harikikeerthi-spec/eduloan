import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LogoService {
  /// Fetches a company/university logo URL dynamically using external APIs.
  static Future<String?> getLogoByName(String name) async {
    try {
      final encodedName = Uri.encodeComponent(name);

      // Try 1: Utilize the comprehensive hipolabs university registry to find the exact domain
      final hipoUrl =
          'http://universities.hipolabs.com/search?name=$encodedName';
      final hipoResponse = await http
          .get(Uri.parse(hipoUrl))
          .timeout(const Duration(seconds: 3));

      if (hipoResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(hipoResponse.body);
        if (data.isNotEmpty) {
          var uniData = data.first;
          if (uniData['web_pages'] != null &&
              (uniData['web_pages'] as List).isNotEmpty) {
            String domain = uniData['web_pages'][0].toString();
            domain = domain.replaceAll(RegExp(r'^https?://'), '');
            domain = domain.replaceAll(RegExp(r'^www\.'), '');
            domain = domain.replaceAll(RegExp(r'/$'), '');
            domain = domain.split('/')[0];
            return 'https://logo.clearbit.com/$domain';
          }
        }
      }

      // Try 2: Fallback to Clearbit Autocomplete
      final url =
          'https://autocomplete.clearbit.com/v1/companies/suggest?query=$encodedName';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var match in data) {
          if (match['logo'] != null) {
            return match['logo'] as String;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching logo for $name: $e');
    }
    return null;
  }
}
