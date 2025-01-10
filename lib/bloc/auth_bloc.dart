import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

// События
abstract class AuthEvent {}

class LoginEvent extends AuthEvent {
  final String login;
  final String password;
  final bool rememberMe;

  LoginEvent({
    required this.login,
    required this.password,
    required this.rememberMe,
  });
}

class LogoutEvent extends AuthEvent {}

// Состояния
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {}
class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthBloc({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
       _storageService = storageService,
       super(AuthInitial()) {
    
    on<LoginEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await _apiService.login(
          event.login,
          event.password,
        );
        
        if (event.rememberMe) {
          await _storageService.saveToken(response.token);
        }
        
        emit(AuthSuccess());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<LogoutEvent>((event, emit) async {
      await _storageService.deleteToken();
      emit(AuthInitial());
    });
  }
}