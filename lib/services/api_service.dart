import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:manage_center/models/BoilerTypeCompareValues.dart';
import 'package:manage_center/models/boiler_configuration.dart';
import 'package:manage_center/models/boiler_history_model.dart';
import 'package:manage_center/models/boiler_model.dart';
import 'package:manage_center/models/boiler_type_model.dart';
import 'package:manage_center/models/district_model.dart';
import 'package:manage_center/models/parameter_group_model.dart';
import 'package:manage_center/models/role_model.dart';
import 'package:manage_center/models/user_info_model.dart';
import 'package:manage_center/models/boiler_list_item_model.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/services/storage_service.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import '../models/token_model.dart';

class ApiService {
  static const String baseUrl =
      'https://boiler.nwwork.site/api/v1'; // Замените на ваш URL
  static const String apiV1 = '/api/v1';

  Future<TokenResponse> login(String login, String password) async {
    try {
      // login = "RyltsevAV";
      // password = "rav";
      final response = await http.post(
        Uri.parse('$baseUrl/Auth'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'login': login,
          'password': password,
        }),
      );

      switch (response.statusCode) {
        case 200:
          final data = json.decode(response.body);
          return TokenResponse.fromJson(data);
        case 400:
          throw Exception('Некорректно заполнено одно или несколько полей');
        case 401:
          throw Exception('Неверный логин или пароль');
        default:
          throw Exception('Ошибка сервера');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserInfo> getUserInfo(String token) async {
    try {
      print('Getting user info with token: $token');
      final response = await http.get(
        Uri.parse('$baseUrl/Users/Me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      switch (response.statusCode) {
        case 200:
          final data = json.decode(response.body);
          print(
              'Decoded data: $data'); // Добавляем логирование декодированных данных
          final userInfo = UserInfo.fromJson(data);
          print(
              'Created UserInfo object: ${userInfo.name}'); // Логируем созданный объект
          return userInfo;
        case 401:
          throw Exception('Некорректный токен авторизации');
        default:
          throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getUserInfo: $e'); // Логируем ошибку
      throw Exception('Ошибка при получении данных: $e');
    }
  }

  Future<void> changePassword(String token, String currentPassword, String newPassword) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/Users/Me/ChangePassword'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      print('Password changed successfully');
    } else if (response.statusCode == 400) {
      print('Bad request: ${response.body}');
      throw Exception('Invalid password data');
    } else if (response.statusCode == 401) {
      print('Unauthorized: Invalid current password');
      throw Exception('Current password is incorrect');
    } else {
      print('Error changing password: ${response.statusCode}');
      throw Exception('Failed to change password');
    }
  } catch (e) {
    print('Exception during password change: $e');
    rethrow;
  }
}

  Future<List<BoilerWithLastData>> getBoilersWithLastData(String token) async {
    try {
      print('Getting boilers with token: $token');
      final response = await http.get(
        Uri.parse('$baseUrl/Boilers/WithLastData'), // Изменен URL
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      switch (response.statusCode) {
        case 200:
          final List<dynamic> data = json.decode(response.body);
          print('Decoded data: $data');
          final boilers =
              data.map((json) => BoilerWithLastData.fromJson(json)).toList();
          print('Created Boiler objects: $boilers');
          return boilers;
        case 401:
          throw Exception('Некорректный токен авторизации');
        default:
          throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getBoilers: $e');
      throw Exception('Ошибка при получении данных: $e');
    }
  }

  Future<List<BoilerListItem>> getBoilers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Boilers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final boilers =
            data.map((json) => BoilerListItem.fromJson(json)).toList();
        return boilers;
      } else if (response.statusCode == 401) {
        throw Exception('Некорректный токен авторизации');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при получении списка объектов: $e');
      rethrow; // Перебрасываем исключение дальше (?)
    }
  }
    // Исправленный метод getBoilerParameters
Future<BoilerConfiguration> getBoilerParameters(String token, int boilerId) async {
  try {
    print('Getting boiler parameters for boiler $boilerId with token: $token');
    final response = await http.get(
      Uri.parse('$baseUrl/BoilerParameters/$boilerId/Parameters'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    switch (response.statusCode) {
      case 200:
        final dynamic data = json.decode(response.body);
        print('Decoded data: $data');
        // ИСПРАВЛЕНО: парсим как один объект BoilerConfiguration
        final configuration = BoilerConfiguration.fromJson(data);
        print('Created BoilerConfiguration with ${configuration.boilerParameters.length} parameters and ${configuration.groups.length} groups');
        return configuration;
      case 401:
        throw Exception('Некорректный токен авторизации');
      case 404:
        throw Exception('Объект не найден');
      default:
        throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getBoilerParameters: $e');
    throw Exception('Ошибка при получении параметров объекта: $e');
  }
}

// Исправленный метод getBoilerParameterValues
Future<BoilerHistoryResponse> getBoilerParameterValues(
  String token, 
  int boilerId, 
  DateTime start, 
  DateTime end,
  int interval,
  {List<int>? parameterIds}
) async {
  try {
    print('Getting boiler parameter values for boiler $boilerId from $start to $end');
    if (parameterIds != null) {
      print('Filtering by parameter IDs: $parameterIds');
    }

    Map<String, String> queryParams = {
      'Start': start.toIso8601String(),
      'End': end.toIso8601String(),
      'Interval': interval.toString(),
    };

    if (parameterIds != null && parameterIds.isNotEmpty) {
      queryParams['ParameterIds'] = parameterIds.join(',');
    }

    final uri = Uri.parse('$baseUrl/BoilerParameters/$boilerId/Values').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body length: ${response.body.length}');

    switch (response.statusCode) {
      case 200:
        final dynamic data = json.decode(response.body);
        print('Decoded data with ${data['historyNodeValues']?.length ?? 0} values and ${data['groups']?.length ?? 0} groups');
        // ИСПРАВЛЕНО: парсим как один объект BoilerHistoryResponse
        final historyResponse = BoilerHistoryResponse.fromJson(data);
        print('Created BoilerHistoryResponse with ${historyResponse.historyNodeValues.length} values');
        return historyResponse;
      case 401:
        throw Exception('Некорректный токен авторизации');
      case 404:
        throw Exception('Объект не найден');
      default:
        throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getBoilerParameterValues: $e');
    throw Exception('Ошибка при получении значений параметров: $e');
  }
}

// Получение истории значений для конкретного параметра
Future<List<BoilerParameterValue>> getParameterHistoryValues(
  String token, 
  int boilerId, 
  int parameterId,
  DateTime startDate, 
  DateTime endDate,
  int interval
) async {
  try {
    print('Getting history values for parameter $parameterId from $startDate to $endDate');
    
    Map<String, String> queryParams = {
      'Start': startDate.toIso8601String(),
      'End': endDate.toIso8601String(),
      'Interval': interval.toString(),
    };

    final uri = Uri.parse('$baseUrl/BoilerParameters/$boilerId/$parameterId/Values').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Response status code: ${response.statusCode}');

    switch (response.statusCode) {
      case 200:
        final dynamic data = json.decode(response.body);
        
        // Выводим структуру ответа для отладки
        print('Response structure: ${data.runtimeType}');
        
        if (data is Map<String, dynamic>) {
          // Если это объект, проверяем наличие нужных полей
          if (data.containsKey('historyNodeValues') && data['historyNodeValues'] is List) {
            final List<dynamic> values = data['historyNodeValues'];
            print('Received ${values.length} parameter values from historyNodeValues');
            return values.map((item) => BoilerParameterValue.fromJson(item)).toList();
          } else if (data.containsKey('values') && data['values'] is List) {
            final List<dynamic> values = data['values'];
            print('Received ${values.length} parameter values from values');
            return values.map((item) => BoilerParameterValue.fromJson(item)).toList();
          } else {
            // Если нет нужных ключей, создаем параметр из самого объекта
            print('Creating parameter value from response object');
            
            // Проверяем наличие необходимых полей
            if (!data.containsKey('parameter')) {
              // Создаем параметр вручную
              data['parameter'] = {
                'id': parameterId,
                'name': 'Параметр $parameterId',
                'valueType': 'double'
              };
            }
            
            // Проверяем наличие даты получения
            if (!data.containsKey('receiptDate')) {
              data['receiptDate'] = DateTime.now().toIso8601String();
            }
            
            return [BoilerParameterValue.fromJson(data)];
          }
        } else if (data is List) {
          // Если это список, обрабатываем как раньше
          print('Received ${data.length} parameter values from list');
          return data.map((item) => BoilerParameterValue.fromJson(item)).toList();
        } else {
          throw Exception('Неожиданный формат данных: ${data.runtimeType}');
        }
        
      case 401:
        throw Exception('Некорректный токен авторизации');
      case 404:
        throw Exception('Параметр не найден');
      default:
        throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getParameterHistoryValues: $e');
    throw Exception('Ошибка при получении истории значений параметра: $e');
  }
}

// Получение истории значений параметров по типу объекта
Future<List<BoilerTypeCompareValues>> getBoilerParametersByTypeCompareValues(
  String token, 
  int boilerTypeId, 
  List<int>? groupIds, 
  String compareDateTime, 
  {bool includeUngrouped = true}
) async {
  try {
    print('Getting parameter values for boiler type $boilerTypeId at $compareDateTime');
    
    // Формируем базовый URL
    String url = '$baseUrl/BoilerParameters/$boilerTypeId/CompareValues';
    
    // Формируем параметры запроса
    Map<String, String> queryParams = {
      'compareDateTime': compareDateTime,
      'includeUngrouped': includeUngrouped.toString(),
    };
    
    // Добавляем groupIds, если они указаны
    if (groupIds != null && groupIds.isNotEmpty) {
      queryParams['groupIds'] = groupIds.join(',');
    }
    
    // Создаем URI с параметрами
    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    
    print('Request URL: $uri');
    
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'text/plain',
      },
    );
    
    print('Response status code: ${response.statusCode}');
    
    switch (response.statusCode) {
      case 200:
        final List<dynamic> data = json.decode(response.body);
        print('Received data for ${data.length} boilers');
        
        return data.map((boilerData) => 
          BoilerTypeCompareValues.fromJson(boilerData)
        ).toList();
        
      case 401:
        throw Exception('Некорректный токен авторизации');
      case 403:
        throw Exception('Пользователь должен иметь доступ к указанной котельной');
      case 404:
        throw Exception('Тип объекта не найден');
      default:
        throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getBoilerParametersByTypeCompareValues: $e');
    throw Exception('Ошибка при получении значений параметров: $e');
  }
}

  //----управление группами параметров----

// Получение всех групп параметров
Future<List<ParameterGroup>> getParameterGroups(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/ParamGroups'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'text/plain',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ParameterGroup.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при получении групп параметров: $e');
    rethrow;
  }
}

// Получение группы по ID
Future<ParameterGroup> getParameterGroupById(String token, int paramGroupId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/ParamGroups/$paramGroupId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'text/plain',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ParameterGroup.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Группа параметров не найдена');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при получении группы параметров: $e');
    rethrow;
  }
}

// Создание новой группы параметров
Future<ParameterGroup> createParameterGroup(String token, String name, String color, String? iconFileName) async {
  try {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/ParamGroups'));
    
    // Добавляем заголовки
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'text/plain',
    });
    
    // Добавляем поля формы
    request.fields['Name'] = name;
    
    if (color != null && color.isNotEmpty) {
      request.fields['Color'] = color;
    }
    
    // Если есть файл иконки, добавляем его
    if (iconFileName != null && iconFileName.isNotEmpty) {
      request.fields['IconFileName'] = iconFileName;
      // Если нужно загрузить файл, добавь его как MultipartFile
      // request.files.add(await http.MultipartFile.fromPath('IconFile', iconFilePath));
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ParameterGroup.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Ошибка при создании группы параметров: $e');
    rethrow;
  }
}

// Обновление группы параметров
Future<ParameterGroup> updateParameterGroup(String token, int paramGroupId, String name, String color, String? iconFileName) async {
  try {
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/ParamGroups/$paramGroupId'));
    
    // Добавляем заголовки
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'text/plain',
    });
    
    // Добавляем поля формы
    request.fields['Name'] = name;
    
    if (color != null && color.isNotEmpty) {
      request.fields['Color'] = color;
    }
    
    // Если есть файл иконки, добавляем его
    if (iconFileName != null && iconFileName.isNotEmpty) {
      request.fields['IconFileName'] = iconFileName;
      // Если нужно загрузить файл, добавь его как MultipartFile
      // request.files.add(await http.MultipartFile.fromPath('IconFile', iconFilePath));
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ParameterGroup.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Группа параметров не найдена');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Ошибка при обновлении группы параметров: $e');
    rethrow;
  }
}

// Удаление группы параметров
Future<void> deleteParameterGroup(String token, int paramGroupId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/ParamGroups/$paramGroupId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'text/plain',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Группа параметров не найдена');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при удалении группы параметров: $e');
    rethrow;
  }
}

// Получение иконки группы по имени файла
Future<String> getParameterGroupIconByName(String token, String? fileName, bool isDownload) async {
  try {
    final queryParams = {
      'isDownload': isDownload.toString(),
    };
    
    final uri = Uri.parse('$baseUrl/ParamGroups/icon').replace(
      queryParameters: queryParams,
    );
    
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return response.body; // Возвращаем содержимое файла или base64 строку
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Файл не найден');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при получении иконки группы: $e');
    rethrow;
  }
}

// Получение иконки группы по ID группы
Future<String> getParameterGroupIconById(String token, int paramGroupId, bool isDownload) async {
  try {
    final queryParams = {
      'isDownload': isDownload.toString(),
    };
    
    final uri = Uri.parse('$baseUrl/ParamGroups/$paramGroupId/Icon').replace(
      queryParameters: queryParams,
    );
    
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return response.body; // Возвращаем содержимое файла или base64 строку
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Группа или иконка не найдена');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при получении иконки группы: $e');
    rethrow;
  }
}

// Изменение группы у параметров
Future<void> updateParametersGroup(String token, int groupId, List<int> parametersId) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/BoilerParameters/Parameters/Groups'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'groupId': groupId,
        'parametersId': parametersId,
      }),
    );

    if (response.statusCode == 200) {
      // Успешно обновлено
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при изменении группы параметров: $e');
    rethrow;
  }
}

  //-------управление пользователями--------

Future<List<UserInfo>> getUsers(String token) async {
  try {
    print('Making request to: $baseUrl/users');
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    print('getUsers response status: ${response.statusCode}');
    print('getUsers response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final responseBody = response.body;
      if (responseBody.isEmpty) {
        print('Empty response body');
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(responseBody);
      print('Parsed JSON list length: ${jsonList.length}');
      
      return jsonList.map((json) {
        print('Processing user JSON: $json');
        if (json == null) {
          print('Warning: null user in list');
          return null;
        }
        return UserInfo.fromJson(json as Map<String, dynamic>);
      }).where((user) => user != null).cast<UserInfo>().toList();
      
    } else {
      throw Exception('Failed to load users: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Error in getUsers: $e');
    rethrow;
  }
}

Future<UserInfo> createUser(String token, Map<String, dynamic> userData) async {
  final response = await http.post(
    Uri.parse('$baseUrl/users'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: json.encode(userData), // {login, password, roleId, etc.}
  );
  if (response.statusCode == 200) {
    return UserInfo.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to create user: ${response.statusCode}');
  }
}

Future<UserInfo> updateUser(String token, int userId, Map<String, dynamic> userData) async {
  final response = await http.put(
    Uri.parse('$baseUrl/users/$userId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: json.encode(userData),
  );
  if (response.statusCode == 200) {
    return UserInfo.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to update user: ${response.statusCode}');
  }
}

Future<void> deleteUser(String token, int userId) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/users/$userId'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to delete user: ${response.statusCode}');
  }
}

//-------управление ролями--------

Future<List<Role>> getRoles(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/Roles'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((json) => Role.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load roles: ${response.statusCode}');
  }
}

Future<Role> createRole(String token, Map<String, dynamic> roleData) async {
  final response = await http.post(
    Uri.parse('$baseUrl/Roles'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: json.encode(roleData), // {name, canAccessAllBoilers: bool, canManageAccounts: bool, canManageBoilers: bool}
  );
  if (response.statusCode == 200) {
    return Role.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to create role: ${response.statusCode}');
  }
}

Future<Role> updateRole(String token, int roleId, Map<String, dynamic> roleData) async {
  final response = await http.put(
    Uri.parse('$baseUrl/Roles/$roleId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: json.encode(roleData),
  );
  if (response.statusCode == 200) {
    return Role.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to update role: ${response.statusCode}');
  }
}

Future<void> deleteRole(String token, int roleId) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/Roles/$roleId'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to delete role: ${response.statusCode}');
  }
}

//-------управление районами--------

// Получение всех районов
Future<List<District>> getAllDistricts(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/Districts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final districts = data.map((json) => District.fromJson(json)).toList();
      return districts;
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при получении списка районов: $e');
    rethrow;
  }
}

// Получение района по ID
Future<District> getDistrictById(String token, int districtId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/Districts/$districtId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return District.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Район не найден');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при получении района: $e');
    rethrow;
  }
}

// Создание нового района
Future<void> createDistrict(String token, String name) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/Districts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при создании района: $e');
    rethrow;
  }
}

// Редактирование района
Future<void> updateDistrict(String token, int districtId, String name) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/Districts/$districtId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Район не найден');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при редактировании района: $e');
    rethrow;
  }
}

// Удаление района
Future<void> deleteDistrict(String token, int districtId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/Districts/$districtId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Район не найден');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при удалении района: $e');
    rethrow;
  }
}

//-------управление районами--------

// Получение всех типов объектов
Future<List<BoilerType>> getAllBoilerTypes(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/BoilerTypes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final boilerTypes = data.map((json) => BoilerType.fromJson(json)).toList();
      return boilerTypes;
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при получении списка типов объектов: $e');
    rethrow;
  }
}

// Получение типа объекта по ID
Future<BoilerType> getBoilerTypeById(String token, int boilerTypeId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/BoilerTypes/$boilerTypeId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return BoilerType.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Тип объекта не найден');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при получении типа объекта: $e');
    rethrow;
  }
}

// Создание нового типа объекта
Future<void> createBoilerType(String token, String name) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/BoilerTypes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при создании типа объекта: $e');
    rethrow;
  }
}

// Редактирование типа объекта
Future<void> updateBoilerType(String token, int boilerTypeId, String name) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/BoilerTypes/$boilerTypeId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Тип объекта не найден');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при редактировании типа объекта: $e');
    rethrow;
  }
}

// Удаление типа объекта
Future<void> deleteBoilerType(String token, int boilerTypeId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/BoilerTypes/$boilerTypeId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Тип объекта не найден');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при удалении типа объекта: $e');
    rethrow;
  }
}

//-------управление объектами--------

// Создание нового объекта
Future<void> createBoiler(String token, Map<String, dynamic> boilerData) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/Boilers'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(boilerData),
    );

    if (response.statusCode == 200) {
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при создании объекта: $e');
    rethrow;
  }
}

// Получение объекта по ID
Future<BoilerListItem> getBoilerById(String token, int boilerId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/Boilers/$boilerId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return BoilerListItem.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Объект не найден');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при получении объекта: $e');
    rethrow;
  }
}

// Обновление объекта
Future<void> updateBoiler(String token, int boilerId, Map<String, dynamic> boilerData) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/Boilers/$boilerId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(boilerData),
    );

    if (response.statusCode == 200) {
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Объект не найден');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при обновлении объекта: $e');
    rethrow;
  }
}

// Удаление объекта
Future<void> deleteBoiler(String token, int boilerId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/Boilers/$boilerId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Некорректный токен авторизации');
    } else if (response.statusCode == 404) {
      throw Exception('Объект не найден');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при удалении объекта: $e');
    rethrow;
  }
}
}
