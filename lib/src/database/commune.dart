import 'package:postgres/postgres.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class Commune {
  final int id;
  final List<List<LatLng>> polygons;

  Commune(this.id, this.polygons);
}

class CommuneDatabase {
  final PostgreSQLConnection connection;

  CommuneDatabase(this.connection);

  Future<List<Commune>> fetchCommunesData() async {
    final results = await connection.query(
      "SELECT id, ST_AsText(geom) as geom FROM public.map_communes"
    );
    
    List<Commune> communes = [];
    
    for (final row in results) {
      int id = row[0] as int;
      String wktGeometry = row[1] as String;
      List<List<LatLng>> polygons = _parseMultiPolygon(wktGeometry);
      
      communes.add(Commune(id, polygons));
    }
    
    return communes;
  }

  List<List<LatLng>> _parseMultiPolygon(String wktGeometry) {
    List<List<LatLng>> polygons = [];
    if (wktGeometry.startsWith('MULTIPOLYGON')) {
      wktGeometry = wktGeometry.substring(15, wktGeometry.length - 3);
      List<String> polygonStrings = wktGeometry.split(')),((');
      
      for (String polygonString in polygonStrings) {
        List<LatLng> polygon = _parsePolygon(polygonString);
        polygons.add(polygon);
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
}