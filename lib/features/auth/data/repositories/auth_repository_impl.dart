import '../../../../core/session/user_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required UserSession userSession,
  })  : _remoteDataSource = remoteDataSource,
        _userSession = userSession;

  final AuthRemoteDataSource _remoteDataSource;
  final UserSession _userSession;

  @override
  Future<User> login(int userId) async {
    if (userId <= 0) {
      throw const InvalidUserIdException();
    }

    final user = await _remoteDataSource.getUserById(userId);
    final saved = await _userSession.saveUserId(user.id);
    if (!saved) {
      throw const AuthException(
          'Unable to save your session. Please try again.');
    }
    return user;
  }

  @override
  Future<User?> restoreSession() async {
    final userId = _userSession.userId;
    if (userId == null) {
      return null;
    }
    if (userId <= 0) {
      await _userSession.clear();
      return null;
    }

    try {
      return await _remoteDataSource.getUserById(userId);
    } on UserNotFoundException {
      await _userSession.clear();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await _userSession.clear();
  }
}
