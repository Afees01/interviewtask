import 'package:dio/dio.dart';

import '../../domain/exceptions/auth_exception.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserModel> getUserById(int userId);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserModel> getUserById(int userId) async {
    try {
      final response = await _dio.get<Object?>('/users/$userId');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const UserNotFoundException();
      }
      return UserModel.fromJson(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw const UserNotFoundException();
      }
      throw const AuthException(
        'Unable to reach the user service. Check your connection and try again.',
      );
    } on FormatException {
      throw const UserNotFoundException();
    }
  }
}
