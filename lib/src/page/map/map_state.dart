import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/district_data.dart';
import 'package:truotlo/src/data/map/landslide_point.dart';
import 'package:truotlo/src/data/forecast/hourly_forecast_response.dart';
import 'package:truotlo/src/data/map/map_data.dart';
import 'package:truotlo/src/database/database.dart';
import 'package:truotlo/src/database/commune.dart';
import 'package:truotlo/src/config/map.dart';
import 'package:truotlo/src/page/home/elements/landslide/hourly_forecast_point.dart';
import 'elements/map_utils.dart';
import 'elements/location_service.dart';
import 'dart:math' show cos, sqrt, asin;

mixin MapState<T extends StatefulWidget> on State<T> {
  // Basic Map Configuration
  String currentStyle = MapboxStyles.MAPBOX_STREETS;
  late MapboxMapController mapController;
  late MapUtils _mapUtils;
  final List<MapStyleCategory> styleCategories = MapConfig().getStyleCategories();
  final DefaultDatabase database = DefaultDatabase();
  final LocationService locationService = LocationService();

  LatLng defaultTarget = MapConfig().getDefaultTarget();
  double defaultZoom = MapConfig().getDefaultZoom();
  String mapToken = MapConfig().getMapToken();

  // State Variables
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

  // Hourly Forecast State
  List<HourlyForecastPoint> _hourlyForecastPoints = [];
  String _currentForecastHour = '';
  Timer? _refreshTimer;
  bool _isLoadingHourlyForecast = false;

  // Route State
  bool _isRouteDisplayed = false;
  int? _currentRouteId;
  int? _currentSearchId;

  // Loading State
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
    _fetchHourlyForecastPoints();
    _startPeriodicRefresh();
  }

  // Database Connection
  Future<void> connectToDatabase() async {
    await database.connect();
  }

  // Data Initialization Methods
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
        showErrorSnackBar('Không thể tải dữ liệu đường viền. Vui lòng thử lại sau.');
      }
    }
  }

  Future<void> _fetchCommunes() async {
    if (!isCommunesLoaded) {
      try {
        communes = await database.fetchCommunesData();
        isCommunesLoaded = true;
        setState(() {});
        if (_isMapInitialized) {
          await _mapUtils.drawCommunesOnMap(communes);
          await _drawCommuneLabels();
        }
      } catch (e) {
        print('Lỗi khi lấy dữ liệu xã: $e');
        showErrorSnackBar('Không thể tải dữ liệu xã. Vui lòng thử lại sau.');
      }
    }
  }

  Future<void> _fetchLandslidePoints() async {
    if (!isLandslidePointsLoaded) {
      try {
        landslidePoints = await database.fetchLandslidePoints();
        isLandslidePointsLoaded = true;

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
        showErrorSnackBar('Không thể tải dữ liệu điểm trượt lở. Vui lòng thử lại sau.');
      }
    }
  }

  // Hourly Forecast Methods
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _fetchHourlyForecastPoints();
    });
  }

  Future<void> _fetchHourlyForecastPoints() async {
    if (_isLoadingHourlyForecast) return;

    setState(() {
      _isLoadingHourlyForecast = true;
    });

    try {
      final response = await database.landslideDatabase.fetchHourlyForecastPoints();
      if (response.success && response.data.isNotEmpty) {
        final newHour = response.data.keys.first;
        final newPoints = response.data[newHour] ?? [];

        if (newHour != _currentForecastHour || 
            newPoints.length != _hourlyForecastPoints.length) {
          setState(() {
            _currentForecastHour = newHour;
            _hourlyForecastPoints = newPoints;
          });

          if (_isMapInitialized) {
            await _mapUtils.drawHourlyForecastPoints(newPoints);
          }

          _showUpdateNotification(newHour);
        }
      }
    } catch (e) {
      print('Error fetching hourly forecast points: $e');
      showErrorSnackBar('Không thể tải dữ liệu dự báo theo giờ. Vui lòng thử lại sau.');
    } finally {
      setState(() {
        _isLoadingHourlyForecast = false;
      });
    }
  }

  void _showUpdateNotification(String hour) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật dữ liệu dự báo cho $hour'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Đóng',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Map Event Handlers
  void onMapCreated(MapboxMapController controller) async {
    mapController = controller;
    _mapUtils = MapUtils(mapController);
    _isMapInitialized = true;

    await _mapUtils.loadMapIcons();
    await _initializeData();
    mapController.onSymbolTapped.add(onSymbolTapped);
  }

void onStyleLoaded() async {
  if (isDistrictsVisible && isDistrictsLoaded) {
    await _mapUtils.drawDistrictsOnMap(districts);
    for (var district in districts) {
      await _mapUtils.toggleDistrictVisibility(
        district.id,
        districtVisibility[district.id] ?? true
      );
    }
    LatLng center;
    for (var district in districts) {
      try {
        center = _calculatePolygonCenter(district.polygons);
        await mapController.addSymbol(
          SymbolOptions(
            geometry: center,
            textField: district.name,
            textOffset: const Offset(0, 0.8),
            textAnchor: 'top',
            textSize: 16,
            textColor: '#000000',
            textHaloColor: '#FFFFFF',
            textHaloWidth: 2,
            zIndex: 1,
          ),
        );
      } catch (e) {
        print('Lỗi khi vẽ label huyện: $e');
      }
    }
  }

  if (isBorderVisible && isBorderLoaded) {
    await _mapUtils.drawPolygonsOnMap(borderPolygons);
    await _mapUtils.toggleBorderVisibility(isBorderVisible);
  }

  if (isCommunesVisible && isCommunesLoaded) {
    await _mapUtils.drawCommunesOnMap(communes);
    await _mapUtils.toggleCommunesVisibility(isCommunesVisible);
    for (var commune in communes) {
      try {
        LatLng center = _calculatePolygonCenter(commune.polygons);
        await mapController.addSymbol(
          SymbolOptions(
            geometry: center,
            textField: commune.name,
            textOffset: const Offset(0, 0.8),
            textAnchor: 'top',
            textSize: 10,
            textColor: '#000000',
            textHaloColor: '#FFFFFF',
            textHaloWidth: 1,
            zIndex: 2,
          ),
        );
      } catch (e) {
        print('Lỗi khi vẽ label xã: $e');
      }
    }
  }

  // Thêm các icon cho các loại điểm
  for (String icon in ['landslide_0', 'landslide_1', 'landslide_2', 'landslide_3', 'landslide_4', 'landslide_5']) {
    try {
      ByteData bytes = await rootBundle.load('lib/assets/map/$icon.png');
      Uint8List list = bytes.buffer.asUint8List();
      await mapController.addImage(icon, list);
    } catch (e) {
      print('Lỗi khi tải icon $icon: $e');
    }
  }

  if (isLandslidePointsVisible && isLandslidePointsLoaded) {
    await _mapUtils.clearLandslidePointsOnMap();
    await _mapUtils.drawLandslidePointsOnMap(landslidePoints);
    await _mapUtils.toggleLandslidePointsVisibility(isLandslidePointsVisible);
  }

  // Vẽ các điểm dự báo theo giờ sau cùng để hiển thị trên cùng
  if (_hourlyForecastPoints.isNotEmpty) {
    await _mapUtils.clearHourlyForecastPoints();
    await _mapUtils.drawHourlyForecastPoints(_hourlyForecastPoints);
  }

  // Hiển thị vị trí hiện tại
  if (currentLocation != null) {
    await _mapUtils.updateLocationOnMap(currentLocation!);
  }

  // Đảm bảo các điểm luôn hiển thị trên cùng
  await _mapUtils.ensureLandslidePointsOnTop();
}

  // Symbol Management
  void onSymbolTapped(Symbol symbol) async {
    if (symbol.data != null && symbol.data!['id'] != null) {
      int landslideId = symbol.data!['id'];
      Map<String, dynamic> landslideDetail =
          await database.landslideDatabase.fetchLandslideDetail(landslideId);
      showLandslideDetailDialog(landslideDetail);
    }
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
          textSize: 16,
          textColor: '#000000',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 2,
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
          textHaloColor: '#FFFFFF',
          textHaloWidth: 1,
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

  // Visibility Controls
  void toggleDistrictVisibility(int districtId, bool? value) async {
    if (value != null) {
      setState(() {
        districtVisibility[districtId] = value;
      });
      await _mapUtils.toggleDistrictVisibility(districtId, value);
    }
  }

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
        landslidePoints, 
        districtLandslideVisibility
      );
    }
  }

  // Navigation and Route Methods
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
        const SnackBar(content: Text('Không thể tìm đường đi. Vui lòng thử lại sau.')),
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

  void _cancelRouteDisplay() {
    _mapUtils.clearRoute();
    setState(() {
      _isRouteDisplayed = false;
      _currentRouteId = null;
    });
  }

  void _showSearchingSnackBar(int destinationId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('Đang tìm đường đến điểm ($destinationId)'),
          ],
        ),
        duration: const Duration(days: 365),
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

  // Location Services
  void initializeLocationService() async {
    bool permissionGranted = await locationService.checkAndRequestLocationPermission(context);
    if (permissionGranted) {
      locationService.startLocationUpdates(
        (location) {
          setState(() {
            currentLocation = location;
          });
          if (_isMapInitialized) {
            _mapUtils.updateLocationOnMap(location);
          }
        },
        handleLocationError
      );
    }
  }

  void handleLocationError(dynamic e) {
    String errorMessage = 'Đã xảy ra lỗi khi lấy vị trí: $e';
    print(errorMessage);
    showErrorSnackBar(errorMessage);
  }

  // Map Navigation Controls
  void moveToCurrentLocation() {
    if (currentLocation != null) {
      mapController.animateCamera(CameraUpdate.newLatLng(currentLocation!));
    }
  }

  void moveToDefaultLocation() {
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(defaultTarget, defaultZoom)
    );
  }

  // Style Management
  void changeMapStyle(String? style) {
    if (style != null) {
      setState(() {
        currentStyle = style;
      });
      if (isLandslidePointsVisible && isLandslidePointsLoaded) {
        _mapUtils.clearLandslidePointsOnMap().then((_) {
          _mapUtils.drawLandslidePointsOnMap(landslidePoints);
        });
      }
    }
  }

  // Utility Methods
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

  double calculateDistance(LatLng start, LatLng end) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
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

    return "${degrees.toString().padLeft(3, '0')}° "
        "${minutes.toString().padLeft(2, '0')}' "
        "${seconds.toStringAsFixed(2).padLeft(5, '0')}\" "
        "$direction";
  }

  // Dialog and Error Handling
  void showLandslideDetailDialog(Map<String, dynamic> landslideDetail) {
    LatLng landslideLocation;
    try {
      landslideLocation = LatLng(
        double.parse(landslideDetail['lat'].toString()),
        double.parse(landslideDetail['lon'].toString())
      );
    } catch (e) {
      print('Error parsing coordinates: $e');
      showErrorSnackBar('Lỗi khi xử lý tọa độ điểm trượt lở.');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Thông tin điểm trượt lở'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Vị trí: ${landslideDetail['vi_tri']}'),
                    Text('Xã: ${landslideDetail['commune_name'] ?? landslideDetail['ten_xa'] ?? 'Không có thông tin'}'),
                    Text('Huyện: ${landslideDetail['district_name'] ?? 'Không có thông tin'}'),
                    Text('Mô tả: ${landslideDetail['mo_ta']}'),
                    Text(
                      'Tọa độ: ${convertToDMS(landslideLocation.longitude, false)}, '
                      '${convertToDMS(landslideLocation.latitude, true)}',
                    ),
                    const SizedBox(height: 20),
                    if (currentLocation != null) ...[
                      ElevatedButton(
                        child: const Text('Tính khoảng cách'),
                        onPressed: () {
                          double distance = calculateDistance(
                            currentLocation!,
                            landslideLocation
                          );
                          setState(() {
                            landslideDetail['distance'] = distance;
                          });
                        },
                      ),
                      if (landslideDetail.containsKey('distance'))
                        Text(
                          'Khoảng cách: ${landslideDetail['distance'].toStringAsFixed(2)} km'
                        ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      child: const Text('Tìm đường'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _findRoute(landslideLocation, landslideDetail['id']);
                      },
                    ),
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
          },
        );
      },
    );
  }

  void showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
      );
    }
  }

  // Route Information Widget
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
                child: Text('Đường đi tới điểm ($_currentRouteId)'),
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

  // Lifecycle Methods
  @override
  void dispose() {
    _refreshTimer?.cancel();
    locationService.stopLocationUpdates();
    mapController.onSymbolTapped.remove(onSymbolTapped);
    super.dispose();
  }
}