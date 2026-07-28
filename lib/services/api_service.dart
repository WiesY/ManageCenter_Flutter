import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:manage_center/models/BoilerTypeCompareValues.dart';
import 'package:manage_center/models/boiler_configuration.dart';
import 'package:manage_center/models/boiler_history_model.dart';
import 'package:manage_center/models/boiler_model.dart';
import 'package:manage_center/models/boiler_type_model.dart';
import 'package:manage_center/models/district_model.dart';
import 'package:manage_center/models/incident_model.dart';
import 'package:manage_center/models/parameter_group_model.dart';
import 'package:manage_center/models/role_model.dart';
import 'package:manage_center/models/user_info_model.dart';
import 'package:manage_center/models/boiler_list_item_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/services/api_client.dart';
import 'package:manage_center/services/api_exception.dart';
import 'package:manage_center/services/storage_service.dart';
import 'package:manage_center/utils/app_logger.dart';
import '../models/token_model.dart';

/// Типизированная обёртка над эндпоинтами бэкенда.
///
/// Токен, коды ответа и сетевые ошибки — забота [ApiClient]; здесь остаётся
/// только адрес эндпоинта, параметры и разбор тела ответа в модель.
class ApiService {
  final ApiClient _client;

  ApiService({required StorageService storageService, ApiClient? client})
      : _client = client ?? ApiClient(storageService);

  /// Нужен подписчикам на [ApiClient.onUnauthorized] (см. `AppBloc`).
  ApiClient get client => _client;

  // ==================== АВТОРИЗАЦИЯ ====================

  Future<TokenResponse> login(String login, String password) async {
    final device = await _collectDeviceInfo();

    final data = await _client.post(
      '/Auth/Login',
      version: ApiVersion.v2,
      skipAuth: true,
      // 401 здесь — неверный пароль, а не истёкшая сессия.
      logoutOn401: false,
      body: {
        'login': login,
        'password': password,
        'deviceName': device.name,
        'deviceId': device.id,
        'operatingSystem': device.osVersion,
      },
      errors: {
        400: 'Некорректно заполнено одно или несколько полей',
        401: 'Неверный логин или пароль',
      },
    );

    // Новая сессия — разрешаем сигналу о протухшем токене сработать снова.
    _client.resetAuthGuard();
    return TokenResponse.fromJson(data as Map<String, dynamic>);
  }

  /// [token] задаётся только сразу после входа, пока токен ещё не в хранилище.
  Future<UserInfo> getUserInfo({String? token}) async {
    final data = await _client.get(
      '/Users/Me',
      authToken: token,
      errors: {401: 'Некорректный токен авторизации'},
    );
    return UserInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    await _client.put(
      '/Users/Me/ChangePassword',
      // 401 здесь — неверный текущий пароль, разлогинивать нельзя.
      logoutOn401: false,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      errors: {
        400: 'Некорректные данные пароля',
        401: 'Текущий пароль указан неверно',
      },
    );
  }

  Future<({String? name, String? id, String? osVersion})>
      _collectDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return (
          name: '${info.manufacturer} ${info.model}',
          id: info.id,
          osVersion: 'Android ${info.version.release}',
        );
      }
      if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return (
          name: info.name,
          id: info.identifierForVendor,
          osVersion: 'iOS ${info.systemVersion}',
        );
      }
      if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        return (
          name: info.computerName,
          id: info.deviceId,
          osVersion: '${info.productName} (Build ${info.buildNumber})',
        );
      }
    } catch (e) {
      logError('Не удалось получить информацию об устройстве', error: e);
    }
    return (name: 'Unknown Device', id: null, osVersion: null);
  }

  // ==================== ОБЪЕКТЫ И ПАРАМЕТРЫ ====================

  Future<List<BoilerWithLastData>> getBoilersWithLastData() async {
    final data = await _client.get('/Boilers/WithLastData') as List<dynamic>;
    return data
        .map((e) => BoilerWithLastData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BoilerListItem>> getBoilers() async {
    final data =
        await _client.get('/Dashboard', version: ApiVersion.v2) as List<dynamic>;
    return data
        .map((e) => BoilerListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BoilerConfiguration> getBoilerParameters(int boilerId) async {
    final data = await _client.get(
      '/BoilerParameters/$boilerId/Parameters',
      errors: {404: 'Объект не найден'},
    );
    return BoilerConfiguration.fromJson(data as Map<String, dynamic>);
  }

  Future<BoilerHistoryResponse> getBoilerParameterValues(
    int boilerId,
    DateTime start,
    DateTime end,
    int interval, {
    List<int>? parameterIds,
  }) async {
    final data = await _client.get(
      '/BoilerParameters/$boilerId/Values',
      query: {
        'Start': start.toIso8601String(),
        'End': end.toIso8601String(),
        'Interval': interval.toString(),
        if (parameterIds != null && parameterIds.isNotEmpty)
          'ParameterIds': parameterIds.join(','),
      },
      errors: {404: 'Объект не найден'},
    );
    return BoilerHistoryResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<List<BoilerParameterValue>> getParameterHistoryValues(
    int boilerId,
    int parameterId,
    DateTime startDate,
    DateTime endDate,
    int interval,
  ) async {
    final data = await _client.get(
      '/BoilerParameters/$boilerId/$parameterId/Values',
      query: {
        'Start': startDate.toIso8601String(),
        'End': endDate.toIso8601String(),
        'Interval': interval.toString(),
      },
      errors: {404: 'Параметр не найден'},
    );

    if (data is List) {
      return data
          .map((e) => BoilerParameterValue.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final values = data['historyNodeValues'] ?? data['values'];
      if (values is List) {
        return values
            .map((e) => BoilerParameterValue.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Сервер вернул одно значение объектом — достраиваем поля, которых
      // ждёт модель.
      data['parameter'] ??= {
        'id': parameterId,
        'name': 'Параметр $parameterId',
        'valueType': 'double',
      };
      data['receiptDate'] ??= DateTime.now().toIso8601String();
      return [BoilerParameterValue.fromJson(data)];
    }

    throw ApiException('Неожиданный формат данных: ${data.runtimeType}');
  }

  Future<List<BoilerTypeCompareValues>> getBoilerParametersByTypeCompareValues(
    int boilerTypeId,
    List<int>? groupIds,
    String compareDateTime, {
    bool includeUngrouped = true,
  }) async {
    final data = await _client.get(
      '/BoilerParameters/$boilerTypeId/CompareValues',
      accept: 'text/plain',
      query: {
        'compareDateTime': compareDateTime,
        'includeUngrouped': includeUngrouped.toString(),
        if (groupIds != null && groupIds.isNotEmpty)
          'groupIds': groupIds.join(','),
      },
      errors: {
        403: 'Пользователь должен иметь доступ к указанной котельной',
        404: 'Тип объекта не найден',
      },
    ) as List<dynamic>;

    return data
        .map((e) => BoilerTypeCompareValues.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createBoiler(Map<String, dynamic> boilerData) async {
    await _client.post('/Boilers', body: boilerData);
  }

  Future<BoilerListItem> getBoilerById(int boilerId) async {
    final data = await _client.get(
      '/boilers/$boilerId/details',
      version: ApiVersion.v2,
      errors: {404: 'Объект не найден'},
    );
    return BoilerListItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> updateBoiler(
      int boilerId, Map<String, dynamic> boilerData) async {
    await _client.put(
      '/Boilers/$boilerId',
      body: boilerData,
      errors: {404: 'Объект не найден'},
    );
  }

  Future<void> deleteBoiler(int boilerId) async {
    await _client.delete(
      '/Boilers/$boilerId',
      errors: {404: 'Объект не найден'},
    );
  }

  // ==================== ИНЦИДЕНТЫ (ЖУРНАЛ АВАРИЙ) ====================

  Future<List<IncidentModel>> getIncidents({
    bool onlyActive = true,
    int? boilerId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final data = await _client.get(
      '/Incidents',
      version: ApiVersion.v2,
      query: {
        'onlyActive': onlyActive.toString(),
        if (boilerId != null) 'boilerId': boilerId.toString(),
        if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
        if (toDate != null) 'toDate': toDate.toIso8601String(),
      },
    ) as List<dynamic>;

    final incidents = data
        .map((e) => IncidentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    // Новые сверху.
    incidents.sort((a, b) => b.startTime.compareTo(a.startTime));
    return incidents;
  }

  Future<void> resetIncident(int incidentId) async {
    await _client.post(
      '/Incidents/$incidentId/reset',
      version: ApiVersion.v2,
      errors: {404: 'Инцидент не найден'},
    );
  }

  Future<int> getActiveIncidentsCount({int? boilerId}) async {
    try {
      final incidents = await getIncidents(onlyActive: true, boilerId: boilerId);
      return incidents.length;
    } catch (e) {
      logError('Не удалось получить число активных инцидентов', error: e);
      return 0;
    }
  }

  // ==================== ГРУППЫ ПАРАМЕТРОВ ====================

  Future<List<ParameterGroup>> getParameterGroups() async {
    final data =
        await _client.get('/ParamGroups', accept: 'text/plain') as List<dynamic>;
    return data
        .map((e) => ParameterGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ParameterGroup> getParameterGroupById(int paramGroupId) async {
    final data = await _client.get(
      '/ParamGroups/$paramGroupId',
      accept: 'text/plain',
      errors: {404: 'Группа параметров не найдена'},
    );
    return ParameterGroup.fromJson(data as Map<String, dynamic>);
  }

  Future<ParameterGroup> createParameterGroup(
      String name, String color, String? iconFileName) async {
    final data = await _client.multipart(
      'POST',
      '/ParamGroups',
      accept: 'text/plain',
      fields: {
        'Name': name,
        if (color.isNotEmpty) 'Color': color,
        if (iconFileName != null && iconFileName.isNotEmpty)
          'IconFileName': iconFileName,
      },
    );
    return ParameterGroup.fromJson(data as Map<String, dynamic>);
  }

  Future<ParameterGroup> updateParameterGroup(int paramGroupId, String name,
      String color, String? iconFileName) async {
    final data = await _client.multipart(
      'PUT',
      '/ParamGroups/$paramGroupId',
      accept: 'text/plain',
      fields: {
        'Name': name,
        if (color.isNotEmpty) 'Color': color,
        if (iconFileName != null && iconFileName.isNotEmpty)
          'IconFileName': iconFileName,
      },
      errors: {404: 'Группа параметров не найдена'},
    );
    return ParameterGroup.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteParameterGroup(int paramGroupId) async {
    await _client.delete(
      '/ParamGroups/$paramGroupId',
      accept: 'text/plain',
      errors: {404: 'Группа параметров не найдена'},
    );
  }

  Future<String> getParameterGroupIconByName(
      String? fileName, bool isDownload) async {
    final data = await _client.get(
      '/ParamGroups/icon',
      accept: 'application/json',
      responseType: ResponseType.plain,
      query: {'isDownload': isDownload.toString()},
      errors: {404: 'Файл не найден'},
    );
    return data as String;
  }

  Future<String> getParameterGroupIconById(
      int paramGroupId, bool isDownload) async {
    final data = await _client.get(
      '/ParamGroups/$paramGroupId/Icon',
      accept: 'application/json',
      responseType: ResponseType.plain,
      query: {'isDownload': isDownload.toString()},
      errors: {404: 'Группа или иконка не найдена'},
    );
    return data as String;
  }

  Future<void> updateParametersGroup(int groupId, List<int> parametersId) async {
    await _client.put(
      '/BoilerParameters/Parameters/Groups',
      body: {
        'groupId': groupId,
        'parametersId': parametersId,
      },
    );
  }

  // ==================== ПОЛЬЗОВАТЕЛИ ====================

  Future<List<UserInfo>> getUsers() async {
    final data = await _client.get('/users');
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(UserInfo.fromJson)
        .toList();
  }

  Future<UserInfo> createUser(Map<String, dynamic> userData) async {
    final data = await _client.post('/users', body: userData);
    return UserInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<UserInfo> updateUser(int userId, Map<String, dynamic> userData) async {
    final data = await _client.put('/users/$userId', body: userData);
    return UserInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteUser(int userId) async {
    await _client.delete('/users/$userId');
  }

  // ==================== РОЛИ ====================

  Future<List<Role>> getRoles() async {
    final data = await _client.get('/Roles') as List<dynamic>;
    return data.map((e) => Role.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Role> createRole(Map<String, dynamic> roleData) async {
    final data = await _client.post('/Roles', body: roleData);
    return Role.fromJson(data as Map<String, dynamic>);
  }

  Future<Role> updateRole(int roleId, Map<String, dynamic> roleData) async {
    final data = await _client.put('/Roles/$roleId', body: roleData);
    return Role.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteRole(int roleId) async {
    await _client.delete('/Roles/$roleId');
  }

  // ==================== РАЙОНЫ ====================

  Future<List<District>> getAllDistricts() async {
    final data = await _client.get('/Districts') as List<dynamic>;
    return data
        .map((e) => District.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<District> getDistrictById(int districtId) async {
    final data = await _client.get(
      '/Districts/$districtId',
      errors: {404: 'Район не найден'},
    );
    return District.fromJson(data as Map<String, dynamic>);
  }

  Future<void> createDistrict(String name) async {
    await _client.post('/Districts', body: {'name': name});
  }

  Future<void> updateDistrict(int districtId, String name) async {
    await _client.put(
      '/Districts/$districtId',
      body: {'name': name},
      errors: {404: 'Район не найден'},
    );
  }

  Future<void> deleteDistrict(int districtId) async {
    await _client.delete(
      '/Districts/$districtId',
      errors: {404: 'Район не найден'},
    );
  }

  // ==================== ТИПЫ ОБЪЕКТОВ ====================

  Future<List<BoilerType>> getAllBoilerTypes() async {
    final data = await _client.get('/BoilerTypes') as List<dynamic>;
    return data
        .map((e) => BoilerType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BoilerType> getBoilerTypeById(int boilerTypeId) async {
    final data = await _client.get(
      '/BoilerTypes/$boilerTypeId',
      errors: {404: 'Тип объекта не найден'},
    );
    return BoilerType.fromJson(data as Map<String, dynamic>);
  }

  Future<void> createBoilerType(String name) async {
    await _client.post('/BoilerTypes', body: {'name': name});
  }

  Future<void> updateBoilerType(int boilerTypeId, String name) async {
    await _client.put(
      '/BoilerTypes/$boilerTypeId',
      body: {'name': name},
      errors: {404: 'Тип объекта не найден'},
    );
  }

  Future<void> deleteBoilerType(int boilerTypeId) async {
    await _client.delete(
      '/BoilerTypes/$boilerTypeId',
      errors: {404: 'Тип объекта не найден'},
    );
  }
}
