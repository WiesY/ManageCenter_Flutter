import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences.dart';

abstract class AuthEvent {}
class LoginEvent extends AuthEvent {
  final String username;
  final String password;
  final bool rememberMe;
  LoginEvent({required this.username, required this.password, required this.rememberMe});
}
class LogoutEvent extends AuthEvent {}

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {}
class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        // Mock authentication
        await Future.delayed(const Duration(seconds: 1));
        emit(AuthSuccess());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<LogoutEvent>((event, emit) async {
      emit(AuthInitial());
    });
  }
}