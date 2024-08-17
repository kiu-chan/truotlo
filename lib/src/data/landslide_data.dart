import 'package:http/http.dart' as http;
import 'dart:convert';

class LandslideDataModel {
  final int id;
  final String rawContent;
  final String createdAt;
  final String updatedAt;
  final double batteryVoltage;
  final double temperatureDatalogger;
  final double calculatedTiltAOr1;
  final double calculatedTiltAOr2;
  final double calculatedTiltAOr3;
  final double calculatedTiltBOr1;
  final double calculatedTiltBOr2;
  final double calculatedTiltBOr3;
  final double calculatedPZ1Digit;
  final double calculatedPZ2Digit;
  final double calculatedCR1Digit;
  final double calculatedCR2Digit;
  final double calculatedCR3Digit;
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
    required this.rawContent,
    required this.createdAt,
    required this.updatedAt,
    required this.batteryVoltage,
    required this.temperatureDatalogger,
    required this.calculatedTiltAOr1,
    required this.calculatedTiltAOr2,
    required this.calculatedTiltAOr3,
    required this.calculatedTiltBOr1,
    required this.calculatedTiltBOr2,
    required this.calculatedTiltBOr3,
    required this.calculatedPZ1Digit,
    required this.calculatedPZ2Digit,
    required this.calculatedCR1Digit,
    required this.calculatedCR2Digit,
    required this.calculatedCR3Digit,
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
    final parsedContent = _parseRawContent(json['raw_content']);
    return LandslideDataModel(
      id: json['id'],
      rawContent: json['raw_content'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      batteryVoltage: parsedContent['Batt(Volts)'] ?? 0,
      temperatureDatalogger: parsedContent['Temp_Dataloger(Celsius)'] ?? 0,
      calculatedTiltAOr1: 500 * ((parsedContent['Tilt_A_Or_1(sin)'] ?? 0) - (-0.001565)),
      calculatedTiltAOr2: 500 * ((parsedContent['Tilt_A_Or_2(sin)'] ?? 0) - 0.009616),
      calculatedTiltAOr3: 500 * ((parsedContent['Tilt_A_Or_3(sin)'] ?? 0) - 0.000935),
      calculatedTiltBOr1: 500 * ((parsedContent['Tilt_B_Or_1(sin)'] ?? 0) - (-0.03261)),
      calculatedTiltBOr2: 500 * ((parsedContent['Tilt_B_Or_2(sin)'] ?? 0) - (-0.053559)),
      calculatedTiltBOr3: 500 * ((parsedContent['Tilt_B_Or_3(sin)'] ?? 0) - (-0.032529)),
      calculatedPZ1Digit: -0.09763 * ((parsedContent['PZ1_(Digit)'] ?? 0) - 9338.196),
      calculatedPZ2Digit: -0.0953721 * ((parsedContent['PZ2_(Digit)'] ?? 0) - 9952.377),
      calculatedCR1Digit: 0.0452854 * ((parsedContent['CR1_(Digit)'] ?? 0) - 4645.767),
      calculatedCR2Digit: 0.0456835 * ((parsedContent['CR2_(Digit)'] ?? 0) - 6104.228),
      calculatedCR3Digit: 0.0452898 * ((parsedContent['CR3_(Digit)'] ?? 0) - 4722.004),
      pz1Temp: parsedContent['PZ1_Temp'] ?? 0,
      pz2Temp: parsedContent['PZ2_Temp'] ?? 0,
      cr1Temp: parsedContent['CR1_Temp'] ?? 0,
      cr2Temp: parsedContent['CR2_Temp'] ?? 0,
      cr3Temp: parsedContent['CR3_Temp'] ?? 0,
      tilt1Temp: parsedContent['Tilt_1_Temp'] ?? 0,
      tilt2Temp: parsedContent['Tilt_2_Temp'] ?? 0,
      tilt3Temp: parsedContent['Tilt_3_Temp'] ?? 0,
    );
  }

  static Map<String, double> _parseRawContent(String rawContent) {
    final Map<String, double> parsedData = {};
    final List<String> parts = rawContent.split(';');

    for (String part in parts) {
      final List<String> keyValue = part.split(',');
      if (keyValue.length == 2) {
        String key = keyValue[0].trim();
        double value = double.tryParse(keyValue[1].trim()) ?? 0;
        parsedData[key] = value;
      }
    }

    return parsedData;
  }
}

class LandslideDataService {
  static const String _baseUrl = 'http://171.244.133.49/api';

  Future<List<LandslideDataModel>> fetchLandslideData() async {
    final response = await http.get(Uri.parse('$_baseUrl/getLandSlideRawData'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> dataList = jsonData['data'];
      return dataList.map((item) => LandslideDataModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load landslide data');
    }
  }
}