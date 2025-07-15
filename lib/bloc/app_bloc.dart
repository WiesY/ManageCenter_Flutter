import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/services/storage_service.dart';

// --- СОБЫТИЯ ---
abstract class AppEvent {}

// Событие, которое вызывается при старте приложения
class AppStarted extends AppEvent {}

// Событие, которое будет вызываться при изменении состояния аутентификации
class _AuthenticationStatusChanged extends AppEvent {
  final AuthState authState;
  _AuthenticationStatusChanged(this.authState);
}


// --- СОСТОЯНИЯ ---
enum AppStatus {
  unknown, // Начальное состояние, пока мы не знаем, есть ли токен
  authenticated,
  unauthenticated,
}

class AppState {
  final AppStatus status;
  
  const AppState._({this.status = AppStatus.unknown});

  const AppState.unknown() : this._();

  const AppState.authenticated() : this._(status: AppStatus.authenticated);
  
  const AppState.unauthenticated() : this._(status: AppStatus.unauthenticated);
}


// --- БЛОК ---
class AppBloc extends Bloc<AppEvent, AppState> {
  final StorageService _storageService;
  final AuthBloc _authBloc;
  late StreamSubscription<AuthState> _authSubscription;

  AppBloc({
    required StorageService storageService,
    required AuthBloc authBloc,
  }) : _storageService = storageService,
       _authBloc = authBloc,
       super(const AppState.unknown()) {
    
    // Подписываемся на изменения в AuthBloc
    _authSubscription = _authBloc.stream.listen((authState) {
      add(_AuthenticationStatusChanged(authState));
    });

    on<AppStarted>(_onAppStarted);
    on<_AuthenticationStatusChanged>(_onAuthenticationStatusChanged);
  }

  // Обработчик события старта приложения
  Future<void> _onAppStarted(AppStarted event, Emitter<AppState> emit) async {
    final token = await _storageService.getToken();
    if (token != null) {
      _authBloc.add(RestoreAuthEvent());
      emit(const AppState.authenticated());
    } else {
      emit(const AppState.unauthenticated());
    }
  }

  // Обработчик изменения статуса аутентификации
  void _onAuthenticationStatusChanged(_AuthenticationStatusChanged event, Emitter<AppState> emit) {
    if (event.authState is AuthSuccess) {
      emit(const AppState.authenticated());
    } else if (event.authState is AuthInitial) { // AuthInitial после логаута
      emit(const AppState.unauthenticated());
    } else if (event.authState is AuthFailure) {
    emit(const AppState.unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}