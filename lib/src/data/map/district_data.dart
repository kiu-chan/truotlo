import 'package:mapbox_gl/mapbox_gl.dart';

class District {
  final int id;
  final String name;
  final List<List<LatLng>> polygons;

  District(this.id, this.name, this.polygons);
}