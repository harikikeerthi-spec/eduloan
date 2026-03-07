import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final name = 'University of Auckland';
  final encodedName = Uri.encodeComponent(name);
  final hipoUrl = 'http://universities.hipolabs.com/search?name=$encodedName';
  print('Fetching: $hipoUrl');
  try {
    final response = await http.get(Uri.parse(hipoUrl));
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
