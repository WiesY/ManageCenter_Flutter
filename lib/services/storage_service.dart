import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String tokenKey = 'auth_token';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Future<void> saveToken(String token) async {
    await _prefs.setString(tokenKey, token);
  }

  Future<String?> getToken() async {
    return _prefs.getString(tokenKey);
  }

  Future<void> deleteToken() async {
    await _prefs.remove(tokenKey);
  }
}