import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String tokenKey = 'auth_token';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String biometricUserKey = 'biometric_user';
  static const String biometricPasswordKey = 'biometric_password';
  static const String userRoleIdKey = 'user_role_id';
  static const String userRoleNameKey = 'user_role_name';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // ==================== ТОКЕН ====================

  Future<void> saveToken(String token) async {
    await _prefs.setString(tokenKey, token);
  }

  Future<String?> getToken() async {
    return _prefs.getString(tokenKey);
  }

  Future<void> deleteToken() async {
    await _prefs.remove(tokenKey);
  }

  // ==================== ТИП ТОКЕНА ====================

  Future<void> saveTokenType(bool isSessionToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_session_token', isSessionToken);
  }

  Future<bool> isSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_session_token') ?? false;
  }

  // ==================== БИОМЕТРИЯ ====================

  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(biometricEnabledKey, enabled);
  }

  Future<bool> isBiometricEnabled() async {
    return _prefs.getBool(biometricEnabledKey) ?? false;
  }

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

  // ==================== РОЛЬ ПОЛЬЗОВАТЕЛЯ ====================

  Future<void> saveUserRoleId(int roleId) async {
    await _prefs.setInt(userRoleIdKey, roleId);
  }

  Future<int?> getUserRoleId() async {
    return _prefs.getInt(userRoleIdKey);
  }

  Future<void> saveUserRoleName(String roleName) async {
    await _prefs.setString(userRoleNameKey, roleName);
  }

  Future<String?> getUserRoleName() async {
    return _prefs.getString(userRoleNameKey);
  }

  Future<void> clearUserRole() async {
    await _prefs.remove(userRoleIdKey);
    await _prefs.remove(userRoleNameKey);
  }
}