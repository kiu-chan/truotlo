import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:truotlo/src/data/map/district_data.dart';
import 'package:truotlo/src/data/map/landslide_point.dart';
import 'package:truotlo/src/database/commune.dart';
import 'package:truotlo/src/page/home/elements/landslide/hourly_forecast_point.dart';

class MapUtils {
  final MapboxMapController _mapController;
  Line? _routeLine;
  Symbol? _destinationMarker;
  Circle? _locationCircle;
  final Map<int, List<Line>> _drawnDistricts = {};
  final List<Line> _drawnPolygons = [];
  final List<Line> _drawnCommunes = [];
  final List<Symbol> _drawnLandslidePoints = [];
  final Map<String, Symbol> _hourlyForecastSymbols = {};
  Symbol? _originalMarker;

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
        await _mapController.removeCircle(_locationCircle!);
      }
      _locationCircle = await _mapController.addCircle(circleOptions);
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
            lineColor: '#000000',
            lineWidth: 2.0,
            lineOpacity: 1.0,
          ),
        );
        lines.add(line);
      } catch (e) {
        print('Lỗi khi vẽ ranh giới huyện ${district.name}: $e');
      }
    }
    _drawnDistricts[district.id] = lines;
  }

  Future<void> toggleDistrictVisibility(int districtId, bool isVisible) async {
    if (_drawnDistricts.containsKey(districtId)) {
      for (var line in _drawnDistricts[districtId]!) {
        try {
          await _mapController.updateLine(
            line, 
            LineOptions(lineOpacity: isVisible ? 1.0 : 0.0)
          );
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
            line, 
            LineOptions(lineOpacity: isVisible ? 1.0 : 0.0)
          );
        } catch (e) {
          print('Lỗi khi chuyển đổi tính hiển thị của tất cả các huyện: $e');
        }
      }
    }
  }

  Future<void> drawPolygonsOnMap(List<List<LatLng>> polygons) async {
    await clearPolygonsOnMap();

    for (var polygon in polygons) {
      try {
        Line line = await _mapController.addLine(
          LineOptions(
            geometry: polygon,
            lineColor: "#FF1493", // Deep Pink color for borders
            lineWidth: 3.0,
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
    for (var line in _drawnPolygons) {
      try {
        await _mapController.updateLine(
          line, 
          LineOptions(lineOpacity: isVisible ? 1.0 : 0.0)
        );
      } catch (e) {
        print('Lỗi khi chuyển đổi tính hiển thị của đường biên: $e');
      }
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
              lineColor: "#808080", // Gray color for communes
              lineWidth: 1.0,
              lineOpacity: 1.0,
              linePattern: "dash",
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
          line, 
          LineOptions(lineOpacity: isVisible ? 1.0 : 0.0)
        );
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
          iconImage: 'landslide_0',
          iconSize: 0.15,
          iconColor: '#808080', // Màu xám cho các điểm cũ
          zIndex: 90, // zIndex thấp hơn các điểm dự báo
          iconOpacity: 0.7, // Độ trong suốt cao hơn
        ),
        {
          'id': point.id,
          'district': point.district,
          'isLandslide': true,
        },
      );
      _drawnLandslidePoints.add(symbol);
    } catch (e) {
      print('Error drawing landslide point: $e');
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
          symbol,
          SymbolOptions(iconOpacity: isVisible ? 1.0 : 0.0)
        );
      } catch (e) {
        print('Error toggling landslide point visibility: $e');
      }
    }
  }

  Future<void> clearHourlyForecastPoints() async {
    for (var symbol in _hourlyForecastSymbols.values) {
      try {
        await _mapController.removeSymbol(symbol);
      } catch (e) {
        print('Error removing hourly forecast point: $e');
      }
    }
    _hourlyForecastSymbols.clear();
  }

Future<void> drawHourlyForecastPoints(List<HourlyForecastPoint> points) async {
  await clearHourlyForecastPoints();

  for (var point in points) {
    try {
      String riskLevel = _determineRiskLevel(point);
      String iconImage = _getRiskLevelIcon(riskLevel);
      
      // Tạo hiệu ứng đổ bóng cho điểm dự báo
      await _mapController.addCircle(
        CircleOptions(
          geometry: LatLng(
            double.parse(point.viDo),
            double.parse(point.kinhDo),
          ),
          circleRadius: 12.0,
          circleColor: '#FFFFFF',
          circleOpacity: 0.3,
          circleStrokeWidth: 2,
          circleStrokeColor: '#000000',
          circleStrokeOpacity: 0.2,
        ),
      );
      
      Symbol symbol = await _mapController.addSymbol(
        SymbolOptions(
          geometry: LatLng(
            double.parse(point.viDo),
            double.parse(point.kinhDo),
          ),
          iconImage: iconImage,
          iconSize: 0.25, // Tăng kích thước biểu tượng
          iconColor: _getRiskColor(riskLevel),
          zIndex: 150, // Tăng zIndex để luôn hiển thị trên cùng
          iconAnchor: 'bottom',
          textField: '${point.viTri}\n${_getRiskText(point)}',
          textSize: 12,
          textOffset: const Offset(0, 0.8),
          textAnchor: 'top',
          textColor: '#000000',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 2,
          textHaloBlur: 1,
        ),
        {
          'id': point.id,
          'district': point.huyen,
          'isHourly': true,
          'data': point.toJson(),
        },
      );

      _hourlyForecastSymbols[point.id.toString()] = symbol;
      
      // Thêm hiệu ứng nhấp nháy (pulse effect)
      if (_getRiskValue(riskLevel) >= 4) { // Chỉ áp dụng cho mức độ cao và rất cao
        _addPulseEffect(
          LatLng(double.parse(point.viDo), double.parse(point.kinhDo)),
          _getRiskColor(riskLevel),
        );
      }
    } catch (e) {
      print('Error drawing hourly forecast point: $e');
    }
  }
}

String _getRiskColor(String riskLevel) {
  switch (riskLevel) {
    case 'very_high':
      return '#FF0000'; // Đỏ
    case 'high':
      return '#FF4500'; // Đỏ cam
    case 'medium':
      return '#FFA500'; // Cam
    case 'low':
      return '#FFFF00'; // Vàng
    case 'very_low':
      return '#90EE90'; // Xanh nhạt
    default:
      return '#008000'; // Xanh lá
  }
}

int _getRiskValue(String riskLevel) {
  switch (riskLevel) {
    case 'very_high':
      return 5;
    case 'high':
      return 4;
    case 'medium':
      return 3;
    case 'low':
      return 2;
    case 'very_low':
      return 1;
    default:
      return 0;
  }
}

Future<void> _addPulseEffect(LatLng location, String color) async {
  for (var i = 0; i < 3; i++) { // 3 vòng tròn cho hiệu ứng pulse
    await _mapController.addCircle(
      CircleOptions(
        geometry: location,
        circleRadius: 15.0 + (i * 5), // Kích thước tăng dần
        circleColor: color,
        circleOpacity: 0.3 - (i * 0.1), // Độ trong suốt tăng dần
        circleBlur: 1,
      ),
    );
  }
}

  String _getRiskText(HourlyForecastPoint point) {
    return 'LQ: ${point.nguyCoLuQuet}, TN: ${point.nguyCoTruotNong}, TL: ${point.nguyCoTruotLon}';
  }

  String _determineRiskLevel(HourlyForecastPoint point) {
    double luQuet = double.parse(point.nguyCoLuQuet);
    double truotNong = double.parse(point.nguyCoTruotNong);
    double truotLon = double.parse(point.nguyCoTruotLon);
    
    double maxRisk = [luQuet, truotNong, truotLon].reduce((max, value) => value > max ? value : max);
    
    if (maxRisk >= 5.0) return 'very_high';
    if (maxRisk >= 4.0) return 'high';
    if (maxRisk >= 3.0) return 'medium';
    if (maxRisk >= 2.0) return 'low';
    return 'very_low';
  }

  String _getRiskLevelIcon(String riskLevel) {
    switch (riskLevel) {
      case 'very_high':
        return 'landslide_5';
      case 'high':
        return 'landslide_4';
      case 'medium':
        return 'landslide_3';
      case 'low':
        return 'landslide_2';
      case 'very_low':
        return 'landslide_1';
      default:
        return 'landslide_0';
    }
  }

  Future<void> updateLandslidePointsVisibility(
    List<LandslidePoint> points,
    Map<String, bool> districtVisibility
  ) async {
    for (var symbol in _drawnLandslidePoints) {
      try {
        final pointData = symbol.data;
        if (pointData != null && pointData['district'] != null) {
          final district = pointData['district'] as String;
          final isVisible = districtVisibility[district] ?? true;
          await _mapController.updateSymbol(
            symbol,
            SymbolOptions(iconOpacity: isVisible ? 1.0 : 0.0),
          );
        }
      } catch (e) {
        print('Error updating landslide point visibility: $e');
      }
    }

    // Also update hourly forecast points visibility
    for (var symbol in _hourlyForecastSymbols.values) {
      try {
        final pointData = symbol.data;
        if (pointData != null && pointData['district'] != null) {
          final district = pointData['district'] as String;
          final isVisible = districtVisibility[district] ?? true;
          await _mapController.updateSymbol(
            symbol,
            SymbolOptions(iconOpacity: isVisible ? 1.0 : 0.0),
          );
        }
      } catch (e) {
        print('Error updating hourly forecast point visibility: $e');
      }
    }
  }

  Future<List<LatLng>> getRouteCoordinates(
    LatLng start, 
    LatLng end,
    String accessToken
  ) async {
    final url = 'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?geometries=geojson&steps=true&overview=full&access_token=$accessToken';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      final route = decodedBody['routes'][0]['geometry']['coordinates'] as List;
      return route.map((e) => LatLng(e[1] as double, e[0] as double)).toList();
    } else {
      throw Exception('Failed to load route');
    }
  }

  Future<void> drawRouteOnMap(List<LatLng> routeCoordinates) async {
    if (_routeLine != null) {
      await _mapController.removeLine(_routeLine!);
    }

    _routeLine = await _mapController.addLine(
      LineOptions(
        geometry: routeCoordinates,
        lineColor: "#3bb2d0",
        lineWidth: 5.0,
        lineOpacity: 0.8,
      ),
    );
  }

  Future<void> addDestinationMarker(LatLng destination) async {
    if (_destinationMarker != null) {
      await _mapController.removeSymbol(_destinationMarker!);
    }
    
    if (_originalMarker == null) {
      Set<Symbol> symbols = _mapController.symbols;
      if (symbols.isNotEmpty) {
        _originalMarker = symbols.first;
      }
    }

    _destinationMarker = await _mapController.addSymbol(
      SymbolOptions(
geometry: destination,
        iconImage: 'landslide_0',
        iconSize: 0.15,
        zIndex: 100,
      ),
    );

    if (_originalMarker != null) {
      await _mapController.updateSymbol(
        _originalMarker!,
        const SymbolOptions(iconOpacity: 0),
      );
    }
  }

  Future<void> clearRoute() async {
    if (_routeLine != null) {
      await _mapController.removeLine(_routeLine!);
      _routeLine = null;
    }

    if (_destinationMarker != null) {
      await _mapController.removeSymbol(_destinationMarker!);
      _destinationMarker = null;
    }

    if (_originalMarker != null) {
      await _mapController.updateSymbol(
        _originalMarker!,
        const SymbolOptions(iconOpacity: 1),
      );
    }
  }

  Future<void> clearAllPoints() async {
    await clearLandslidePointsOnMap();
    await clearHourlyForecastPoints();
    await clearRoute();
  }

  Future<void> resetMap() async {
    await clearAllPoints();
    await clearPolygonsOnMap();
    await clearCommunesOnMap();
    
    for (var lines in _drawnDistricts.values) {
      for (var line in lines) {
        try {
          await _mapController.removeLine(line);
        } catch (e) {
          print('Error removing district line: $e');
        }
      }
    }
    _drawnDistricts.clear();

    if (_locationCircle != null) {
      try {
        await _mapController.removeCircle(_locationCircle!);
        _locationCircle = null;
      } catch (e) {
        print('Error removing location circle: $e');
      }
    }
  }

  Future<void> addCustomSymbol(
    String id,
    LatLng location,
    String label,
    {
      String iconImage = 'landslide_0',
      double iconSize = 0.15,
      String? customColor,
      int zIndex = 99,
      Map<String, dynamic>? data,
    }
  ) async {
    try {
      final symbol = await _mapController.addSymbol(
        SymbolOptions(
          geometry: location,
          iconImage: iconImage,
          iconSize: iconSize,
          iconColor: customColor ?? '#FF0000',
          zIndex: zIndex,
          textField: label,
          textSize: 12,
          textOffset: const Offset(0, 0.5),
          textAnchor: 'top',
          textColor: '#000000',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 1,
        ),
        data,
      );
      _hourlyForecastSymbols[id] = symbol;
    } catch (e) {
      print('Error adding custom symbol: $e');
    }
  }

  Future<void> updateSymbolPosition(String id, LatLng newLocation) async {
    try {
      final symbol = _hourlyForecastSymbols[id];
      if (symbol != null) {
        await _mapController.updateSymbol(
          symbol,
          SymbolOptions(geometry: newLocation),
        );
      }
    } catch (e) {
      print('Error updating symbol position: $e');
    }
  }

  Future<void> removeSymbol(String id) async {
    try {
      final symbol = _hourlyForecastSymbols[id];
      if (symbol != null) {
        await _mapController.removeSymbol(symbol);
        _hourlyForecastSymbols.remove(id);
      }
    } catch (e) {
      print('Error removing symbol: $e');
    }
  }

  Future<void> highlightSymbol(String id) async {
    try {
      final symbol = _hourlyForecastSymbols[id];
      if (symbol != null) {
        await _mapController.updateSymbol(
          symbol,
          const SymbolOptions(
            iconSize: 0.2,
            iconColor: '#FFFF00', // Yellow for highlighting
          ),
        );
      }
    } catch (e) {
      print('Error highlighting symbol: $e');
    }
  }

  Future<void> unhighlightSymbol(String id) async {
    try {
      final symbol = _hourlyForecastSymbols[id];
      if (symbol != null) {
        await _mapController.updateSymbol(
          symbol,
          const SymbolOptions(
            iconSize: 0.15,
            iconColor: '#FF0000',
          ),
        );
      }
    } catch (e) {
      print('Error unhighlighting symbol: $e');
    }
  }

  Future<void> ensureLandslidePointsOnTop() async {
    for (var symbol in _drawnLandslidePoints) {
      try {
        await _mapController.updateSymbol(
          symbol,
          const SymbolOptions(zIndex: 98),
        );
      } catch (e) {
        print('Error updating landslide point zIndex: $e');
      }
    }

    for (var symbol in _hourlyForecastSymbols.values) {
      try {
        await _mapController.updateSymbol(
          symbol,
          const SymbolOptions(zIndex: 99),
        );
      } catch (e) {
        print('Error updating hourly forecast point zIndex: $e');
      }
    }
  }

  Future<Uint8List> _loadImageFromAsset(String assetName) async {
    final ByteData data = await rootBundle.load(assetName);
    return data.buffer.asUint8List();
  }

  Future<void> loadMapIcons() async {
    try {
      final icons = [
        'landslide_0',
        'landslide_1',
        'landslide_2',
        'landslide_3',
        'landslide_4',
        'landslide_5',
      ];

      for (var icon in icons) {
        final imageData = await _loadImageFromAsset('lib/assets/map/$icon.png');
        await _mapController.addImage(icon, imageData);
      }
    } catch (e) {
      print('Error loading map icons: $e');
    }
  }

  void dispose() {
    clearAllPoints();
    resetMap();
  }
}