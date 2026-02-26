import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:manage_center/models/user_info_model.dart';
import 'package:manage_center/services/push_notification_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

// События
abstract class AuthEvent {}

class LoginEvent extends AuthEvent {
  final String login;
  final String password;
  final bool rememberMe;
  final bool enableBiometric;

  LoginEvent({
    required this.login,
    required this.password,
    required this.rememberMe,
    this.enableBiometric = false,
  });
}

class BiometricLoginEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}

class RestoreAuthEvent extends AuthEvent {}

// Состояния
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class BiometricAuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserInfo userInfo;
  AuthSuccess(this.userInfo);
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}

class BiometricNotAvailable extends AuthState {}

class BiometricNotEnrolled extends AuthState {}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;
  final StorageService _storageService;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthBloc({
    required ApiService? apiService,
    required StorageService storageService,
  })  : _apiService = apiService!,
        _storageService = storageService,
        super(AuthInitial()) {
    // ==================== ОБЫЧНЫЙ ЛОГИН ====================
    on<LoginEvent>((event, emit) async {
      try {
        emit(AuthLoading());
        final tokenResponse = await _apiService.login(
          event.login,
          event.password,
        );

        if (event.rememberMe) {
          await _storageService.saveToken(tokenResponse.token);
        }

        if (event.enableBiometric) {
          await _storageService.saveTokenType(true);
          await _storageService.saveBiometricCredentials(
              event.login, event.password);
          await _storageService.setBiometricEnabled(true);
        } else {
          await _storageService.saveTokenType(false);
        }

        final userInfo = await _apiService.getUserInfo(tokenResponse.token);
        debugLog('userInfo = ${userInfo.name}');

        // ✅ Сохраняем роль
        if (userInfo.role != null) {
          await _storageService.saveUserRoleId(userInfo.role!.id);
          await _storageService.saveUserRoleName(userInfo.role!.name);
          debugLog(
              '💾 Роль сохранена: ${userInfo.role!.name} (ID: ${userInfo.role!.id})');
        }

        // ✅ Подписка на push-уведомления
        await _subscribeToPushTopics(userInfo);

        emit(AuthSuccess(userInfo));
      } catch (e) {
        emit(AuthFailure(e.toString().split('Exception: ')[1]));
      }
    });

    // ==================== БИОМЕТРИЧЕСКИЙ ЛОГИН ====================
    on<BiometricLoginEvent>((event, emit) async {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        emit(BiometricNotAvailable());
        return;
      }

      bool isBiometricEnabled = await _storageService.isBiometricEnabled();
      if (!isBiometricEnabled) {
        emit(AuthInitial());
        return;
      }

      emit(BiometricAuthLoading());

      try {
        bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Пожалуйста, подтвердите свою личность для входа',
        );

        if (didAuthenticate) {
          final credentials = await _storageService.getBiometricCredentials();
          final login = credentials['login'];
          final password = credentials['password'];

          if (login != null && password != null) {
            final tokenResponse = await _apiService.login(login, password);
            await _storageService.saveToken(tokenResponse.token);

            final userInfo = await _apiService.getUserInfo(tokenResponse.token);

            // ✅ Сохраняем роль
            if (userInfo.role != null) {
              await _storageService.saveUserRoleId(userInfo.role!.id);
              await _storageService.saveUserRoleName(userInfo.role!.name);
              debugLog(
                  '💾 Роль сохранена: ${userInfo.role!.name} (ID: ${userInfo.role!.id})');
            }

            // ✅ Подписка на push-уведомления
            await _subscribeToPushTopics(userInfo);

            emit(AuthSuccess(userInfo));
          } else {
            await _storageService.setBiometricEnabled(false);
            emit(AuthFailure('Учетные данные для биометрии не найдены'));
          }
        } else {
          emit(AuthFailure('Биометрическая аутентификация отменена'));
        }
      } catch (e) {
        emit(AuthFailure(
            'Ошибка биометрической аутентификации: ${e.toString()}'));
      }
    });

    // ==================== ВЫХОД ====================
    on<LogoutEvent>((event, emit) async {
      // ✅ Отписка от всех push-каналов
      await _unsubscribeFromAllTopics();

      await _storageService.deleteToken();
      await _storageService.clearBiometricCredentials();
      await _storageService.clearUserRole();
      emit(AuthInitial());
    });

    // ==================== ВОССТАНОВЛЕНИЕ СЕССИИ ====================
    on<RestoreAuthEvent>((event, emit) async {
      final token = await _storageService.getToken();
      if (token != null) {
        emit(AuthLoading());
        try {
          final userInfo = await _apiService.getUserInfo(token);

          // ✅ Сохраняем/обновляем роль
          if (userInfo.role != null) {
            await _storageService.saveUserRoleId(userInfo.role!.id);
            await _storageService.saveUserRoleName(userInfo.role!.name);
            debugLog(
                '💾 Роль обновлена: ${userInfo.role!.name} (ID: ${userInfo.role!.id})');
          }

          // ✅ Подписка на push-уведомления
          await _subscribeToPushTopics(userInfo);

          emit(AuthSuccess(userInfo));
        } catch (e) {
          await _storageService.deleteToken();
          emit(AuthFailure(e.toString()));
        }
      } else {
        emit(AuthInitial());
      }
    });
  }

  // ==================== PUSH-ПОДПИСКА ====================

  Future<void> _subscribeToPushTopics(UserInfo userInfo) async {
    if (Platform.isWindows) return;
    if (userInfo.role == null) {
      debugLog('⚠️ [PUSH] Роль не указана, подписка пропущена');
      return;
    }

    final roleId = userInfo.role!.id;
    final roleName = userInfo.role!.name;
    debugLog('🔔 [PUSH] Подписка для роли: $roleName (ID: $roleId)');

    final pushService = PushNotificationService();

    if (roleId == 1) {
      // АДМИН — только свой канал
      await pushService.subscribeToTopic('role_admin');
    } else if (roleId == 2) {
      // ДИСПЕТЧЕР — только свой канал
      await pushService.subscribeToTopic('role_dispatcher');
    } else if (roleId == 3) {
      // МАСТЕР — только свой канал
      await pushService.subscribeToTopic('role_master');
    } else {
      debugLog('⚠️ [PUSH] Неизвестная роль (ID: $roleId). Подписка пропущена.');
    }
  }

  Future<void> _unsubscribeFromAllTopics() async {
    if (Platform.isWindows) return;

    debugLog('🚪 [PUSH] Отписка от всех каналов...');
    final pushService = PushNotificationService();
    await pushService.unsubscribeFromTopic('role_admin');
    await pushService.unsubscribeFromTopic('role_dispatcher');
    await pushService.unsubscribeFromTopic('role_master');
  }

  // ==================== УТИЛИТЫ ====================

  Future<bool> isBiometricAvailable() async {
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    bool isDeviceSupported = await _localAuth.isDeviceSupported();
    return canCheckBiometrics && isDeviceSupported;
  }

  Future<bool> isBiometricEnabled() async {
    return await _storageService.isBiometricEnabled();
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }

  void debugLog(String message) {
    assert(() {
      // ignore: avoid_print
      //print(message);
      return true;
    }());
  }
}
