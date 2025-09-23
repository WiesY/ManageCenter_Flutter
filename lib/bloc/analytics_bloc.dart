// analytics_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:manage_center/models/BoilerTypeCompareValues.dart';
import 'package:manage_center/models/boiler_list_item_model.dart';
import 'package:manage_center/models/boiler_type_model.dart';
import 'package:manage_center/models/boiler_configuration.dart';
import 'package:manage_center/models/groups_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// События
abstract class AnalyticsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AnalyticsInitEvent extends AnalyticsEvent {}

class AnalyticsSelectBoilerTypeEvent extends AnalyticsEvent {
  final int boilerTypeId;
  
  AnalyticsSelectBoilerTypeEvent(this.boilerTypeId);
  
  @override
  List<Object?> get props => [boilerTypeId];
}

class AnalyticsSelectBoilerEvent extends AnalyticsEvent {
  final int boilerId;
  
  AnalyticsSelectBoilerEvent(this.boilerId);
  
  @override
  List<Object?> get props => [boilerId];
}

class AnalyticsSelectParameterGroupEvent extends AnalyticsEvent {
  final int? groupId;
  
  AnalyticsSelectParameterGroupEvent(this.groupId);
  
  @override
  List<Object?> get props => [groupId];
}

class AnalyticsSelectDateEvent extends AnalyticsEvent {
  final DateTime date;
  
  AnalyticsSelectDateEvent(this.date);
  
  @override
  List<Object?> get props => [date];
}

class AnalyticsLoadDataEvent extends AnalyticsEvent {}

// Состояния
abstract class AnalyticsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AnalyticsInitialState extends AnalyticsState {}

class AnalyticsLoadingState extends AnalyticsState {}

class AnalyticsLoadedState extends AnalyticsState {
  final List<BoilerType> boilerTypes;
  final List<BoilerListItem> boilers;
  final List<Group> parameterGroups;
  final List<BoilerTypeCompareValues>? compareValues;
  final int? selectedBoilerTypeId;
  final int? selectedBoilerId;
  final int? selectedGroupId;
  final DateTime selectedDate;
  
  AnalyticsLoadedState({
    required this.boilerTypes,
    required this.boilers,
    required this.parameterGroups,
    this.compareValues,
    this.selectedBoilerTypeId,
    this.selectedBoilerId,
    this.selectedGroupId,
    required this.selectedDate,
  });
  
  @override
  List<Object?> get props => [
    boilerTypes, 
    boilers,
    parameterGroups, 
    compareValues, 
    selectedBoilerTypeId,
    selectedBoilerId,
    selectedGroupId, 
    selectedDate
  ];
  
  AnalyticsLoadedState copyWith({
    List<BoilerType>? boilerTypes,
    List<BoilerListItem>? boilers,
    List<Group>? parameterGroups,
    List<BoilerTypeCompareValues>? compareValues,
    int? selectedBoilerTypeId,
    int? selectedBoilerId,
    int? selectedGroupId,
    DateTime? selectedDate,
  }) {
    return AnalyticsLoadedState(
      boilerTypes: boilerTypes ?? this.boilerTypes,
      boilers: boilers ?? this.boilers,
      parameterGroups: parameterGroups ?? this.parameterGroups,
      compareValues: compareValues ?? this.compareValues,
      selectedBoilerTypeId: selectedBoilerTypeId ?? this.selectedBoilerTypeId,
      selectedBoilerId: selectedBoilerId ?? this.selectedBoilerId,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class AnalyticsErrorState extends AnalyticsState {
  final String message;
  
  AnalyticsErrorState(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Блок
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final ApiService _apiService;
  final StorageService _storageService;
  
  AnalyticsBloc({
    required ApiService apiService,
    required StorageService storageService,
  }) : 
    _apiService = apiService,
    _storageService = storageService,
    super(AnalyticsInitialState()) {
    on<AnalyticsInitEvent>(_onInit);
    on<AnalyticsSelectBoilerTypeEvent>(_onSelectBoilerType);
    on<AnalyticsSelectBoilerEvent>(_onSelectBoiler);
    on<AnalyticsSelectParameterGroupEvent>(_onSelectParameterGroup);
    on<AnalyticsSelectDateEvent>(_onSelectDate);
    on<AnalyticsLoadDataEvent>(_onLoadData);
  }
  
  Future<void> _onInit(AnalyticsInitEvent event, Emitter<AnalyticsState> emit) async {
    emit(AnalyticsLoadingState());
    
    try {
      final token = await _storageService.getToken();
      
      // Получаем список типов объектов
      final boilerTypes = await _apiService.getAllBoilerTypes(token ?? '');
      
      // Получаем список объектов
      final boilers = await _apiService.getBoilers(token ?? '');
      
      // Создаем начальное состояние с пустым списком групп параметров
      emit(AnalyticsLoadedState(
        boilerTypes: boilerTypes,
        boilers: boilers,
        parameterGroups: [],
        selectedDate: DateTime.now(),
      ));
    } catch (e) {
      emit(AnalyticsErrorState('Ошибка при загрузке данных: $e'));
    }
  }
  
  Future<void> _onSelectBoilerType(AnalyticsSelectBoilerTypeEvent event, Emitter<AnalyticsState> emit) async {
    if (state is AnalyticsLoadedState) {
      final currentState = state as AnalyticsLoadedState;
      
      emit(AnalyticsLoadingState());
      
      try {
        final token = await _storageService.getToken();
        
        // Фильтруем объекты по выбранному типу
        final filteredBoilers = currentState.boilers
            .where((boiler) => boiler.boilerType.id == event.boilerTypeId)
            .toList();
        
        // Если есть объекты выбранного типа, выбираем первый
        int? selectedBoilerId;
       if (filteredBoilers.isNotEmpty) {
    selectedBoilerId = filteredBoilers.first.id;
    
    // Получаем параметры для выбранного объекта
    final boilerConfig = await _apiService.getBoilerParameters(token ?? '', selectedBoilerId);
    
    // Обновляем состояние с новым выбранным типом объекта, объектом и группами параметров
    emit(currentState.copyWith(
        selectedBoilerTypeId: event.boilerTypeId,
        selectedBoilerId: selectedBoilerId,
        parameterGroups: boilerConfig.groups,
        selectedGroupId: null, // Сбрасываем выбранную группу
        compareValues: null, // Сбрасываем данные таблицы
    ));
} else {
    // Если нет объектов выбранного типа
    emit(currentState.copyWith(
        selectedBoilerTypeId: event.boilerTypeId,
        selectedBoilerId: null,
        parameterGroups: [],
        selectedGroupId: null,
        compareValues: null,
    ));
}
      } catch (e) {
        emit(AnalyticsErrorState('Ошибка при загрузке параметров: $e'));
      }
    }
  }
  
  Future<void> _onSelectBoiler(AnalyticsSelectBoilerEvent event, Emitter<AnalyticsState> emit) async {
    if (state is AnalyticsLoadedState) {
      final currentState = state as AnalyticsLoadedState;
      
      emit(AnalyticsLoadingState());
      
      try {
        final token = await _storageService.getToken();
        
        // Получаем параметры для выбранного объекта
        final boilerConfig = await _apiService.getBoilerParameters(token ?? '', event.boilerId);
        
        // Обновляем состояние с новым выбранным объектом и группами параметров
        emit(currentState.copyWith(
          selectedBoilerId: event.boilerId,
          parameterGroups: boilerConfig.groups,
          selectedGroupId: null, // Сбрасываем выбранную группу
          compareValues: null, // Сбрасываем данные таблицы
        ));
      } catch (e) {
        emit(AnalyticsErrorState('Ошибка при загрузке параметров: $e'));
      }
    }
  }
  
  Future<void> _onSelectParameterGroup(AnalyticsSelectParameterGroupEvent event, Emitter<AnalyticsState> emit) async {
    if (state is AnalyticsLoadedState) {
      final currentState = state as AnalyticsLoadedState;
      
      // Обновляем состояние с новой выбранной группой параметров
      emit(currentState.copyWith(
        selectedGroupId: event.groupId,
        compareValues: null, // Сбрасываем данные таблицы
      ));
      
      // Если выбраны и тип объекта, и группа параметров, загружаем данные
      if (currentState.selectedBoilerTypeId != null && currentState.selectedBoilerId != null) {
        add(AnalyticsLoadDataEvent());
      }
    }
  }
  
  Future<void> _onSelectDate(AnalyticsSelectDateEvent event, Emitter<AnalyticsState> emit) async {
    if (state is AnalyticsLoadedState) {
      final currentState = state as AnalyticsLoadedState;
      
      // Обновляем состояние с новой выбранной датой
      emit(currentState.copyWith(
        selectedDate: event.date.toUtc(),
        compareValues: null, // Сбрасываем данные таблицы
      ));
      
      // Если выбраны и тип объекта, и группа параметров, загружаем данные
      if (currentState.selectedBoilerTypeId != null && currentState.selectedBoilerId != null) {
        add(AnalyticsLoadDataEvent());
      }
    }
  }
  
  Future<void> _onLoadData(AnalyticsLoadDataEvent event, Emitter<AnalyticsState> emit) async {
    if (state is AnalyticsLoadedState) {
      final currentState = state as AnalyticsLoadedState;
      
      // Проверяем, что выбран тип объекта и объект
      if (currentState.selectedBoilerTypeId == null || currentState.selectedBoilerId == null) {
        return;
      }
      
      emit(AnalyticsLoadingState());
      
      try {
        final token = await _storageService.getToken();
        final compareDateTime = currentState.selectedDate.toUtc().toIso8601String();
        
        // Формируем список ID групп параметров, если выбрана конкретная группа
        List<int>? groupIds;
        if (currentState.selectedGroupId != null) {
          groupIds = [currentState.selectedGroupId!];
        }
        
        // Получаем данные для таблицы
        final compareValues = await _apiService.getBoilerParametersByTypeCompareValues(
          token ?? '',
          currentState.selectedBoilerTypeId!,
          groupIds,
          compareDateTime,
        );
        
        // Обновляем состояние с полученными данными
        emit(currentState.copyWith(
          compareValues: compareValues,
        ));
      } catch (e) {
        emit(AnalyticsErrorState('Ошибка при загрузке данных: $e'));
      }
    }
  }
}