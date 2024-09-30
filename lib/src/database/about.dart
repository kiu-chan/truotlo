import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:truotlo/src/config/api.dart';

class AboutDatabase {
  final String baseUrl = ApiConfig().getApiUrl();

  Future<String> fetchAboutContent() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/about'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['content'] as String;
      } else {
        throw Exception('Failed to load about content. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching about content: $e');
      rethrow;
    }
  }
}