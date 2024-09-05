import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/district_data.dart';

class DistrictDatabase {
  final String baseUrl = 'https://truotlobinhdinh.girc.edu.vn/api';

  Future<List<District>> fetchDistrictsData() async {
    final response = await http.get(Uri.parse('$baseUrl/districts-data'));
    
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) {
        return District(
          data['id'],
          data['name'],
          _parseMultiPolygon(data['geometry'])
        );
      }).toList();
    } else {
      throw Exception('Failed to load districts data');
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
    return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
  }
}