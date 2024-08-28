import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:postgres/postgres.dart';
import 'package:truotlo/src/data/account/user.dart';
import 'package:truotlo/src/data/map/district_data.dart';
import 'package:truotlo/src/data/map/landslide_point.dart';
import 'package:truotlo/src/database/account.dart';
import 'package:truotlo/src/database/border.dart';
import 'package:truotlo/src/database/district.dart';
import 'package:truotlo/src/database/commune.dart';
import 'package:truotlo/src/database/landslide.dart';

class DefaultDatabase {
  bool _connectionFailed = false;
  PostgreSQLConnection? connection;

  late BorderDatabase borderDatabase;
  late DistrictDatabase districtDatabase;
  late CommuneDatabase communeDatabase;
  late LandslideDatabase landslideDatabase;
  late AccountQueries accountQueries;

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
      communeDatabase = CommuneDatabase(connection!);
      landslideDatabase = LandslideDatabase(connection!);
      accountQueries = AccountQueries(connection!);
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

  Future<List<Commune>> fetchCommunesData() async {
    return await communeDatabase.fetchCommunesData();
  }

  Future<List<LandslidePoint>> fetchLandslidePoints() async {
    return await landslideDatabase.fetchLandslidePoints();
  }

  Future<User?> login(String email, String password) async {
    return await accountQueries.login(email, password);
  }
}
