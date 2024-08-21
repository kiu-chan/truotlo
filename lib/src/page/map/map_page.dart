import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/map_data.dart';
import 'package:truotlo/src/config/map.dart';
import 'package:truotlo/src/database/database.dart';
import 'map_utils.dart';
import 'location_service.dart';

class MapboxPage extends StatefulWidget {
  const MapboxPage({super.key});

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
  bool _isBorderVisible = true;

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
    _initializeLocationService();
  }

  Future<void> _connectToDatabase() async {
    await _database.connect();
  }

  void _initializeLocationService() async {
    bool permissionGranted = await _locationService.checkAndRequestLocationPermission(context);
    if (permissionGranted) {
      _locationService.startLocationUpdates(
        (location) {
          setState(() {
            _currentLocation = location;
          });
          _mapUtils.updateLocationOnMap(location);
        },
        _handleLocationError
      );
    }
  }

  void _handleLocationError(dynamic e) {
    String errorMessage = 'Đã xảy ra lỗi khi lấy vị trí: $e';
    print(errorMessage);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  void _onStyleLoaded() async {
    if (_database.connection != null) {
      try {
        List<List<LatLng>> polygons = await _database.fetchAndParseGeometry();
        if (_isBorderVisible) {
          await _mapUtils.drawPolygonsOnMap(polygons);
        } else {
          await _mapUtils.clearPolygonsOnMap();
        }
      } catch (e) {
        print('Error fetching or drawing polygons: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải dữ liệu bản đồ. Vui lòng thử lại sau.')),
        );
      }
    } else {
      print('Database connection not available');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể kết nối đến cơ sở dữ liệu. Vui lòng kiểm tra kết nối mạng.')),
      );
    }
    if (_currentLocation != null) {
      _mapUtils.updateLocationOnMap(_currentLocation!);
    }
  }

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    _mapUtils = MapUtils(_mapController);
  }

  void _changeMapStyle(String style) {
    setState(() {
      currentStyle = style;
    });
    Navigator.pop(context);
  }

  void _moveToCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_currentLocation!),
      );
    }
  }

  void _moveToDefaultLocation() {
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(defaultTarget, defaultZoom),
    );
  }

  void _toggleBorderVisibility(bool? value) async {
    if (value != null) {
      setState(() {
        _isBorderVisible = value;
      });
      if (_isBorderVisible) {
        List<List<LatLng>> polygons = await _database.fetchAndParseGeometry();
        await _mapUtils.drawPolygonsOnMap(polygons);
      } else {
        await _mapUtils.clearPolygonsOnMap();
      }
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
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Tùy chọn bản đồ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ExpansionTile(
              leading: const Icon(Icons.map),
              title: const Text('Bản đồ'),
              children: <Widget>[
                ...styleCategories.map((category) => ExpansionTile(
                      title: Text(category.name),
                      children: category.styles
                          .map((style) => RadioListTile<String>(
                                title: Text(style.name),
                                value: style.url,
                                groupValue: currentStyle,
                                onChanged: (value) => _changeMapStyle(value!),
                              ))
                          .toList(),
                    )),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Khu vực'),
              children: <Widget>[
                CheckboxListTile(
                  title: const Text('Hiển thị ranh giới'),
                  value: _isBorderVisible,
                  onChanged: _toggleBorderVisibility,
                ),
              ],
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_pin, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Tọa độ: ${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
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

  @override
  void dispose() {
    _locationService.stopLocationUpdates();
    _database.connection?.close();
    super.dispose();
  }
}