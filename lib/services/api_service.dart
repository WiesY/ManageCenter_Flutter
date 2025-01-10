import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/token_model.dart';

class ApiService {
  static const String baseUrl = 'http://185.46.8.228:7111'; // Замените на ваш URL

  Future<TokenResponse> login(String login, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/Auth'),
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
}