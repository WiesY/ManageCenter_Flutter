import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:manage_center/models/user_info_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// События
abstract class UserProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchUserProfile extends UserProfileEvent {}

class RefreshUserProfile extends UserProfileEvent {}

// Состояния
abstract class UserProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserProfileInitial extends UserProfileState {}

class UserProfileLoading extends UserProfileState {}

class UserProfileLoaded extends UserProfileState {
  final UserInfo userInfo;

  UserProfileLoaded(this.userInfo);

  @override
  List<Object?> get props => [userInfo];
}

class UserProfileError extends UserProfileState {
  final String error;

  UserProfileError(this.error);

  @override
  List<Object?> get props => [error];
}

// BLoC
class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final ApiService apiService;
  final StorageService storageService;

  UserProfileBloc({
    required this.apiService,
    required this.storageService,
  }) : super(UserProfileInitial()) {
    on<FetchUserProfile>(_onFetchUserProfile);
    on<RefreshUserProfile>(_onRefreshUserProfile);
  }

  Future<void> _onFetchUserProfile(
    FetchUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(UserProfileLoading());
    await _loadUserProfile(emit);
  }

  Future<void> _onRefreshUserProfile(
    RefreshUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    await _loadUserProfile(emit);
  }

  Future<void> _loadUserProfile(Emitter<UserProfileState> emit) async {
    try {
      final token = await storageService.getToken();
      if (token == null) {
        emit(UserProfileError('Токен авторизации не найден'));
        return;
      }

      final userInfo = await apiService.getUserInfo(token);
      emit(UserProfileLoaded(userInfo));
    } catch (e) {
      String errorMessage = 'Произошла ошибка при загрузке данных';
      
      if (e.toString().contains('Некорректный токен авторизации')) {
        errorMessage = 'Сессия истекла. Войдите в систему заново';
      } else if (e.toString().contains('Ошибка сервера')) {
        errorMessage = 'Ошибка сервера. Попробуйте позже';
      }

      emit(UserProfileError(errorMessage));
    }
  }
}