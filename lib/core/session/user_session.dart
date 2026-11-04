import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  const UserSession(this._preferences);

  static const authenticatedUserIdKey = 'authenticated_user_id';

  final SharedPreferences _preferences;

  int? get userId => _preferences.getInt(authenticatedUserIdKey);

  Future<bool> saveUserId(int userId) {
    return _preferences.setInt(authenticatedUserIdKey, userId);
  }

  Future<bool> clear() => _preferences.remove(authenticatedUserIdKey);
}
