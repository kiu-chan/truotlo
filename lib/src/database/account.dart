import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:truotlo/src/config/api.dart';
import 'package:truotlo/src/data/account/user.dart';

class AccountQueries {
  final String baseUrl = ApiConfig().getApiUrl();

  Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final user = User.fromJson(data['user']);
        // You might want to store the access token somewhere secure
        // For example: await secureStorage.write(key: 'access_token', value: data['access_token']);
        return user;
      } else {
        print('Failed to login: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }

  Future<User?> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final user = User.fromJson(data['user']);
        // You might want to store the access token somewhere secure
        // For example: await secureStorage.write(key: 'access_token', value: data['access_token']);
        return user;
      } else {
        print('Failed to register: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during registration: $e');
      return null;
    }
  }
}