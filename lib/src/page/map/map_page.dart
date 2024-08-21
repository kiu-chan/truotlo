import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/map_data.dart';
import 'package:truotlo/src/config/map.dart';
import 'package:truotlo/src/database/database.dart'; // Import the database file

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

  LatLng defaultTarget = MapConfig().getDefaultTarget();
  double defaultZoom = MapConfig().getDefaultZoom();
  String mapToken = MapConfig().getMapToken();

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
  }

  Future<void> _connectToDatabase() async {
    await _database.connect();
  }

  void drawPolygonsOnMap(MapboxMapController controller, List<List<LatLng>> polygons) {
    for (int i = 0; i < polygons.length; i++) {
      controller.addLine(
        LineOptions(
          geometry: polygons[i],
          lineColor: "#FF0000", // Red color
          lineWidth: 2.0, // Adjust the line width as needed
          lineOpacity: 1.0,
        ),
      );
    }
  }

  void _onStyleLoaded() async {
    if (_database.connection != null) {
      try {
        List<List<LatLng>> polygons = await _database.fetchAndParseGeometry();
        drawPolygonsOnMap(_mapController, polygons);
      } catch (e) {
        print('Error fetching or drawing polygons: $e');
      }
    } else {
      print('Database connection not available');
    }
  }

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
  }

  void _changeMapStyle(String style) {
    setState(() {
      currentStyle = style;
    });
    Navigator.pop(context); // Close Drawer after selecting style
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
                'Chọn loại bản đồ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ExpansionTile(
              leading: const Icon(Icons.api),
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
          ],
        ),
      ),
      body: MapboxMap(
        accessToken: mapToken,
        initialCameraPosition: CameraPosition(
          target: defaultTarget,
          zoom: defaultZoom,
        ),
        styleString: currentStyle,
        onStyleLoadedCallback: _onStyleLoaded,
        onMapCreated: _onMapCreated,
      ),
    );
  }

  @override
  void dispose() {
    _database.connection?.close();
    super.dispose();
  }
}