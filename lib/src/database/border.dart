import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/config/api.dart';

class BorderDatabase {
  final String baseUrl = ApiConfig().getApiUrl();

  Future<List<List<LatLng>>> fetchAndParseGeometry() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/borders-data'));
      
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        List<List<LatLng>> allPolygons = [];
        
        for (var border in jsonResponse) {
          try {
            allPolygons.addAll(_parseMultiPolygon(border['geometry']));
          } catch (e) {
            print('Error parsing border geometry: $e');
          }
        }
        
        return allPolygons;
      } else {
        throw Exception('Failed to load borders data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching borders data: $e');
      rethrow;
    }
  }

  List<List<LatLng>> _parseMultiPolygon(Map<String, dynamic> geometry) {
    List<List<LatLng>> polygons = [];
    if (geometry['type'] == 'MultiPolygon') {
      for (var polygon in geometry['coordinates']) {
        polygons.add(_parsePolygon(polygon[0]));
      }
    } else if (geometry['type'] == 'Polygon') {
      polygons.add(_parsePolygon(geometry['coordinates'][0]));
    }
    return polygons;
  }

  List<LatLng> _parsePolygon(List<dynamic> coordinates) {
    return coordinates.map((coord) {
      try {
        double lng = (coord[0] is int) ? (coord[0] as int).toDouble() : coord[0];
        double lat = (coord[1] is int) ? (coord[1] as int).toDouble() : coord[1];
        return LatLng(lat, lng);
      } catch (e) {
        print('Error parsing coordinate: $e');
        return null;
      }
    }).whereType<LatLng>().toList();
  }
}