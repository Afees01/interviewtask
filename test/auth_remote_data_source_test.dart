import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interviewtask/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:interviewtask/features/auth/domain/exceptions/auth_exception.dart';

void main() {
  late Dio dio;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        validateStatus: (status) => status != null && status < 300,
      ),
    );
    dataSource = AuthRemoteDataSourceImpl(dio);
  });

  tearDown(() {
    dio.close(force: true);
  });

  test('fetches API profiles for user IDs 1 and 2', () async {
    dio.httpClientAdapter = _FakeHttpClientAdapter((request) {
      final id = int.parse(request.uri.pathSegments.last);
      return _jsonResponse(_userJson(id));
    });

    final firstUser = await dataSource.getUserById(1);
    final secondUser = await dataSource.getUserById(2);

    expect(firstUser.id, 1);
    expect(firstUser.name, 'API user 1');
    expect(secondUser.id, 2);
    expect(secondUser.name, 'API user 2');
  });

  test('maps empty response for user ID 999 to user-not-found', () async {
    dio.httpClientAdapter = _FakeHttpClientAdapter(
      (_) => _jsonResponse(<String, Object?>{}),
    );

    await expectLater(
      dataSource.getUserById(999),
      throwsA(isA<UserNotFoundException>()),
    );
  });

  test('maps HTTP 404 and 500 responses to meaningful errors', () async {
    dio.httpClientAdapter = _FakeHttpClientAdapter(
      (_) => _jsonResponse({'message': 'not found'}, statusCode: 404),
    );
    await expectLater(
      dataSource.getUserById(999),
      throwsA(isA<UserNotFoundException>()),
    );

    dio.httpClientAdapter = _FakeHttpClientAdapter(
      (_) => _jsonResponse({'message': 'server error'}, statusCode: 500),
    );
    await expectLater(
      dataSource.getUserById(1),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          contains('temporarily unavailable'),
        ),
      ),
    );
  });

  test('reports timeout, DNS, and SSL failures distinctly', () async {
    dio.httpClientAdapter = _FakeHttpClientAdapter(
      (_) => throw DioException(
        requestOptions: RequestOptions(path: '/users/1'),
        type: DioExceptionType.connectionTimeout,
      ),
    );
    await expectLater(
      dataSource.getUserById(1),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );

    dio.httpClientAdapter = _FakeHttpClientAdapter(
      (_) => throw DioException(
        requestOptions: RequestOptions(path: '/users/1'),
        type: DioExceptionType.connectionError,
        error: Exception('Failed host lookup'),
      ),
    );
    await expectLater(
      dataSource.getUserById(1),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          contains('resolve the user service address'),
        ),
      ),
    );

    dio.httpClientAdapter = _FakeHttpClientAdapter(
      (_) => throw DioException(
        requestOptions: RequestOptions(path: '/users/1'),
        type: DioExceptionType.badCertificate,
      ),
    );
    await expectLater(
      dataSource.getUserById(1),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          contains('secure connection'),
        ),
      ),
    );
  });

  test('rejects invalid JSON and malformed profile responses', () async {
    dio.httpClientAdapter = _FakeHttpClientAdapter(
      (_) => ResponseBody.fromString(
        'not valid json',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    await expectLater(
      dataSource.getUserById(1),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          contains('invalid'),
        ),
      ),
    );

    dio.httpClientAdapter = _FakeHttpClientAdapter(
      (_) => _jsonResponse({'id': 1}),
    );
    await expectLater(
      dataSource.getUserById(1),
      throwsA(isA<InvalidUserResponseException>()),
    );
  });
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._response);

  final ResponseBody Function(RequestOptions request) _response;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _response(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(
  Object? value, {
  int statusCode = 200,
}) {
  return ResponseBody.fromString(
    jsonEncode(value),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Map<String, Object?> _userJson(int id) => {
      'id': id,
      'name': 'API user $id',
      'username': 'user$id',
      'email': 'user$id@example.test',
      'phone': '555-$id',
      'website': 'user$id.example.test',
      'company': {'name': 'Company $id'},
    };
