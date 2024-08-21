import 'package:postgres/postgres.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

Future<List<List<LatLng>>> fetchAndParseGeometry(PostgreSQLConnection connection) async {
  final results = await connection.query("SELECT ST_AsText(geom) as geom FROM public.borders");
  
  List<List<LatLng>> polygons = [];
  
  for (final row in results) {
    String wktGeometry = row[0] as String;
    if (wktGeometry.startsWith('MULTIPOLYGON')) {
      // Remove MULTIPOLYGON wrapper and split into individual polygons
      wktGeometry = wktGeometry.substring(15, wktGeometry.length - 3);
      List<String> polygonStrings = wktGeometry.split(')),((');
      
      for (String polygonString in polygonStrings) {
        List<LatLng> polygon = _parsePolygon(polygonString);
        polygons.add(polygon);
      }
    }
  }
  
  return polygons;
}

List<LatLng> _parsePolygon(String polygonString) {
  List<LatLng> points = [];
  List<String> coordinates = polygonString.replaceAll('(', '').replaceAll(')', '').split(',');
  
  for (String coord in coordinates) {
    List<String> latLng = coord.trim().split(' ');
    double lng = double.parse(latLng[0]);
    double lat = double.parse(latLng[1]);
    points.add(LatLng(lat, lng));
  }
  
  return points;
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