// lib/src/data/chart/rainfall_data.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class RainfallData {
  final DateTime measurementTime;
  final double rainfallAmount;

  RainfallData({
    required this.measurementTime,
    required this.rainfallAmount,
  });

  factory RainfallData.fromJson(Map<String, dynamic> json) {
    return RainfallData(
      measurementTime: DateTime.parse(json['measurement_time']),
      rainfallAmount: double.parse(json['rainfall_amount']),
    );
  }

  Map<String, dynamic> toJson() => {
    'measurement_time': measurementTime.toIso8601String(),
    'rainfall_amount': rainfallAmount,
  };
}

class RainfallDataService {
  static const String baseUrl = 'http://truotlobinhdinh.girc.edu.vn';

  static Future<List<RainfallData>> fetchRainfallData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rainfall-data'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'];
        
        List<RainfallData> rainfallDataList = data.map((item) => RainfallData.fromJson(item)).toList();
        
        // Sort by measurement time
        rainfallDataList.sort((a, b) => a.measurementTime.compareTo(b.measurementTime));
        
        return rainfallDataList;
      } else {
        throw Exception('Failed to load rainfall data');
      }
    } catch (e) {
      print('Error fetching rainfall data: $e');
      rethrow;
    }
  }
}