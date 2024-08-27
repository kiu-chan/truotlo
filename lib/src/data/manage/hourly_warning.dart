class HourlyWarning {
  final String id;
  final int hour;
  final int day;
  final int month;
  final int year;
  final String location;
  final String warningLevel;
  final String description;

  HourlyWarning({
    required this.id,
    required this.hour,
    required this.day,
    required this.month,
    required this.year,
    required this.location,
    required this.warningLevel,
    required this.description,
  });

  String get formattedDate => 'Giờ $hour - Ngày $day/$month/$year';
}