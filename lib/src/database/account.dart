import 'package:postgres/postgres.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:truotlo/src/data/account/user.dart';


class AccountQueries {
  final PostgreSQLConnection connection;

  AccountQueries(this.connection);

  Future<User?> login(String email, String password) async {
    final results = await connection.mappedResultsQuery(
      'SELECT id, name, email, role, password FROM public.users WHERE email = @email LIMIT 1',
      substitutionValues: {
        'email': email,
      },
    );

    if (results.isNotEmpty) {
      final userData = results.first['users']!;
      final storedHash = userData['password'] as String;
      
      if (BCrypt.checkpw(password, storedHash)) {
        return User.fromJson(userData);
      }
    }
    
    return null;
  }
}