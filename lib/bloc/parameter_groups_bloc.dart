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
  final String color;
  final String iconFileName;

  CreateParameterGroup(this.name, this.color, this.iconFileName);
}

class UpdateParameterGroup extends ParameterGroupsEvent {
  final int groupId;
  final String name;
  final String color;
  final String iconFileName;

  UpdateParameterGroup(this.groupId, this.name, this.color, this.iconFileName);
}

class DeleteParameterGroup extends ParameterGroupsEvent {
  final int groupId;

  DeleteParameterGroup(this.groupId);
}

class FetchParameterGroupIcon extends ParameterGroupsEvent {
  final int groupId;
  final bool isDownload;

  FetchParameterGroupIcon(this.groupId, {this.isDownload = false});
}

class FetchParameterGroupIconByName extends ParameterGroupsEvent {
  final String fileName;
  final bool isDownload;

  FetchParameterGroupIconByName(this.fileName, {this.isDownload = false});
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

// Новое состояние для загрузки иконок
class ParameterGroupIconLoadInProgress extends ParameterGroupsState {
  final List<ParameterGroup> parameterGroups;
  
  ParameterGroupIconLoadInProgress(this.parameterGroups);
}

class ParameterGroupIconLoadSuccess extends ParameterGroupsState {
  final String iconData;
  final int groupId;
  final List<ParameterGroup> parameterGroups;
  
  ParameterGroupIconLoadSuccess(this.iconData, this.groupId, this.parameterGroups);
}

// Блок
class ParameterGroupsBloc extends Bloc<ParameterGroupsEvent, ParameterGroupsState> {
  final ApiService _apiService;
  final StorageService _storageService;
  
  // Кэш для хранения загруженных иконок
  final Map<int, String> _iconCache = {};

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
    on<FetchParameterGroupIcon>(_onFetchParameterGroupIcon);
    on<FetchParameterGroupIconByName>(_onFetchParameterGroupIconByName);
  }
  
  // Геттер для доступа к кэшу иконок
  Map<int, String> get iconCache => _iconCache;

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
    // Сохраняем текущее состояние
    final currentState = state;
    List<ParameterGroup> currentGroups = [];
    
    if (currentState is ParameterGroupsLoadSuccess) {
      currentGroups = currentState.parameterGroups;
    }
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        emit(ParameterGroupsLoadFailure('Токен авторизации не найден'));
        return;
      }

      // Используем обновленный метод с поддержкой цвета и иконки
      await _apiService.createParameterGroup(
        token, 
        event.name, 
        event.color, 
        event.iconFileName
      );
      
      // После создания обновляем список групп
      add(FetchParameterGroups());
    } catch (e) {
      // В случае ошибки восстанавливаем предыдущее состояние
      if (currentGroups.isNotEmpty) {
        emit(ParameterGroupsLoadSuccess(currentGroups));
      } else {
        emit(ParameterGroupsLoadFailure(e.toString()));
      }
    }
  }

  Future<void> _onUpdateParameterGroup(
    UpdateParameterGroup event,
    Emitter<ParameterGroupsState> emit,
  ) async {
    // Сохраняем текущее состояние
    final currentState = state;
    List<ParameterGroup> currentGroups = [];
    
    if (currentState is ParameterGroupsLoadSuccess) {
      currentGroups = currentState.parameterGroups;
    }
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        emit(ParameterGroupsLoadFailure('Токен авторизации не найден'));
        return;
      }

      // Используем обновленный метод с поддержкой цвета и иконки
      await _apiService.updateParameterGroup(
        token, 
        event.groupId, 
        event.name, 
        event.color, 
        event.iconFileName
      );
      
      // После обновления обновляем список групп
      add(FetchParameterGroups());
    } catch (e) {
      // В случае ошибки восстанавливаем предыдущее состояние
      if (currentGroups.isNotEmpty) {
        emit(ParameterGroupsLoadSuccess(currentGroups));
      } else {
        emit(ParameterGroupsLoadFailure(e.toString()));
      }
    }
  }

  Future<void> _onDeleteParameterGroup(
    DeleteParameterGroup event,
    Emitter<ParameterGroupsState> emit,
  ) async {
    // Сохраняем текущее состояние
    final currentState = state;
    List<ParameterGroup> currentGroups = [];
    
    if (currentState is ParameterGroupsLoadSuccess) {
      currentGroups = List.from(currentState.parameterGroups);
      // Удаляем группу из локального списка для мгновенного UI-отклика
      currentGroups.removeWhere((group) => group.id == event.groupId);
      // Обновляем UI с уже удаленной группой
      emit(ParameterGroupsLoadSuccess(currentGroups));
    }
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        emit(ParameterGroupsLoadFailure('Токен авторизации не найден'));
        return;
      }

      await _apiService.deleteParameterGroup(token, event.groupId);
      
      // Удаляем иконку из кэша, если она там есть
      _iconCache.remove(event.groupId);
      
      // После удаления обновляем список групп с сервера
      add(FetchParameterGroups());
    } catch (e) {
      emit(ParameterGroupsLoadFailure(e.toString()));
    }
  }

  Future<void> _onFetchParameterGroupIcon(
    FetchParameterGroupIcon event,
    Emitter<ParameterGroupsState> emit,
  ) async {
    // Получаем текущий список групп
    List<ParameterGroup> currentGroups = [];
    if (state is ParameterGroupsLoadSuccess) {
      currentGroups = (state as ParameterGroupsLoadSuccess).parameterGroups;
    }
    
    // Проверяем, есть ли иконка в кэше
    if (_iconCache.containsKey(event.groupId) && !event.isDownload) {
      // Если иконка уже в кэше и не требуется принудительная загрузка,
      // просто эмитим успешное состояние с данными из кэша
      emit(ParameterGroupIconLoadSuccess(
        _iconCache[event.groupId]!,
        event.groupId,
        currentGroups
      ));
      return;
    }
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        // Восстанавливаем предыдущее состояние в случае ошибки
        if (currentGroups.isNotEmpty) {
          emit(ParameterGroupsLoadSuccess(currentGroups));
        } else {
          emit(ParameterGroupsLoadFailure('Токен авторизации не найден'));
        }
        return;
      }

      final iconData = await _apiService.getParameterGroupIconById(
        token, 
        event.groupId, 
        event.isDownload
      );
      
      // Сохраняем иконку в кэш
      _iconCache[event.groupId] = iconData;
      
      // Эмитим успешную загрузку иконки с сохранением списка групп
      emit(ParameterGroupIconLoadSuccess(iconData, event.groupId, currentGroups));
      
      // Восстанавливаем состояние со списком групп
      if (currentGroups.isNotEmpty) {
        emit(ParameterGroupsLoadSuccess(currentGroups));
      }
    } catch (e) {
      // Восстанавливаем предыдущее состояние в случае ошибки
      if (currentGroups.isNotEmpty) {
        emit(ParameterGroupsLoadSuccess(currentGroups));
      } else {
        emit(ParameterGroupsLoadFailure(e.toString()));
      }
    }
  }

  Future<void> _onFetchParameterGroupIconByName(
    FetchParameterGroupIconByName event,
    Emitter<ParameterGroupsState> emit,
  ) async {
    // Получаем текущий список групп
    List<ParameterGroup> currentGroups = [];
    if (state is ParameterGroupsLoadSuccess) {
      currentGroups = (state as ParameterGroupsLoadSuccess).parameterGroups;
    }
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        // Восстанавливаем предыдущее состояние в случае ошибки
        if (currentGroups.isNotEmpty) {
          emit(ParameterGroupsLoadSuccess(currentGroups));
        } else {
          emit(ParameterGroupsLoadFailure('Токен авторизации не найден'));
        }
        return;
      }

      final iconData = await _apiService.getParameterGroupIconByName(
        token, 
        event.fileName, 
        event.isDownload
      );
      
      // Находим группу с таким именем файла иконки
      int? groupId;
      for (var group in currentGroups) {
        if (group.iconFileName == event.fileName) {
          groupId = group.id;
          break;
        }
      }
      
      // Если нашли группу, сохраняем иконку в кэш
      if (groupId != null) {
        _iconCache[groupId] = iconData;
      }
      
      // Эмитим успешную загрузку иконки с сохранением списка групп
      emit(ParameterGroupIconLoadSuccess(iconData, groupId ?? -1, currentGroups));
      
      // Восстанавливаем состояние со списком групп
      if (currentGroups.isNotEmpty) {
        emit(ParameterGroupsLoadSuccess(currentGroups));
      }
    } catch (e) {
      // Восстанавливаем предыдущее состояние в случае ошибки
      if (currentGroups.isNotEmpty) {
        emit(ParameterGroupsLoadSuccess(currentGroups));
      } else {
        emit(ParameterGroupsLoadFailure(e.toString()));
      }
    }
  }
}