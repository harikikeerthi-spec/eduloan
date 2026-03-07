import 'lib/services/wikipedia_service.dart';

Future<void> main() async {
  final queries = [
    'Queen Mary University of London',
    'University of York',
    'University of Bristol',
    'Newcastle University'
  ];
  
  for (final q in queries) {
    print('Testing: $q');
    final images = await WikipediaService.fetchImages(q);
    if (images.isNotEmpty) {
      print('FOUND: ${images.first}');
    } else {
      print('FAILED: returned empty');
    }
  }
}
