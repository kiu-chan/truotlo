import 'package:mapbox_gl/mapbox_gl.dart';

class LandslidePoint {
  final int id;
  final LatLng location;

  LandslidePoint(this.id, this.location);

  factory LandslidePoint.fromJson(Map<String, dynamic> json) {
    return LandslidePoint(
      json['id'] as int,
      LatLng(json['lat'] as double, json['lon'] as double),
    );
  }
}