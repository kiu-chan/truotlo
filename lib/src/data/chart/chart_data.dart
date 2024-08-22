class ChartData {
  final String name;
  final List<List<double>> dataPoints;
  final List<DateTime> dates;

  ChartData({
    required this.name,
    required this.dataPoints,
    required this.dates,
  });
}