import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/models/user_info_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

// События
abstract class UsersEvent {}
class FetchUsers extends UsersEvent {}
class CreateUser extends UsersEvent { final Map<String, dynamic> userData; CreateUser(this.userData); }
class UpdateUser extends UsersEvent { final int userId; final Map<String, dynamic> userData; UpdateUser(this.userId, this.userData); }
class DeleteUser extends UsersEvent { final int userId; DeleteUser(this.userId); }

// Состояния
abstract class UsersState {}
class UsersInitial extends UsersState {}
class UsersLoading extends UsersState {}
class UsersLoaded extends UsersState { final List<UserInfo> users; UsersLoaded(this.users); }
class UsersError extends UsersState { final String error; UsersError(this.error); }

// Bloc
class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final ApiService _apiService;

  UsersBloc({required ApiService apiService, required StorageService storageService})
      : _apiService = apiService, super(UsersInitial()) {


    on<FetchUsers>(_onFetchUsers);
    on<CreateUser>(_onCreateUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
  }

  Future<void> _onFetchUsers(FetchUsers event, Emitter<UsersState> emit) async {
    emit(UsersLoading());
    try {
      final users = await _apiService.getUsers();
      emit(UsersLoaded(users));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onCreateUser(CreateUser event, Emitter<UsersState> emit) async {
    emit(UsersLoading());
    try {
      await _apiService.createUser(event.userData);
      add(FetchUsers()); // Refresh списка
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

   Future<void> _onUpdateUser(UpdateUser event, Emitter<UsersState> emit) async {
    emit(UsersLoading());
    try {
      await _apiService.updateUser(event.userId, event.userData);
    add(FetchUsers());
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

Future<void> _onDeleteUser(DeleteUser event, Emitter<UsersState> emit) async {
  try {
    await _apiService.deleteUser(event.userId);


    // Небольшая задержка перед обновлением списка
    await Future.delayed(const Duration(milliseconds: 500));
    add(FetchUsers());
    
  } catch (e) {
    print('Error deleting user: $e');
    emit(UsersError('Ошибка при удалении пользователя: $e'));
  }
}
}