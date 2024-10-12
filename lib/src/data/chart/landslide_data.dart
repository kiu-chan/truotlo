import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:truotlo/src/config/chart.dart';

class LandslideDataModel {
  final int id;
  final String createdAt;
  final String updatedAt;
  final double batteryVoltage;
  final double temperatureDatalogger;
  final double pz1Digit;
  final double pz2Digit;
  final double cr1Digit;
  final double cr2Digit;
  final double cr3Digit;
  final double tiltAOr1;
  final double tiltBOr1;
  final double tiltAOr2;
  final double tiltBOr2;
  final double tiltAOr3;
  final double tiltBOr3;
  final double pz1Temp;
  final double pz2Temp;
  final double cr1Temp;
  final double cr2Temp;
  final double cr3Temp;
  final double tilt1Temp;
  final double tilt2Temp;
  final double tilt3Temp;

  LandslideDataModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.batteryVoltage,
    required this.temperatureDatalogger,
    required this.pz1Digit,
    required this.pz2Digit,
    required this.cr1Digit,
    required this.cr2Digit,
    required this.cr3Digit,
    required this.tiltAOr1,
    required this.tiltBOr1,
    required this.tiltAOr2,
    required this.tiltBOr2,
    required this.tiltAOr3,
    required this.tiltBOr3,
    required this.pz1Temp,
    required this.pz2Temp,
    required this.cr1Temp,
    required this.cr2Temp,
    required this.cr3Temp,
    required this.tilt1Temp,
    required this.tilt2Temp,
    required this.tilt3Temp,
  });

  factory LandslideDataModel.fromJson(Map<String, dynamic> json) {
    return LandslideDataModel(
      id: json['id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      batteryVoltage: _parseDouble(json['Batt(Volts)']),
      temperatureDatalogger: _parseDouble(json['Temp_Dataloger(Celsius)']),
      pz1Digit: _parseDouble(json['PZ1_(Digit)']),
      pz2Digit: _parseDouble(json['PZ2_(Digit)']),
      cr1Digit: _parseDouble(json['CR1_(Digit)']),
      cr2Digit: _parseDouble(json['CR2_(Digit)']),
      cr3Digit: _parseDouble(json['CR3_(Digit)']),
      tiltAOr1: _parseDouble(json['Tilt_A_Or_1(sin)']),
      tiltBOr1: _parseDouble(json['Tilt_B_Or_1(sin)']),
      tiltAOr2: _parseDouble(json['Tilt_A_Or_2(sin)']),
      tiltBOr2: _parseDouble(json['Tilt_B_Or_2(sin)']),
      tiltAOr3: _parseDouble(json['Tilt_A_Or_3(sin)']),
      tiltBOr3: _parseDouble(json['Tilt_B_Or_3(sin)']),
      pz1Temp: _parseDouble(json['PZ1_Temp']),
      pz2Temp: _parseDouble(json['PZ2_Temp']),
      cr1Temp: _parseDouble(json['CR1_Temp']),
      cr2Temp: _parseDouble(json['CR2_Temp']),
      cr3Temp: _parseDouble(json['CR3_Temp']),
      tilt1Temp: _parseDouble(json['Tilt_1_Temp']),
      tilt2Temp: _parseDouble(json['Tilt_2_Temp']),
      tilt3Temp: _parseDouble(json['Tilt_3_Temp']),
    );
  }

  // Hàm helper để parse giá trị double từ chuỗi hoặc số
  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.parse(value);
    }
    throw FormatException('Cannot parse $value to double');
  }

  // Các phương thức tính toán
  double get calculatedTiltAOr1 => 500 * (tiltAOr1 - (-0.001565));
  double get calculatedTiltAOr2 => 500 * (tiltAOr2 - 0.009616);
  double get calculatedTiltAOr3 => 500 * (tiltAOr3 - 0.000935);
  double get calculatedTiltBOr1 => 500 * (tiltBOr1 - (-0.03261));
  double get calculatedTiltBOr2 => 500 * (tiltBOr2 - (-0.053559));
  double get calculatedTiltBOr3 => 500 * (tiltBOr3 - (-0.032529));
  double get calculatedPZ1Digit => -0.09763 * (pz1Digit - 9338.196);
  double get calculatedPZ2Digit => -0.0953721 * (pz2Digit - 9952.377);
  double get calculatedCR1Digit => 0.0452854 * (cr1Digit - 4645.767);
  double get calculatedCR2Digit => 0.0456835 * (cr2Digit - 6104.228);
  double get calculatedCR3Digit => 0.0452898 * (cr3Digit - 4722.004);
}

class LandslideDataService {
  static final String _baseApi = ChartConfig().chartApi;

  Future<List<LandslideDataModel>> fetchLandslideData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String endpoint;
    if (startDate != null && endDate != null) {
      String formattedStartDate = _formatDate(startDate);
      String formattedEndDate = _formatDate(endDate);
      String formattedStartTime = _formatTime(startDate);
      String formattedEndTime = _formatTime(endDate);
      endpoint = '$_baseApi/filtered-data?start_date=$formattedStartDate&start_time=$formattedStartTime&end_date=$formattedEndDate&end_time=$formattedEndTime';
    } else {
      endpoint = '$_baseApi/latest-48-data';
    }

    final response = await http.get(Uri.parse(endpoint));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((item) => LandslideDataModel.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải dữ liệu trượt lở');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}