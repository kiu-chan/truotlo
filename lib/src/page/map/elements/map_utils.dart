import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/district_data.dart';

class MapUtils {
  final MapboxMapController _mapController;
  Circle? _locationCircle;
  Map<int, List<Fill>> _drawnDistricts = {};
  List<Line> _drawnPolygons = [];

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
      // Xử lý lỗi một cách phù hợp, ví dụ: hiển thị thông báo cho người dùng
    }
  }

  Future<void> drawDistrictsOnMap(List<District> districts) async {
    for (var district in districts) {
      await drawDistrict(district);
    }
  }

  Future<void> drawDistrict(District district) async {
    List<Fill> fills = [];
    for (var polygon in district.polygons) {
      try {
        Fill fill = await _mapController.addFill(
          FillOptions(
            geometry: [polygon],
            fillColor:
                '#${district.color.value.toRadixString(16).substring(2)}',
            fillOpacity: 0.5,
            fillOutlineColor: '#000000',
          ),
        );
        fills.add(fill);
      } catch (e) {
        print('Lỗi khi vẽ huyện ${district.name}: $e');
        // Xử lý lỗi một cách phù hợp
      }
    }
    _drawnDistricts[district.id] = fills;
  }

  Future<void> toggleDistrictVisibility(int districtId, bool isVisible) async {
    if (_drawnDistricts.containsKey(districtId)) {
      for (var fill in _drawnDistricts[districtId]!) {
        try {
          await _mapController.updateFill(
              fill, FillOptions(fillOpacity: isVisible ? 0.5 : 0.0));
        } catch (e) {
          print('Lỗi khi chuyển đổi tính hiển thị của huyện $districtId: $e');
          // Xử lý lỗi một cách phù hợp
        }
      }
    }
  }

  Future<void> toggleAllDistrictsVisibility(bool isVisible) async {
    for (var fills in _drawnDistricts.values) {
      for (var fill in fills) {
        try {
          await _mapController.updateFill(
              fill, FillOptions(fillOpacity: isVisible ? 0.5 : 0.0));
        } catch (e) {
          print('Lỗi khi chuyển đổi tính hiển thị của tất cả các huyện: $e');
          // Xử lý lỗi một cách phù hợp
        }
      }
    }
  }

  Future<void> clearDistrictsOnMap() async {
    for (var fills in _drawnDistricts.values) {
      for (var fill in fills) {
        try {
          await _mapController.removeFill(fill);
        } catch (e) {
          print('Lỗi khi xóa fill của huyện: $e');
          // Xử lý lỗi một cách phù hợp
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
        // Xử lý lỗi một cách phù hợp
      }
    }
  }

  Future<void> clearPolygonsOnMap() async {
    for (var line in _drawnPolygons) {
      try {
        await _mapController.removeLine(line);
      } catch (e) {
        print('Lỗi khi xóa đường của đa giác: $e');
        // Xử lý lỗi một cách phù hợp
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
          // Xử lý lỗi một cách phù hợp
        }
      }
    } catch (e) {
      print('lỗi: $e');
    }
  }
}
