import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  final String apiKey;
  final String baseUrl;

  WeatherService({required this.apiKey, required this.baseUrl});

  Future<Map<String, dynamic>> getWeatherByCoordinates(double lat, double lon) async {
    final response = await http.get(Uri.parse(
        '$baseUrl/weather?lat=$lat&lon=$lon&units=metric&lang=vi&appid=$apiKey'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final iconCode = data['weather'][0]['icon'];
      data['iconPath'] = 'lib/assets/clouds/$iconCode.png';
      return data;
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<Map<String, dynamic>> getForecastByCoordinates(double lat, double lon) async {
    final response = await http.get(Uri.parse(
        '$baseUrl/forecast?lat=$lat&lon=$lon&units=metric&lang=vi&appid=$apiKey'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load forecast data');
    }
  }
}