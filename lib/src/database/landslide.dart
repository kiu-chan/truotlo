import 'package:postgres/postgres.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:truotlo/src/data/map/landslide_point.dart';

class LandslideDatabase {
  final PostgreSQLConnection connection;

  LandslideDatabase(this.connection);

  Future<List<LandslidePoint>> fetchLandslidePoints() async {
    final results = await connection!.query('''
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
    
    return results.map((row) => LandslidePoint.fromJson({
      'id': row[0] as int,
      'lon': row[1] as double,
      'lat': row[2] as double,
    })).toList();
  }
}