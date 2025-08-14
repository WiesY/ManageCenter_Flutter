import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:manage_center/models/boiler_type_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// События
abstract class BoilerTypesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchBoilerTypes extends BoilerTypesEvent {}

class CreateBoilerType extends BoilerTypesEvent {
  final Map<String, dynamic> boilerTypeData;

  CreateBoilerType(this.boilerTypeData);

  @override
  List<Object?> get props => [boilerTypeData];
}

class UpdateBoilerType extends BoilerTypesEvent {
  final int boilerTypeId;
  final Map<String, dynamic> boilerTypeData;

  UpdateBoilerType(this.boilerTypeId, this.boilerTypeData);

  @override
  List<Object?> get props => [boilerTypeId, boilerTypeData];
}

class DeleteBoilerType extends BoilerTypesEvent {
  final int boilerTypeId;

  DeleteBoilerType(this.boilerTypeId);

  @override
  List<Object?> get props => [boilerTypeId];
}

// Состояния
abstract class BoilerTypesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BoilerTypesInitial extends BoilerTypesState {}

class BoilerTypesLoading extends BoilerTypesState {}

class BoilerTypesLoaded extends BoilerTypesState {
  final List<BoilerType> boilerTypes;

  BoilerTypesLoaded(this.boilerTypes);

  @override
  List<Object?> get props => [boilerTypes];
}

class BoilerTypesError extends BoilerTypesState {
  final String error;

  BoilerTypesError(this.error);

  @override
  List<Object?> get props => [error];
}

// BLoC
class BoilerTypesBloc extends Bloc<BoilerTypesEvent, BoilerTypesState> {
  final ApiService apiService;
  final StorageService storageService;

  BoilerTypesBloc({required this.apiService, required this.storageService})
      : super(BoilerTypesInitial()) {
    on<FetchBoilerTypes>(_onFetchBoilerTypes);
    on<CreateBoilerType>(_onCreateBoilerType);
    on<UpdateBoilerType>(_onUpdateBoilerType);
    on<DeleteBoilerType>(_onDeleteBoilerType);
  }

  Future<void> _onFetchBoilerTypes(
      FetchBoilerTypes event, Emitter<BoilerTypesState> emit) async {
    emit(BoilerTypesLoading());
    try {
      final token = await storageService.getToken();
      if (token == null) {
        emit(BoilerTypesError('Токен авторизации не найден'));
        return;
      }

      final boilerTypes = await apiService.getAllBoilerTypes(token);
      emit(BoilerTypesLoaded(boilerTypes));
    } catch (e) {
      emit(BoilerTypesError(e.toString()));
    }
  }

  Future<void> _onCreateBoilerType(
      CreateBoilerType event, Emitter<BoilerTypesState> emit) async {
    emit(BoilerTypesLoading());
    try {
      final token = await storageService.getToken();
      if (token == null) {
        emit(BoilerTypesError('Токен авторизации не найден'));
        return;
      }

      await apiService.createBoilerType(token, event.boilerTypeData['name']);
      
      // Перезагружаем список типов объектов
      final boilerTypes = await apiService.getAllBoilerTypes(token);
      emit(BoilerTypesLoaded(boilerTypes));
    } catch (e) {
      emit(BoilerTypesError(e.toString()));
    }
  }

  Future<void> _onUpdateBoilerType(
      UpdateBoilerType event, Emitter<BoilerTypesState> emit) async {
    emit(BoilerTypesLoading());
    try {
      final token = await storageService.getToken();
      if (token == null) {
        emit(BoilerTypesError('Токен авторизации не найден'));
        return;
      }

      await apiService.updateBoilerType(
          token, event.boilerTypeId, event.boilerTypeData['name']);
      
      // Перезагружаем список типов объектов
      final boilerTypes = await apiService.getAllBoilerTypes(token);
      emit(BoilerTypesLoaded(boilerTypes));
    } catch (e) {
      emit(BoilerTypesError(e.toString()));
    }
  }

  Future<void> _onDeleteBoilerType(
      DeleteBoilerType event, Emitter<BoilerTypesState> emit) async {
    emit(BoilerTypesLoading());
    try {
      final token = await storageService.getToken();
      if (token == null) {
        emit(BoilerTypesError('Токен авторизации не найден'));
        return;
      }

      await apiService.deleteBoilerType(token, event.boilerTypeId);
      
      // Перезагружаем список типов объектов
      final boilerTypes = await apiService.getAllBoilerTypes(token);
      emit(BoilerTypesLoaded(boilerTypes));
    } catch (e) {
      emit(BoilerTypesError(e.toString()));
    }
  }
}