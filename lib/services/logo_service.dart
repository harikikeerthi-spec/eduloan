import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LogoService {
  static final Map<String, String?> _cache = {};

  /// Fetches a company/university logo URL dynamically using external APIs.
  static Future<String?> getLogoByName(String name) async {
    if (_cache.containsKey(name)) {
      return _cache[name];
    }
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
            
            final logo = await getValidLogoForDomain(domain);
            if (logo != null) {
              _cache[name] = logo;
              return logo;
            }
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
            final logoUrl = match['logo'] as String;
            if (await isUrlValid(logoUrl)) {
              _cache[name] = logoUrl;
              return logoUrl;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching logo for $name: $e');
    }
    _cache[name] = null;
    return null;
  }

  static Future<String?> getValidLogoForDomain(String domain) async {
    final clearbitUrl = 'https://logo.clearbit.com/$domain';
    if (await isUrlValid(clearbitUrl)) {
      return clearbitUrl;
    }
    // Fallback to Google Favicon which resolves for almost all domains
    final googleFaviconUrl = 'https://www.google.com/s2/favicons?sz=128&domain=$domain';
    if (await isUrlValid(googleFaviconUrl)) {
      return googleFaviconUrl;
    }
    return null;
  }

  static Future<bool> isUrlValid(String url) async {
    try {
      final response = await http.head(Uri.parse(url)).timeout(const Duration(milliseconds: 1500));
      if (response.statusCode == 200) return true;
    } catch (_) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(milliseconds: 1500));
        if (response.statusCode == 200) return true;
      } catch (_) {}
    }
    return false;
  }
}
