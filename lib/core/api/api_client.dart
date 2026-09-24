import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../storage/secure_store.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({Dio? dio, SecureStore? secureStore})
      : _secureStore = secureStore ?? SecureStore(const FlutterSecureStorage()),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: const String.fromEnvironment(
                  'API_BASE_URL',
                  defaultValue: 'http://10.0.2.2:8000/api/v1',
                ),
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 25),
                headers: const {'Accept': 'application/json'},
              ),
            ) {
    if (kReleaseMode && Uri.tryParse(_dio.options.baseUrl)?.scheme.toLowerCase() != 'https') {
      throw StateError('Release builds require an HTTPS API_BASE_URL.');
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStore.accessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (_isMutation(options.method) && options.headers['Idempotency-Key'] == null) {
            options.headers['Idempotency-Key'] = _uuid.v4();
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final options = error.requestOptions;
          final canRefresh = error.response?.statusCode == 401 &&
              options.path != '/auth/token/refresh' &&
              options.extra['retried_after_refresh'] != true;

          if (canRefresh && await _refreshTokens()) {
            try {
              options.extra['retried_after_refresh'] = true;
              final token = await _secureStore.accessToken();
              options.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch<dynamic>(options);
              return handler.resolve(response);
            } catch (_) {
              await _secureStore.clearTokens();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final SecureStore _secureStore;
  final _uuid = const Uuid();
  bool _refreshing = false;

  SecureStore get secureStore => _secureStore;
  String get baseUrl => _dio.options.baseUrl;

  bool _isMutation(String method) => const {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(method.toUpperCase());

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    return _request(() => _dio.get(path, queryParameters: query));
  }

  Future<Map<String, dynamic>> post(String path, {Object? data, Map<String, dynamic>? headers}) async {
    return _request(() => _dio.post(path, data: data, options: Options(headers: headers)));
  }

  Future<Map<String, dynamic>> patch(String path, {Object? data, Map<String, dynamic>? headers}) async {
    return _request(() => _dio.patch(path, data: data, options: Options(headers: headers)));
  }

  Future<Map<String, dynamic>> put(String path, {Object? data, Map<String, dynamic>? headers}) async {
    return _request(() => _dio.put(path, data: data, options: Options(headers: headers)));
  }

  Future<Map<String, dynamic>> delete(String path, {Object? data, Map<String, dynamic>? headers}) async {
    return _request(() => _dio.delete(path, data: data, options: Options(headers: headers)));
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fieldName,
    required String filename,
    required Uint8List bytes,
    Map<String, dynamic> fields = const {},
  }) async {
    final form = FormData.fromMap({
      ...fields,
      fieldName: MultipartFile.fromBytes(bytes, filename: filename),
    });
    return _request(() => _dio.post(path, data: form));
  }

  Future<void> putSignedBytes(
    String url,
    Uint8List bytes, {
    required String mime,
    Map<String, dynamic> headers = const {},
    ProgressCallback? onSendProgress,
  }) async {
    final uploadDio = Dio();
    await uploadDio.put<void>(
      url,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          ...headers,
          'Content-Type': mime,
          'Content-Length': bytes.length,
        },
      ),
      onSendProgress: onSendProgress,
    );
  }

  Future<bool> _refreshTokens() async {
    if (_refreshing) {
      for (var i = 0; i < 20 && _refreshing; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return (await _secureStore.accessToken())?.isNotEmpty == true;
    }

    final refreshToken = await _secureStore.refreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    _refreshing = true;
    try {
      final response = await Dio(
        BaseOptions(baseUrl: _dio.options.baseUrl, headers: const {'Accept': 'application/json'}),
      ).post<dynamic>('/auth/token/refresh', data: {'refresh_token': refreshToken});
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      if (data is Map) {
        final access = '${data['access_token'] ?? ''}';
        final refresh = '${data['refresh_token'] ?? ''}';
        if (access.isNotEmpty && refresh.isNotEmpty) {
          await _secureStore.saveTokens(accessToken: access, refreshToken: refresh);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  Future<Map<String, dynamic>> _request(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return data.cast<String, dynamic>();
      return {'data': data};
    } on DioException catch (e) {
      final body = e.response?.data;
      String message = switch (e.type) {
        DioExceptionType.connectionError => 'You appear to be offline. Check your connection and try again.',
        DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout || DioExceptionType.sendTimeout => 'The connection is taking too long. Please try again.',
        _ => 'Something went wrong. Please try again.',
      };
      String? code;
      Map<String, dynamic>? errors;
      if (body is Map) {
        message = (body['detail'] ?? body['message'] ?? body['title'] ?? message).toString();
        code = body['code']?.toString();
        if (body['errors'] is Map) errors = (body['errors'] as Map).cast<String, dynamic>();
      }
      throw ApiException(message: message, code: code, statusCode: e.response?.statusCode, errors: errors);
    }
  }
}
