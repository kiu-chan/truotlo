class Forecast {
  final String id;
  final String name;
  final String location;
  final String province;
  final String district;
  final String commune;
  final List<DayForecast> days;

  Forecast({
    required this.id,
    required this.name,
    required this.location,
    required this.province,
    required this.district,
    required this.commune,
    required this.days,
  });
}

class DayForecast {
  final int day;
  final String riskLevel;

  DayForecast({required this.day, required this.riskLevel});
}