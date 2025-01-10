import 'dart:convert';
import 'package:http/http.dart' as http;
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
      print(token);
      final response = await http.get(
        Uri.parse('$baseUrl/User/Me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      switch (response.statusCode) {
        case 200:
          final data = json.decode(response.body);
          return UserInfo.fromJson(data);
        case 401:
          throw Exception('Некорректный токен авторизации');
        default:
          throw Exception('Ошибка сервера');
      }
    } catch (e) {
      rethrow;
    }
  }
}
