import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:postgres/postgres.dart';

class DefaultDatabase {
  bool _connectionFailed = false;
  PostgreSQLConnection? connection;

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
    } catch (e) {
      print('Failed to connect to database: $e');
      _connectionFailed = true;
    }
  }

  bool get connectionFailed => _connectionFailed;
}