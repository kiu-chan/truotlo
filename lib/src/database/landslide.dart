import 'package:postgres/postgres.dart';
import 'package:truotlo/src/data/manage/forecast.dart';
import 'package:truotlo/src/data/manage/hourly_warning.dart';
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
  if (connection != null) {
    try {
      final results = await connection!.mappedResultsQuery('''
        SELECT 
          fs.id, 
          fs.nam, 
          fs.thang, 
          fs.created_at as start_date,
          fs.created_at + interval '5 days' as end_date,
          fp.ten_diem as location,
          fp.huyen as district,
          fp.xa as commune,
          fp.tinh as province,
          json_agg(json_build_object(
            'day', fr.ngay,
            'risk_level', fr.nguy_co,
            'date', fs.created_at + (fr.ngay - 1) * interval '1 day'
          ) ORDER BY fr.ngay) as days
        FROM 
          public.forecast_sessions fs
        JOIN 
          public.forecast_points fp ON fs.id = fp.session_id
        JOIN 
          public.forecast_risks fr ON fp.id = fr.point_id
        GROUP BY 
          fs.id, fp.ten_diem, fp.huyen, fp.xa, fp.tinh
        ORDER BY 
          fs.created_at DESC
        LIMIT 10
      ''');

      return results.map((row) {
        final forecastData = row['forecast_sessions']!;
        final pointData = row['forecast_points']!;

        return Forecast(
          id: forecastData['id'].toString() ?? '',
          name: 'Forecast ${forecastData['nam']}-${forecastData['thang']}' ?? '',
          location: pointData['location'] ?? '',
          province: pointData['province'] ?? '',
          district: pointData['district'] ?? '',
          commune: pointData['commune'] ?? '',
          startDate: forecastData['start_date'] ?? '',
          endDate: forecastData['end_date'] ?? '',
          days: (forecastData['days'] as List).map((day) => DayForecast(
            day: day['day'] ?? 0,
            riskLevel: day['risk_level'] ?? '',
            date: day['date'] ?? '',
          )).toList(),
        );
      }).toList();
    } catch (e) {
      print('Error loading forecasts: $e');
      return [];
    }
  }
  return [];
}
}
