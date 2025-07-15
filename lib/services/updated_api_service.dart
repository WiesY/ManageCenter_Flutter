// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:manage_center/models/boiler_model.dart';
// import 'package:manage_center/models/user_info_model.dart';
// import 'package:manage_center/models/boiler_list_item_model.dart';
// import 'package:manage_center/models/boiler_parameter_model.dart';
// import 'package:manage_center/models/boiler_parameter_value_model.dart';
// import '../models/token_model.dart';
// import 'package:manage_center/models/user_management_model.dart';

// class ApiService {
//   static const String baseUrl =
//       'https://boiler.nwwork.site/api/v1'; // Замените на ваш URL
//   static const String apiV1 = '/api/v1';

//   Future<TokenResponse> login(String login, String password) async {
//     try {
//       login = "RyltsevAV";
//       password = "rav";
//       final response = await http.post(
//         Uri.parse('$baseUrl/Auth'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'login': login,
//           'password': password,
//         }),
//       );

//       switch (response.statusCode) {
//         case 200:
//           final data = json.decode(response.body);
//           return TokenResponse.fromJson(data);
//         case 400:
//           throw Exception('Некорректно заполнено одно или несколько полей');
//         case 401:
//           throw Exception('Неверный логин или пароль');
//         default:
//           throw Exception('Ошибка сервера');
//       }
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<UserInfo> getUserInfo(String token) async {
//     try {
//       print('Getting user info with token: $token');
//       final response = await http.get(
//         Uri.parse('$baseUrl/Users/Me'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       print('Response status code: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       switch (response.statusCode) {
//         case 200:
//           final data = json.decode(response.body);
//           print(
//               'Decoded data: $data'); // Добавляем логирование декодированных данных
//           final userInfo = UserInfo.fromJson(data);
//           print(
//               'Created UserInfo object: $userInfo'); // Логируем созданный объект
//           return userInfo;
//         case 401:
//           throw Exception('Некорректный токен авторизации');
//         default:
//           throw Exception('Ошибка сервера: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getUserInfo: $e'); // Логируем ошибку
//       throw Exception('Ошибка при получении данных: $e');
//     }
//   }

//   Future<List<BoilerWithLastData>> getBoilersWithLastData(String token) async {
//     try {
//       print('Getting boilers with token: $token');
//       final response = await http.get(
//         Uri.parse('$baseUrl/Boilers/WithLastData'), // Изменен URL
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       print('Response status code: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       switch (response.statusCode) {
//         case 200:
//           final List<dynamic> data = json.decode(response.body);
//           print('Decoded data: $data');
//           final boilers =
//               data.map((json) => BoilerWithLastData.fromJson(json)).toList();
//           print('Created Boiler objects: $boilers');
//           return boilers;
//         case 401:
//           throw Exception('Некорректный токен авторизации');
//         default:
//           throw Exception('Ошибка сервера: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getBoilers: $e');
//       throw Exception('Ошибка при получении данных: $e');
//     }
//   }

//   Future<List<BoilerListItem>> getBoilers(String token) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/Boilers'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         final boilers =
//             data.map((json) => BoilerListItem.fromJson(json)).toList();
//         return boilers;
//       } else if (response.statusCode == 401) {
//         throw Exception('Некорректный токен авторизации');
//       } else {
//         throw Exception('Ошибка сервера: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Ошибка при получении списка котельных: $e');
//       rethrow; // Перебрасываем исключение дальше (?)
//     }
//   }
//     Future<List<BoilerParameter>> getBoilerParameters(String token, int boilerId) async {
//     try {
//       print('Getting boiler parameters for boiler $boilerId with token: $token');
//       final response = await http.get(
//         Uri.parse('$baseUrl/BoilerParameters/$boilerId/Parameters'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       print('Response status code: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       switch (response.statusCode) {
//         case 200:
//           final List<dynamic> data = json.decode(response.body);
//           print('Decoded data: $data');
//           final parameters = data.map((json) => BoilerParameter.fromJson(json)).toList();
//           print('Created BoilerParameter objects: $parameters');
//           return parameters;
//         case 401:
//           throw Exception('Некорректный токен авторизации');
//         case 404:
//           throw Exception('Котельная не найдена');
//         default:
//           throw Exception('Ошибка сервера: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getBoilerParameters: $e');
//       throw Exception('Ошибка при получении параметров котельной: $e');
//     }
//   }

//    // Получение значений параметров котельной за период с возможностью фильтрации
//   Future<List<BoilerParameterValue>> getBoilerParameterValues(
//     String token, 
//     int boilerId, 
//     DateTime start, 
//     DateTime end,
//     {List<int>? parameterIds} // Опциональный параметр для фильтрации
//   ) async {
//     try {
//       print('Getting boiler parameter values for boiler $boilerId from $start to $end');
//       if (parameterIds != null) {
//         print('Filtering by parameter IDs: $parameterIds');
//       }

//       Map<String, String> queryParams = {
//         'Start': start.toIso8601String(),
//         'End': end.toIso8601String(),
//       };

//       // Добавляем фильтр по параметрам, если он указан
//       if (parameterIds != null && parameterIds.isNotEmpty) {
//         // Преобразуем список ID в строку для query параметра
//         queryParams['ParameterIds'] = parameterIds.join(',');
//       }

//       final uri = Uri.parse('$baseUrl/BoilerParameters/$boilerId/Values').replace(
//         queryParameters: queryParams,
//       );

//       final response = await http.get(
//         uri,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       print('Response status code: ${response.statusCode}');
//       print('Response body length: ${response.body.length}');

//       switch (response.statusCode) {
//         case 200:
//           final List<dynamic> data = json.decode(response.body);
//           print('Decoded ${data.length} parameter values');
//           final values = data.map((json) => BoilerParameterValue.fromJson(json)).toList();
//           print('Created ${values.length} BoilerParameterValue objects');
//           return values;
//         case 401:
//           throw Exception('Некорректный токен авторизации');
//         case 404:
//           throw Exception('Котельная не найдена');
//         default:
//           throw Exception('Ошибка сервера: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getBoilerParameterValues: $e');
//       throw Exception('Ошибка при получении значений параметров: $e');
//     }
//   }


//   // ========== МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ ПОЛЬЗОВАТЕЛЯМИ ==========

//   // Получение всех пользователей
//   Future<List<UserManagement>> getAllUsers(String token) async {
//     try {
//       print('Getting all users with token: $token');
//       final response = await http.get(
//         Uri.parse('$baseUrl/Users'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       print('Response status code: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       switch (response.statusCode) {
//         case 200:
//           final List<dynamic> data = json.decode(response.body);
//           return data.map((json) => UserManagement.fromJson(json)).toList();
//         case 401:
//           throw Exception('Некорректный токен авторизации');
//         case 403:
//           throw Exception('Недостаточно прав для просмотра пользователей');
//         default:
//           throw Exception('Ошибка сервера: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getAllUsers: $e');
//       throw Exception('Ошибка при получении списка пользователей: $e');
//     }
//   }

//   // Получение конкретного пользователя по ID
//   Future<UserManagement> getUserById(String token, int userId) async {
//     try {
//       print('Getting user $userId with token: $token');
//       final response = await http.get(
//         Uri.parse('$baseUrl/Users/$userId'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       print('Response status code: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       switch (response.statusCode) {
//         case 200:
//           final data = json.decode(response.body);
//           return UserManagement.fromJson(data);
//         case 401:
//           throw Exception('Некорректный токен авторизации');
//         case 403:
//           throw Exception('Недостаточно прав для просмотра пользователя');
//         case 404:
//           throw Exception('Пользователь не найден');
//         default:
//           throw Exception('Ошибка сервера: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getUserById: $e');
//       throw Exception('Ошибка при получении пользователя: $e');
//     }
//   }

//   // Создание нового пользователя
//   Future<UserManagement> createUser(String token, CreateUserRequest request) async {
//     try {
//       print('Creating user with token: $token');
//       print('Request data: ${request.toJson()}');

//       final response = await http.post(
//         Uri.parse('$baseUrl/Users'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(request.toJson()),
//       );

//       print('Response status code: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       switch (response.statusCode) {
//         case 200:
//         case 201:
//           final data = json.decode(response.body);
//           return UserManagement.fromJson(data);
//         case 400:
//           throw Exception('Некорректные данные пользователя');
//         case 401:
//           throw Exception('Некорректный токен авторизации');
//         case 403:
//           throw Exception('Недостаточно прав для создания пользователя');
//         case 409:
//           throw Exception('Пользователь с таким логином уже существует');
//         default:
//           throw Exception('Ошибка сервера: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in createUser: $e');
//       throw Exception('Ошибка при создании пользователя: $e');
//     }
//   }

//   // Обновление пользователя
//   Future<UserManagement> updateUser(String token, int userId, UpdateUserRequest request) async {
//     try {
//       print('Updating user $userId with token: $token');
//       print('Request data: ${request.toJson()}');

//       final response = await http.put(
//         Uri.parse('$baseUrl/Users/$userId'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(request.toJson()),
//       );

//       print('Response status code: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       switch (response.statusCode) {
//         case 200:
//           final data = json.decode(response.body);
//           return UserManagement.fromJson(data);
//         case 400:
//           throw Exception('Некорректные данные пользователя');
//         case 401:
//           throw Exception('Некорректный токен авторизации');
//         case 403:
//           throw Exception('Недостаточно прав для редактирования пользователя');
//         case 404:
//           throw Exception('Пользователь не найден');
//         case 409:
//           throw Exception('Пользователь с таким логином уже существует');
//         default:
//           throw Exception('Ошибка сервера: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in updateUser: $e');
//       throw Exception('Ошибка при обновлении пользователя: $e');
//     }
//   }

//   // Удаление пользователя
//   Future<void> deleteUser(String token, int userId) async {
//     try {
//       print('Deleting user $userId with token: $token');

//       final response = await http.delete(
//         Uri.parse('$baseUrl/Users/$userId'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       print('Response status code: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       switch (response.statusCode) {
//         case 200:
//         case 204:
//           return; // Успешное удаление
//         case 401:
//           throw Exception('Некорректный токен авторизации');
//         case 403:
//           throw Exception('Недостаточно прав для удаления пользователя');
//         case 404:
//           throw Exception('Пользователь не найден');
//         case 409:
//           throw Exception('Невозможно удалить пользователя (возможно, есть связанные данные)');
//         default:
//           throw Exception('Ошибка сервера: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in deleteUser: $e');
//       throw Exception('Ошибка при удалении пользователя: $e');
//     }
//   }

//   // Изменение пароля текущего пользователя
//   Future<void> changeMyPassword(String token, ChangePasswordRequest request) async {
//     try {
//       print('Changing password for current user with token: $token');

//       final response = await http.put(
//         Uri.parse('$baseUrl/Users/Me/ChangePassword'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(request.toJson()),
//       );

//       print('Response status code: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       switch (response.statusCode) {
//         case 200:
//         case 204:
//           return; // Успешное изменение пароля
//         case 400:
//           throw Exception('Некорректные данные для смены пароля');
//         case 401:
//           throw Exception('Некорректный токен авторизации или неверный текущий пароль');
//         default:
//           throw Exception('Ошибка сервера: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in changeMyPassword: $e');
//       throw Exception('Ошибка при смене пароля: $e');
//     }
//   }

//   // Получение всех ролей (для выпадающих списков)
//   Future<List<Role>> getAllRoles(String token) async {
//     try {
//       print('Getting all roles with token: $token');
//       final response = await http.get(
//         Uri.parse('$baseUrl/Roles'), // Предполагаем, что есть такой эндпоинт
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       print('Response status code: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       switch (response.statusCode) {
//         case 200:
//           final List<dynamic> data = json.decode(response.body);
//           return data.map((json) => Role.fromJson(json)).toList();
//         case 401:
//           throw Exception('Некорректный токен авторизации');
//         default:
//           throw Exception('Ошибка сервера: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getAllRoles: $e');
//       throw Exception('Ошибка при получении списка ролей: $e');
//     }
//   }

// }