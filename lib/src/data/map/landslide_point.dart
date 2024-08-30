import 'package:mapbox_gl/mapbox_gl.dart';

class LandslidePoint {
  final int id;
  final LatLng location;
  final String district;  // Add this line

  LandslidePoint(this.id, this.location, this.district);  // Update constructor

  factory LandslidePoint.fromJson(Map<String, dynamic> json) {
    return LandslidePoint(
      json['id'] as int,
      LatLng(json['lat'] as double, json['lon'] as double),
      json['district'] as String,  // Add this line
    );
  }
}