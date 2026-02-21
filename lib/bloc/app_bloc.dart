import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/services/storage_service.dart';

// --- СОБЫТИЯ ---
abstract class AppEvent {}

class AppStarted extends AppEvent {}

class _AuthenticationStatusChanged extends AppEvent {
  final AuthState authState;
  _AuthenticationStatusChanged(this.authState);
}

// --- СОСТОЯНИЯ ---
enum AppStatus {
  unknown,
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
  })  : _storageService = storageService,
        _authBloc = authBloc,
        super(const AppState.unknown()) {
    // Подписываемся на изменения в AuthBloc
    _authSubscription = _authBloc.stream.listen((authState) {
      add(_AuthenticationStatusChanged(authState));
    });

    on<AppStarted>(_onAppStarted);
    on<_AuthenticationStatusChanged>(_onAuthenticationStatusChanged);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AppState> emit) async {
    final token = await _storageService.getToken();
    if (token != null) {
      // ✅ Только отправляем RestoreAuthEvent
      // НЕ эмитим authenticated — ждём ответ от AuthBloc
      _authBloc.add(RestoreAuthEvent());
      // AppBloc остаётся в unknown, пока AuthBloc не ответит
    } else {
      emit(const AppState.unauthenticated());
    }
  }

  void _onAuthenticationStatusChanged(
      _AuthenticationStatusChanged event, Emitter<AppState> emit) {
    if (event.authState is AuthSuccess) {
      emit(const AppState.authenticated());
    } else if (event.authState is AuthInitial) {
      emit(const AppState.unauthenticated());
    } else if (event.authState is AuthFailure) {
      emit(const AppState.unauthenticated());
    }
    // AuthLoading — не эмитим, остаёмся в unknown (показывается спиннер)
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}