import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// --- СОБЫТИЯ ---
abstract class BoilerDetailEvent {}

// Загрузка параметров котельной
class LoadBoilerParameters extends BoilerDetailEvent {
  final int boilerId;

  LoadBoilerParameters(this.boilerId);
}

// Загрузка значений параметров за выбранную минуту для конкретных параметров
class LoadBoilerParameterValues extends BoilerDetailEvent {
  final int boilerId;
  final DateTime startDate;
  final DateTime endDate;
  final List<int> selectedParameterIds; // Обязательный параметр - ID выбранных параметров

  LoadBoilerParameterValues({
    required this.boilerId,
    required this.startDate,
    required this.endDate,
    required this.selectedParameterIds,
  });
}

// --- СОСТОЯНИЯ ---
abstract class BoilerDetailState {}

class BoilerDetailInitial extends BoilerDetailState {}

class BoilerDetailLoadInProgress extends BoilerDetailState {}

class BoilerDetailParametersLoaded extends BoilerDetailState {
  final List<BoilerParameter> parameters;

  BoilerDetailParametersLoaded({
    required this.parameters,
  });
}

class BoilerDetailValuesLoaded extends BoilerDetailState {
  final List<BoilerParameter> parameters;
  final List<BoilerParameterValue> values;
  final List<int> selectedParameterIds;
  final DateTime selectedDateTime;

  BoilerDetailValuesLoaded({
    required this.parameters,
    required this.values,
    required this.selectedParameterIds,
    required this.selectedDateTime,
  });
}

class BoilerDetailLoadFailure extends BoilerDetailState {
  final String error;

  BoilerDetailLoadFailure({
    required this.error,
  });
}

// --- БЛОК ---
class BoilerDetailBloc extends Bloc<BoilerDetailEvent, BoilerDetailState> {
  final ApiService _apiService;
  final StorageService _storageService;

  // Кэшируем параметры, чтобы не загружать их каждый раз
  List<BoilerParameter>? _cachedParameters;
  int? _currentBoilerId;

  BoilerDetailBloc({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
        _storageService = storageService,
        super(BoilerDetailInitial()) {

    on<LoadBoilerParameters>(_onLoadBoilerParameters);
    on<LoadBoilerParameterValues>(_onLoadBoilerParameterValues);
  }

  Future<void> _onLoadBoilerParameters(
    LoadBoilerParameters event, 
    Emitter<BoilerDetailState> emit
  ) async {
    emit(BoilerDetailLoadInProgress());

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('Токен не найден. Авторизуйтесь.');
      }

      print('Loading parameters for boiler ${event.boilerId}');
      final parameters = await _apiService.getBoilerParameters(token, event.boilerId);

      _cachedParameters = parameters;
      _currentBoilerId = event.boilerId;

      print('Loaded ${parameters.length} parameters:');
      for (var param in parameters) {
        print('  - ID: ${param.id}, Name: "${param.paramDescription}", Type: ${param.valueType}');
      }

      emit(BoilerDetailParametersLoaded(
        parameters: parameters,
      ));
    } catch (e) {
      print('Error loading parameters: $e');
      emit(BoilerDetailLoadFailure(
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadBoilerParameterValues(
    LoadBoilerParameterValues event, 
    Emitter<BoilerDetailState> emit
  ) async {
    emit(BoilerDetailLoadInProgress());

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('Токен не найден. Авторизуйтесь.');
      }

      // Если параметры не загружены или это другая котельная, загружаем их
      if (_cachedParameters == null || _currentBoilerId != event.boilerId) {
        print('Loading parameters first...');
        final parameters = await _apiService.getBoilerParameters(token, event.boilerId);
        _cachedParameters = parameters;
        _currentBoilerId = event.boilerId;
      }

      print('Loading parameter values for boiler ${event.boilerId}');
      print('Selected parameter IDs: ${event.selectedParameterIds}');
      print('Time range: ${event.startDate} to ${event.endDate}');

      // Получаем названия выбранных параметров для логирования
      final selectedParameterNames = _cachedParameters!
          .where((param) => event.selectedParameterIds.contains(param.id))
          .map((param) => '"${param.paramDescription}"')
          .toList();
      print('Selected parameters: ${selectedParameterNames.join(', ')}');

      // Загружаем значения за указанный период
      final values = await _apiService.getBoilerParameterValues(
        token, 
        event.boilerId, 
        event.startDate, 
        event.endDate,
        parameterIds: event.selectedParameterIds, // Передаем выбранные параметры
      );

      print('Loaded ${values.length} parameter values from API');

      // Фильтруем значения только для выбранных параметров
      final filteredValues = values.where((value) => 
        event.selectedParameterIds.contains(value.parameter.id)
      ).toList();

      print('After filtering: ${filteredValues.length} values');

      // Логируем какие параметры получили данные
      final receivedParameterIds = filteredValues.map((v) => v.parameter.id).toSet();
      final missingParameterIds = event.selectedParameterIds.toSet().difference(receivedParameterIds);

      if (missingParameterIds.isNotEmpty) {
        print('Warning: No data received for parameter IDs: $missingParameterIds');
        final missingParameterNames = _cachedParameters!
            .where((param) => missingParameterIds.contains(param.id))
            .map((param) => '"${param.paramDescription}"')
            .toList();
        print('Missing parameters: ${missingParameterNames.join(', ')}');
      }

      // Логируем что получили
      print('Final values:');
      for (var value in filteredValues) {
        print('  - Parameter: "${value.parameter.paramDescription}" = ${value.displayValue} (${value.parameter.valueType})');
      }

      emit(BoilerDetailValuesLoaded(
        parameters: _cachedParameters!,
        values: filteredValues,
        selectedParameterIds: event.selectedParameterIds,
        selectedDateTime: event.startDate,
      ));
    } catch (e) {
      print('Error loading parameter values: $e');
      emit(BoilerDetailLoadFailure(
        error: e.toString(),
      ));
    }
  }

  // Вспомогательный метод для получения временного диапазона выбранной минуты
  static Map<String, DateTime> getMinuteRange(DateTime selectedDateTime) {
    final startOfMinute = DateTime(
      selectedDateTime.year,
      selectedDateTime.month,
      selectedDateTime.day,
      selectedDateTime.hour,
      selectedDateTime.minute,
      0, // секунды = 0
    );

    final endOfMinute = startOfMinute.add(const Duration(minutes: 1)).subtract(const Duration(seconds: 1));

    return {
      'start': startOfMinute,
      'end': endOfMinute,
    };
  }

  // Вспомогательный метод для получения временного диапазона текущей минуты
  static Map<String, DateTime> getCurrentMinuteRange() {
    final now = DateTime.now();
    return getMinuteRange(now);
  }

  // Метод для загрузки данных за выбранную минуту
  void loadDataForSelectedMinute(int boilerId, DateTime selectedDateTime, List<int> selectedParameterIds) {
    final timeRange = getMinuteRange(selectedDateTime);
    add(LoadBoilerParameterValues(
      boilerId: boilerId,
      startDate: timeRange['start']!,
      endDate: timeRange['end']!,
      selectedParameterIds: selectedParameterIds,
    ));
  }

  // Метод для загрузки данных за текущую минуту
  void loadCurrentMinuteData(int boilerId, List<int> selectedParameterIds) {
    final timeRange = getCurrentMinuteRange();
    add(LoadBoilerParameterValues(
      boilerId: boilerId,
      startDate: timeRange['start']!,
      endDate: timeRange['end']!,
      selectedParameterIds: selectedParameterIds,
    ));
  }
}