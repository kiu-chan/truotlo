import 'package:postgres/postgres.dart';
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
      FROM public.landslides
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
        l.id,
        ST_X(
          CASE 
            WHEN ST_GeometryType(l.geom) = 'ST_Point' THEN l.geom
            ELSE ST_Centroid(l.geom)
          END
        ) as lon, 
        ST_Y(
          CASE 
            WHEN ST_GeometryType(l.geom) = 'ST_Point' THEN l.geom
            ELSE ST_Centroid(l.geom)
          END
        ) as lat,
        l.commune_id,
        l.vi_tri,
        l.mo_ta,
        d.ten_huyen AS district_name,
        x.ten_xa AS commune_name
      FROM 
        public.landslides l
      LEFT JOIN 
        public.map_districts d ON ST_Intersects(d.geom, l.geom)
      LEFT JOIN 
        public.map_communes x ON l.commune_id = x.id
      WHERE 
        l.id = @id
    ''', substitutionValues: {'id': id});

    if (results.isNotEmpty) {
      return {
        'id': results[0][0],
        'lon': results[0][1],
        'lat': results[0][2],
        'commune_id': results[0][3],
        'vi_tri': results[0][4],
        'mo_ta': results[0][5],
        'district_name': results[0][6],
        'commune_name': results[0][7],
      };
    }
    return {};
  }
}