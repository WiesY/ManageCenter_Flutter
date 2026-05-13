import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/models/boiler_list_item_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// --- СОБЫТИЯ ---
abstract class BoilersEvent {}

class FetchBoilers extends BoilersEvent {}

class CreateBoiler extends BoilersEvent {
  final Map<String, dynamic> boilerData;
  CreateBoiler(this.boilerData);
}

class UpdateBoiler extends BoilersEvent {
  final int boilerId;
  final Map<String, dynamic> boilerData;
  UpdateBoiler(this.boilerId, this.boilerData);
}

class DeleteBoiler extends BoilersEvent {
  final int boilerId;
  DeleteBoiler(this.boilerId);
}

class BoilerConnectionStatusChangedEvent extends BoilersEvent {
  final int boilerId;
  final bool hasConnection;
  BoilerConnectionStatusChangedEvent(this.boilerId, this.hasConnection);
}

class BoilerEmergencyStatusChangedEvent extends BoilersEvent {
  final int boilerId;
  final bool isEmergency;
  BoilerEmergencyStatusChangedEvent(this.boilerId, this.isEmergency);
}

class BoilerParametersUpdatedEvent extends BoilersEvent {
  final int boilerId;
  final Map<String, dynamic> newData;
  BoilerParametersUpdatedEvent(this.boilerId, this.newData);
}

// --- СОСТОЯНИЯ ---
abstract class BoilersState {}

class BoilersInitial extends BoilersState {}

class BoilersLoadInProgress extends BoilersState {}

class BoilersLoadSuccess extends BoilersState {
  final List<BoilerListItem> boilers;
  BoilersLoadSuccess(this.boilers);
}

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
    on<BoilerConnectionStatusChangedEvent>(_onConnectionStatusChanged);
    on<BoilerEmergencyStatusChangedEvent>(_onEmergencyStatusChanged);
    on<BoilerParametersUpdatedEvent>(_onBoilerParametersUpdated);
  }

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
      if (token == null) throw Exception('Токен не найден. Авторизуйтесь.');
      await _apiService.createBoiler(token, event.boilerData);
      add(FetchBoilers());
    } catch (e) {
      emit(BoilersLoadFailure(e.toString()));
    }
  }

  Future<void> _onUpdateBoiler(
      UpdateBoiler event, Emitter<BoilersState> emit) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Токен не найден. Авторизуйтесь.');
      await _apiService.updateBoiler(token, event.boilerId, event.boilerData);
      add(FetchBoilers());
    } catch (e) {
      emit(BoilersLoadFailure(e.toString()));
    }
  }

  Future<void> _onDeleteBoiler(
      DeleteBoiler event, Emitter<BoilersState> emit) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Токен не найден. Авторизуйтесь.');
      await _apiService.deleteBoiler(token, event.boilerId);
      add(FetchBoilers());
    } catch (e) {
      emit(BoilersLoadFailure(e.toString()));
    }
  }

  void _onConnectionStatusChanged(
      BoilerConnectionStatusChangedEvent event, Emitter<BoilersState> emit) {
    print(
        '[BoilersBloc] ConnectionChanged boilerId=${event.boilerId} hasConnection=${event.hasConnection}');
    final current = state;
    if (current is! BoilersLoadSuccess) {
      print('[BoilersBloc] state=${current.runtimeType} — skip connection update');
      return;
    }

    final updated = current.boilers.map((b) {
      if (b.id == event.boilerId) {
        return b.copyWith(hasConnection: event.hasConnection);
      }
      return b;
    }).toList();

    emit(BoilersLoadSuccess(updated));
  }

  void _onEmergencyStatusChanged(
      BoilerEmergencyStatusChangedEvent event, Emitter<BoilersState> emit) {
    print(
        '[BoilersBloc] EmergencyChanged boilerId=${event.boilerId} isEmergency=${event.isEmergency}');
    final current = state;
    if (current is! BoilersLoadSuccess) {
      print('[BoilersBloc] state=${current.runtimeType} — skip emergency update');
      return;
    }

    final updated = current.boilers.map((b) {
      if (b.id == event.boilerId) {
        return b.copyWith(isEmergency: event.isEmergency);
      }
      return b;
    }).toList();

    emit(BoilersLoadSuccess(updated));
  }

  void _onBoilerParametersUpdated(
    BoilerParametersUpdatedEvent event, Emitter<BoilersState> emit) {
  final current = state;
  if (current is! BoilersLoadSuccess) return;

  final updated = current.boilers.map((b) {
    if (b.id != event.boilerId) return b;
    // в зависимости от того, какие поля действительно есть в newData,
    // вытаскиваешь нужные и кладёшь через copyWith
    return b.copyWith(
      // например: temperature: (event.newData['temperature'] as num?)?.toDouble() ?? b.temperature,
      // hasConnection: event.newData['hasConnection'] as bool? ?? b.hasConnection,
      // isEmergency:   event.newData['isEmergency']   as bool? ?? b.isEmergency,
    );
  }).toList();

  emit(BoilersLoadSuccess(updated));
}
}