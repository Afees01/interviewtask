import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<User> login(int userId);

  Future<User?> restoreSession();

  Future<void> logout();
}
