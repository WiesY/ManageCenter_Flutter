import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:manage_center/models/user_info_model.dart';
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
  late ApiService _apiService;
  final StorageService _storageService;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthBloc({
    required ApiService? apiService,
    required StorageService storageService,
  })  : _apiService = apiService!,
        _storageService = storageService,
        super(AuthInitial()) {
    on<LoginEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        // Получаем токен
        final tokenResponse = await _apiService.login(
          event.login,
          event.password,
        );

        if (event.rememberMe) {
          await _storageService.saveToken(tokenResponse.token);
        }

        // Если пользователь хочет включить биометрию
        if (event.enableBiometric) {
          await _storageService.setBiometricEnabled(true);
          await _storageService.saveBiometricCredentials(
            event.login,
            event.password,
          );
        }

        // Получаем информацию о пользователе
        final userInfo = await _apiService.getUserInfo(tokenResponse.token);
        print('userInfo = ${userInfo.name}');

        emit(AuthSuccess(userInfo));
      } catch (e) {
        emit(AuthFailure(e.toString().split('Exception: ')[1]));
      }
    });

    on<BiometricLoginEvent>((event, emit) async {
      // Проверяем, доступна ли биометрия
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        emit(BiometricNotAvailable());
        return;
      }

      // Проверяем, включена ли биометрия в настройках
      bool isBiometricEnabled = await _storageService.isBiometricEnabled();
      if (!isBiometricEnabled) {
        emit(AuthInitial());
        return;
      }

      emit(BiometricAuthLoading());
      
      try {
        // Запускаем биометрическую аутентификацию
        bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Пожалуйста, подтвердите свою личность для входа',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (didAuthenticate) {
          // Получаем сохраненные учетные данные
          final credentials = await _storageService.getBiometricCredentials();
          final login = credentials['login'];
          final password = credentials['password'];

          if (login != null && password != null) {
            // Выполняем вход с сохраненными учетными данными
            final tokenResponse = await _apiService.login(login, password);
            await _storageService.saveToken(tokenResponse.token);
            
            final userInfo = await _apiService.getUserInfo(tokenResponse.token);
            emit(AuthSuccess(userInfo));
          } else {
            // Если учетные данные не найдены
            await _storageService.setBiometricEnabled(false);
            emit(AuthFailure('Учетные данные для биометрии не найдены'));
          }
        } else {
          emit(AuthFailure('Биометрическая аутентификация отменена'));
        }
      } catch (e) {
        emit(AuthFailure('Ошибка биометрической аутентификации: ${e.toString()}'));
      }
    });

    on<LogoutEvent>((event, emit) async {
      await _storageService.deleteToken();
      emit(AuthInitial());
    });

    on<RestoreAuthEvent>((event, emit) async {
      final token = await _storageService.getToken();
      if (token != null) {
        emit(AuthLoading());
        try {
          final userInfo = await _apiService.getUserInfo(token);
          emit(AuthSuccess(userInfo));
        } catch (e) {
          await _storageService.deleteToken(); // Удаляем invalid токен
          emit(AuthFailure(e.toString())); // Эмитим ошибку
        }
      } else {
        emit(AuthInitial());
      }
    });
  }

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
}