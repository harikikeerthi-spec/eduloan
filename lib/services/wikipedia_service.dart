import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WikipediaService {
  /// Fetches a list of valid image URLs from a Wikipedia page matching the query.
  /// Typically passes a university name and optionally a city name for fallbacks.
  static Future<List<String>> fetchImages(
    String universityName, {
    String? cityName,
  }) async {
    final cleanUniQuery = universityName.trim();
    if (cleanUniQuery.isEmpty) return [];

    // Pass 1: Try Exact Title Match for University
    debugPrint('Wiki FETCH Pass 1: $cleanUniQuery');
    var results = await _fetchFromWikiApi(
      'action=query&redirects=1&generator=images&titles=${Uri.encodeComponent(cleanUniQuery)}&gimlimit=50&prop=imageinfo&iiprop=url&format=json',
    );

    // Pass 2: Search for "[University] campus"
    if (results.isEmpty) {
      debugPrint('Wiki FETCH Pass 2: $cleanUniQuery campus');
      results = await _fetchFromWikiApi(
        'action=query&generator=search&gsrsearch=${Uri.encodeComponent("$cleanUniQuery campus")}&prop=imageinfo&iiprop=url&format=json&gsrlimit=5&gimlimit=50',
      );

      // Pass 3: Search for "[University] building"
      if (results.isEmpty) {
        debugPrint('Wiki FETCH Pass 3: $cleanUniQuery building');
        results = await _fetchFromWikiApi(
          'action=query&generator=search&gsrsearch=${Uri.encodeComponent("$cleanUniQuery building")}&prop=imageinfo&iiprop=url&format=json&gsrlimit=5&gimlimit=50',
        );
      }
    }

    // City-Level Fallbacks (If university specific photos are missing)
    if (results.isEmpty && cityName != null && cityName.isNotEmpty) {
      final cleanCity = cityName.trim();

      // Pass 4: City landmarks
      debugPrint('Wiki FETCH Pass 4: $cleanCity landmarks');
      results = await _fetchFromWikiApi(
        'action=query&generator=search&gsrsearch=${Uri.encodeComponent("$cleanCity landmarks")}&prop=imageinfo&iiprop=url&format=json&gsrlimit=5&gimlimit=50',
      );

      // Pass 5: City bridges
      if (results.isEmpty) {
        debugPrint('Wiki FETCH Pass 5: $cleanCity bridges');
        results = await _fetchFromWikiApi(
          'action=query&generator=search&gsrsearch=${Uri.encodeComponent("$cleanCity bridge")}&prop=imageinfo&iiprop=url&format=json&gsrlimit=3&gimlimit=50',
        );
      }

      // Pass 6: General City buildings
      if (results.isEmpty) {
        debugPrint('Wiki FETCH Pass 6: $cleanCity buildings');
        results = await _fetchFromWikiApi(
          'action=query&generator=search&gsrsearch=${Uri.encodeComponent("$cleanCity buildings")}&prop=imageinfo&iiprop=url&format=json&gsrlimit=5&gimlimit=50',
        );
      }

      // Pass 7: City skyline
      if (results.isEmpty) {
        debugPrint('Wiki FETCH Pass 7: $cleanCity skyline');
        results = await _fetchFromWikiApi(
          'action=query&generator=search&gsrsearch=${Uri.encodeComponent("$cleanCity skyline")}&prop=imageinfo&iiprop=url&format=json&gsrlimit=3&gimlimit=50',
        );
      }

      // Pass 8: Just the City Name (Last resort)
      if (results.isEmpty) {
        debugPrint('Wiki FETCH Pass 8: $cleanCity');
        results = await _fetchFromWikiApi(
          'action=query&generator=search&gsrsearch=${Uri.encodeComponent(cleanCity)}&prop=imageinfo&iiprop=url&format=json&gsrlimit=5&gimlimit=50',
        );
      }
    }

    if (results.isNotEmpty) {
      debugPrint(
        'Wiki FETCH SUCCESS for $cleanUniQuery: ${results.length} images',
      );
    } else {
      debugPrint('Wiki FETCH FAILED for $cleanUniQuery');
    }

    return results;
  }

  static Future<List<String>> _fetchFromWikiApi(String queryParams) async {
    try {
      final url = 'https://en.wikipedia.org/w/api.php?$queryParams';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'EduloanApp/1.2 (https://vidhyaloan.com; research@vidhyaloan.com) University-Image-Bot/1.2',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;

        if (pages != null) {
          List<Map<String, dynamic>> scoredUrls = [];

          for (var page in pages.values) {
            final imageinfo = page['imageinfo'] as List<dynamic>?;
            if (imageinfo != null && imageinfo.isNotEmpty) {
              final String imgUrl = imageinfo[0]['url'] ?? '';
              final lowerUrl = imgUrl.toLowerCase();

              // Filter out non-photo files
              if ((lowerUrl.endsWith('.jpg') ||
                      lowerUrl.endsWith('.jpeg') ||
                      lowerUrl.endsWith('.png')) &&
                  !lowerUrl.contains('logo') &&
                  !lowerUrl.contains('seal') &&
                  !lowerUrl.contains('map') &&
                  !lowerUrl.contains('shield') &&
                  !lowerUrl.contains('coat_of_arms') &&
                  !lowerUrl.contains('portrait') &&
                  !lowerUrl.contains('signature') &&
                  !lowerUrl.contains('graph') &&
                  !lowerUrl.contains('chart')) {
                int score = 0;

                // Primary Building/Landmark Keywords (High Weight)
                if (lowerUrl.contains('campus')) score += 70;
                if (lowerUrl.contains('building')) score += 60;
                if (lowerUrl.contains('hall')) score += 50;
                if (lowerUrl.contains('facade')) score += 50;
                if (lowerUrl.contains('exterior')) score += 50;
                if (lowerUrl.contains('bridge')) score += 40;
                if (lowerUrl.contains('landmark')) score += 40;
                if (lowerUrl.contains('aerial')) score += 40;
                if (lowerUrl.contains('quad')) score += 40;
                if (lowerUrl.contains('skyline')) score += 35;
                if (lowerUrl.contains('library')) score += 35;
                if (lowerUrl.contains('tower')) score += 35;
                if (lowerUrl.contains('entrance')) score += 30;
                if (lowerUrl.contains('court')) score += 25;
                if (lowerUrl.contains('plaza')) score += 25;
                if (lowerUrl.contains('theatre')) score += 20;
                if (lowerUrl.contains('monument')) score += 20;
                if (lowerUrl.contains('statue')) score += 20;

                // Educational Keywords
                if (lowerUrl.contains('university')) score += 10;
                if (lowerUrl.contains('college')) score += 10;
                if (lowerUrl.contains('school')) score += 10;
                if (lowerUrl.contains('institute')) score += 10;
                if (lowerUrl.contains('architecture')) score += 10;

                // Penalties for non-building images (People/Events)
                if (lowerUrl.contains('student')) score -= 150;
                if (lowerUrl.contains('people')) score -= 150;
                if (lowerUrl.contains('person')) score -= 150;
                if (lowerUrl.contains('graduation')) score -= 150;
                if (lowerUrl.contains('ceremony')) score -= 150;
                if (lowerUrl.contains('crowd')) score -= 150;
                if (lowerUrl.contains('staff')) score -= 150;
                if (lowerUrl.contains('alumni')) score -= 150;
                if (lowerUrl.contains('meeting')) score -= 100;
                if (lowerUrl.contains('office')) score -= 100;
                if (lowerUrl.contains('interior')) score -= 100;
                if (lowerUrl.contains('classroom')) score -= 100;
                if (lowerUrl.contains('lecture')) score -= 100;

                if (score > 0) {
                  scoredUrls.add({'url': imgUrl, 'score': score});
                }
              }
            }
          }

          if (scoredUrls.isNotEmpty) {
            scoredUrls.sort(
              (a, b) => (b['score'] as int).compareTo(a['score'] as int),
            );
            return scoredUrls.map((e) => e['url'] as String).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Error in WikipediaService: $e');
    }
    return [];
  }
}
