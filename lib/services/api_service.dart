import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:manage_center/models/boiler_model.dart';
import 'package:manage_center/models/user_info_model.dart';
import '../models/token_model.dart';

class ApiService {
  static const String baseUrl =
      'http://185.46.8.228:7111/api/v1'; // Замените на ваш URL
  static const String apiV1 = '/api/v1';

  Future<TokenResponse> login(String login, String password) async {
    try {
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
        Uri.parse('$baseUrl/User/Me'),
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
              'Created UserInfo object: $userInfo'); // Логируем созданный объект
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
}
