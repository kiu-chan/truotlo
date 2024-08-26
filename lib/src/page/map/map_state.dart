import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/district_data.dart';
import 'package:truotlo/src/data/map/map_data.dart';
import 'package:truotlo/src/config/map.dart';
import 'package:truotlo/src/database/database.dart';
import 'package:truotlo/src/database/commune.dart';
import 'package:truotlo/src/data/map/landslide_point.dart';
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
  List<List<LatLng>> borderPolygons = [];
  List<Commune> communes = [];
  List<LandslidePoint> landslidePoints = [];
  Map<int, bool> districtVisibility = {};

  bool isDistrictsLoaded = false;
  bool isBorderLoaded = false;
  bool isCommunesLoaded = false;
  bool isLandslidePointsLoaded = false;

  bool _isMapInitialized = false;

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
    if (database.connection != null && !isDistrictsLoaded) {
      try {
        districts = await database.fetchDistrictsData();
        districtVisibility = {
          for (var district in districts) district.id: true
        };
        isDistrictsLoaded = true;
        setState(() {});
        if (_isMapInitialized) {
          await _mapUtils.drawDistrictsOnMap(districts);
        }
      } catch (e) {
        print('Lỗi khi lấy dữ liệu huyện: $e');
        showErrorSnackBar('Không thể tải dữ liệu huyện. Vui lòng thử lại sau.');
      }
    }
  }

  // Phương thức lấy dữ liệu đường biên
  Future<void> _fetchBorderPolygons() async {
    if (database.connection != null && !isBorderLoaded) {
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
    if (database.connection != null && !isCommunesLoaded) {
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
    if (database.connection != null && !isLandslidePointsLoaded) {
      try {
        landslidePoints = await database.fetchLandslidePoints();
        isLandslidePointsLoaded = true;
        setState(() {});
        if (_isMapInitialized) {
          await _mapUtils.drawLandslidePointsOnMap(landslidePoints);
        }
      } catch (e) {
        print('Lỗi khi lấy dữ liệu điểm trượt lở: $e');
        showErrorSnackBar(
            'Không thể tải dữ liệu điểm trượt lở. Vui lòng thử lại sau.');
      }
    }
  }

  // Phương thức khởi tạo bản đồ
  void onMapCreated(MapboxMapController controller) async {
    mapController = controller;
    _mapUtils = MapUtils(mapController);
    _isMapInitialized = true;

    final ByteData bytes = await rootBundle.load('lib/assets/landslide.png');
    final Uint8List list = bytes.buffer.asUint8List();
    await mapController.addImage("location_on", list);

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
    if (isLandslidePointsVisible && isLandslidePointsLoaded) {
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
      Map<String, dynamic> landslideDetail =
          await database.landslideDatabase.fetchLandslideDetail(landslideId);
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

  // Phương thức hiển thị hộp thoại chi tiết điểm trượt lở
  void showLandslideDetailDialog(Map<String, dynamic> landslideDetail) {
    LatLng landslideLocation;
    try {
      landslideLocation = LatLng(
          double.parse(landslideDetail['lat'].toString()),
          double.parse(landslideDetail['lon'].toString()));
    } catch (e) {
      print('Error parsing coordinates: $e');
      // Xử lý lỗi ở đây, có thể là hiển thị một thông báo lỗi
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
                  Text('ID: ${landslideDetail['id']}'),
                  Text('Vị trí: ${landslideDetail['vi_tri']}'),
                  Text(
                      'Xã: ${landslideDetail['commune_name'] ?? landslideDetail['ten_xa'] ?? 'Không có thông tin'}'),
                  Text(
                      'Huyện: ${landslideDetail['district_name'] ?? 'Không có thông tin'}'),
                  Text('Mô tả: ${landslideDetail['mo_ta']}'),
                  Text('Mô tả: ' +
                      (landslideDetail['lat'] +
                      ', ' +
                      landslideDetail['lon'])),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    child: const Text('Khoảng cách theo đường chim bay'),
                    onPressed: () {
                      if (currentLocation != null) {
                        double distance = _calculateDistance(
                            currentLocation!, landslideLocation);
                        setState(() {
                          landslideDetail['distance'] = distance;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Không thể xác định vị trí hiện tại')),
                        );
                      }
                    },
                  ),
                  if (landslideDetail.containsKey('distance'))
                    Text(
                        'Khoảng cách: ${landslideDetail['distance'].toStringAsFixed(5)} km'),
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
