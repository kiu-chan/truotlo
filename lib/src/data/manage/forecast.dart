import 'package:intl/intl.dart';

class Forecast {
  final String id;
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
}

class DayForecast {
  final int day;
  final String riskLevel;
  final DateTime date;

  DayForecast({required this.day, required this.riskLevel, required this.date});
}
