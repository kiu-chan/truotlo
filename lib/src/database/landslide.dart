import 'package:postgres/postgres.dart';
import 'package:truotlo/src/data/manage/forecast.dart';
import 'package:truotlo/src/data/manage/hourly_warning.dart';
import 'package:truotlo/src/data/map/landslide_point.dart';
import 'package:truotlo/src/data/manage/landslide_point.dart';

class LandslideDatabase {
  final PostgreSQLConnection connection;

  LandslideDatabase(this.connection);

  Future<List<LandslidePoint>> fetchLandslidePoints() async {
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
        d.ten_huyen as district
      FROM public.landslides l
      JOIN public.map_districts d ON ST_Intersects(d.geom, l.geom)
    ''');

    return results
        .map((row) => LandslidePoint.fromJson({
              'id': row[0] as int,
              'lon': row[1] as double,
              'lat': row[2] as double,
              'district': row[3] as String,
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

  Future<List<HourlyWarning>> fetchHourlyWarnings() async {
    final results = await connection.mappedResultsQuery('''
      SELECT 
        fr.id, 
        fr.nam as year, 
        fr.thang as month, 
        fr.ngay as day, 
        fr.gio as hour,
        frp.ten_diem as location,
        frp.nguy_co as warning_level,
        frp.vi_tri as description,
        frp.kinh_do as lat,
        frp.vi_do as lon
      FROM 
        public.forecast_records fr
      JOIN 
        public.forecast_record_points frp ON fr.id = frp.record_id
      ORDER BY 
        fr.nam DESC, fr.thang DESC, fr.ngay DESC, fr.gio DESC
      LIMIT 100
    ''');

    return results.map((row) {
      final data = row['forecast_records']!;
      final pdata = row['forecast_record_points']!;
      return HourlyWarning(
        id: data['id'] ?? 0,
        year: data['year'] ?? 0,
        month: data['month'] ?? 0,
        day: data['day'] ?? 0,
        hour: data['hour'] ?? 0,
        location: pdata['location'] ?? '',
        warningLevel: pdata['warning_level'] ?? '',
        description: pdata['description'] ?? '',
        lat: double.parse(pdata['lat']),
        lon: double.parse(pdata['lon']),
      );
    }).toList();
  }

  Future<List<Forecast>> fetchForecasts() async {
    final results = await connection.query('''
      SELECT DISTINCT 
        fs.id,
        fs.nam, 
        fs.thang
      FROM 
        public.forecast_sessions fs
      ORDER BY 
        fs.nam DESC, fs.thang DESC
      LIMIT 10
    ''');

    return results.map((row) {
      return Forecast(
        id: row[0].toString(),
        name: 'Phiên dự báo ${row[2]}/${row[1]}',
        year: row[1],
        month: row[2],
        location: '',
        province: '',
        district: '',
        commune: '',
        startDate: DateTime(row[1], row[2], 1),
        endDate: DateTime(row[1], row[2] + 1, 0).subtract(Duration(days: 1)),
        days: [],
      );
    }).toList();
  }

  Future<ForecastDetail> fetchForecastDetail(String id) async {
    final results = await connection.mappedResultsQuery('''
      SELECT 
        fp.ten_diem, 
        fp.vi_tri, 
        fp.kinh_do, 
        fp.vi_do, 
        fp.tinh, 
        fp.huyen, 
        fp.xa,
        fr.nguy_co,
        fr.ngay,
        fs.nam,
        fs.thang
      FROM 
        public.forecast_points fp
      JOIN
        public.forecast_risks fr ON fp.id = fr.point_id
      JOIN
        public.forecast_sessions fs ON fp.session_id = fs.id
      WHERE 
        fs.id = @id
      ORDER BY
        fr.ngay
    ''', substitutionValues: {'id': id});

    if (results.isEmpty) {
      throw Exception('No forecast found for id $id');
    }

    final firstRow = results.first;
    final List<DayForecast> days = results.map((row) {
      return DayForecast(
        day: row['forecast_risks']!['ngay'] as int,
        riskLevel: row['forecast_risks']!['nguy_co'] as String,
        date: DateTime(
          row['forecast_sessions']!['nam'] as int,
          row['forecast_sessions']!['thang'] as int,
          row['forecast_risks']!['ngay'] as int,
        ),
      );
    }).toList();

    return ForecastDetail(
      tenDiem: firstRow['forecast_points']!['ten_diem'] as String,
      viTri: firstRow['forecast_points']!['vi_tri'] as String,
      kinhDo: double.parse(firstRow['forecast_points']!['kinh_do'] as String),
      viDo: double.parse(firstRow['forecast_points']!['vi_do'] as String),
      tinh: firstRow['forecast_points']!['tinh'] as String,
      huyen: firstRow['forecast_points']!['huyen'] as String,
      xa: firstRow['forecast_points']!['xa'] as String,
      days: days,
    );
  }

  Future<List<ManageLandslidePoint>> fetchListLandslidePoints() async {
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
        ) as lat,
        commune_id,
        vi_tri,
        mo_ta
      FROM public.landslides
      ORDER BY id
    ''');

    return results
        .map((row) => ManageLandslidePoint(
              id: row[0].toString(),
              name: row[4] as String? ?? 'Không có tên',
              code: row[3]?.toString() ?? 'Không có mã',
              latitude: row[2] as double,
              longitude: row[1] as double,
              description: row[5] as String? ?? 'Không có mô tả',
            ))
        .toList();
  }

  Future<List<String>> getAllDistricts() async {
    final results = await connection.query('''
      SELECT DISTINCT d.ten_huyen
      FROM public.landslides l
      JOIN public.map_districts d ON ST_Intersects(d.geom, l.geom)
      ORDER BY d.ten_huyen
    ''');

    return results.map((row) => row[0] as String).toList();
  }
}
