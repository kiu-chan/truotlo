import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:truotlo/src/config/api.dart';

class HomeDatabase {
  final String baseUrl = ApiConfig().getApiUrl();

  Future<List<dynamic>> fetchReferences() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        print('Failed to load references. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching references: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchReferenceDetails(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts/$id'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load reference details. Status code: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('Error fetching reference details: $e');
      return {};
    }
  }

  Future<bool> incrementViews(int id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/posts/$id/increment-views'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error incrementing views: $e');
      return false;
    }
  }
}