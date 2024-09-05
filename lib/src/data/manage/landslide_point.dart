class ManageLandslidePoint {
  final String id;
  final String name;
  final String code;
  final double latitude;
  final double longitude;
  final String description;

  ManageLandslidePoint({
    required this.id,
    required this.name,
    required this.code,
    required this.latitude,
    required this.longitude,
    required this.description,
  });

  factory ManageLandslidePoint.fromJson(Map<String, dynamic> json) {
    return ManageLandslidePoint(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      description: json['description'],
    );
  }
}