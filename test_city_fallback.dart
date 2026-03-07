import 'dart:convert';
import 'package:http/http.dart' as http;

// Mock debugPrint for pure Dart test
void debugPrint(String message) => print(message);

class WikipediaService {
  static Future<List<String>> fetchImages(String universityName, {String? cityName}) async {
    final cleanUniQuery = universityName.trim();
    if (cleanUniQuery.isEmpty) return [];
    
    debugPrint('Wiki FETCH Pass 1: $cleanUniQuery');
    var results = await _fetchFromWikiApi('action=query&redirects=1&generator=images&titles=${Uri.encodeComponent(cleanUniQuery)}&gimlimit=50&prop=imageinfo&iiprop=url&format=json');
    
    if (results.isEmpty) {
      debugPrint('Wiki FETCH Pass 2: $cleanUniQuery campus');
      results = await _fetchFromWikiApi('action=query&generator=search&gsrsearch=${Uri.encodeComponent(cleanUniQuery + " campus")}&prop=imageinfo&iiprop=url&format=json&gsrlimit=5&gimlimit=50');
      
      if (results.isEmpty) {
        debugPrint('Wiki FETCH Pass 3: $cleanUniQuery building');
        results = await _fetchFromWikiApi('action=query&generator=search&gsrsearch=${Uri.encodeComponent(cleanUniQuery + " building")}&prop=imageinfo&iiprop=url&format=json&gsrlimit=5&gimlimit=50');
      }
    }

    if (results.isEmpty && cityName != null && cityName.isNotEmpty) {
      final cleanCity = cityName.trim();
      debugPrint('Wiki FETCH Pass 5: $cleanCity buildings landmark');
      results = await _fetchFromWikiApi('action=query&generator=search&gsrsearch=${Uri.encodeComponent(cleanCity + " buildings landmark")}&prop=imageinfo&iiprop=url&format=json&gsrlimit=5&gimlimit=50');
      
      if (results.isEmpty) {
        debugPrint('Wiki FETCH Pass 6: $cleanCity bridge');
        results = await _fetchFromWikiApi('action=query&generator=search&gsrsearch=${Uri.encodeComponent(cleanCity + " bridge")}&prop=imageinfo&iiprop=url&format=json&gsrlimit=3&gimlimit=50');
      }
    }
    
    return results;
  }

  static Future<List<String>> _fetchFromWikiApi(String queryParams) async {
    try {
      final url = 'https://en.wikipedia.org/w/api.php?$queryParams';
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'EduloanApp/1.2'}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        if (pages != null) {
          List<String> urls = [];
          for (var page in pages.values) {
            final imageinfo = page['imageinfo'] as List<dynamic>?;
            if (imageinfo != null && imageinfo.isNotEmpty) {
              urls.add(imageinfo[0]['url']);
            }
          }
          return urls;
        }
      }
    } catch (e) {
      print('Error: $e');
    }
    return [];
  }
}

void main() async {
  print('--- Testing City Fallback ---');
  // Newcastle is good, let's try a city search directly
  final cityResults = await WikipediaService.fetchImages("NonExistentUni", cityName: "Newcastle upon Tyne");
  print('Results for Newcastle City Fallback: ${cityResults.length}');
  if (cityResults.isNotEmpty) {
    print('First City Landmark: ${cityResults.first}');
  }

  print('\n--- Testing University with City ---');
  final uniResults = await WikipediaService.fetchImages("University of Leeds", cityName: "Leeds");
  print('Results for Leeds: ${uniResults.length}');
  if (uniResults.isNotEmpty) {
    print('First University Building: ${uniResults.first}');
  }
}
