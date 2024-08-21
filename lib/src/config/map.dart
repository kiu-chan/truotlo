import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/map_data.dart';

class MapConfig {
  String mapToken =
      'sk.eyJ1IjoibW9ubHljdXRlIiwiYSI6ImNtMDI4enByaDAwMnIycXIwdDhqc3diNHgifQ.cpA69qDo8WHZ7ZxeGzCSlw';
  LatLng defaultTarget = const LatLng(14.0583, 108.2772);
  double defaultZoom = 8.0;

  final List<MapStyleCategory> styleCategories = [
    MapStyleCategory("Cơ bản", [
      MapStyle("Đường phố", MapboxStyles.MAPBOX_STREETS),
      MapStyle("Ngoài trời", MapboxStyles.OUTDOORS),
    ]),
    MapStyleCategory("Sáng & Tối", [
      MapStyle("Sáng", MapboxStyles.LIGHT),
      MapStyle("Tối", MapboxStyles.DARK),
    ]),
    MapStyleCategory("Vệ tinh", [
      MapStyle("Vệ tinh", MapboxStyles.SATELLITE),
      MapStyle("Vệ tinh với đường phố", MapboxStyles.SATELLITE_STREETS),
    ]),
  ];

  String getMapToken() {
    return mapToken;
  }

  LatLng getDefaultTarget() {
    return defaultTarget;
  }

  double getDefaultZoom() {
    return defaultZoom;
  }

  List<MapStyleCategory> getStyleCategories() {
    return styleCategories;
  }
}
