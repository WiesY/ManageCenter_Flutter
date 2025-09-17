import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/models/parameter_group_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// События
abstract class ParameterGroupsEvent {}

class FetchParameterGroups extends ParameterGroupsEvent {}

class CreateParameterGroup extends ParameterGroupsEvent {
  final String name;
  final IconData icon;
  final Color color;

  CreateParameterGroup(this.name, this.icon, this.color);
}

class UpdateParameterGroup extends ParameterGroupsEvent {
  final ParameterGroup group;

  UpdateParameterGroup(this.group);
}

class DeleteParameterGroup extends ParameterGroupsEvent {
  final int groupId;

  DeleteParameterGroup(this.groupId);
}

// Состояния
abstract class ParameterGroupsState {}

class ParameterGroupsInitial extends ParameterGroupsState {}

class ParameterGroupsLoadInProgress extends ParameterGroupsState {}

class ParameterGroupsLoadSuccess extends ParameterGroupsState {
  final List<ParameterGroup> parameterGroups;

  ParameterGroupsLoadSuccess(this.parameterGroups);
}

class ParameterGroupsLoadFailure extends ParameterGroupsState {
  final String error;

  ParameterGroupsLoadFailure(this.error);
}

// Блок
class ParameterGroupsBloc extends Bloc<ParameterGroupsEvent, ParameterGroupsState> {
  final ApiService _apiService;
  final StorageService _storageService;

  ParameterGroupsBloc({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService,
        super(ParameterGroupsInitial()) {
    on<FetchParameterGroups>(_onFetchParameterGroups);
    on<CreateParameterGroup>(_onCreateParameterGroup);
    on<UpdateParameterGroup>(_onUpdateParameterGroup);
    on<DeleteParameterGroup>(_onDeleteParameterGroup);
  }

  Future<void> _onFetchParameterGroups(
    FetchParameterGroups event,
    Emitter<ParameterGroupsState> emit,
  ) async {
    emit(ParameterGroupsLoadInProgress());
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        emit(ParameterGroupsLoadFailure('Токен авторизации не найден'));
        return;
      }

      final parameterGroups = await _apiService.getParameterGroups(token);
      emit(ParameterGroupsLoadSuccess(parameterGroups));
    } catch (e) {
      emit(ParameterGroupsLoadFailure(e.toString()));
    }
  }

  Future<void> _onCreateParameterGroup(
    CreateParameterGroup event,
    Emitter<ParameterGroupsState> emit,
  ) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        emit(ParameterGroupsLoadFailure('Токен авторизации не найден'));
        return;
      }

      await _apiService.createParameterGroup(token, event.name);
      
      // После создания обновляем список групп
      add(FetchParameterGroups());
    } catch (e) {
      emit(ParameterGroupsLoadFailure(e.toString()));
    }
  }

  Future<void> _onUpdateParameterGroup(
    UpdateParameterGroup event,
    Emitter<ParameterGroupsState> emit,
  ) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        emit(ParameterGroupsLoadFailure('Токен авторизации не найден'));
        return;
      }

      await _apiService.updateParameterGroup(token, event.group.id, event.group.name);
      
      // После обновления обновляем список групп
      add(FetchParameterGroups());
    } catch (e) {
      emit(ParameterGroupsLoadFailure(e.toString()));
    }
  }

  Future<void> _onDeleteParameterGroup(
    DeleteParameterGroup event,
    Emitter<ParameterGroupsState> emit,
  ) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        emit(ParameterGroupsLoadFailure('Токен авторизации не найден'));
        return;
      }

      await _apiService.deleteParameterGroup(token, event.groupId);
      
      // После удаления обновляем список групп
      add(FetchParameterGroups());
    } catch (e) {
      emit(ParameterGroupsLoadFailure(e.toString()));
    }
  }
}