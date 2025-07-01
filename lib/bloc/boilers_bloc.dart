import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/models/boiler_list_item_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// --- СОБЫТИЯ ---
abstract class BoilersEvent {}

// Единственное событие - запросить загрузку
class FetchBoilers extends BoilersEvent {}


// --- СОСТОЯНИЯ ---
abstract class BoilersState {}

class BoilersInitial extends BoilersState {} // Начальное состояние
class BoilersLoadInProgress extends BoilersState {} // Идет загрузка
class BoilersLoadSuccess extends BoilersState { // Успех
  final List<BoilerListItem> boilers;
  BoilersLoadSuccess(this.boilers);
}
class BoilersLoadFailure extends BoilersState { // Ошибка
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
  }) : _apiService = apiService,
       _storageService = storageService,
       super(BoilersInitial()) {
    
    on<FetchBoilers>(_onFetchBoilers);
  }

  Future<void> _onFetchBoilers(FetchBoilers event, Emitter<BoilersState> emit) async {
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
}