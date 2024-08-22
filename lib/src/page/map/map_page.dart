import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/district_data.dart';
import 'package:truotlo/src/data/map/map_data.dart';
import 'package:truotlo/src/config/map.dart';
import 'package:truotlo/src/database/database.dart';
import 'map_utils.dart';
import 'location_service.dart';

class MapboxPage extends StatefulWidget {
  const MapboxPage({Key? key}) : super(key: key);

  @override
  MapboxPageState createState() => MapboxPageState();
}

class MapboxPageState extends State<MapboxPage> {
  String currentStyle = MapboxStyles.MAPBOX_STREETS;
  late MapboxMapController _mapController;
  final List<MapStyleCategory> styleCategories = MapConfig().getStyleCategories();
  final DefaultDatabase _database = DefaultDatabase();
  late MapUtils _mapUtils;
  final LocationService _locationService = LocationService();

  LatLng defaultTarget = MapConfig().getDefaultTarget();
  double defaultZoom = MapConfig().getDefaultZoom();
  String mapToken = MapConfig().getMapToken();

  LatLng? _currentLocation;
  bool _isDistrictsVisible = true;
  bool _isBorderVisible = true;
  List<District> _districts = [];
  List<List<LatLng>> _borderPolygons = [];
  Map<int, bool> _districtVisibility = {};

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
    _initializeLocationService();
  }

  Future<void> _connectToDatabase() async {
    await _database.connect();
    await _fetchDistricts();
    await _fetchBorderPolygons();
    _onStyleLoaded();
  }

  Future<void> _fetchDistricts() async {
    if (_database.connection != null) {
      try {
        _districts = await _database.fetchDistrictsData();
        _districtVisibility = {
          for (var district in _districts) district.id: true
        };
        setState(() {});
      } catch (e) {
        print('Lỗi khi lấy dữ liệu huyện: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải dữ liệu huyện. Vui lòng thử lại sau.')),
        );
      }
    }
  }

  Future<void> _fetchBorderPolygons() async {
    if (_database.connection != null) {
      try {
        _borderPolygons = await _database.borderDatabase.fetchAndParseGeometry();
        setState(() {});
      } catch (e) {
        print('Lỗi khi lấy dữ liệu đường viền: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải dữ liệu đường viền. Vui lòng thử lại sau.')),
        );
      }
    }
  }

  void _onStyleLoaded() async {
    if (_mapUtils != null) {
      try {
        await _mapUtils.drawDistrictsOnMap(_districts);
        await _mapUtils.drawPolygonsOnMap(_borderPolygons);
        
        // Thiết lập trạng thái hiển thị ban đầu
        for (var district in _districts) {
          await _mapUtils.toggleDistrictVisibility(
              district.id, _districtVisibility[district.id] ?? true);
        }
        await _mapUtils.toggleBorderVisibility(_isBorderVisible);
        
        // Ẩn tất cả các huyện nếu _isDistrictsVisible là false
        if (!_isDistrictsVisible) {
          await _mapUtils.toggleAllDistrictsVisibility(false);
        }
      } catch (e) {
        print('Lỗi khi vẽ huyện hoặc đường viền: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể hiển thị dữ liệu huyện hoặc đường viền. Vui lòng thử lại sau.')),
        );
      }
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
      await _mapUtils.toggleAllDistrictsVisibility(value);
    }
  }

  void _toggleBorderVisibility(bool? value) async {
    if (value != null) {
      setState(() {
        _isBorderVisible = value;
      });
      await _mapUtils.toggleBorderVisibility(value);
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
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Tùy chọn bản đồ', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ExpansionTile(
              leading: const Icon(Icons.map),
              title: const Text('Bản đồ'),
              children: <Widget>[
                ...styleCategories.map((category) => ExpansionTile(
                  title: Text(category.name),
                  children: category.styles.map((style) => RadioListTile<String>(
                    title: Text(style.name),
                    value: style.url,
                    groupValue: currentStyle,
                    onChanged: (value) => _changeMapStyle(value!),
                  )).toList(),
                )),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Khu vực'),
              children: <Widget>[
                CheckboxListTile(
                  title: const Text('Huyện'),
                  value: _isDistrictsVisible,
                  onChanged: _toggleDistrictsVisibility,
                ),
                CheckboxListTile(
                  title: const Text('Ranh giới'),
                  value: _isBorderVisible,
                  onChanged: _toggleBorderVisibility,
                ),
              ],
            ),
            if (_isDistrictsVisible)
              ExpansionTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('Huyện'),
                children: _districts.map((district) => CheckboxListTile(
                  title: Text(district.name),
                  value: _districtVisibility[district.id],
                  onChanged: (bool? value) => _toggleDistrictVisibility(district.id, value),
                  secondary: Container(
                    width: 24,
                    height: 24,
                    color: district.color,
                  ),
                )).toList(),
              ),
          ],
        ),
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

  void _changeMapStyle(String style) {
    setState(() {
      currentStyle = style;
    });
    Navigator.pop(context);
  }

  void _moveToCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
    }
  }

  void _moveToDefaultLocation() {
    _mapController.animateCamera(CameraUpdate.newLatLngZoom(defaultTarget, defaultZoom));
  }

  void _initializeLocationService() async {
    bool permissionGranted = await _locationService.checkAndRequestLocationPermission(context);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  @override
  void dispose() {
    _locationService.stopLocationUpdates();
    _database.connection?.close();
    super.dispose();
  }
}