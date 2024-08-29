import 'package:intl/intl.dart';

class Forecast {
  final String id;
  final String name;
  final String location;
  final String province;
  final String district;
  final String commune;
  final DateTime startDate;
  final DateTime endDate;
  final List<DayForecast> days;

  Forecast({
    required this.id,
    required this.name,
    required this.location,
    required this.province,
    required this.district,
    required this.commune,
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  String get formattedDateRange {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
  }

factory Forecast.fromJson(Map<String, dynamic> json) {
  return Forecast(
    id: json['id'].toString(),
    name: json['name'] ?? '',
    location: json['location'] ?? '',
    province: json['province'] ?? '',
    district: json['district'] ?? '',
    commune: json['commune'] ?? '',
    startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : DateTime.now(),
    endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : DateTime.now(),
    days: json['days'] != null
        ? (json['days'] as List<dynamic>)
            .map((day) => DayForecast.fromJson(day))
            .toList()
        : [],
  );
}
}

class DayForecast {
  final int day;
  final String riskLevel;
  final DateTime date;

  DayForecast({required this.day, required this.riskLevel, required this.date});

  factory DayForecast.fromJson(Map<String, dynamic> json) {
    return DayForecast(
      day: json['day'],
      riskLevel: json['risk_level'],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}