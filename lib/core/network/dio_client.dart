import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_paths.dart';
import '../error/failure.dart';
import '../storage/cache_storage.dart';

class DioClient {
  DioClient(this._cacheStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiPaths.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(_LocaleInterceptor(_cacheStorage));
    dio.interceptors.add(const _CurlLogInterceptor());
  }

  final CacheStorage _cacheStorage;
  late final Dio dio;
}

class _LocaleInterceptor extends Interceptor {
  _LocaleInterceptor(this._cacheStorage);

  final CacheStorage _cacheStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept-Language'] = _cacheStorage.locale;
    handler.next(options);
  }
}

class _CurlLogInterceptor extends Interceptor {
  const _CurlLogInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[HTTP cURL] ${_toCurl(options)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint(
      '[HTTP Response] ${response.statusCode} ${response.requestOptions.uri}\n'
      '${_formatBody(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    debugPrint(
      '[HTTP Error] ${response?.statusCode ?? '-'} ${err.requestOptions.uri}\n'
      '${_formatBody(response?.data ?? err.message)}',
    );
    handler.next(err);
  }

  static String _toCurl(RequestOptions options) {
    final buffer = StringBuffer('curl');
    buffer.write(' -X ${_shell(options.method)}');
    buffer.write(' ${_shell(options.uri.toString())}');

    final headers = Map<String, dynamic>.from(options.headers)
      ..removeWhere((key, value) => value == null);
    for (final entry in headers.entries) {
      buffer.write(' -H ${_shell('${entry.key}: ${entry.value}')}');
    }

    final data = options.data;
    if (data != null) {
      if (data is FormData) {
        for (final entry in data.fields) {
          buffer.write(' -F ${_shell('${entry.key}=${entry.value}')}');
        }
        for (final entry in data.files) {
          buffer.write(
            ' -F ${_shell('${entry.key}=@${entry.value.filename ?? 'file'}')}',
          );
        }
      } else {
        buffer.write(' --data-raw ${_shell(_formatBody(data))}');
      }
    }

    return buffer.toString();
  }

  static String _formatBody(Object? body) {
    if (body == null) return '';
    if (body is String) return body;
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
    }
  }

  static String _shell(String value) {
    return "'${value.replaceAll("'", r"'\''")}'";
  }
}

Failure mapDioFailure(Object error) {
  if (error is DioException) {
    final response = error.response;
    final data = response?.data;
    final errors = <String, List<String>>{};
    var message = 'Something went wrong. Please try again.';
    if (data is Map<String, dynamic>) {
      message = data['message']?.toString() ?? message;
      final rawErrors = data['errors'];
      if (rawErrors is Map<String, dynamic>) {
        for (final entry in rawErrors.entries) {
          final value = entry.value;
          errors[entry.key] = value is List
              ? value.map((item) => item.toString()).toList()
              : [value.toString()];
        }
      }
    }
    return Failure(message, statusCode: response?.statusCode, errors: errors);
  }
  if (error is Failure) return error;
  return Failure(error.toString());
}
