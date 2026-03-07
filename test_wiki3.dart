import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final unis = ['University of Birmingham', 'Newcastle University', 'University of Leeds', 'University of Bristol'];
  for (final uni in unis) {
    print('--- $uni ---');
    final encodedQuery = Uri.encodeComponent(uni);
    final url = 'https://en.wikipedia.org/w/api.php?action=query&redirects=1&generator=images&titles=$encodedQuery&gimlimit=50&prop=imageinfo&iiprop=url&format=json';
    
    final response = await http.get(Uri.parse(url));
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
                
                if (lowerUrl.contains('campus')) score += 50;
                if (lowerUrl.contains('building')) score += 40;
                if (lowerUrl.contains('hall')) score += 30;
                if (lowerUrl.contains('library')) score += 30;
                if (lowerUrl.contains('aerial')) score += 20;
                if (lowerUrl.contains('facade')) score += 20;
                if (lowerUrl.contains('exterior')) score += 20;
                if (lowerUrl.contains('university')) score += 10;
                if (lowerUrl.contains('college')) score += 10;
                if (lowerUrl.contains('school')) score += 10;

                scoredUrls.add({
                  'url': imgUrl,
                  'score': score,
                });
              }
            }
        }
        
        if (scoredUrls.isNotEmpty) {
            scoredUrls.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
            var best = scoredUrls.map((e) => '${e['url']} (Score: ${e['score']})').take(3).toList();
            for (var u in best) {
              print(u);
            }
        }
      }
    }
  }
}
