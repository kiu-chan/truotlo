import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:truotlo/src/data/manage/forecast.dart';
import 'package:truotlo/src/data/manage/hourly_warning.dart';
import 'package:truotlo/src/data/map/landslide_point.dart';
import 'package:truotlo/src/data/manage/landslide_point.dart';

class LandslideDatabase {
  final String baseUrl = 'https://truotlobinhdinh.girc.edu.vn/api';

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

  Future<ForecastDetail> fetchForecastDetail(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/forecasts/$id'));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      return ForecastDetail.fromJson(jsonResponse);
    } else {
      throw Exception('Không thể tải chi tiết dự báo');
    }
  }

  Future<List<ManageLandslidePoint>> fetchListLandslidePoints() async {
    final response = await http.get(Uri.parse('$baseUrl/manage-landslide-points'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => ManageLandslidePoint.fromJson(data)).toList();
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
}