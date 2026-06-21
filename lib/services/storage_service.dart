import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String tokenKey = 'auth_token';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String biometricUserKey = 'biometric_user';
  static const String biometricPasswordKey = 'biometric_password';
  static const String userRoleIdKey = 'user_role_id';
  static const String userRoleNameKey = 'user_role_name';

  static const String alarmSoundEnabledKey = 'alarm_sound_enabled';
  static const bool defaultAlarmSoundEnabled = true;

  static const String alarmVolumeKey = 'alarm_volume';
  static const String alarmSoundKey = 'alarm_sound';

  static const double defaultAlarmVolume = 0.5;
  static const String defaultAlarmSound = 'sounds/alarm.wav';

  final SharedPreferences _prefs;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

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
    await _secureStorage.write(key: biometricUserKey, value: login);
    await _secureStorage.write(key: biometricPasswordKey, value: password);
  }

  Future<Map<String, String?>> getBiometricCredentials() async {
    return {
      'login': await _secureStorage.read(key: biometricUserKey),
      'password': await _secureStorage.read(key: biometricPasswordKey),
    };
  }

  Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: biometricUserKey);
    await _secureStorage.delete(key: biometricPasswordKey);
    await _prefs.remove(biometricEnabledKey);
    // Чистим возможные старые креды из незащищённого хранилища
    await _prefs.remove(biometricUserKey);
    await _prefs.remove(biometricPasswordKey);
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

  // ==== НАСТРОЙКИ УВЕДОМЛЕНИЙ ====

  Future<void> setAlarmVolume(double volume) async {
    await _prefs.setDouble(alarmVolumeKey, volume);
  }

  Future<double> getAlarmVolume() async {
    return _prefs.getDouble(alarmVolumeKey) ?? defaultAlarmVolume;
  }

  Future<void> setAlarmSound(String assetPath) async {
    await _prefs.setString(alarmSoundKey, assetPath);
  }

  Future<String> getAlarmSound() async {
    return _prefs.getString(alarmSoundKey) ?? defaultAlarmSound;
  }

  Future<void> setAlarmSoundEnabled(bool enabled) async {
    await _prefs.setBool(alarmSoundEnabledKey, enabled);
  }

  Future<bool> isAlarmSoundEnabled() async {
    return _prefs.getBool(alarmSoundEnabledKey) ?? defaultAlarmSoundEnabled;
  }
}
