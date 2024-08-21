import 'package:mapbox_gl/mapbox_gl.dart';

class MapUtils {
  final MapboxMapController _mapController;
  Circle? _locationCircle;
  List<Line> _drawnPolygons = [];

  MapUtils(this._mapController);

  void updateLocationOnMap(LatLng location) {
    _addOrUpdateLocationCircle(location);
  }

  void _addOrUpdateLocationCircle(LatLng location) async {
    final CircleOptions circleOptions = CircleOptions(
      geometry: location,
      circleRadius: 8.0,
      circleColor: '#007bff',
      circleStrokeColor: '#ffffff',
      circleStrokeWidth: 2,
    );

    if (_locationCircle != null) {
      await _mapController.updateCircle(_locationCircle!, circleOptions);
    } else {
      _locationCircle = await _mapController.addCircle(circleOptions);
    }
  }

  Future<void> drawPolygonsOnMap(List<List<LatLng>> polygons) async {
    // Remove previously drawn polygons
    for (var line in _drawnPolygons) {
      await _mapController.removeLine(line);
    }
    _drawnPolygons.clear();

    for (int i = 0; i < polygons.length; i++) {
      Line line = await _mapController.addLine(
        LineOptions(
          geometry: polygons[i],
          lineColor: "#FF0000",
          lineWidth: 2.0,
          lineOpacity: 1.0,
        ),
      );
      _drawnPolygons.add(line);
    }
  }
}