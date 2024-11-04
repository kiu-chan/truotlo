import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:truotlo/src/config/chart.dart';
import 'package:truotlo/src/data/chart/landslide_data.dart';
import 'package:truotlo/src/data/forecast/hourly_forecast_response.dart';
import 'package:truotlo/src/user/auth_service.dart';
import 'package:truotlo/src/data/manage/forecast.dart';
import 'package:truotlo/src/data/manage/hourly_warning.dart';
import 'package:truotlo/src/data/manage/landslide_point.dart';
import 'package:truotlo/src/data/map/landslide_point.dart';

class LandslideDatabase {
  static const String _baseUrl = 'http://truotlobinhdinh.girc.edu.vn/api';

  Future<List<LandslideDataModel>> fetchLandslideData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String endpoint;
    bool isLoggedIn = await UserPreferences.isLoggedIn();

    if (startDate != null && endDate != null) {
      String formattedStartDate = _formatDate(startDate);
      String formattedEndDate = _formatDate(endDate);
      String formattedStartTime = _formatTime(startDate);
      String formattedEndTime = _formatTime(endDate);

      endpoint = '$_baseUrl/filtered-data?start_date=$formattedStartDate&start_time=$formattedStartTime&end_date=$formattedEndDate&end_time=$formattedEndTime';
    } else {
      endpoint = isLoggedIn ? '$_baseUrl/latest-100-data' : '$_baseUrl/latest-48-data';
    }
    print(endpoint);

    final response = await http.get(Uri.parse(endpoint));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((item) => LandslideDataModel.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải dữ liệu trượt lở');
    }
  }

  Future<List<LandslidePoint>> fetchLandslidePoints() async {
    final response = await http.get(Uri.parse('$_baseUrl/landslides'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => LandslidePoint.fromJson(data)).toList();
    } else {
      throw Exception('Không thể tải danh sách điểm trượt lở');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>> fetchLandslideDetail(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/landslides/$id'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Không thể tải chi tiết điểm trượt lở');
    }
  }

  Future<List<HourlyWarning>> fetchHourlyWarnings() async {
    final response = await http.get(Uri.parse('$_baseUrl/hourly-warnings'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => HourlyWarning.fromJson(data)).toList();
    } else {
      throw Exception('Không thể tải cảnh báo theo giờ');
    }
  }

  Future<List<Forecast>> fetchForecasts() async {
    final response = await http.get(Uri.parse('$_baseUrl/forecasts'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Forecast.fromJson(data)).toList();
    } else {
      throw Exception('Không thể tải dự báo');
    }
  }

  Future<ForecastDetail> fetchForecastDetail(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/forecasts/$id'));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      return ForecastDetail.fromJson(jsonResponse);
    } else {
      throw Exception('Không thể tải chi tiết dự báo');
    }
  }

  Future<List<ManageLandslidePoint>> fetchListLandslidePoints() async {
    final response = await http.get(Uri.parse('$_baseUrl/manage-landslide-points'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => ManageLandslidePoint.fromJson(data)).toList();
    } else {
      throw Exception('Không thể tải danh sách điểm trượt lở để quản lý');
    }
  }

  Future<List<String>> getAllDistricts() async {
    final response = await http.get(Uri.parse('$_baseUrl/districts'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return List<String>.from(jsonResponse);
    } else {
      throw Exception('Không thể tải danh sách huyện');
    }
  }


  String _classifyRiskLevel(String nguyCo) {
    try {
      final double value = double.parse(nguyCo);
      if (value >= 5) {
        return 'Rất cao';
      } else if (value >= 4) {
        return 'Cao';
      } else if (value >= 3) {
        return 'Trung bình';
      } else if (value >= 2) {
        return 'Thấp';
      } else {
        return 'Rất thấp';
      }
    } catch (e) {
      print('Error parsing nguy_co value: $e');
      return 'Không xác định';
    }
  }

  Future<Map<String, int>> getForecastCounts(String currentDateTime) async {
    try {
      final url = '$_baseUrl/forecast-record-points';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List;
        final DateTime now = DateTime.now();
        final String currentHour = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}';
        
        // Lọc chỉ lấy các điểm trong giờ hiện tại
        final currentHourData = data.where((item) {
          String createdAt = item['created_at'] as String;
          return createdAt.startsWith(currentHour);
        }).toList();

        Map<String, int> counts = {
          'Rất cao': 0,
          'Cao': 0,
          'Trung bình': 0,
          'Thấp': 0,
          'Rất thấp': 0,
        };

        for (var item in currentHourData) {
          String nguyCo = item['nguy_co'].toString();
          String riskLevel = _classifyRiskLevel(nguyCo);
          if (counts.containsKey(riskLevel)) {
            counts[riskLevel] = (counts[riskLevel] ?? 0) + 1;
          }
        }
        
        return counts;
      } else {
        throw Exception('Không thể tải dữ liệu dự báo');
      }
    } catch (e) {
      print('Error getting forecast counts: $e');
      throw Exception('Lỗi khi lấy dữ liệu dự báo');
    }
  }

    Future<HourlyForecastResponse> fetchHourlyForecastPoints() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/forecast-points'));
      
      if (response.statusCode == 200) {
        return HourlyForecastResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load hourly forecast points');
      }
    } catch (e) {
      print('Error fetching hourly forecast points: $e');
      rethrow;
    }
  }
}