// parameter_chart_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// ==================== СОБЫТИЯ ====================

abstract class ParameterChartEvent {}

class LoadParameterValues extends ParameterChartEvent {
  final int boilerId;
  final int parameterId;
  final DateTime startDate;
  final DateTime endDate;
  final int? interval; // null = автоподбор

  LoadParameterValues({
    required this.boilerId,
    required this.parameterId,
    required this.startDate,
    required this.endDate,
    this.interval,
  });
}

class LoadMultipleParameterValues extends ParameterChartEvent {
  final int boilerId;
  final List<int> parameterIds;
  final DateTime startDate;
  final DateTime endDate;
  final int? interval;

  LoadMultipleParameterValues({
    required this.boilerId,
    required this.parameterIds,
    required this.startDate,
    required this.endDate,
    this.interval,
  });
}

// ==================== СОСТОЯНИЯ ====================

abstract class ParameterChartState {}

class ParameterChartInitial extends ParameterChartState {}

class ParameterChartLoadInProgress extends ParameterChartState {}

class ParameterChartLoaded extends ParameterChartState {
  /// Для одного параметра — обратная совместимость
  final List<BoilerParameterValue> values;

  /// Для нескольких параметров: parameterId -> список значений
  final Map<int, List<BoilerParameterValue>> parameterValues;

  /// parameterId -> BoilerParameter
  final Map<int, BoilerParameter> parameters;

  final DateTime startDate;
  final DateTime endDate;
  final int interval;

  /// Обратная совместимость: parameter из первого параметра
  BoilerParameter get parameter =>
      parameters.values.isNotEmpty
          ? parameters.values.first
          : BoilerParameter(id: 0, name: '', valueType: '');

  ParameterChartLoaded({
    required this.values,
    required this.parameterValues,
    required this.parameters,
    required this.startDate,
    required this.endDate,
    required this.interval,
  });
}

class ParameterChartEmpty extends ParameterChartState {
  final String message;
  ParameterChartEmpty({this.message = 'Нет данных за выбранный период'});
}

class ParameterChartLoadFailure extends ParameterChartState {
  final String error;
  final bool isAuthError;

  ParameterChartLoadFailure({
    required this.error,
    this.isAuthError = false,
  });
}

// ==================== БЛОК ====================

class ParameterChartBloc
    extends Bloc<ParameterChartEvent, ParameterChartState> {
  final ApiService _apiService;
  final StorageService _storageService;

  ParameterChartBloc({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService,
        super(ParameterChartInitial()) {
    on<LoadParameterValues>(_onLoadParameterValues);
    on<LoadMultipleParameterValues>(_onLoadMultipleParameterValues);
  }

  /// Автоподбор интервала: целимся на 200–500 точек
  int _calculateOptimalInterval(DateTime start, DateTime end) {
    final totalMinutes = end.difference(start).inMinutes;
    if (totalMinutes <= 60) return 1;
    if (totalMinutes <= 360) return 5;
    if (totalMinutes <= 1440) return 15;
    if (totalMinutes <= 10080) return 60;
    if (totalMinutes <= 43200) return 240;
    return 1440;
  }

  Future<void> _onLoadParameterValues(
    LoadParameterValues event,
    Emitter<ParameterChartState> emit,
  ) async {
    emit(ParameterChartLoadInProgress());

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        emit(ParameterChartLoadFailure(
          error: 'Токен не найден. Авторизуйтесь.',
          isAuthError: true,
        ));
        return;
      }

      final interval =
          event.interval ?? _calculateOptimalInterval(event.startDate, event.endDate);

      final values = await _apiService.getParameterHistoryValues(
        token,
        event.boilerId,
        event.parameterId,
        event.startDate,
        event.endDate,
        interval,
      );

      if (values.isEmpty) {
        emit(ParameterChartEmpty());
        return;
      }

      // Убираем дубликаты по времени и сортируем
      final seen = <int>{};
      final filtered = values
          .where((v) => seen.add(v.receiptDate.millisecondsSinceEpoch))
          .toList()
        ..sort((a, b) => a.receiptDate.compareTo(b.receiptDate));

      final parameter = filtered.first.parameter;

      emit(ParameterChartLoaded(
        values: filtered,
        parameterValues: {event.parameterId: filtered},
        parameters: {event.parameterId: parameter},
        startDate: event.startDate,
        endDate: event.endDate,
        interval: interval,
      ));
    } catch (e) {
      final errorStr = e.toString();
      emit(ParameterChartLoadFailure(
        error: errorStr,
        isAuthError: errorStr.contains('401') ||
            errorStr.contains('auth') ||
            errorStr.contains('Токен'),
      ));
    }
  }

  Future<void> _onLoadMultipleParameterValues(
    LoadMultipleParameterValues event,
    Emitter<ParameterChartState> emit,
  ) async {
    emit(ParameterChartLoadInProgress());

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        emit(ParameterChartLoadFailure(
          error: 'Токен не найден. Авторизуйтесь.',
          isAuthError: true,
        ));
        return;
      }

      final interval =
          event.interval ?? _calculateOptimalInterval(event.startDate, event.endDate);

      // Параллельная загрузка
      final futures = event.parameterIds.map((paramId) =>
          _apiService.getParameterHistoryValues(
            token,
            event.boilerId,
            paramId,
            event.startDate,
            event.endDate,
            interval,
          ));

      final results = await Future.wait(futures);

      final parameterValues = <int, List<BoilerParameterValue>>{};
      final parameters = <int, BoilerParameter>{};
      final allValues = <BoilerParameterValue>[];

      for (int i = 0; i < event.parameterIds.length; i++) {
        final paramId = event.parameterIds[i];
        final values = results[i];

        final seen = <int>{};
        final filtered = values
            .where((v) => seen.add(v.receiptDate.millisecondsSinceEpoch))
            .toList()
          ..sort((a, b) => a.receiptDate.compareTo(b.receiptDate));

        parameterValues[paramId] = filtered;
        if (filtered.isNotEmpty) {
          parameters[paramId] = filtered.first.parameter;
        }
        allValues.addAll(filtered);
      }

      if (allValues.isEmpty) {
        emit(ParameterChartEmpty());
        return;
      }

      allValues.sort((a, b) => a.receiptDate.compareTo(b.receiptDate));

      emit(ParameterChartLoaded(
        values: allValues,
        parameterValues: parameterValues,
        parameters: parameters,
        startDate: event.startDate,
        endDate: event.endDate,
        interval: interval,
      ));
    } catch (e) {
      final errorStr = e.toString();
      emit(ParameterChartLoadFailure(
        error: errorStr,
        isAuthError: errorStr.contains('401') ||
            errorStr.contains('auth') ||
            errorStr.contains('Токен'),
      ));
    }
  }
}