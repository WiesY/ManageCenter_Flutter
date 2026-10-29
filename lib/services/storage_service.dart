import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manage_center/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String tokenKey = 'auth_token';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String biometricUserKey = 'biometric_user';
  static const String biometricPasswordKey = 'biometric_password';
  static const String userRoleIdKey = 'user_role_id';
  static const String userRoleNameKey = 'user_role_name';

  static const String themeModeKey = 'theme_mode';
  static const ThemeMode defaultThemeMode = ThemeMode.system;

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

  /// Токен текущей сессии. Живёт в памяти всегда, даже без «запомнить меня»:
  /// иначе запросам после входа неоткуда было бы его взять.
  String? _sessionToken;

  /// Сохраняет токен сессии. С [persist] он переживает перезапуск приложения
  /// и лежит в защищённом хранилище; без него — только в памяти.
  Future<void> saveToken(String token, {bool persist = true}) async {
    _sessionToken = token;
    if (persist) {
      await _writePersistedToken(token);
    } else {
      await _deletePersistedToken();
    }
  }

  Future<String?> getToken() async {
    return _sessionToken ??= await _readPersistedToken();
  }

  Future<void> deleteToken() async {
    _sessionToken = null;
    await _deletePersistedToken();
  }

  Future<String?> _readPersistedToken() async {
    try {
      final token = await _secureStorage.read(key: tokenKey);
      if (token != null) return token;
    } catch (e) {
      logError('Защищённое хранилище недоступно', error: e, name: 'storage');
    }

    // Старые версии хранили токен открытым текстом — переносим его один раз.
    final legacy = _prefs.getString(tokenKey);
    if (legacy != null) await _writePersistedToken(legacy);
    return legacy;
  }

  Future<void> _writePersistedToken(String token) async {
    try {
      await _secureStorage.write(key: tokenKey, value: token);
      await _prefs.remove(tokenKey);
    } catch (e) {
      // Там, где защищённого хранилища нет (десктоп без связки ключей),
      // остаёмся на прежнем поведении, чтобы вход не пропадал.
      logError('Токен сохранён без шифрования', error: e, name: 'storage');
      await _prefs.setString(tokenKey, token);
    }
  }

  Future<void> _deletePersistedToken() async {
    try {
      await _secureStorage.delete(key: tokenKey);
    } catch (e) {
      logError('Не удалось удалить токен', error: e, name: 'storage');
    }
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

  // ==================== ОФОРМЛЕНИЕ ====================

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(themeModeKey, mode.name);
  }

  /// Синхронное чтение — режим нужен ещё до первого кадра, чтобы приложение
  /// не мигнуло светлой темой при запуске.
  ThemeMode getThemeMode() {
    final stored = _prefs.getString(themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => defaultThemeMode,
    );
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
