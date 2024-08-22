import 'package:postgres/postgres.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:truotlo/src/data/map/district_data.dart';

class DistrictDatabase {
  final PostgreSQLConnection connection;

  DistrictDatabase(this.connection);

  Future<List<District>> fetchDistrictsData() async {
    final results = await connection.query(
      "SELECT id, ten_huyen, ST_AsText(geom) as geom FROM public.districts"
    );
    
    List<District> districts = [];
    Random random = Random();
    
    for (final row in results) {
      int id = row[0] as int;
      String name = row[1] as String;
      String wktGeometry = row[2] as String;
      List<List<LatLng>> polygons = _parseMultiPolygon(wktGeometry);
      
      // Tạo màu ngẫu nhiên cho mỗi huyện
      Color color = Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        1
      );
      
      districts.add(District(id, name, polygons, color));
    }
    
    return districts;
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