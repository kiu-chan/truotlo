import 'package:postgres/postgres.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/landslide_point.dart';

class LandslideDatabase {
  final PostgreSQLConnection connection;

  LandslideDatabase(this.connection);

  Future<List<LandslidePoint>> fetchLandslidePoints() async {
    final results = await connection.query('''
      SELECT 
        id, 
        ST_X(
          CASE 
            WHEN ST_GeometryType(geom) = 'ST_Point' THEN geom
            ELSE ST_Centroid(geom)
          END
        ) as lon, 
        ST_Y(
          CASE 
            WHEN ST_GeometryType(geom) = 'ST_Point' THEN geom
            ELSE ST_Centroid(geom)
          END
        ) as lat 
      FROM public.landslide
    ''');

    return results
        .map((row) => LandslidePoint.fromJson({
              'id': row[0] as int,
              'lon': row[1] as double,
              'lat': row[2] as double,
            }))
        .toList();
  }

  Future<Map<String, dynamic>> fetchLandslideDetail(int id) async {
    final results = await connection.query('''
      SELECT 
        id,
        lon,
        lat,
        commune_id,
        ten_xa,
        vi_tri,
        mo_ta
      FROM 
        public.landslide
      WHERE 
        id = @id
    ''', substitutionValues: {'id': id});

    if (results.isNotEmpty) {
      return {
        'id': results[0][0],
        'lon': results[0][1],
        'lat': results[0][2],
        'commune_id': results[0][3],
        'ten_xa': results[0][4],
        'vi_tri': results[0][5],
        'mo_ta': results[0][6],
      };
    }
    return {};
  }
}
