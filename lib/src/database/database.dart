import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:postgres/postgres.dart';
import 'package:truotlo/src/data/map/district_data.dart';
import 'package:truotlo/src/database/border.dart';
import 'package:truotlo/src/database/district.dart';

class DefaultDatabase {
  bool _connectionFailed = false;
  PostgreSQLConnection? connection;

  late BorderDatabase borderDatabase;
  late DistrictDatabase districtDatabase;

  Future<void> connect() async {
    try {
      connection = PostgreSQLConnection(
        '163.44.193.74',
        5432,
        'binhdinh_truotlo',
        username: 'postgres',
        password: 'yfti*m0xZYtRy3QfF)tV',
      );

      await connection!.open();
      print('Connected to PostgreSQL database.');
      _connectionFailed = false;

      borderDatabase = BorderDatabase(connection!);
      districtDatabase = DistrictDatabase(connection!);
    } catch (e) {
      print('Failed to connect to database: $e');
      _connectionFailed = true;
    }
  }

  bool get connectionFailed => _connectionFailed;

  Future<List<List<LatLng>>> fetchAndParseGeometry() async {
    return await borderDatabase.fetchAndParseGeometry();
  }
    Future<List<District>> fetchDistrictsData() async {
    return await districtDatabase.fetchDistrictsData();
  }
}
