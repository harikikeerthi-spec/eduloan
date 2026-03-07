import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final name = "University of Auckland";
  final encodedName = Uri.encodeComponent(name);
  final url =
      'https://autocomplete.clearbit.com/v1/companies/suggest?query=$encodedName';

  print('Fetching: $url');
  try {
    final response = await http.get(Uri.parse(url));
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
