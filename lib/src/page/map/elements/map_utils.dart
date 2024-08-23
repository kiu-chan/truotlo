import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/district_data.dart';
import 'package:truotlo/src/data/map/landslide_point.dart';
import 'package:truotlo/src/database/commune.dart';

class MapUtils {
  final MapboxMapController _mapController;
  Circle? _locationCircle;
  final Map<int, List<Line>> _drawnDistricts = {};
  final List<Line> _drawnPolygons = [];
  final List<Line> _drawnCommunes = [];
  final List<Symbol> _drawnLandslidePoints = [];

  MapUtils(this._mapController);

  Future<void> updateLocationOnMap(LatLng location) async {
    await _addOrUpdateLocationCircle(location);
  }

  Future<void> _addOrUpdateLocationCircle(LatLng location) async {
    final CircleOptions circleOptions = CircleOptions(
      geometry: location,
      circleRadius: 8.0,
      circleColor: '#007bff',
      circleStrokeColor: '#ffffff',
      circleStrokeWidth: 2,
    );

    try {
      if (_locationCircle != null) {
        await _mapController.updateCircle(_locationCircle!, circleOptions);
      } else {
        _locationCircle = await _mapController.addCircle(circleOptions);
      }
    } catch (e) {
      print('Lỗi khi cập nhật vòng tròn vị trí: $e');
    }
  }

  Future<void> drawDistrictsOnMap(List<District> districts) async {
    for (var district in districts) {
      await drawDistrict(district);
    }
  }

  Future<void> drawDistrict(District district) async {
    List<Line> lines = [];
    for (var polygon in district.polygons) {
      try {
        Line line = await _mapController.addLine(
          LineOptions(
            geometry: polygon,
            lineColor: '#00000', // Red color for district boundaries
            lineWidth: 2.0,
            lineOpacity: 1.0,
          ),
        );
        lines.add(line);
      } catch (e) {
        print('Lỗi khi vẽ ranh giới huyện ${district.name}: $e');
      }
    }
    _drawnDistricts[district.id] = lines.cast<Line>();
  }

  Future<void> toggleDistrictVisibility(int districtId, bool isVisible) async {
    if (_drawnDistricts.containsKey(districtId)) {
      for (var line in _drawnDistricts[districtId]!) {
        try {
          await _mapController.updateLine(
              line, LineOptions(lineOpacity: isVisible ? 1.0 : 0.0));
        } catch (e) {
          print('Lỗi khi chuyển đổi tính hiển thị của huyện $districtId: $e');
        }
      }
    }
  }

  Future<void> toggleAllDistrictsVisibility(bool isVisible) async {
    for (var lines in _drawnDistricts.values) {
      for (var line in lines) {
        try {
          await _mapController.updateLine(
              line, LineOptions(lineOpacity: isVisible ? 1.0 : 0.0));
        } catch (e) {
          print('Lỗi khi chuyển đổi tính hiển thị của tất cả các huyện: $e');
        }
      }
    }
  }

  Future<void> clearDistrictsOnMap() async {
    for (var lines in _drawnDistricts.values) {
      for (var line in lines) {
        try {
          await _mapController.removeLine(line);
        } catch (e) {
          print('Lỗi khi xóa đường ranh giới của huyện: $e');
        }
      }
    }
    _drawnDistricts.clear();
  }

  Future<void> drawPolygonsOnMap(List<List<LatLng>> polygons) async {
    await clearPolygonsOnMap();

    for (var polygon in polygons) {
      try {
        Line line = await _mapController.addLine(
          LineOptions(
            geometry: polygon,
            lineColor: "#FF0000",
            lineWidth: 2.0,
            lineOpacity: 1.0,
          ),
        );
        _drawnPolygons.add(line);
      } catch (e) {
        print('Lỗi khi vẽ đa giác: $e');
      }
    }
  }

  Future<void> clearPolygonsOnMap() async {
    for (var line in _drawnPolygons) {
      try {
        await _mapController.removeLine(line);
      } catch (e) {
        print('Lỗi khi xóa đường của đa giác: $e');
      }
    }
    _drawnPolygons.clear();
  }

  Future<void> toggleBorderVisibility(bool isVisible) async {
    try {
      for (var line in _drawnPolygons) {
        try {
          await _mapController.updateLine(
              line, LineOptions(lineOpacity: isVisible ? 1.0 : 0.0));
        } catch (e) {
          print('Lỗi khi chuyển đổi tính hiển thị của đường biên: $e');
        }
      }
    } catch (e) {
      print('lỗi: $e');
    }
  }

  Future<void> drawCommunesOnMap(List<Commune> communes) async {
    await clearCommunesOnMap();

    for (var commune in communes) {
      for (var polygon in commune.polygons) {
        try {
          Line line = await _mapController.addLine(
            LineOptions(
              geometry: polygon,
              lineColor: "#000000",
              lineWidth: 1.0,
              lineOpacity: 1.0,
            ),
          );
          _drawnCommunes.add(line);
        } catch (e) {
          print('Lỗi khi vẽ xã: $e');
        }
      }
    }
  }

  Future<void> clearCommunesOnMap() async {
    for (var line in _drawnCommunes) {
      try {
        await _mapController.removeLine(line);
      } catch (e) {
        print('Lỗi khi xóa đường của xã: $e');
      }
    }
    _drawnCommunes.clear();
  }

  Future<void> toggleCommunesVisibility(bool isVisible) async {
    for (var line in _drawnCommunes) {
      try {
        await _mapController.updateLine(
            line, LineOptions(lineOpacity: isVisible ? 1.0 : 0.0));
      } catch (e) {
        print('Lỗi khi chuyển đổi tính hiển thị của xã: $e');
      }
    }
  }

  Future<void> drawLandslidePointsOnMap(List<LandslidePoint> points) async {
    await clearLandslidePointsOnMap();

    for (var point in points) {
      try {
        Symbol symbol = await _mapController.addSymbol(
          SymbolOptions(
            geometry: point.location,
            iconImage: 'location_on',
            iconSize: 1.0,
            iconColor: '#FF0000',
            zIndex: 99,
          ),
          {'id': point.id},
        );
        _drawnLandslidePoints.add(symbol);
      } catch (e) {
        print('Error drawing landslide point: $e');
      }
    }
  }

  Future<void> ensureLandslidePointsOnTop() async {
    for (var symbol in _drawnLandslidePoints) {
      try {
        await _mapController.updateSymbol(
          symbol,
          const SymbolOptions(zIndex: 99),
        );
      } catch (e) {
        print('Error updating landslide point zIndex: $e');
      }
    }
  }

  Future<void> clearLandslidePointsOnMap() async {
    for (var symbol in _drawnLandslidePoints) {
      try {
        await _mapController.removeSymbol(symbol);
      } catch (e) {
        print('Error removing landslide point: $e');
      }
    }
    _drawnLandslidePoints.clear();
  }

  Future<void> toggleLandslidePointsVisibility(bool isVisible) async {
    for (var symbol in _drawnLandslidePoints) {
      try {
        await _mapController.updateSymbol(
            symbol, SymbolOptions(iconOpacity: isVisible ? 1.0 : 0.0));
      } catch (e) {
        print('Error toggling landslide point visibility: $e');
      }
    }
  }
}
