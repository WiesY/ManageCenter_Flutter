import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/role_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

// События
abstract class RolesEvent {}
class FetchRoles extends RolesEvent {}
class CreateRole extends RolesEvent { final Map<String, dynamic> roleData; CreateRole(this.roleData); }
class UpdateRole extends RolesEvent { final int roleId; final Map<String, dynamic> roleData; UpdateRole(this.roleId, this.roleData); }
class DeleteRole extends RolesEvent { final int roleId; DeleteRole(this.roleId); }

// Состояния
abstract class RolesState {}
class RolesInitial extends RolesState {}
class RolesLoading extends RolesState {}
class RolesLoaded extends RolesState { final List<Role> roles; RolesLoaded(this.roles); }
class RolesError extends RolesState { final String error; RolesError(this.error); }

// Bloc
class RolesBloc extends Bloc<RolesEvent, RolesState> {
  final ApiService _apiService;
  final StorageService _storageService;

  RolesBloc({required ApiService apiService, required StorageService storageService})
      : _apiService = apiService, _storageService = storageService, super(RolesInitial()) {
    
    on<FetchRoles>(_onFetchRoles);
    on<CreateRole>(_onCreateRole);
    on<UpdateRole>(_onUpdateRole);
    on<DeleteRole>(_onDeleteRole);
  }

  Future<void> _onFetchRoles(FetchRoles event, Emitter<RolesState> emit) async {
    emit(RolesLoading());
    try {
      final token = await _storageService.getToken();
      print('token = $token');
      if (token == null) throw Exception('No token');
      final roles = await _apiService.getRoles(token);
      emit(RolesLoaded(roles));
    } catch (e) {
      emit(RolesError(e.toString()));
    }
  }

  Future<void> _onCreateRole(CreateRole event, Emitter<RolesState> emit) async {
    emit(RolesLoading());
    try {
      final token = await _storageService.getToken();
      await _apiService.createRole(token!, event.roleData);
      add(FetchRoles()); // Refresh
    } catch (e) {
      emit(RolesError(e.toString()));
    }
  }

  // Аналогично для _onUpdateRole и _onDeleteRole (вызов api, emit, refresh)
  Future<void> _onUpdateRole(UpdateRole event, Emitter<RolesState> emit) async {
    emit(RolesLoading());
    try {
      final token = await _storageService.getToken();
      await _apiService.updateRole(token!, event.roleId, event.roleData);
      add(FetchRoles());
    } catch (e) {
      emit(RolesError(e.toString()));
    }
  }

  Future<void> _onDeleteRole(DeleteRole event, Emitter<RolesState> emit) async {
    emit(RolesLoading());
    try {
      final token = await _storageService.getToken();
      await _apiService.deleteRole(token!, event.roleId);
      add(FetchRoles());
    } catch (e) {
      emit(RolesError(e.toString()));
    }
  }
}