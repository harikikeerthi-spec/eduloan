import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final name = "University of Auckland";
  print('Testing LogoService logic for: $name');
  try {
    final encodedName = Uri.encodeComponent(name);

    // Try 1: Utilize the comprehensive hipolabs university registry to find the exact domain
    final hipoUrl = 'http://universities.hipolabs.com/search?name=$encodedName';
    print('Calling Hipo URL: $hipoUrl');
    final hipoResponse = await http
        .get(Uri.parse(hipoUrl))
        .timeout(const Duration(seconds: 3));

    print('Hipo Status: ${hipoResponse.statusCode}');
    if (hipoResponse.statusCode == 200) {
      final List<dynamic> data = json.decode(hipoResponse.body);
      print('Hipo Data: $data');
      if (data.isNotEmpty) {
        var uniData = data.first;
        if (uniData['web_pages'] != null &&
            (uniData['web_pages'] as List).isNotEmpty) {
          String domain = uniData['web_pages'][0].toString();
          domain = domain.replaceAll(RegExp(r'^https?://'), '');
          domain = domain.replaceAll(RegExp(r'^www\.'), '');
          domain = domain.replaceAll(RegExp(r'/$'), '');
          domain = domain.split('/')[0];
          print('Extracted Domain from Hipo: $domain');
          print('Final Clearbit Logo: https://logo.clearbit.com/$domain');
          return;
        } else {
          print('No web_pages found in Hipo data');
        }
      } else {
        print('Hipo data is empty');
      }
    }

    // Try 2: Fallback to Clearbit Autocomplete
    final url =
        'https://autocomplete.clearbit.com/v1/companies/suggest?query=$encodedName';
    print('Calling Clearbit Autocomplete URL: $url');
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 3));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      for (var match in data) {
        if (match['logo'] != null) {
          print('Found Clearbit Autocomplete Logo: ${match['logo']}');
          return;
        }
      }
      print('No logos found in Clearbit autocomplete');
    }
  } catch (e) {
    print('Error testing logo logic: $e');
  }
}
