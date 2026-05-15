import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/models/boiler_configuration.dart';
import 'package:manage_center/models/boiler_history_model.dart';
import 'package:manage_center/models/groups_model.dart';
import 'package:manage_center/models/incident_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// --- СОБЫТИЯ ---
abstract class BoilerDetailEvent {}

class LoadBoilerConfiguration extends BoilerDetailEvent {
  final int boilerId;
  LoadBoilerConfiguration(this.boilerId);
}

class LoadBoilerParameters extends BoilerDetailEvent {
  final int boilerId;
  LoadBoilerParameters(this.boilerId);
}

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

class UpdateParametersGroup extends BoilerDetailEvent {
  final int groupId;
  final List<int> parameterIds;

  UpdateParametersGroup({
    required this.groupId,
    required this.parameterIds,
  });
}

class SignalRParametersUpdated extends BoilerDetailEvent {
  final int boilerId;
  final Map<String, dynamic> newData;
  SignalRParametersUpdated(this.boilerId, this.newData);
}

// --- СОСТОЯНИЯ ---
abstract class BoilerDetailState {}

class BoilerDetailInitial extends BoilerDetailState {}

class BoilerDetailLoadInProgress extends BoilerDetailState {}

class BoilerDetailConfigurationLoaded extends BoilerDetailState {
  final List<BoilerParameter> parameters;
  final List<Group> groups;
  final Set<int> incidentParameterIds;
  final Set<int> incidentGroupIds;

  BoilerDetailConfigurationLoaded({
    required this.parameters,
    required this.groups,
    this.incidentParameterIds = const {},
    this.incidentGroupIds = const {},
  });
}

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
  final Set<int> incidentParameterIds;
  final Set<int> incidentGroupIds;

  BoilerDetailValuesLoaded({
    required this.parameters,
    required this.groups,
    required this.values,
    required this.selectedParameterIds,
    required this.selectedDateTime,
    this.incidentParameterIds = const {},
    this.incidentGroupIds = const {},
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

  List<BoilerParameter>? _cachedParameters;
  List<Group>? _cachedGroups;
  int? _currentBoilerId;
  Set<int> _cachedIncidentParameterIds = {};
  Set<int> _cachedIncidentGroupIds = {};

  BoilerDetailBloc({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService,
        super(BoilerDetailInitial()) {
    on<LoadBoilerConfiguration>(_onLoadBoilerConfiguration);
    on<LoadBoilerParameterValues>(_onLoadBoilerParameterValues);
    on<UpdateParametersGroup>(_onUpdateParametersGroup);
    on<SignalRParametersUpdated>(_onSignalRParametersUpdated);
  }

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

      // Загружаем конфигурацию и активные инциденты параллельно
      final results = await Future.wait([
        _apiService.getBoilerParameters(token, event.boilerId),
        _apiService.getIncidents(token, onlyActive: true, boilerId: event.boilerId),
      ]);

      final configuration = results[0] as BoilerConfiguration;
      final incidents = results[1] as List<IncidentModel>;

      _cachedParameters = configuration.boilerParameters;
      _cachedGroups = configuration.groups;
      _currentBoilerId = event.boilerId;

      // Собираем id аварийных параметров и групп из инцидентов
      _cachedIncidentParameterIds = incidents.map((i) => i.parameterId).toSet();
      _cachedIncidentGroupIds = incidents
          .where((i) => i.parameter != null)
          .map((i) => i.parameter!.groupId)
          .toSet();

      print(
          'Loaded ${_cachedParameters!.length} parameters, '
          '${_cachedGroups!.length} groups, '
          '${incidents.length} active incidents');

      emit(BoilerDetailConfigurationLoaded(
        parameters: _cachedParameters!,
        groups: _cachedGroups!,
        incidentParameterIds: _cachedIncidentParameterIds,
        incidentGroupIds: _cachedIncidentGroupIds,
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

      if (_cachedParameters == null ||
          _cachedGroups == null ||
          _currentBoilerId != event.boilerId) {
        print('Loading configuration first...');
        final configuration =
            await _apiService.getBoilerParameters(token, event.boilerId);
        _cachedParameters = configuration.boilerParameters;
        _cachedGroups = configuration.groups;
        _currentBoilerId = event.boilerId;
      }

      print('Loading parameter values for boiler ${event.boilerId}');

      final historyResponse = await _apiService.getBoilerParameterValues(
        token,
        event.boilerId,
        event.startDate,
        event.endDate,
        event.interval,
        parameterIds: event.selectedParameterIds,
      );

      if (historyResponse.groups.isNotEmpty) {
        _cachedGroups = historyResponse.groups;
      }

      final values = historyResponse.historyNodeValues;
      print('Loaded ${values.length} parameter values from API');

      final filteredValues = values
          .where((value) =>
              event.selectedParameterIds.contains(value.parameter.id))
          .toList();

      emit(BoilerDetailValuesLoaded(
        parameters: _cachedParameters!,
        groups: _cachedGroups!,
        values: filteredValues,
        selectedParameterIds: event.selectedParameterIds,
        selectedDateTime: event.startDate,
        incidentParameterIds: _cachedIncidentParameterIds,
        incidentGroupIds: _cachedIncidentGroupIds,
      ));
    } catch (e) {
      print('Error loading parameter values: $e');
      emit(BoilerDetailLoadFailure(error: e.toString()));
    }
  }

  Future<void> _onUpdateParametersGroup(
    UpdateParametersGroup event,
    Emitter<BoilerDetailState> emit,
  ) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('Токен не найден. Авторизуйтесь.');
      }
      print('==== ${token}, ${event.groupId}, ${event.parameterIds}');
      await _apiService.updateParametersGroup(
          token, event.groupId, event.parameterIds);

      if (_currentBoilerId != null) {
        add(LoadBoilerConfiguration(_currentBoilerId!));
      }
    } catch (e) {
      print('Error updating parameters group: $e');
      emit(BoilerDetailLoadFailure(error: e.toString()));
    }
  }

  Future<void> _onSignalRParametersUpdated(
    SignalRParametersUpdated event,
    Emitter<BoilerDetailState> emit,
  ) async {
    if (_currentBoilerId != event.boilerId) return;
    if (_cachedParameters == null || _cachedGroups == null) return;

    try {
      final token = await _storageService.getToken();
      if (token == null) return;

      final now = DateTime.now().toUtc();
      final historyResponse = await _apiService.getBoilerParameterValues(
        token,
        event.boilerId,
        now.subtract(const Duration(minutes: 5)),
        now,
        1,
        parameterIds: _cachedParameters!.map((p) => p.id).toList(),
      );

      if (historyResponse.groups.isNotEmpty) {
        _cachedGroups = historyResponse.groups;
      }

      final values = historyResponse.historyNodeValues;
      final allParamIds = _cachedParameters!.map((p) => p.id).toList();
      final filteredValues =
          values.where((v) => allParamIds.contains(v.parameter.id)).toList();

      emit(BoilerDetailValuesLoaded(
        parameters: _cachedParameters!,
        groups: _cachedGroups!,
        values: filteredValues,
        selectedParameterIds: allParamIds,
        selectedDateTime: now,
        incidentParameterIds: _cachedIncidentParameterIds,
        incidentGroupIds: _cachedIncidentGroupIds,
      ));
    } catch (e) {
      print('[SignalR] Ошибка обновления параметров: $e');
    }
  }

  // --- Вспомогательные методы ---

  static Map<String, DateTime> getMinuteRange(DateTime selectedDateTime) {
    final startOfMinute = DateTime(
      selectedDateTime.year,
      selectedDateTime.month,
      selectedDateTime.day,
      selectedDateTime.hour,
      selectedDateTime.minute,
      0,
    );
    final endOfMinute = startOfMinute
        .add(const Duration(minutes: 1))
        .subtract(const Duration(seconds: 1));
    return {'start': startOfMinute, 'end': endOfMinute};
  }

  static Map<String, DateTime> getCurrentMinuteRange() {
    return getMinuteRange(DateTime.now());
  }

  void loadConfiguration(int boilerId) {
    add(LoadBoilerConfiguration(boilerId));
  }

  void loadDataForSelectedMinute(
      int boilerId, DateTime selectedDateTime, List<int> selectedParameterIds,
      {int interval = 60}) {
    final timeRange = getMinuteRange(selectedDateTime);
    add(LoadBoilerParameterValues(
      boilerId: boilerId,
      startDate: timeRange['start']!,
      endDate: timeRange['end']!,
      selectedParameterIds: selectedParameterIds,
      interval: interval,
    ));
  }

  void loadCurrentMinuteData(int boilerId, List<int> selectedParameterIds,
      {int interval = 60}) {
    final timeRange = getCurrentMinuteRange();
    add(LoadBoilerParameterValues(
      boilerId: boilerId,
      startDate: timeRange['start']!,
      endDate: timeRange['end']!,
      selectedParameterIds: selectedParameterIds,
      interval: interval,
    ));
  }

  void updateParametersGroup(int groupId, List<int> parameterIds) {
    add(UpdateParametersGroup(groupId: groupId, parameterIds: parameterIds));
  }

  List<BoilerParameter> getParametersByGroup(int groupId) {
    if (_cachedParameters == null) return [];
    return _cachedParameters!
        .where((param) => param.groupId == groupId)
        .toList();
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