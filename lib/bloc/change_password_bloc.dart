import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// События
abstract class ChangePasswordEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChangePasswordRequested extends ChangePasswordEvent {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class ResetChangePasswordState extends ChangePasswordEvent {}

// Состояния
abstract class ChangePasswordState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChangePasswordInitial extends ChangePasswordState {}

class ChangePasswordLoading extends ChangePasswordState {}

class ChangePasswordSuccess extends ChangePasswordState {}

class ChangePasswordError extends ChangePasswordState {
  final String error;

  ChangePasswordError(this.error);

  @override
  List<Object?> get props => [error];
}

// BLoC
class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final ApiService apiService;
  final StorageService storageService;

  ChangePasswordBloc({
    required this.apiService,
    required this.storageService,
  }) : super(ChangePasswordInitial()) {
    on<ChangePasswordRequested>(_onChangePasswordRequested);
    on<ResetChangePasswordState>(_onResetChangePasswordState);
  }

  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(ChangePasswordLoading());
    try {
      final token = await storageService.getToken();
      if (token == null) {
        emit(ChangePasswordError('Токен авторизации не найден'));
        return;
      }

      await apiService.changePassword(
        token,
        event.currentPassword,
        event.newPassword,
      );

      emit(ChangePasswordSuccess());
    } catch (e) {
      String errorMessage = 'Произошла ошибка при смене пароля';
      
      if (e.toString().contains('Current password is incorrect')) {
        errorMessage = 'Неверный текущий пароль';
      } else if (e.toString().contains('Invalid password data')) {
        errorMessage = 'Некорректные данные пароля';
      } else if (e.toString().contains('Unauthorized')) {
        errorMessage = 'Неверный текущий пароль';
      }

      emit(ChangePasswordError(errorMessage));
    }
  }

  void _onResetChangePasswordState(
    ResetChangePasswordState event,
    Emitter<ChangePasswordState> emit,
  ) {
    emit(ChangePasswordInitial());
  }
}