import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/district_data.dart';
import 'package:truotlo/src/data/map/map_data.dart';
import 'package:truotlo/src/config/map.dart';
import 'package:truotlo/src/database/database.dart';
import 'package:truotlo/src/database/commune.dart';
import 'elements/map_utils.dart';
import 'elements/location_service.dart';
import 'menu.dart';

class MapboxPage extends StatefulWidget {
  const MapboxPage({Key? key}) : super(key: key);

  @override
  MapboxPageState createState() => MapboxPageState();
}

class MapboxPageState extends State<MapboxPage> {
  String currentStyle = MapboxStyles.MAPBOX_STREETS;
  late MapboxMapController _mapController;
  final List<MapStyleCategory> styleCategories =
      MapConfig().getStyleCategories();
  final DefaultDatabase _database = DefaultDatabase();
  late MapUtils _mapUtils;
  final LocationService _locationService = LocationService();

  LatLng defaultTarget = MapConfig().getDefaultTarget();
  double defaultZoom = MapConfig().getDefaultZoom();
  String mapToken = MapConfig().getMapToken();

  LatLng? _currentLocation;
  bool _isDistrictsVisible = true;
  bool _isBorderVisible = false;
  bool _isCommunesVisible = false;
  List<District> _districts = [];
  List<List<LatLng>> _borderPolygons = [];
  List<Commune> _communes = [];
  Map<int, bool> _districtVisibility = {};

  bool _isDistrictsLoaded = false;
  bool _isBorderLoaded = false;
  bool _isCommunesLoaded = false;

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
    _initializeLocationService();
  }

  Future<void> _connectToDatabase() async {
    await _database.connect();

    if(_isDistrictsVisible) {
      await _fetchDistricts();
    }
    if(_isBorderVisible) {
      await _fetchBorderPolygons();
    }
    if(_isCommunesVisible) {
      await _fetchCommunes();
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
        await _mapUtils.drawDistrictsOnMap(_districts);
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
        await _mapUtils.drawPolygonsOnMap(_borderPolygons);
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
        await _mapUtils.drawCommunesOnMap(_communes);
      } catch (e) {
        print('Lỗi khi lấy dữ liệu xã: $e');
        _showErrorSnackBar('Không thể tải dữ liệu xã. Vui lòng thử lại sau.');
      }
    }
  }

  void _onStyleLoaded() async {
    if (_mapUtils != null) {
      if (_isDistrictsVisible && _isDistrictsLoaded) {
        await _mapUtils.drawDistrictsOnMap(_districts);
      }
      if (_isBorderVisible && _isBorderLoaded) {
        await _mapUtils.drawPolygonsOnMap(_borderPolygons);
      }
      if (_isCommunesVisible && _isCommunesLoaded) {
        await _mapUtils.drawCommunesOnMap(_communes);
      }

      for (var district in _districts) {
        await _mapUtils.toggleDistrictVisibility(
            district.id, _districtVisibility[district.id] ?? true);
      }
      await _mapUtils.toggleBorderVisibility(_isBorderVisible);
      await _mapUtils.toggleCommunesVisibility(_isCommunesVisible);
    }

    if (_currentLocation != null) {
      _mapUtils.updateLocationOnMap(_currentLocation!);
    }
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

  void _toggleDistrictVisibility(int districtId, bool? value) async {
    if (value != null) {
      setState(() {
        _districtVisibility[districtId] = value;
      });
      await _mapUtils.toggleDistrictVisibility(districtId, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ'),
      ),
      endDrawer: MapMenu(
        styleCategories: styleCategories,
        currentStyle: currentStyle,
        isDistrictsVisible: _isDistrictsVisible,
        isBorderVisible: _isBorderVisible,
        isCommunesVisible: _isCommunesVisible,
        districts: _districts,
        districtVisibility: _districtVisibility,
        onStyleChanged: _changeMapStyle,
        onDistrictsVisibilityChanged: _toggleDistrictsVisibility,
        onBorderVisibilityChanged: _toggleBorderVisibility,
        onCommunesVisibilityChanged: _toggleCommunesVisibility,
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: Text(
                  'Vị trí hiện tại: ${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 12),
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
            child: Icon(Icons.my_location),
            heroTag: 'moveToCurrentLocation',
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _moveToDefaultLocation,
            child: Icon(Icons.home),
            heroTag: 'moveToDefaultLocation',
          ),
        ],
      ),
    );
  }

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    _mapUtils = MapUtils(_mapController);
    _onStyleLoaded();
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
        _mapUtils.updateLocationOnMap(location);
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
  void dispose() {
    _locationService.stopLocationUpdates();
    _database.connection?.close();
    super.dispose();
  }
}