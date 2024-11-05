import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/district_data.dart';
import 'package:truotlo/src/data/map/map_data.dart';
import 'package:truotlo/src/config/map.dart';
import 'package:truotlo/src/database/database.dart';
import 'package:truotlo/src/database/commune.dart';
import 'package:truotlo/src/data/map/landslide_point.dart';
import 'package:url_launcher/url_launcher.dart';
import 'elements/map_utils.dart';
import 'elements/location_service.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math' show cos, sqrt, asin;

mixin MapState<T extends StatefulWidget> on State<T> {
  // Các biến trạng thái
  String currentStyle = MapboxStyles.MAPBOX_STREETS;
  late MapboxMapController mapController;
  late MapUtils _mapUtils;
  final List<MapStyleCategory> styleCategories =
      MapConfig().getStyleCategories();
  final DefaultDatabase database = DefaultDatabase();
  final LocationService locationService = LocationService();

  LatLng defaultTarget = MapConfig().getDefaultTarget();
  double defaultZoom = MapConfig().getDefaultZoom();
  String mapToken = MapConfig().getMapToken();

  LatLng? currentLocation;
  bool isDistrictsVisible = true;
  bool isBorderVisible = false;
  bool isCommunesVisible = false;
  bool isLandslidePointsVisible = true;
  List<District> districts = [];
  Set<String> allDistricts = {};
  List<Symbol> _districtLabels = [];
  List<Symbol> _communeLabels = [];
  List<List<LatLng>> borderPolygons = [];
  List<Commune> communes = [];
  List<LandslidePoint> landslidePoints = [];
  Map<int, bool> districtVisibility = {};
  Map<String, bool> districtLandslideVisibility = {};

  int? _currentSearchId;

  bool _isRouteDisplayed = false;
  int? _currentRouteId;

  bool isDistrictsLoaded = false;
  bool isBorderLoaded = false;
  bool isCommunesLoaded = false;
  bool isLandslidePointsLoaded = false;

  bool _isMapInitialized = false;

  @override
  void initState() {
    super.initState();
    connectToDatabase();
    initializeLocationService();
  }

  // Phương thức khởi tạo kết nối đến cơ sở dữ liệu
  Future<void> connectToDatabase() async {
    await database.connect();
  }

  // Phương thức khởi tạo dữ liệu ban đầu
  Future<void> _initializeData() async {
    if (isDistrictsVisible) {
      await _fetchDistricts();
    }
    if (isBorderVisible) {
      await _fetchBorderPolygons();
    }
    if (isCommunesVisible) {
      await _fetchCommunes();
    }
    if (isLandslidePointsVisible) {
      await _fetchLandslidePoints();
    }
  }

  // Phương thức lấy dữ liệu các huyện
  Future<void> _fetchDistricts() async {
    if (!isDistrictsLoaded) {
      try {
        districts = await database.fetchDistrictsData();
        districtVisibility = {
          for (var district in districts) district.id: true
        };
        isDistrictsLoaded = true;
        setState(() {});
        if (_isMapInitialized) {
          await _mapUtils.drawDistrictsOnMap(districts);
          await _drawDistrictLabels();
        }
      } catch (e) {
        print('Lỗi khi lấy dữ liệu huyện: $e');
        showErrorSnackBar('Không thể tải dữ liệu huyện. Vui lòng thử lại sau.');
      }
    }
  }

  // Phương thức lấy dữ liệu đường biên
  Future<void> _fetchBorderPolygons() async {
    if (!isBorderLoaded) {
      try {
        borderPolygons = await database.borderDatabase.fetchAndParseGeometry();
        isBorderLoaded = true;
        setState(() {});
        if (_isMapInitialized) {
          await _mapUtils.drawPolygonsOnMap(borderPolygons);
        }
      } catch (e) {
        print('Lỗi khi lấy dữ liệu đường viền: $e');
        showErrorSnackBar(
            'Không thể tải dữ liệu đường viền. Vui lòng thử lại sau.');
      }
    }
  }

  // Phương thức lấy dữ liệu các xã
  Future<void> _fetchCommunes() async {
    if (!isCommunesLoaded) {
      try {
        communes = await database.fetchCommunesData();
        isCommunesLoaded = true;
        setState(() {});
        if (_isMapInitialized) {
          await _mapUtils.drawCommunesOnMap(communes);
        }
      } catch (e) {
        print('Lỗi khi lấy dữ liệu xã: $e');
        showErrorSnackBar('Không thể tải dữ liệu xã. Vui lòng thử lại sau.');
      }
    }
  }

  // Phương thức lấy dữ liệu các điểm trượt lở
  Future<void> _fetchLandslidePoints() async {
    if (!isLandslidePointsLoaded) {
      try {
        landslidePoints = await database.fetchLandslidePoints();
        isLandslidePointsLoaded = true;

        // Initialize district visibility
        allDistricts = landslidePoints.map((point) => point.district).toSet();
        districtLandslideVisibility = {
          for (var district in allDistricts) district: true
        };

        setState(() {});
        if (_isMapInitialized) {
          await _mapUtils.drawLandslidePointsOnMap(landslidePoints);
          _updateLandslidePointsVisibility();
        }
      } catch (e) {
        print('Error fetching landslide points: $e');
        showErrorSnackBar(
            'Unable to load landslide point data. Please try again later.');
      }
    }
  }

  void toggleDistrictLandslideVisibility(String district, bool? value) {
    if (value != null) {
      setState(() {
        districtLandslideVisibility[district] = value;
      });
      _updateLandslidePointsVisibility();
    }
  }

  void _updateLandslidePointsVisibility() {
    if (_isMapInitialized) {
      _mapUtils.updateLandslidePointsVisibility(
          landslidePoints, districtLandslideVisibility);
    }
  }

  // Phương thức khởi tạo bản đồ
  void onMapCreated(MapboxMapController controller) async {
    mapController = controller;
    _mapUtils = MapUtils(mapController);
    _isMapInitialized = true;

    await _initializeData();

    mapController.onSymbolTapped.add(onSymbolTapped);
  }

  // Phương thức xử lý khi style bản đồ được tải
  void onStyleLoaded() async {
    if (isDistrictsVisible && isDistrictsLoaded) {
      await _mapUtils.drawDistrictsOnMap(districts);
    }
    if (isBorderVisible && isBorderLoaded) {
      await _mapUtils.drawPolygonsOnMap(borderPolygons);
    }
    if (isCommunesVisible && isCommunesLoaded) {
      await _mapUtils.drawCommunesOnMap(communes);
    }

    // Thêm hình ảnh cho điểm trượt lở
    final ByteData bytes =
        await rootBundle.load('lib/assets/map/landslide_0.png');
    final Uint8List list = bytes.buffer.asUint8List();
    await mapController.addImage("location_on", list);

    if (isLandslidePointsVisible && isLandslidePointsLoaded) {
      await _mapUtils.clearLandslidePointsOnMap();
      await _mapUtils.drawLandslidePointsOnMap(landslidePoints);
    }

    for (var district in districts) {
      await _mapUtils.toggleDistrictVisibility(
          district.id, districtVisibility[district.id] ?? true);
    }
    await _mapUtils.toggleBorderVisibility(isBorderVisible);
    await _mapUtils.toggleCommunesVisibility(isCommunesVisible);
    await _mapUtils.toggleLandslidePointsVisibility(isLandslidePointsVisible);

    if (currentLocation != null) {
      await _mapUtils.updateLocationOnMap(currentLocation!);
    }
  }

  // Phương thức xử lý khi người dùng nhấn vào biểu tượng trên bản đồ
  void onSymbolTapped(Symbol symbol) async {
    if (symbol.data != null && symbol.data!['id'] != null) {
      int landslideId = symbol.data!['id'];
      Map<String, dynamic> landslideDetail = await database.landslideDatabase.fetchLandslideDetail(landslideId);
      
      // Thêm thông tin forecast vào landslideDetail
      if (symbol.data!['forecast_data'] != null) {
        Map<String, dynamic> forecastData = symbol.data!['forecast_data'];
        landslideDetail['nguy_co_lu_quet'] = forecastData['nguy_co_lu_quet'];
        landslideDetail['nguy_co_truot_nong'] = forecastData['nguy_co_truot_nong'];
        landslideDetail['nguy_co_truot_lon'] = forecastData['nguy_co_truot_lon'];
      }
      
      showLandslideDetailDialog(landslideDetail);
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  double calculateDistance(LatLng start, LatLng end) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  String convertToDMS(double coordinate, bool isLatitude) {
    String direction = isLatitude
        ? (coordinate >= 0 ? "N" : "S")
        : (coordinate >= 0 ? "E" : "W");

    coordinate = coordinate.abs();
    int degrees = coordinate.floor();
    double minutesDecimal = (coordinate - degrees) * 60;
    int minutes = minutesDecimal.floor();
    double seconds = (minutesDecimal - minutes) * 60;

    return "${degrees.toString().padLeft(3, '0')}° ${minutes.toString().padLeft(2, '0')}' ${seconds.toStringAsFixed(2).padLeft(5, '0')}\" $direction";
  }

  // Phương thức hiển thị hộp thoại chi tiết điểm trượt lở
void showLandslideDetailDialog(Map<String, dynamic> landslideDetail) {
  LatLng landslideLocation;
  try {
    landslideLocation = LatLng(
      double.parse(landslideDetail['lat'].toString()),
      double.parse(landslideDetail['lon'].toString()),
    );
  } catch (e) {
    print('Error parsing coordinates: $e');
    showErrorSnackBar('Lỗi khi xử lý tọa độ điểm trượt lở.');
    return;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Thông tin điểm trượt lở'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                buildInfoRow('Xã', landslideDetail['commune_name'] ?? landslideDetail['ten_xa'] ?? 'Không có thông tin'),
                buildInfoRow('Huyện', landslideDetail['district_name'] ?? 'Không có thông tin'),
                buildInfoRow('Vị trí', landslideDetail['vi_tri'] ?? 'Không có thông tin'),
                buildInfoRow('Tọa độ', 
                  'Kinh độ ${convertToDMS(landslideDetail['lon'], false)}, '
                  'Vĩ độ ${convertToDMS(landslideDetail['lat'], true)}'
                ),
                buildInfoRow('Mô tả', landslideDetail['mo_ta'] ?? 'Không có thông tin'),
                
                // Thêm 3 loại nguy cơ
                const SizedBox(height: 20),
                buildRiskRow(
                  'Nguy cơ lũ quét:',
                  landslideDetail['nguy_co_lu_quet']?.toString() ?? 'Không có thông tin',
                  _getRiskColor(landslideDetail['nguy_co_lu_quet']?.toString())
                ),
                buildRiskRow(
                  'Nguy cơ trượt nông:',
                  landslideDetail['nguy_co_truot_nong']?.toString() ?? 'Không có thông tin',
                  _getRiskColor(landslideDetail['nguy_co_truot_nong']?.toString())
                ),
                buildRiskRow(
                  'Nguy cơ trượt lớn:',
                  landslideDetail['nguy_co_truot_lon']?.toString() ?? 'Không có thông tin',
                  _getRiskColor(landslideDetail['nguy_co_truot_lon']?.toString())
                ),
                
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text('Khoảng cách theo đường chim bay'),
                  onPressed: () {
                    if (currentLocation != null) {
                      double distance = _calculateDistance(currentLocation!, landslideLocation);
                      setState(() {
                        landslideDetail['distance'] = distance;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Không thể xác định vị trí hiện tại')),
                      );
                    }
                  },
                ),
                if (landslideDetail.containsKey('distance'))
                  Center(
                    child: Text(
                      'Khoảng cách: ${landslideDetail['distance'].toStringAsFixed(2)} km'
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text('Tìm đường trực tiếp'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _findRoute(landslideLocation, landslideDetail['id']);
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text('Mở trong Google Maps'),
                  onPressed: () => _openGoogleMaps(landslideLocation),
                ),
                if (landslideDetail['images'] != null &&
                    (landslideDetail['images'] as List).isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Hình ảnh:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...buildImageList(landslideDetail['images']),
                ]
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
    },
  );
}

Widget buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    ),
  );
}

Widget buildRiskRow(String label, String value, Color textColor) {
  String displayValue;
  if (value == "0") {
    displayValue = "Không có";
  } else if (value == "1") {
    displayValue = "Rất thấp";
  } else if (double.tryParse(value) != null) {
    double numValue = double.parse(value);
    if (numValue >= 5) {
      displayValue = "Rất cao";
    } else if (numValue >= 4) {
      displayValue = "Cao";
    } else if (numValue >= 3) {
      displayValue = "Trung bình";
    } else if (numValue >= 2) {
      displayValue = "Thấp";
    } else {
      displayValue = "Rất thấp";
    }
  } else {
    displayValue = "Không xác định";
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            displayValue,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

Color _getRiskColor(String? value) {
  if (value == null || value == "0") return Colors.black;
  try {
    double numValue = double.parse(value);
    if (numValue >= 5) return Colors.purple; // Rất cao
    if (numValue >= 4) return Colors.red; // Cao
    if (numValue >= 3) return Colors.orange; // Trung bình
    if (numValue >= 2) return Colors.blue; // Thấp
    return Colors.green; // Rất thấp
  } catch (e) {
    return Colors.black;
  }
}

List<Widget> buildImageList(List<dynamic> images) {
  return images.map((image) {
    String imageUrl = 'http://truotlobinhdinh.girc.edu.vn/storage/$image';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Image.network(
        imageUrl,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Text('Không thể tải hình ảnh');
        },
      ),
    );
  }).toList();
}

  void _findRoute(LatLng destination, int destinationId) async {
    if (currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xác định vị trí hiện tại')),
      );
      return;
    }

    setState(() {
      _isRouteDisplayed = true;
      _currentRouteId = destinationId;
      _currentSearchId = destinationId;
    });

    _showSearchingSnackBar(destinationId);

    try {
      List<LatLng> routeCoordinates = await _mapUtils.getRouteCoordinates(
        currentLocation!,
        destination,
        mapToken,
      );

      if (_currentSearchId != destinationId) {
        // Tìm kiếm đã bị hủy
        return;
      }

      await _mapUtils.drawRouteOnMap(routeCoordinates);

      LatLngBounds bounds = _calculateBounds(routeCoordinates);

      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds));

      setState(() {
        _isRouteDisplayed = true;
        _currentRouteId = destinationId;
      });
    } catch (e) {
      print('Error finding route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Không thể tìm đường đi. Vui lòng thử lại sau.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _currentSearchId = null;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    }
  }

  void _openGoogleMaps(LatLng destination) async {
    if (currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xác định vị trí hiện tại')),
      );
      return;
    }

    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${currentLocation!.latitude},${currentLocation!.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving';

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Không thể mở Google Maps. Vui lòng cài đặt ứng dụng Google Maps.')),
      );
    }
  }

  void _cancelRouteDisplay() {
    _mapUtils.clearRoute();
    setState(() {
      _isRouteDisplayed = false;
      _currentRouteId = null;
    });
  }

  Widget buildRouteInfo() {
    if (!_isRouteDisplayed) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Text('Đường đi tới ($_currentRouteId)'),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelRouteDisplay,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchingSnackBar(int destinationId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('Đang tìm đường đến ($destinationId)'),
          ],
        ),
        duration: const Duration(days: 365), // Snackbar sẽ không tự động đóng
        action: SnackBarAction(
          label: 'Hủy',
          onPressed: () {
            setState(() {
              _currentSearchId = null;
            });
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _mapUtils.clearRoute();
          },
        ),
      ),
    );
  }

  LatLngBounds _calculateBounds(List<LatLng> coordinates) {
    double minLat = coordinates[0].latitude;
    double maxLat = coordinates[0].latitude;
    double minLng = coordinates[0].longitude;
    double maxLng = coordinates[0].longitude;

    for (LatLng coord in coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _drawDistrictLabels() async {
    await _removeDistrictLabels();
    for (var district in districts) {
      LatLng center = _calculatePolygonCenter(district.polygons);
      Symbol symbol = await mapController.addSymbol(
        SymbolOptions(
          geometry: center,
          textField: district.name,
          textOffset: const Offset(0, 0.8),
          textAnchor: 'top',
          textSize: 16, // Tăng kích thước chữ
          textColor: '#000000',
          textHaloColor: '#FFFFFF', // Thêm viền trắng xung quanh chữ
          textHaloWidth: 2, // Độ rộng của viền
        ),
      );
      _districtLabels.add(symbol);
    }
  }

  Future<void> _removeDistrictLabels() async {
    for (var symbol in _districtLabels) {
      await mapController.removeSymbol(symbol);
    }
    _districtLabels.clear();
  }

  Future<void> _drawCommuneLabels() async {
    await _removeCommuneLabels();
    for (var commune in communes) {
      LatLng center = _calculatePolygonCenter(commune.polygons);
      Symbol symbol = await mapController.addSymbol(
        SymbolOptions(
          geometry: center,
          textField: commune.name,
          textOffset: const Offset(0, 0.8),
          textAnchor: 'top',
          textSize: 10,
          textColor: '#000000',
        ),
      );
      _communeLabels.add(symbol);
    }
  }

  Future<void> _removeCommuneLabels() async {
    for (var symbol in _communeLabels) {
      await mapController.removeSymbol(symbol);
    }
    _communeLabels.clear();
  }

  LatLng _calculatePolygonCenter(List<List<LatLng>> polygons) {
    double sumLat = 0, sumLng = 0;
    int totalPoints = 0;

    for (var polygon in polygons) {
      for (var point in polygon) {
        sumLat += point.latitude;
        sumLng += point.longitude;
        totalPoints++;
      }
    }

    return LatLng(sumLat / totalPoints, sumLng / totalPoints);
  }

  // Phương thức chuyển đổi hiển thị các huyện
  void toggleDistrictsVisibility(bool? value) async {
    if (value != null) {
      setState(() {
        isDistrictsVisible = value;
      });
      if (isDistrictsVisible && !isDistrictsLoaded) {
        await _fetchDistricts();
      } else {
        await _mapUtils.toggleAllDistrictsVisibility(value);
      }

      if (isDistrictsVisible) {
        await _drawDistrictLabels();
      } else {
        await _removeDistrictLabels();
      }
    }
  }

  // Phương thức chuyển đổi hiển thị đường biên
  void toggleBorderVisibility(bool? value) async {
    if (value != null) {
      setState(() {
        isBorderVisible = value;
      });
      if (isBorderVisible && !isBorderLoaded) {
        await _fetchBorderPolygons();
      } else {
        await _mapUtils.toggleBorderVisibility(value);
      }
    }
  }

// Phương thức chuyển đổi hiển thị các xã
  void toggleCommunesVisibility(bool? value) async {
    if (value != null) {
      setState(() {
        isCommunesVisible = value;
      });
      if (isCommunesVisible && !isCommunesLoaded) {
        await _fetchCommunes();
      } else {
        await _mapUtils.toggleCommunesVisibility(value);
      }

      if (isCommunesVisible) {
        await _drawCommuneLabels();
      } else {
        await _removeCommuneLabels();
      }
    }
  }

  // Phương thức chuyển đổi hiển thị các điểm trượt lở
  void toggleLandslidePointsVisibility(bool? value) async {
    if (value != null) {
      setState(() {
        isLandslidePointsVisible = value;
      });
      if (isLandslidePointsVisible && !isLandslidePointsLoaded) {
        await _fetchLandslidePoints();
      } else {
        await _mapUtils.toggleLandslidePointsVisibility(value);
      }
    }
  }

  // Phương thức chuyển đổi hiển thị một huyện cụ thể
  void toggleDistrictVisibility(int districtId, bool? value) async {
    if (value != null) {
      setState(() {
        districtVisibility[districtId] = value;
      });
      await _mapUtils.toggleDistrictVisibility(districtId, value);
    }
  }

  // Phương thức thay đổi style bản đồ
  void changeMapStyle(String? style) {
    if (style != null) {
      setState(() {
        currentStyle = style;
      });
      // Vẽ lại các điểm trượt lở sau khi thay đổi style
      if (isLandslidePointsVisible && isLandslidePointsLoaded) {
        _mapUtils.clearLandslidePointsOnMap().then((_) {
          _mapUtils.drawLandslidePointsOnMap(landslidePoints);
        });
      }
      Navigator.pop(context);
    }
  }

  // Phương thức di chuyển đến vị trí hiện tại
  void moveToCurrentLocation() {
    if (currentLocation != null) {
      mapController.animateCamera(CameraUpdate.newLatLng(currentLocation!));
    }
  }

  // Phương thức di chuyển đến vị trí mặc định
  void moveToDefaultLocation() {
    mapController
        .animateCamera(CameraUpdate.newLatLngZoom(defaultTarget, defaultZoom));
  }

  // Phương thức khởi tạo dịch vụ vị trí
  void initializeLocationService() async {
    bool permissionGranted =
        await locationService.checkAndRequestLocationPermission(context);
    if (permissionGranted) {
      locationService.startLocationUpdates((location) {
        setState(() {
          currentLocation = location;
        });
        if (_isMapInitialized) {
          _mapUtils.updateLocationOnMap(location);
        }
      }, handleLocationError);
    }
  }

  // Phương thức xử lý lỗi vị trí
  void handleLocationError(dynamic e) {
    String errorMessage = 'Đã xảy ra lỗi khi lấy vị trí: $e';
    print(errorMessage);
    showErrorSnackBar(errorMessage);
  }

  // Phương thức hiển thị thông báo lỗi
  void showErrorSnackBar(String message) {
    if (mounted) {
      // Kiểm tra xem widget còn được mount hay không
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } else {
      // Xử lý trường hợp widget đã bị unmount
      print('Không thể hiển thị SnackBar: $message');
    }
  }

  @override
  void dispose() {
    locationService.stopLocationUpdates();
    mapController.onSymbolTapped.remove(onSymbolTapped);
    super.dispose();
  }
}
