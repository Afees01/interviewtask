import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithUserId {
  const LoginWithUserId(this._repository);

  final AuthRepository _repository;

  Future<User> call(int userId) => _repository.login(userId);
}
