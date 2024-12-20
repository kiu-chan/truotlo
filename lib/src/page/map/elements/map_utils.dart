import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/district_data.dart';
import 'package:truotlo/src/data/map/landslide_point.dart';
import 'package:truotlo/src/database/commune.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show max;

class MapUtils {
  final MapboxMapController _mapController;
  Line? _routeLine;
  Symbol? _destinationMarker;
  Circle? _locationCircle;
  final Map<int, List<Line>> _drawnDistricts = {};
  final List<Line> _drawnPolygons = [];
  final List<Line> _drawnCommunes = [];
  final List<Symbol> _drawnLandslidePoints = [];
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
  }

  Future<void> drawLandslidePointsOnMap(
    List<LandslidePoint> points, {
    bool showOnlyLandslideRisk = false,
    bool showOnlyFlashFloodRisk = false,
    bool showOnlyLargeSlideRisk = false,
  }) async {
    await clearLandslidePointsOnMap();

    // Tải trước tất cả các icon cảnh báo
    for (int i = 0; i <= 5; i++) {
      final ByteData bytes = await rootBundle.load('lib/assets/map/landslide_$i.png');
      final Uint8List list = bytes.buffer.asUint8List();
      await _mapController.addImage("landslide_$i", list);
    }

    try {
      final forecastResponse = await http.get(
        Uri.parse('http://truotlobinhdinh.girc.edu.vn/api/forecast-points')
      );

      Map<String, Map<String, dynamic>> forecastMap = {};

      if (forecastResponse.statusCode == 200) {
        final responseData = json.decode(forecastResponse.body);
        // Debug: In ra cấu trúc dữ liệu
        print('Response data structure: ${responseData.runtimeType}');
        print('Response data: $responseData');
        
        if (responseData is Map<String, dynamic> && 
            responseData.containsKey('data') && 
            responseData['data'] is Map<String, dynamic>) {
          
          final Map<String, dynamic> dataMap = responseData['data'];
          // Lấy timestamp mới nhất (key đầu tiên trong map)
          if (dataMap.isNotEmpty) {
            String latestTimestamp = dataMap.keys.first;
            final forecastPoints = dataMap[latestTimestamp];
            
            if (forecastPoints is List) {
              for (var forecast in forecastPoints) {
                if (forecast is Map<String, dynamic>) {
                  String tenDiem = forecast['ten_diem']?.toString().replaceAll('"', '') ?? '';
                  if (tenDiem.isNotEmpty) {
                    forecastMap[tenDiem] = forecast;
                  }
                }
              }
            }
          }
        }
      }

      // Tạo tất cả các điểm cùng một lúc để tối ưu hiệu suất
      List<Future<Symbol>> symbolFutures = [];

      for (var point in points) {
        String objectId = point.objectId.toString();
        Map<String, dynamic>? matchingForecast = forecastMap[objectId];

        // Nếu không có dự báo và đang bật một trong các bộ lọc, bỏ qua điểm này
        if (matchingForecast == null && (showOnlyLandslideRisk || showOnlyFlashFloodRisk || showOnlyLargeSlideRisk)) {
          continue;
        }

        double landslideValue = 0;
        double flashFloodValue = 0;
        double largeSlideValue = 0;

        if (matchingForecast != null) {
          try {
            landslideValue = double.tryParse(matchingForecast['nguy_co_truot_nong']?.toString() ?? '0') ?? 0;
            flashFloodValue = double.tryParse(matchingForecast['nguy_co_lu_quet']?.toString() ?? '0') ?? 0;
            largeSlideValue = double.tryParse(matchingForecast['nguy_co_truot_lon']?.toString() ?? '0') ?? 0;
          } catch (e) {
            print('Lỗi khi parse giá trị nguy cơ cho điểm $objectId: $e');
          }
        }

        // Kiểm tra các điều kiện lọc
        bool shouldDisplay = true;
        if (showOnlyLandslideRisk && landslideValue <= 0) shouldDisplay = false;
        if (showOnlyFlashFloodRisk && flashFloodValue <= 0) shouldDisplay = false;
        if (showOnlyLargeSlideRisk && largeSlideValue <= 0) shouldDisplay = false;

        if (!shouldDisplay) {
          print('Bỏ qua điểm $objectId do không thỏa mãn điều kiện lọc');
          continue;
        }

        // Xác định icon dựa trên giá trị cao nhất
        String iconImage = 'landslide_0';
        double maxValue = 0;

        if (matchingForecast != null) {
          if (showOnlyLandslideRisk) {
            maxValue = landslideValue;
          } else if (showOnlyFlashFloodRisk) {
            maxValue = flashFloodValue;
          } else if (showOnlyLargeSlideRisk) {
            maxValue = largeSlideValue;
          } else {
            maxValue = [landslideValue, flashFloodValue, largeSlideValue].reduce(max);
          }

          if (maxValue >= 5) {
            iconImage = 'landslide_5';
          } else if (maxValue >= 4) {
            iconImage = 'landslide_4';
          } else if (maxValue >= 3) {
            iconImage = 'landslide_3';
          } else if (maxValue >= 2) {
            iconImage = 'landslide_2';
          } else if (maxValue >= 1) {
            iconImage = 'landslide_1';
          }
        }

        print('Adding point $objectId with maxValue: $maxValue, icon: $iconImage');

        // Tạo symbol và thêm vào danh sách futures
        symbolFutures.add(_mapController.addSymbol(
          SymbolOptions(
            geometry: point.location,
            iconImage: iconImage,
            iconSize: 0.15,
            textField: '', // Thêm trường này để đảm bảo symbol luôn hiển thị
            textOffset: const Offset(0, 0),
          ),
          {
            'id': point.id,
            'district': point.district,
            'object_id': point.objectId,
            'forecast_data': matchingForecast,
          },
        ));
      }

      // Chờ tất cả các symbol được tạo xong
      final symbols = await Future.wait(symbolFutures);
      _drawnLandslidePoints.addAll(symbols);

      // Cập nhật layer để đảm bảo các điểm hiển thị trên cùng
      await _mapController.setSymbolIconIgnorePlacement(true);

      print('Đã vẽ ${symbols.length} điểm trên bản đồ');

    } catch (e) {
      print('Lỗi khi vẽ điểm trượt lở: $e');
      print('Chi tiết lỗi: ${e.toString()}');
      print('Stack trace: ${StackTrace.current}');
    }
  }

// Thêm phương thức này vào lớp MapUtils
Future<Uint8List> _loadImageFromAsset(String assetName) async {
  final ByteData data = await rootBundle.load(assetName);
  return data.buffer.asUint8List();
}

  Future<void> ensureLandslidePointsOnTop() async {
    for (var symbol in _drawnLandslidePoints) {
      try {
        await _mapController.updateSymbol(
          symbol,
          const SymbolOptions(),
        );
      } catch (e) {
        print('Error updating landslide point zIndex: $e');
      }
    }
  }

Future<void> clearLandslidePointsOnMap() async {
  final symbolsToRemove = List<Symbol>.from(_drawnLandslidePoints);
  for (var symbol in symbolsToRemove) {
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

  Future<List<LatLng>> getRouteCoordinates(LatLng start, LatLng end, String accessToken) async {
    final String url = 'https://api.mapbox.com/directions/v5/mapbox/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&steps=true&overview=full&access_token=$accessToken';

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
    
    // Lưu trạng thái icon ban đầu nếu có
    if (_originalMarker == null) {
      Set<Symbol> symbols = _mapController.symbols;
      if (symbols.isNotEmpty) {
        _originalMarker = symbols.first;
      }
    }

    // Thêm marker mới cho điểm đến
    _destinationMarker = await _mapController.addSymbol(
      SymbolOptions(
        geometry: destination,
        iconImage: 'lib/assets/map/landslide_0.png',
        iconSize: 0.15,
      ),
    );

    // Ẩn marker ban đầu
    if (_originalMarker != null) {
      await _mapController.updateSymbol(_originalMarker!, const SymbolOptions(iconOpacity: 0));
    }
  }

  Future<void> clearRoute() async {
    if (_routeLine != null) {
      await _mapController.removeLine(_routeLine!);
      _routeLine = null;
    }
  }
}

class LandslideWarningUtils {
  /// Determines the appropriate warning level icon based on matching forecast and landslide points
  /// Returns a number from 0-5 indicating which landslide_X.png icon to use
  static int getWarningLevel(List<dynamic> forecastPoints, Map<String, dynamic> landslidePoint) {
    // Extract the numeric part from object_id 
    String objectId = landslidePoint['object_id'].toString();
    
    // Look for a matching forecast point
    for (var forecast in forecastPoints) {
      // Extract numeric part from ten_diem
      String tenDiem = forecast['ten_diem'].toString();
      
      // If we find a match
      if (objectId == tenDiem) {
        // Get nguy_co_truot_nong value and convert to warning level
        String nguyCo = forecast['nguy_co_truot_nong'].toString();
        
        // Convert nguy_co value to appropriate warning level (0-5)
        if (nguyCo == "0") return 0;
        try {
          double value = double.parse(nguyCo);
          if (value >= 5) return 5;
          if (value >= 4) return 4;
          if (value >= 3) return 3;
          if (value >= 2) return 2;
          if (value >= 1) return 1;
          return 0;
        } catch (e) {
          print('Error parsing nguy_co_truot_nong value: $e');
          return 0;
        }
      }
    }
    
    // If no match is found, return warning level 0
    return 0;
  }

  /// Gets the asset path for the warning icon based on the warning level
  static String getWarningIconPath(int warningLevel) {
    return 'lib/assets/map/landslide_$warningLevel.png';
  }

  /// Updates symbol options with the appropriate warning icon
  static SymbolOptions getSymbolOptionsForWarningLevel(
    int warningLevel,
    LatLng location,
    {double iconSize = 0.15}
  ) {
    return SymbolOptions(
      geometry: location,
      iconImage: 'landslide_$warningLevel',
      iconSize: iconSize,
    );
  }

  /// Preloads all warning icons into the map controller
  static Future<void> preloadWarningIcons(MapboxMapController controller) async {
    for (int i = 0; i <= 5; i++) {
      final ByteData data = await rootBundle.load('lib/assets/map/landslide_$i.png');
      final Uint8List bytes = data.buffer.asUint8List();
      await controller.addImage('landslide_$i', bytes);
    }
  }
}