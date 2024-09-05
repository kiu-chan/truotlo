import 'package:mapbox_gl/mapbox_gl.dart';

class LandslidePoint {
  final int id;
  final LatLng location;
  final String district;

  LandslidePoint(this.id, this.location, this.district);

  factory LandslidePoint.fromJson(Map<String, dynamic> json) {
    return LandslidePoint(
      json['id'] is int ? json['id'] : int.parse(json['id']),
      LatLng(
        _parseDouble(json['lat']),
        _parseDouble(json['lon'])
      ),
      json['district'] as String,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    throw FormatException('Invalid numeric value: $value');
  }
}