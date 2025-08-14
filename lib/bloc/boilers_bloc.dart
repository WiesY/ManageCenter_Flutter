import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/models/boiler_list_item_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// --- СОБЫТИЯ ---
abstract class BoilersEvent {}

// Загрузка списка объектов
class FetchBoilers extends BoilersEvent {}

// Создание нового объекта
class CreateBoiler extends BoilersEvent {
  final Map<String, dynamic> boilerData;
  CreateBoiler(this.boilerData);
}

// Обновление объекта
class UpdateBoiler extends BoilersEvent {
  final int boilerId;
  final Map<String, dynamic> boilerData;
  UpdateBoiler(this.boilerId, this.boilerData);
}

// Удаление объекта
class DeleteBoiler extends BoilersEvent {
  final int boilerId;
  DeleteBoiler(this.boilerId);
}

// --- СОСТОЯНИЯ ---
abstract class BoilersState {}

// Начальное состояние
class BoilersInitial extends BoilersState {}

// Идет загрузка
class BoilersLoadInProgress extends BoilersState {}

// Успешная загрузка списка объектов
class BoilersLoadSuccess extends BoilersState {
  final List<BoilerListItem> boilers;
  BoilersLoadSuccess(this.boilers);
}

// Ошибка загрузки
class BoilersLoadFailure extends BoilersState {
  final String error;
  BoilersLoadFailure(this.error);
}

// --- БЛОК ---
class BoilersBloc extends Bloc<BoilersEvent, BoilersState> {
  final ApiService _apiService;
  final StorageService _storageService;

  BoilersBloc({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService,
        super(BoilersInitial()) {
    on<FetchBoilers>(_onFetchBoilers);
    on<CreateBoiler>(_onCreateBoiler);
    on<UpdateBoiler>(_onUpdateBoiler);
    on<DeleteBoiler>(_onDeleteBoiler);
  }

  // Обработчик загрузки списка объектов
  Future<void> _onFetchBoilers(
      FetchBoilers event, Emitter<BoilersState> emit) async {
    emit(BoilersLoadInProgress());
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('Токен не найден. Авторизуйтесь.');
      }

      final boilers = await _apiService.getBoilers(token);
      emit(BoilersLoadSuccess(boilers));
    } catch (e) {
      emit(BoilersLoadFailure(e.toString()));
    }
  }

  Future<void> _onCreateBoiler(
      CreateBoiler event, Emitter<BoilersState> emit) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('Токен не найден. Авторизуйтесь.');
      }

      // Вызов API для создания объекта
      await _apiService.createBoiler(token, event.boilerData);

      // После успешного создания загружаем обновленный список
      add(FetchBoilers());
    } catch (e) {
      emit(BoilersLoadFailure(e.toString()));
    }
  }

// Обработчик обновления объекта
  Future<void> _onUpdateBoiler(
      UpdateBoiler event, Emitter<BoilersState> emit) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('Токен не найден. Авторизуйтесь.');
      }

      // Вызов API для обновления объекта
      await _apiService.updateBoiler(token, event.boilerId, event.boilerData);

      // После успешного обновления загружаем обновленный список
      add(FetchBoilers());
    } catch (e) {
      emit(BoilersLoadFailure(e.toString()));
    }
  }

// Обработчик удаления объекта
  Future<void> _onDeleteBoiler(
      DeleteBoiler event, Emitter<BoilersState> emit) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('Токен не найден. Авторизуйтесь.');
      }

      // Вызов API для удаления объекта
      await _apiService.deleteBoiler(token, event.boilerId);

      // После успешного удаления загружаем обновленный список
      add(FetchBoilers());
    } catch (e) {
      emit(BoilersLoadFailure(e.toString()));
    }
  }
}
