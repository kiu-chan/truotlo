import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';

class Commune {
  final int id;
  final String name;
  final String districtName;
  final String provinceName;
  final List<List<LatLng>> polygons;

  Commune(this.id, this.name, this.districtName, this.provinceName, this.polygons);
}

class CommuneDatabase {
  final String baseUrl = 'https://truotlobinhdinh.girc.edu.vn/api';

  Future<List<Commune>> fetchCommunesData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/communes-data'));
      
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) {
          try {
            return Commune(
              data['id'],
              data['name'],
              data['district_name'],
              data['province_name'],
              _parseMultiPolygon(data['geometry'])
            );
          } catch (e) {
            print('Error parsing commune data: $e');
            return null;
          }
        }).whereType<Commune>().toList();
      } else {
        throw Exception('Failed to load communes data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching communes data: $e');
      rethrow;
    }
  }

  List<List<LatLng>> _parseMultiPolygon(Map<String, dynamic> geometry) {
    List<List<LatLng>> polygons = [];
    try {
      if (geometry['type'] == 'MultiPolygon') {
        for (var polygon in geometry['coordinates']) {
          polygons.add(_parsePolygon(polygon[0]));
        }
      } else if (geometry['type'] == 'Polygon') {
        polygons.add(_parsePolygon(geometry['coordinates'][0]));
      }
    } catch (e) {
      print('Error parsing MultiPolygon: $e');
    }
    return polygons;
  }

  List<LatLng> _parsePolygon(List<dynamic> coordinates) {
    return coordinates.map((coord) {
      try {
        // Convert coordinates to double, whether they are int or double
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