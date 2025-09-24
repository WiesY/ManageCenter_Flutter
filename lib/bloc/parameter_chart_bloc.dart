// parameter_chart_bloc.dart (обновленный)
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// События
abstract class ParameterChartEvent {}

class LoadParameterValues extends ParameterChartEvent {
  final int boilerId;
  final int parameterId;
  final DateTime startDate;
  final DateTime endDate;
  final int interval;

  LoadParameterValues({
    required this.boilerId,
    required this.parameterId,
    required this.startDate,
    required this.endDate,
    required this.interval,
  });
}

// Состояния
abstract class ParameterChartState {}

class ParameterChartInitial extends ParameterChartState {}

class ParameterChartLoadInProgress extends ParameterChartState {}

class ParameterChartLoaded extends ParameterChartState {
  final List<BoilerParameterValue> values;
  final DateTime startDate;
  final DateTime endDate;
  final BoilerParameter parameter;

  ParameterChartLoaded({
    required this.values,
    required this.startDate,
    required this.endDate,
    required this.parameter,
  });
}

class ParameterChartLoadFailure extends ParameterChartState {
  final String error;

  ParameterChartLoadFailure({required this.error});
}

// Блок
class ParameterChartBloc extends Bloc<ParameterChartEvent, ParameterChartState> {
  final ApiService _apiService;
  final StorageService _storageService;

  ParameterChartBloc({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
       _storageService = storageService,
       super(ParameterChartInitial()) {
    on<LoadParameterValues>(_onLoadParameterValues);
  }

  Future<void> _onLoadParameterValues(
    LoadParameterValues event,
    Emitter<ParameterChartState> emit,
  ) async {
    emit(ParameterChartLoadInProgress());

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('Токен не найден. Авторизуйтесь.');
      }

      final values = await _apiService.getParameterHistoryValues(
        token,
        event.boilerId,
        event.parameterId,
        event.startDate,
        event.endDate,
        event.interval,
      );

      // Получаем информацию о параметре из первого значения (если есть)
      final parameter = values.isNotEmpty 
          ? values.first.parameter 
          : BoilerParameter(id: event.parameterId, name: '', valueType: '');

      emit(ParameterChartLoaded(
        values: values,
        startDate: event.startDate,
        endDate: event.endDate,
        parameter: parameter,
      ));
    } catch (e) {
      print('Error loading parameter values: $e');
      emit(ParameterChartLoadFailure(error: e.toString()));
    }
  }
}