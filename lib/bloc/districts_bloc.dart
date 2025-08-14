import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:manage_center/models/district_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// События
abstract class DistrictsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchDistricts extends DistrictsEvent {}

class CreateDistrict extends DistrictsEvent {
  final Map<String, dynamic> districtData;

  CreateDistrict(this.districtData);

  @override
  List<Object?> get props => [districtData];
}

class UpdateDistrict extends DistrictsEvent {
  final int districtId;
  final Map<String, dynamic> districtData;

  UpdateDistrict(this.districtId, this.districtData);

  @override
  List<Object?> get props => [districtId, districtData];
}

class DeleteDistrict extends DistrictsEvent {
  final int districtId;

  DeleteDistrict(this.districtId);

  @override
  List<Object?> get props => [districtId];
}

// Состояния
abstract class DistrictsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DistrictsInitial extends DistrictsState {}

class DistrictsLoading extends DistrictsState {}

class DistrictsLoaded extends DistrictsState {
  final List<District> districts;

  DistrictsLoaded(this.districts);

  @override
  List<Object?> get props => [districts];
}

class DistrictsError extends DistrictsState {
  final String error;

  DistrictsError(this.error);

  @override
  List<Object?> get props => [error];
}

// BLoC
class DistrictsBloc extends Bloc<DistrictsEvent, DistrictsState> {
  final ApiService apiService;
  final StorageService storageService;

  DistrictsBloc({required this.apiService, required this.storageService})
      : super(DistrictsInitial()) {
    on<FetchDistricts>(_onFetchDistricts);
    on<CreateDistrict>(_onCreateDistrict);
    on<UpdateDistrict>(_onUpdateDistrict);
    on<DeleteDistrict>(_onDeleteDistrict);
  }

  Future<void> _onFetchDistricts(
      FetchDistricts event, Emitter<DistrictsState> emit) async {
    emit(DistrictsLoading());
    try {
      final token = await storageService.getToken();
      if (token == null) {
        emit(DistrictsError('Токен авторизации не найден'));
        return;
      }

      final districts = await apiService.getAllDistricts(token);
      emit(DistrictsLoaded(districts));
    } catch (e) {
      emit(DistrictsError(e.toString()));
    }
  }

  Future<void> _onCreateDistrict(
      CreateDistrict event, Emitter<DistrictsState> emit) async {
    emit(DistrictsLoading());
    try {
      final token = await storageService.getToken();
      if (token == null) {
        emit(DistrictsError('Токен авторизации не найден'));
        return;
      }

      await apiService.createDistrict(token, event.districtData['name']);
      
      // Перезагружаем список районов
      final districts = await apiService.getAllDistricts(token);
      emit(DistrictsLoaded(districts));
    } catch (e) {
      emit(DistrictsError(e.toString()));
    }
  }

  Future<void> _onUpdateDistrict(
      UpdateDistrict event, Emitter<DistrictsState> emit) async {
    emit(DistrictsLoading());
    try {
      final token = await storageService.getToken();
      if (token == null) {
        emit(DistrictsError('Токен авторизации не найден'));
        return;
      }

      await apiService.updateDistrict(
          token, event.districtId, event.districtData['name']);
      
      // Перезагружаем список районов
      final districts = await apiService.getAllDistricts(token);
      emit(DistrictsLoaded(districts));
    } catch (e) {
      emit(DistrictsError(e.toString()));
    }
  }

  Future<void> _onDeleteDistrict(
      DeleteDistrict event, Emitter<DistrictsState> emit) async {
    emit(DistrictsLoading());
    try {
      final token = await storageService.getToken();
      if (token == null) {
        emit(DistrictsError('Токен авторизации не найден'));
        return;
      }

      await apiService.deleteDistrict(token, event.districtId);
      
      // Перезагружаем список районов
      final districts = await apiService.getAllDistricts(token);
      emit(DistrictsLoaded(districts));
    } catch (e) {
      emit(DistrictsError(e.toString()));
    }
  }
}