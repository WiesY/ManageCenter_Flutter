// incidents_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:manage_center/models/incident_model.dart';
import 'package:manage_center/models/boiler_list_item_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

// События
abstract class IncidentsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class IncidentsInitEvent extends IncidentsEvent {}

class IncidentsToggleStatusEvent extends IncidentsEvent {
  final bool showActive;
  
  IncidentsToggleStatusEvent(this.showActive);
  
  @override
  List<Object?> get props => [showActive];
}

class IncidentsSelectBoilerEvent extends IncidentsEvent {
  final int? boilerId; // null = все котельные
  
  IncidentsSelectBoilerEvent(this.boilerId);
  
  @override
  List<Object?> get props => [boilerId];
}

class IncidentsSelectDateRangeEvent extends IncidentsEvent {
  final DateTime? fromDate;
  final DateTime? toDate;
  
  IncidentsSelectDateRangeEvent({this.fromDate, this.toDate});
  
  @override
  List<Object?> get props => [fromDate, toDate];
}

class IncidentsResetEvent extends IncidentsEvent {
  final int incidentId;
  
  IncidentsResetEvent(this.incidentId);
  
  @override
  List<Object?> get props => [incidentId];
}

class IncidentsRefreshEvent extends IncidentsEvent {}

// Состояния
abstract class IncidentsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class IncidentsSearchBoilerEvent extends IncidentsEvent {
  final String searchQuery;
  
  IncidentsSearchBoilerEvent(this.searchQuery);
  
  @override
  List<Object?> get props => [searchQuery];
}

class IncidentsInitialState extends IncidentsState {}

class IncidentsLoadingState extends IncidentsState {}

class IncidentsLoadedState extends IncidentsState {
  final List<IncidentModel> incidents;
  final List<BoilerListItem> boilers;
  final bool showActive;
  final int? selectedBoilerId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int activeIncidentsCount;
  final String boilerSearchQuery;
  
  IncidentsLoadedState({
    required this.incidents,
    required this.boilers,
    required this.showActive,
    this.selectedBoilerId,
    this.fromDate,
    this.toDate,
    required this.activeIncidentsCount,
    this.boilerSearchQuery = '',
  });
  
  @override
  List<Object?> get props => [
    incidents,
    boilers,
    showActive,
    selectedBoilerId,
    fromDate,
    toDate,
    activeIncidentsCount,
    boilerSearchQuery,
  ];
  
  IncidentsLoadedState copyWith({
    List<IncidentModel>? incidents,
    List<BoilerListItem>? boilers,
    bool? showActive,
    int? selectedBoilerId,
    DateTime? fromDate,
    DateTime? toDate,
    int? activeIncidentsCount,
    String? boilerSearchQuery,
    bool clearBoilerId = false,
    bool clearDateRange = false,
  }) {
    return IncidentsLoadedState(
      incidents: incidents ?? this.incidents,
      boilers: boilers ?? this.boilers,
      showActive: showActive ?? this.showActive,
      selectedBoilerId: clearBoilerId ? null : (selectedBoilerId ?? this.selectedBoilerId),
      fromDate: clearDateRange ? null : (fromDate ?? this.fromDate),
      toDate: clearDateRange ? null : (toDate ?? this.toDate),
      activeIncidentsCount: activeIncidentsCount ?? this.activeIncidentsCount,
      boilerSearchQuery: boilerSearchQuery ?? this.boilerSearchQuery,
    );
  }
}

class IncidentsErrorState extends IncidentsState {
  final String message;
  
  IncidentsErrorState(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Блок
class IncidentsBloc extends Bloc<IncidentsEvent, IncidentsState> {
  final ApiService _apiService;
  final StorageService _storageService;
  
  IncidentsBloc({
    required ApiService apiService,
    required StorageService storageService,
  }) : 
    _apiService = apiService,
    _storageService = storageService,
    super(IncidentsInitialState()) {
    on<IncidentsInitEvent>(_onInit);
    on<IncidentsToggleStatusEvent>(_onToggleStatus);
    //on<IncidentsSelectBoilerEvent>(_onSelectBoiler);
    on<IncidentsSelectDateRangeEvent>(_onSelectDateRange);
    on<IncidentsResetEvent>(_onReset);
    on<IncidentsRefreshEvent>(_onRefresh);
    on<IncidentsSearchBoilerEvent>(_onSearchBoiler);
  }
  
  Future<void> _onInit(IncidentsInitEvent event, Emitter<IncidentsState> emit) async {
    emit(IncidentsLoadingState());
    
    try {
      final token = await _storageService.getToken();
      
      // Получаем список котельных
      final boilers = await _apiService.getBoilers(token ?? '');
      
      // Получаем активные инциденты по умолчанию
      final incidents = await _apiService.getIncidents(
        token ?? '',
        onlyActive: true,
      );
      
      // Получаем количество активных инцидентов
      final activeCount = await _apiService.getActiveIncidentsCount(token ?? '');
      
      emit(IncidentsLoadedState(
        incidents: incidents,
        boilers: boilers,
        showActive: true,
        activeIncidentsCount: activeCount,
      ));
    } catch (e) {
      emit(IncidentsErrorState('Ошибка при загрузке данных: $e'));
    }
  }
  
  Future<void> _onToggleStatus(IncidentsToggleStatusEvent event, Emitter<IncidentsState> emit) async {
    if (state is IncidentsLoadedState) {
      final currentState = state as IncidentsLoadedState;
      
      emit(IncidentsLoadingState());
      
      try {
        final token = await _storageService.getToken();
        
        // Загружаем инциденты с учетом нового статуса
        final incidents = await _apiService.getIncidents(
          token ?? '',
          onlyActive: event.showActive,
          boilerId: currentState.selectedBoilerId,
          fromDate: currentState.fromDate,
          toDate: currentState.toDate,
        );
        
        emit(currentState.copyWith(
          incidents: incidents,
          showActive: event.showActive,
        ));
      } catch (e) {
        emit(IncidentsErrorState('Ошибка при загрузке инцидентов: $e'));
      }
    }
  }
  
  // Future<void> _onSelectBoiler(IncidentsSelectBoilerEvent event, Emitter<IncidentsState> emit) async {
  //   if (state is IncidentsLoadedState) {
  //     final currentState = state as IncidentsLoadedState;
      
  //     emit(IncidentsLoadingState());
      
  //     try {
  //       final token = await _storageService.getToken();
        
  //       // Загружаем инциденты для выбранной котельной
  //       final incidents = await _apiService.getIncidents(
  //         token ?? '',
  //         onlyActive: currentState.showActive,
  //         boilerId: event.boilerId,
  //         fromDate: currentState.fromDate,
  //         toDate: currentState.toDate,
  //       );
        
  //       emit(currentState.copyWith(
  //         incidents: incidents,
  //         selectedBoilerId: event.boilerId,
  //         clearBoilerId: event.boilerId == null,
  //       ));
  //     } catch (e) {
  //       emit(IncidentsErrorState('Ошибка при загрузке инцидентов: $e'));
  //     }
  //   }
  // }
  
  Future<void> _onSelectDateRange(IncidentsSelectDateRangeEvent event, Emitter<IncidentsState> emit) async {
    if (state is IncidentsLoadedState) {
      final currentState = state as IncidentsLoadedState;
      
      emit(IncidentsLoadingState());
      
      try {
        final token = await _storageService.getToken();
        
        // Загружаем инциденты с учетом диапазона дат
        final incidents = await _apiService.getIncidents(
          token ?? '',
          onlyActive: currentState.showActive,
          boilerId: currentState.selectedBoilerId,
          fromDate: event.fromDate,
          toDate: event.toDate,
        );
        
        emit(currentState.copyWith(
          incidents: incidents,
          fromDate: event.fromDate,
          toDate: event.toDate,
          clearDateRange: event.fromDate == null && event.toDate == null,
        ));
      } catch (e) {
        emit(IncidentsErrorState('Ошибка при загрузке инцидентов: $e'));
      }
    }
  }
  
  Future<void> _onReset(IncidentsResetEvent event, Emitter<IncidentsState> emit) async {
    if (state is IncidentsLoadedState) {
      final currentState = state as IncidentsLoadedState;
      
      try {
        final token = await _storageService.getToken();
        
        // Сбрасываем инцидент
        await _apiService.resetIncident(token ?? '', event.incidentId);
        
        // Перезагружаем список инцидентов
        final incidents = await _apiService.getIncidents(
          token ?? '',
          onlyActive: currentState.showActive,
          boilerId: currentState.selectedBoilerId,
          fromDate: currentState.fromDate,
          toDate: currentState.toDate,
        );
        
        // Обновляем количество активных инцидентов
        final activeCount = await _apiService.getActiveIncidentsCount(token ?? '');
        
        emit(currentState.copyWith(
          incidents: incidents,
          activeIncidentsCount: activeCount,
        ));
      } catch (e) {
        emit(IncidentsErrorState('Ошибка при сбросе инцидента: $e'));
      }
    }
  }
  
  Future<void> _onRefresh(IncidentsRefreshEvent event, Emitter<IncidentsState> emit) async {
    if (state is IncidentsLoadedState) {
      final currentState = state as IncidentsLoadedState;
      
      try {
        final token = await _storageService.getToken();
        
        // Перезагружаем список инцидентов
        final incidents = await _apiService.getIncidents(
          token ?? '',
          onlyActive: currentState.showActive,
          boilerId: currentState.selectedBoilerId,
          fromDate: currentState.fromDate,
          toDate: currentState.toDate,
        );
        
        // Обновляем количество активных инцидентов
        final activeCount = await _apiService.getActiveIncidentsCount(token ?? '');
        
        // Обновляем список котельных
        final boilers = await _apiService.getBoilers(token ?? '');
        
        emit(currentState.copyWith(
          incidents: incidents,
          boilers: boilers,
          activeIncidentsCount: activeCount,
        ));
      } catch (e) {
        emit(IncidentsErrorState('Ошибка при обновлении данных: $e'));
      }
    }
  }
  Future<void> _onSearchBoiler(IncidentsSearchBoilerEvent event, Emitter<IncidentsState> emit) async {
  if (state is IncidentsLoadedState) {
    final currentState = state as IncidentsLoadedState;
    
    // Просто обновляем поисковый запрос без загрузки данных
    emit(currentState.copyWith(
      boilerSearchQuery: event.searchQuery,
    ));
  }
}
}