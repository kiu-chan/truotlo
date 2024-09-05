import 'package:intl/intl.dart';

class Forecast {
  final dynamic id; // Thay đổi từ String sang dynamic
  final String name;
  final int year;
  final int month;
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
    required this.year,
    required this.month,
    this.location = '',
    this.province = '',
    this.district = '',
    this.commune = '',
    required this.startDate,
    required this.endDate,
    this.days = const [],
  });

  String get formattedDateRange {
    final dateFormat = DateFormat('MM/yyyy');
    return dateFormat.format(startDate);
  }

  String getIdAsString() {
    return id.toString();
  }

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      id: json['id'], // Không cần chuyển đổi, giữ nguyên kiểu dữ liệu gốc
      name: json['name'],
      year: json['year'],
      month: json['month'],
      location: json['location'] ?? '',
      province: json['province'] ?? '',
      district: json['district'] ?? '',
      commune: json['commune'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      days: (json['days'] as List<dynamic>?)
          ?.map((day) => DayForecast.fromJson(day))
          .toList() ?? [],
    );
  }
}

class ForecastDetail {
  final String tenDiem;
  final String viTri;
  final double kinhDo;
  final double viDo;
  final String tinh;
  final String huyen;
  final String xa;
  final List<DayForecast> days;

  ForecastDetail({
    required this.tenDiem,
    required this.viTri,
    required this.kinhDo,
    required this.viDo,
    required this.tinh,
    required this.huyen,
    required this.xa,
    required this.days,
  });

  factory ForecastDetail.fromJson(Map<String, dynamic> json) {
    return ForecastDetail(
      tenDiem: json['tenDiem'],
      viTri: json['viTri'],
      kinhDo: json['kinhDo'].toDouble(),
      viDo: json['viDo'].toDouble(),
      tinh: json['tinh'],
      huyen: json['huyen'],
      xa: json['xa'],
      days: (json['days'] as List<dynamic>)
          .map((day) => DayForecast.fromJson(day))
          .toList(),
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
      riskLevel: json['riskLevel'],
      date: DateTime.parse(json['date']),
    );
  }
}