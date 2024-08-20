import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class MapboxPage extends StatefulWidget {
  const MapboxPage({Key? key}) : super(key: key);

  @override
  _MapboxPageState createState() => _MapboxPageState();
}

class _MapboxPageState extends State<MapboxPage> {
  String currentStyle = MapboxStyles.MAPBOX_STREETS;

  final List<MapStyle> styles = [
    MapStyle("Streets", MapboxStyles.MAPBOX_STREETS),
    MapStyle("Outdoors", MapboxStyles.OUTDOORS),
    MapStyle("Light", MapboxStyles.LIGHT),
    MapStyle("Dark", MapboxStyles.DARK),
    MapStyle("Satellite", MapboxStyles.SATELLITE),
    MapStyle("Satellite Streets", MapboxStyles.SATELLITE_STREETS),
  ];

  void _onStyleLoaded() {
    // Thêm các tùy chỉnh bản đồ ở đây nếu cần
  }

  void _changeMapStyle(String style) {
    setState(() {
      currentStyle = style;
    });
    Navigator.pop(context); // Đóng Drawer sau khi chọn style
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
            ...styles.map((style) => ListTile(
                  title: Text(style.name),
                  onTap: () => _changeMapStyle(style.url),
                )),
          ],
        ),
      ),
      body: MapboxMap(
        accessToken:
            'sk.eyJ1IjoibW9ubHljdXRlIiwiYSI6ImNtMDI4enByaDAwMnIycXIwdDhqc3diNHgifQ.cpA69qDo8WHZ7ZxeGzCSlw',
        initialCameraPosition: const CameraPosition(
          target: LatLng(14.0583, 108.2772), // Tọa độ trung tâm của Bình Định
          zoom: 8.0,
        ),
        styleString: currentStyle,
        onStyleLoadedCallback: _onStyleLoaded,
      ),
    );
  }
}

class MapStyle {
  final String name;
  final String url;

  MapStyle(this.name, this.url);
}
