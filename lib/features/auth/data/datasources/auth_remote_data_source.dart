import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
      _log('GET https://jsonplaceholder.typicode.com/users/{id}');
      final response = await _dio.get<Object?>('/users/$userId');
      _log('Response status: ${response.statusCode ?? 'unknown'}');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const InvalidUserResponseException();
      }
      if (data.isEmpty) {
        throw const UserNotFoundException();
      }
      return UserModel.fromJson(data);
    } on DioException catch (error) {
      final message = _messageFor(error);
      _log(
        'DioException type=${error.type.name}, '
        'cause=${error.error?.runtimeType ?? 'none'}, '
        'status=${error.response?.statusCode ?? 'none'}, '
        'category=$message',
      );
      if (error.response?.statusCode == 404) {
        throw const UserNotFoundException();
      }
      throw AuthException(message);
    } on FormatException catch (error) {
      _log('Invalid user JSON (${error.runtimeType}).');
      throw const InvalidUserResponseException();
    }
  }

  String _messageFor(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 404) {
      return 'No user was found for that ID. Please try another ID.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'The user service is temporarily unavailable. Please try again later.';
    }
    if (statusCode != null) {
      return 'The user service returned an unexpected response '
          '(HTTP $statusCode). Please try again later.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection to the user service timed out. Check your network '
            'and try again.';
      case DioExceptionType.sendTimeout:
        return 'The request to the user service timed out. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'The user service took too long to respond. Please try again.';
      case DioExceptionType.transformTimeout:
        return 'The user service response took too long to process. Please try '
            'again.';
      case DioExceptionType.badCertificate:
        return 'A secure connection to the user service could not be verified. '
            'Check your device date and network security settings.';
      case DioExceptionType.connectionError:
        return _isDnsFailure(error)
            ? 'Could not resolve the user service address. Check your internet '
                'connection or DNS settings.'
            : 'Could not connect to the user service. Check that your device '
                'has internet access and try again.';
      case DioExceptionType.badResponse:
        return 'The user service returned an unexpected response. Please try '
            'again later.';
      case DioExceptionType.cancel:
        return 'The request was cancelled. Please try again.';
      case DioExceptionType.unknown:
        if (error.error is FormatException) {
          return 'The user service returned invalid data. Please try again '
              'later.';
        }
        if (_isDnsFailure(error)) {
          return 'Could not resolve the user service address. Check your '
              'internet connection or DNS settings.';
        }
        return 'Unable to complete the secure connection to the user service. '
            'Check your network and try again.';
    }
  }

  bool _isDnsFailure(DioException error) {
    final details = error.error?.toString().toLowerCase() ?? '';
    return details.contains('failed host lookup') ||
        details.contains('name or service not known') ||
        details.contains('no address associated with hostname') ||
        details.contains('nodename nor servname') ||
        details.contains('dns');
  }

  void _log(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'AuthRemoteDataSource');
    }
  }
}
