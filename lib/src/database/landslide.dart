import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:truotlo/src/data/manage/forecast.dart';
import 'package:truotlo/src/data/manage/hourly_warning.dart';
import 'package:truotlo/src/data/map/landslide_point.dart';
import 'package:truotlo/src/data/manage/landslide_point.dart';
import 'package:truotlo/src/config/api.dart';

class LandslideDatabase {
  final String baseUrl = ApiConfig().getApiUrl();
  final ApiConfig apiConfig = ApiConfig();

  Future<List<LandslidePoint>> fetchLandslidePoints() async {
    final response = await http.get(Uri.parse('$baseUrl/landslides'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => LandslidePoint.fromJson(data)).toList();
    } else {
      throw Exception('Không thể tải danh sách điểm trượt lở');
    }
  }

  Future<Map<String, dynamic>> fetchLandslideDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/landslides/$id'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Không thể tải chi tiết điểm trượt lở');
    }
  }

  Future<List<HourlyWarning>> fetchHourlyWarnings() async {
    final response = await http.get(Uri.parse('$baseUrl/hourly-warnings'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => HourlyWarning.fromJson(data)).toList();
    } else {
      throw Exception('Không thể tải cảnh báo theo giờ');
    }
  }

  Future<List<Forecast>> fetchForecasts() async {
    final response = await http.get(Uri.parse('$baseUrl/forecasts'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Forecast.fromJson(data)).toList();
    } else {
      throw Exception('Không thể tải dự báo');
    }
  }

  Future<ForecastDetail> fetchForecastDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/forecasts/$id'));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      return ForecastDetail.fromJson(jsonResponse);
    } else {
      throw Exception('Không thể tải chi tiết dự báo');
    }
  }

  Future<List<ManageLandslidePoint>> fetchListLandslidePoints() async {
    final response =
        await http.get(Uri.parse('$baseUrl/manage-landslide-points'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse
          .map((data) => ManageLandslidePoint.fromJson(data))
          .toList();
    } else {
      throw Exception('Không thể tải danh sách điểm trượt lở để quản lý');
    }
  }

  Future<List<String>> getAllDistricts() async {
    final response = await http.get(Uri.parse('$baseUrl/districts'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return List<String>.from(jsonResponse);
    } else {
      throw Exception('Không thể tải danh sách huyện');
    }
  }

  Future<Map<String, int>> getForecastCounts() async {
    final url = '${apiConfig.getApiUrl()}/forecast-record-points';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body) as List;
      Map<String, int> counts = {
        'Rất cao': 0,
        'Cao': 0,
        'Trung bình': 0,
        'Thấp': 0,
        'Rất thấp': 0,
      };

      for (var item in data) {
        String nguyCo = item['nguy_co'].toString().trim().toLowerCase();
        switch (nguyCo) {
          case 'rất cao':
            counts['Rất cao'] = (counts['Rất cao'] ?? 0) + 1;
            break;
          case 'cao':
            counts['Cao'] = (counts['Cao'] ?? 0) + 1;
            break;
          case 'trung bình':
            counts['Trung bình'] = (counts['Trung bình'] ?? 0) + 1;
            break;
          case 'thấp':
            counts['Thấp'] = (counts['Thấp'] ?? 0) + 1;
            break;
          case 'rất thấp':
            counts['Rất thấp'] = (counts['Rất thấp'] ?? 0) + 1;
            break;
        }
      }
      return counts;
    } else {
      throw Exception('Failed to load forecast data');
    }
  }
}
