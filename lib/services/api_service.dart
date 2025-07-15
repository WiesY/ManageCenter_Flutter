import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:manage_center/models/boiler_model.dart';
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
      print('Ошибка при получении списка котельных: $e');
      rethrow; // Перебрасываем исключение дальше (?)
    }
  }
    Future<List<BoilerParameter>> getBoilerParameters(String token, int boilerId) async {
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
          final List<dynamic> data = json.decode(response.body);
          print('Decoded data: $data');
          final parameters = data.map((json) => BoilerParameter.fromJson(json)).toList();
          print('Created BoilerParameter objects: $parameters');
          return parameters;
        case 401:
          throw Exception('Некорректный токен авторизации');
        case 404:
          throw Exception('Котельная не найдена');
        default:
          throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getBoilerParameters: $e');
      throw Exception('Ошибка при получении параметров котельной: $e');
    }
  }

   // Получение значений параметров котельной за период с возможностью фильтрации
  Future<List<BoilerParameterValue>> getBoilerParameterValues(
    String token, 
    int boilerId, 
    DateTime start, 
    DateTime end,
    int interval,
    {List<int>? parameterIds} // Опциональный параметр для фильтрации
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

      // Добавляем фильтр по параметрам, если он указан
      if (parameterIds != null && parameterIds.isNotEmpty) {
        // Преобразуем список ID в строку для query параметра
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
          final List<dynamic> data = json.decode(response.body);
          print('Decoded ${data.length} parameter values');
          final values = data.map((json) => BoilerParameterValue.fromJson(json)).toList();
          print('Created ${values.length} BoilerParameterValue objects');
          return values;
        case 401:
          throw Exception('Некорректный токен авторизации');
        case 404:
          throw Exception('Котельная не найдена');
        default:
          throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getBoilerParameterValues: $e');
      throw Exception('Ошибка при получении значений параметров: $e');
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

}
