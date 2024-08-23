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
import 'menu.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

class MapboxPage extends StatefulWidget {
  const MapboxPage({super.key});

  @override
  MapboxPageState createState() => MapboxPageState();
}

class MapboxPageState extends State<MapboxPage> {
  String currentStyle = MapboxStyles.MAPBOX_STREETS;
  late MapboxMapController _mapController;
  late MapUtils _mapUtils;
  final List<MapStyleCategory> styleCategories =
      MapConfig().getStyleCategories();
  final DefaultDatabase _database = DefaultDatabase();
  final LocationService _locationService = LocationService();

  LatLng defaultTarget = MapConfig().getDefaultTarget();
  double defaultZoom = MapConfig().getDefaultZoom();
  String mapToken = MapConfig().getMapToken();

  LatLng? _currentLocation;
  bool _isDistrictsVisible = true;
  bool _isBorderVisible = false;
  bool _isCommunesVisible = false;
  bool _isLandslidePointsVisible = true;
  List<District> _districts = [];
  List<List<LatLng>> _borderPolygons = [];
  List<Commune> _communes = [];
  List<LandslidePoint> _landslidePoints = [];
  Map<int, bool> _districtVisibility = {};

  bool _isDistrictsLoaded = false;
  bool _isBorderLoaded = false;
  bool _isCommunesLoaded = false;
  bool _isLandslidePointsLoaded = false;

  bool _isMapInitialized = false;

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
    _initializeLocationService();
  }

  Future<void> _connectToDatabase() async {
    await _database.connect();
  }

  Future<void> _initializeData() async {
    if (_isDistrictsVisible) {
      await _fetchDistricts();
    }
    if (_isBorderVisible) {
      await _fetchBorderPolygons();
    }
    if (_isCommunesVisible) {
      await _fetchCommunes();
    }
    if (_isLandslidePointsVisible) {
      await _fetchLandslidePoints();
    }
  }

  Future<void> _fetchDistricts() async {
    if (_database.connection != null && !_isDistrictsLoaded) {
      try {
        _districts = await _database.fetchDistrictsData();
        _districtVisibility = {
          for (var district in _districts) district.id: true
        };
        _isDistrictsLoaded = true;
        setState(() {});
        if (_isMapInitialized) {
          await _mapUtils.drawDistrictsOnMap(_districts);
        }
      } catch (e) {
        print('Lỗi khi lấy dữ liệu huyện: $e');
        _showErrorSnackBar(
            'Không thể tải dữ liệu huyện. Vui lòng thử lại sau.');
      }
    }
  }

  Future<void> _fetchBorderPolygons() async {
    if (_database.connection != null && !_isBorderLoaded) {
      try {
        _borderPolygons =
            await _database.borderDatabase.fetchAndParseGeometry();
        _isBorderLoaded = true;
        setState(() {});
        if (_isMapInitialized) {
          await _mapUtils.drawPolygonsOnMap(_borderPolygons);
        }
      } catch (e) {
        print('Lỗi khi lấy dữ liệu đường viền: $e');
        _showErrorSnackBar(
            'Không thể tải dữ liệu đường viền. Vui lòng thử lại sau.');
      }
    }
  }

  Future<void> _fetchCommunes() async {
    if (_database.connection != null && !_isCommunesLoaded) {
      try {
        _communes = await _database.fetchCommunesData();
        _isCommunesLoaded = true;
        setState(() {});
        if (_isMapInitialized) {
          await _mapUtils.drawCommunesOnMap(_communes);
        }
      } catch (e) {
        print('Lỗi khi lấy dữ liệu xã: $e');
        _showErrorSnackBar('Không thể tải dữ liệu xã. Vui lòng thử lại sau.');
      }
    }
  }

  Future<void> _fetchLandslidePoints() async {
    if (_database.connection != null && !_isLandslidePointsLoaded) {
      try {
        _landslidePoints = await _database.fetchLandslidePoints();
        _isLandslidePointsLoaded = true;
        setState(() {});
        if (_isMapInitialized) {
          await _mapUtils.drawLandslidePointsOnMap(_landslidePoints);
        }
      } catch (e) {
        print('Lỗi khi lấy dữ liệu điểm trượt lở: $e');
        _showErrorSnackBar(
            'Không thể tải dữ liệu điểm trượt lở. Vui lòng thử lại sau.');
      }
    }
  }

  void _onMapCreated(MapboxMapController controller) async {
    _mapController = controller;
    _mapUtils = MapUtils(_mapController);
    _isMapInitialized = true;

    // Thêm icon location_on vào bản đồ
    final ByteData bytes =
        await rootBundle.load('lib/assets/location_icon.png');
    final Uint8List list = bytes.buffer.asUint8List();
    await _mapController.addImage("location_on", list);

    await _initializeData();

    // Add this line to handle symbol taps
    _mapController.onSymbolTapped.add(_onSymbolTapped);
  }

  void _onStyleLoaded() async {
    if (_isDistrictsVisible && _isDistrictsLoaded) {
      await _mapUtils.drawDistrictsOnMap(_districts);
    }
    if (_isBorderVisible && _isBorderLoaded) {
      await _mapUtils.drawPolygonsOnMap(_borderPolygons);
    }
    if (_isCommunesVisible && _isCommunesLoaded) {
      await _mapUtils.drawCommunesOnMap(_communes);
    }
    if (_isLandslidePointsVisible && _isLandslidePointsLoaded) {
      await _mapUtils.drawLandslidePointsOnMap(_landslidePoints);
    }

    for (var district in _districts) {
      await _mapUtils.toggleDistrictVisibility(
          district.id, _districtVisibility[district.id] ?? true);
    }
    await _mapUtils.toggleBorderVisibility(_isBorderVisible);
    await _mapUtils.toggleCommunesVisibility(_isCommunesVisible);
    await _mapUtils.toggleLandslidePointsVisibility(_isLandslidePointsVisible);

    if (_currentLocation != null) {
      _mapUtils.updateLocationOnMap(_currentLocation!);
    }
  }

  void _onSymbolTapped(Symbol symbol) async {
    if (symbol.data != null && symbol.data!['id'] != null) {
      print(1);
      int landslideId = symbol.data!['id'];
      Map<String, dynamic> landslideDetail =
          await _database.landslideDatabase.fetchLandslideDetail(landslideId);
      _showLandslideDetailDialog(landslideDetail);
    }
  }

  void _showLandslideDetailDialog(Map<String, dynamic> landslideDetail) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thông tin điểm trượt lở'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('ID: ${landslideDetail['id']}'),
                Text('Vị trí: ${landslideDetail['vi_tri']}'),
                Text('Xã: ${landslideDetail['ten_xa']}'),
                Text('Mô tả: ${landslideDetail['mo_ta']}'),
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
  }

  void _toggleDistrictsVisibility(bool? value) async {
    if (value != null) {
      setState(() {
        _isDistrictsVisible = value;
      });
      if (_isDistrictsVisible && !_isDistrictsLoaded) {
        await _fetchDistricts();
      } else {
        await _mapUtils.toggleAllDistrictsVisibility(value);
      }
    }
  }

  void _toggleBorderVisibility(bool? value) async {
    if (value != null) {
      setState(() {
        _isBorderVisible = value;
      });
      if (_isBorderVisible && !_isBorderLoaded) {
        await _fetchBorderPolygons();
      } else {
        await _mapUtils.toggleBorderVisibility(value);
      }
    }
  }

  void _toggleCommunesVisibility(bool? value) async {
    if (value != null) {
      setState(() {
        _isCommunesVisible = value;
      });
      if (_isCommunesVisible && !_isCommunesLoaded) {
        await _fetchCommunes();
      } else {
        await _mapUtils.toggleCommunesVisibility(value);
      }
    }
  }

  void _toggleLandslidePointsVisibility(bool? value) async {
    if (value != null) {
      setState(() {
        _isLandslidePointsVisible = value;
      });
      if (_isLandslidePointsVisible && !_isLandslidePointsLoaded) {
        await _fetchLandslidePoints();
      } else {
        await _mapUtils.toggleLandslidePointsVisibility(value);
      }
    }
  }

  void _toggleDistrictVisibility(int districtId, bool? value) async {
    if (value != null) {
      setState(() {
        _districtVisibility[districtId] = value;
      });
      await _mapUtils.toggleDistrictVisibility(districtId, value);
    }
  }

  void _changeMapStyle(String? style) {
    if (style != null) {
      setState(() {
        currentStyle = style;
      });
      Navigator.pop(context);
    }
  }

  void _moveToCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
    }
  }

  void _moveToDefaultLocation() {
    _mapController
        .animateCamera(CameraUpdate.newLatLngZoom(defaultTarget, defaultZoom));
  }

  void _initializeLocationService() async {
    bool permissionGranted =
        await _locationService.checkAndRequestLocationPermission(context);
    if (permissionGranted) {
      _locationService.startLocationUpdates((location) {
        setState(() {
          _currentLocation = location;
        });
        if (_isMapInitialized) {
          _mapUtils.updateLocationOnMap(location);
        }
      }, _handleLocationError);
    }
  }

  void _handleLocationError(dynamic e) {
    String errorMessage = 'Đã xảy ra lỗi khi lấy vị trí: $e';
    print(errorMessage);
    _showErrorSnackBar(errorMessage);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      endDrawer: MapMenu(
        styleCategories: styleCategories,
        currentStyle: currentStyle,
        isDistrictsVisible: _isDistrictsVisible,
        isBorderVisible: _isBorderVisible,
        isCommunesVisible: _isCommunesVisible,
        isLandslidePointsVisible: _isLandslidePointsVisible,
        districts: _districts,
        districtVisibility: _districtVisibility,
        onStyleChanged: _changeMapStyle,
        onDistrictsVisibilityChanged: _toggleDistrictsVisibility,
        onBorderVisibilityChanged: _toggleBorderVisibility,
        onCommunesVisibilityChanged: _toggleCommunesVisibility,
        onLandslidePointsVisibilityChanged: _toggleLandslidePointsVisibility,
        onDistrictVisibilityChanged: _toggleDistrictVisibility,
      ),
      body: Stack(
        children: [
          MapboxMap(
            accessToken: mapToken,
            initialCameraPosition: CameraPosition(
              target: defaultTarget,
              zoom: defaultZoom,
            ),
            styleString: currentStyle,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapCreated: _onMapCreated,
          ),
          if (_currentLocation != null)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8)
                  ],
                ),
                child: Text(
                  'Vị trí cá nhân hiện tại: ${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _moveToCurrentLocation,
            heroTag: 'moveToCurrentLocation',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _moveToDefaultLocation,
            heroTag: 'moveToDefaultLocation',
            child: const Icon(Icons.home),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationService.stopLocationUpdates();
    _database.connection?.close();
    _mapController.onSymbolTapped.remove(_onSymbolTapped);
    super.dispose();
  }
}
