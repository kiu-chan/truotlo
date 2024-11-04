import 'package:truotlo/src/page/home/elements/landslide/hourly_forecast_point.dart';

class HourlyForecastResponse {
  final bool success;
  final Map<String, List<HourlyForecastPoint>> data;
  final Map<String, dynamic> filters;
  final int totalPoints;

  HourlyForecastResponse({
    required this.success,
    required this.data,
    required this.filters,
    required this.totalPoints,
  });

  factory HourlyForecastResponse.fromJson(Map<String, dynamic> json) {
    Map<String, List<HourlyForecastPoint>> parsedData = {};
    (json['data'] as Map<String, dynamic>).forEach((key, value) {
      parsedData[key] = (value as List)
          .map((item) => HourlyForecastPoint.fromJson(item))
          .toList();
    });

    return HourlyForecastResponse(
      success: json['success'] ?? false,
      data: parsedData,
      filters: json['filters'] ?? {},
      totalPoints: json['total_points'] ?? 0,
    );
  }
}