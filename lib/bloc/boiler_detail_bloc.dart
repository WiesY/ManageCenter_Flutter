import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/models/boiler_configuration.dart';
import 'package:manage_center/models/boiler_history_model.dart';
import 'package:manage_center/models/groups_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// --- СОБЫТИЯ ---
abstract class BoilerDetailEvent {}

// Загрузка конфигурации котельной (параметры + группы)
class LoadBoilerConfiguration extends BoilerDetailEvent {
  final int boilerId;
  LoadBoilerConfiguration(this.boilerId);
}

// Загрузка параметров котельной (устаревшее, оставлено для совместимости)
class LoadBoilerParameters extends BoilerDetailEvent {
  final int boilerId;
  LoadBoilerParameters(this.boilerId);
}

// Загрузка значений параметров за выбранный период для конкретных параметров
class LoadBoilerParameterValues extends BoilerDetailEvent {
  final int boilerId;
  final DateTime startDate;
  final DateTime endDate;
  final List<int> selectedParameterIds;
  final int interval;

  LoadBoilerParameterValues({
    required this.boilerId,
    required this.startDate,
    required this.endDate,
    required this.selectedParameterIds,
    this.interval = 60,
  });
}

// --- СОСТОЯНИЯ ---
abstract class BoilerDetailState {}

class BoilerDetailInitial extends BoilerDetailState {}

class BoilerDetailLoadInProgress extends BoilerDetailState {}

class BoilerDetailConfigurationLoaded extends BoilerDetailState {
  final List<BoilerParameter> parameters;
  final List<Group> groups;

  BoilerDetailConfigurationLoaded({
    required this.parameters,
    required this.groups,
  });
}

// Устаревшее состояние, оставлено для совместимости
class BoilerDetailParametersLoaded extends BoilerDetailState {
  final List<BoilerParameter> parameters;
  final List<Group> groups;

  BoilerDetailParametersLoaded({
    required this.parameters,
    this.groups = const [],
  });
}

class BoilerDetailValuesLoaded extends BoilerDetailState {
  final List<BoilerParameter> parameters;
  final List<Group> groups;
  final List<BoilerParameterValue> values;
  final List<int> selectedParameterIds;
  final DateTime selectedDateTime;

  BoilerDetailValuesLoaded({
    required this.parameters,
    required this.groups,
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

  // Кэшируем конфигурацию, чтобы не загружать её каждый раз
  List<BoilerParameter>? _cachedParameters;
  List<Group>? _cachedGroups;
  int? _currentBoilerId;

  BoilerDetailBloc({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
        _storageService = storageService,
        super(BoilerDetailInitial()) {

    on<LoadBoilerConfiguration>(_onLoadBoilerConfiguration);
    on<LoadBoilerParameterValues>(_onLoadBoilerParameterValues);
  }

  // В блоке нужно изменить методы:

Future<void> _onLoadBoilerConfiguration(
  LoadBoilerConfiguration event,
  Emitter<BoilerDetailState> emit,
) async {
  emit(BoilerDetailLoadInProgress());

  try {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Токен не найден. Авторизуйтесь.');
    }

    print('Loading configuration for boiler ${event.boilerId}');
    
    // Используем исправленный метод getBoilerParameters
    final configuration = await _apiService.getBoilerParameters(token, event.boilerId);

    _cachedParameters = configuration.boilerParameters;
    _cachedGroups = configuration.groups;
    _currentBoilerId = event.boilerId;

    print('Loaded ${configuration.boilerParameters.length} parameters and ${configuration.groups.length} groups');

    emit(BoilerDetailConfigurationLoaded(
      parameters: configuration.boilerParameters,
      groups: configuration.groups,
    ));
  } catch (e) {
    print('Error loading configuration: $e');
    emit(BoilerDetailLoadFailure(error: e.toString()));
  }
}

Future<void> _onLoadBoilerParameterValues(
  LoadBoilerParameterValues event,
  Emitter<BoilerDetailState> emit,
) async {
  emit(BoilerDetailLoadInProgress());

  try {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Токен не найден. Авторизуйтесь.');
    }

    // Если конфигурация не загружена, загружаем её
    if (_cachedParameters == null || _cachedGroups == null || _currentBoilerId != event.boilerId) {
      print('Loading configuration first...');
      final configuration = await _apiService.getBoilerParameters(token, event.boilerId);
      _cachedParameters = configuration.boilerParameters;
      _cachedGroups = configuration.groups;
      _currentBoilerId = event.boilerId;
    }

    print('Loading parameter values for boiler ${event.boilerId}');
    
    // Используем исправленный метод getBoilerParameterValues
    final historyResponse = await _apiService.getBoilerParameterValues(
      token,
      event.boilerId,
      event.startDate,
      event.endDate,
      event.interval,
      parameterIds: event.selectedParameterIds,
    );

    // Обновляем группы, если они пришли в ответе
    if (historyResponse.groups.isNotEmpty) {
      _cachedGroups = historyResponse.groups;
    }

    final values = historyResponse.historyNodeValues;
    print('Loaded ${values.length} parameter values from API');

    // Фильтруем значения только для выбранных параметров
    final filteredValues = values.where((value) =>
        event.selectedParameterIds.contains(value.parameter.id)
    ).toList();

    emit(BoilerDetailValuesLoaded(
      parameters: _cachedParameters!,
      groups: _cachedGroups!,
      values: filteredValues,
      selectedParameterIds: event.selectedParameterIds,
      selectedDateTime: event.startDate,
    ));
  } catch (e) {
    print('Error loading parameter values: $e');
    emit(BoilerDetailLoadFailure(error: e.toString()));
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

  // Метод для загрузки конфигурации котельной
  void loadConfiguration(int boilerId) {
    add(LoadBoilerConfiguration(boilerId));
  }

  // Метод для загрузки данных за выбранную минуту
  void loadDataForSelectedMinute(int boilerId, DateTime selectedDateTime, List<int> selectedParameterIds, {int interval = 60}) {
    final timeRange = getMinuteRange(selectedDateTime);
    add(LoadBoilerParameterValues(
      boilerId: boilerId,
      startDate: timeRange['start']!,
      endDate: timeRange['end']!,
      selectedParameterIds: selectedParameterIds,
      interval: interval,
    ));
  }

  // Метод для загрузки данных за текущую минуту
  void loadCurrentMinuteData(int boilerId, List<int> selectedParameterIds, {int interval = 60}) {
    final timeRange = getCurrentMinuteRange();
    add(LoadBoilerParameterValues(
      boilerId: boilerId,
      startDate: timeRange['start']!,
      endDate: timeRange['end']!,
      selectedParameterIds: selectedParameterIds,
      interval: interval,
    ));
  }

  // Вспомогательные методы для работы с группами
  List<BoilerParameter> getParametersByGroup(int groupId) {
    if (_cachedParameters == null) return [];
    return _cachedParameters!.where((param) => param.groupId == groupId).toList();
  }

  Group? getGroupById(int groupId) {
    if (_cachedGroups == null) return null;
    try {
      return _cachedGroups!.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  List<Group> get availableGroups => _cachedGroups ?? [];
  List<BoilerParameter> get availableParameters => _cachedParameters ?? [];
}