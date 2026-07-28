import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:manage_center/services/api_exception.dart';
import 'package:manage_center/services/storage_service.dart';
import 'package:manage_center/utils/app_logger.dart';

/// Какой из двух бэкендов дёргаем.
enum ApiVersion { v1, v2 }

/// Единая точка выхода в сеть.
///
/// Берёт на себя то, что раньше дублировалось в каждом методе `ApiService`:
/// подстановку токена, разбор кодов ответа и приведение ошибок к
/// [ApiException] с текстом, который можно показать пользователю.
///
/// При 401 на запросе, требующем авторизации, шлёт сигнал в [onUnauthorized] —
/// его слушает `AppBloc` и разлогинивает пользователя.
class ApiClient {
  static const String v1BaseUrl = 'https://boiler.nwwork.site/api/v1';
  static const String v2BaseUrl = 'https://boiler-v2.nwwork.site/api';

  static const String _skipAuthKey = 'skipAuth';
  static const String _logoutOn401Key = 'logoutOn401';
  static const String _tokenOverrideKey = 'tokenOverride';

  final StorageService _storage;
  final Dio _dio;

  final StreamController<void> _unauthorized = StreamController<void>.broadcast();

  /// Сигнал «сессия недействительна». Отправляется один раз до [resetAuthGuard],
  /// чтобы десяток параллельных запросов не вызвал десяток логаутов.
  Stream<void> get onUnauthorized => _unauthorized.stream;
  bool _unauthorizedReported = false;

  ApiClient(this._storage, {Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 20)
      ..sendTimeout = const Duration(seconds: 30)
      ..receiveTimeout = const Duration(seconds: 60);

    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  // ==================== ИНТЕРЦЕПТОРЫ ====================

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[_skipAuthKey] != true) {
      // Явный токен нужен сразу после входа: пользователь мог не поставить
      // «запомнить меня», и в хранилище токена ещё (или уже) нет.
      final override = options.extra[_tokenOverrideKey] as String?;
      final token = (override != null && override.isNotEmpty)
          ? override
          : await _storage.getToken();

      if (token == null || token.isEmpty) {
        _reportUnauthorized();
        handler.reject(
          DioException(
            requestOptions: options,
            error: const UnauthorizedException('Требуется авторизация'),
          ),
          // Ошибку уже сформировали — гонять её через onError не нужно.
          false,
        );
        return;
      }
      options.headers['Authorization'] = 'Bearer $token';
    }

    logDebug('→ ${options.method} ${options.uri}', name: 'api');
    handler.next(options);
  }

  void _onError(DioException e, ErrorInterceptorHandler handler) {
    final status = e.response?.statusCode;
    logDebug(
      '← ${status ?? e.type.name} ${e.requestOptions.method} '
      '${e.requestOptions.uri}',
      name: 'api',
    );

    // 401 разлогинивает только там, где он действительно про сессию.
    // На входе и на смене пароля 401 — это «неверный пароль», а не истёкший токен.
    if (status == 401 && e.requestOptions.extra[_logoutOn401Key] != false) {
      _reportUnauthorized();
    }
    handler.next(e);
  }

  void _reportUnauthorized() {
    if (_unauthorizedReported) return;
    _unauthorizedReported = true;
    logError('Сессия недействительна — требуется повторный вход', name: 'api');
    _unauthorized.add(null);
  }

  /// Вызывается после успешного входа, чтобы сигнал мог сработать снова.
  void resetAuthGuard() => _unauthorizedReported = false;

  // ==================== ЗАПРОСЫ ====================

  Future<dynamic> get(
    String path, {
    ApiVersion version = ApiVersion.v1,
    Map<String, dynamic>? query,
    Map<int, String>? errors,
    String? accept,
    ResponseType? responseType,
    String? authToken,
  }) {
    return _request(
      'GET',
      path,
      version: version,
      query: query,
      errors: errors,
      accept: accept,
      responseType: responseType,
      authToken: authToken,
    );
  }

  Future<dynamic> post(
    String path, {
    ApiVersion version = ApiVersion.v1,
    Object? body,
    Map<String, dynamic>? query,
    Map<int, String>? errors,
    bool skipAuth = false,
    bool logoutOn401 = true,
    String? accept,
  }) {
    return _request(
      'POST',
      path,
      version: version,
      body: body,
      query: query,
      errors: errors,
      skipAuth: skipAuth,
      logoutOn401: logoutOn401,
      accept: accept,
    );
  }

  Future<dynamic> put(
    String path, {
    ApiVersion version = ApiVersion.v1,
    Object? body,
    Map<int, String>? errors,
    bool logoutOn401 = true,
    String? accept,
  }) {
    return _request(
      'PUT',
      path,
      version: version,
      body: body,
      errors: errors,
      logoutOn401: logoutOn401,
      accept: accept,
    );
  }

  Future<dynamic> delete(
    String path, {
    ApiVersion version = ApiVersion.v1,
    Map<int, String>? errors,
    String? accept,
  }) {
    return _request(
      'DELETE',
      path,
      version: version,
      errors: errors,
      accept: accept,
    );
  }

  /// Multipart-запрос (используется для групп параметров с иконкой).
  Future<dynamic> multipart(
    String method,
    String path, {
    ApiVersion version = ApiVersion.v1,
    required Map<String, String> fields,
    Map<int, String>? errors,
    String? accept,
  }) {
    return _request(
      method,
      path,
      version: version,
      body: FormData.fromMap(fields),
      errors: errors,
      accept: accept,
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    required ApiVersion version,
    Map<String, dynamic>? query,
    Object? body,
    Map<int, String>? errors,
    bool skipAuth = false,
    bool logoutOn401 = true,
    String? accept,
    ResponseType? responseType,
    String? authToken,
  }) async {
    final baseUrl = version == ApiVersion.v1 ? v1BaseUrl : v2BaseUrl;

    try {
      final response = await _dio.request<dynamic>(
        '$baseUrl$path',
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          responseType: responseType,
          headers: {
            if (accept != null) 'Accept': accept,
            if (body != null && body is! FormData)
              Headers.contentTypeHeader: Headers.jsonContentType,
          },
          extra: {
            _skipAuthKey: skipAuth,
            _logoutOn401Key: logoutOn401,
            if (authToken != null) _tokenOverrideKey: authToken,
          },
        ),
      );
      return _normalize(response.data, responseType);
    } on DioException catch (e) {
      throw _toApiException(e, errors);
    }
  }

  /// Часть эндпоинтов отвечает `text/plain` с JSON внутри — Dio такое тело
  /// оставляет строкой, поэтому дораскодируем сами.
  dynamic _normalize(dynamic data, ResponseType? responseType) {
    if (responseType == ResponseType.plain) return data;
    if (data is! String) return data;

    final trimmed = data.trim();
    if (trimmed.isEmpty) return null;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return data;
    }
  }

  // ==================== ОШИБКИ ====================

  ApiException _toApiException(DioException e, Map<int, String>? errors) {
    // Ошибку, собранную в onRequest, отдаём как есть.
    final inner = e.error;
    if (inner is ApiException) return inner;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Сервер не отвечает. Проверьте соединение');
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const ApiException('Запрос отменён');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final status = e.response?.statusCode;
    if (status == null) return const NetworkException();

    final custom = errors?[status];

    if (status == 401 && e.requestOptions.extra[_logoutOn401Key] != false) {
      return UnauthorizedException(custom ?? 'Сессия истекла. Войдите снова');
    }
    if (custom != null) return ApiException(custom, statusCode: status);

    final fromServer = _extractServerMessage(e.response?.data);
    return ApiException(
      fromServer ?? _defaultMessage(status),
      statusCode: status,
    );
  }

  String? _extractServerMessage(dynamic data) {
    if (data is Map) {
      for (final key in const ['message', 'Message', 'title', 'error', 'detail']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return null;
    }
    if (data is String) {
      final trimmed = data.trim();
      // Отсекаем HTML-страницы ошибок и полотна стектрейсов.
      if (trimmed.isNotEmpty &&
          trimmed.length <= 200 &&
          !trimmed.startsWith('<')) {
        return trimmed;
      }
    }
    return null;
  }

  String _defaultMessage(int status) {
    switch (status) {
      case 400:
        return 'Некорректный запрос';
      case 401:
        return 'Неверный логин или пароль';
      case 403:
        return 'Недостаточно прав для этого действия';
      case 404:
        return 'Данные не найдены';
      case 409:
        return 'Конфликт данных';
      default:
        return status >= 500
            ? 'Ошибка на сервере ($status). Попробуйте позже'
            : 'Ошибка сервера: $status';
    }
  }

  void dispose() {
    _unauthorized.close();
    _dio.close();
  }
}
