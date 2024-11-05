import 'package:mapbox_gl/mapbox_gl.dart';

class LandslidePoint {
  final int id;
  final int objectId;  // Thêm trường objectId
  final String district;
  final LatLng location;

  LandslidePoint({
    required this.id,
    required this.objectId,  // Thêm vào constructor
    required this.district,
    required this.location,
  });

  factory LandslidePoint.fromJson(Map<String, dynamic> json) {
    return LandslidePoint(
      id: json['id'],
      objectId: json['object_id'],  // Parse từ JSON
      district: json['district'],
      location: LatLng(
        double.parse(json['lat'].toString()),
        double.parse(json['lon'].toString()),
      ),
    );
  }
}