import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String tokenKey = 'auth_token';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String biometricUserKey = 'biometric_user';
  static const String biometricPasswordKey = 'biometric_password';

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
  
  // Биометрические методы
  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(biometricEnabledKey, enabled);
  }
  
  Future<bool> isBiometricEnabled() async {
    return _prefs.getBool(biometricEnabledKey) ?? false;
  }
  
  // Сохранение учетных данных для биометрии
  Future<void> saveBiometricCredentials(String login, String password) async {
    await _prefs.setString(biometricUserKey, login);
    await _prefs.setString(biometricPasswordKey, password);
  }
  
  Future<Map<String, String?>> getBiometricCredentials() async {
    return {
      'login': _prefs.getString(biometricUserKey),
      'password': _prefs.getString(biometricPasswordKey),
    };
  }
  
  Future<void> clearBiometricCredentials() async {
    await _prefs.remove(biometricUserKey);
    await _prefs.remove(biometricPasswordKey);
    await _prefs.remove(biometricEnabledKey);
  }
}