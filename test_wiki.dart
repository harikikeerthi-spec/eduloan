import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final unis = ['University of Birmingham', 'Newcastle University', 'University of Leeds'];
  for (final uni in unis) {
    print('--- $uni ---');
    final encodedQuery = Uri.encodeComponent(uni);
    final url = 'https://en.wikipedia.org/w/api.php?action=query&redirects=1&generator=images&titles=$encodedQuery&gimlimit=50&prop=imageinfo&iiprop=url&format=json';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final pages = data['query']?['pages'] as Map<String, dynamic>?;
      if (pages != null) {
        for (var page in pages.values) {
          final imageinfo = page['imageinfo'] as List<dynamic>?;
          if (imageinfo != null && imageinfo.isNotEmpty) {
            print(imageinfo[0]['url']);
          }
        }
      }
    }
  }
}
