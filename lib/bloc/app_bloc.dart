import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/services/storage_service.dart';

// --- СОБЫТИЯ ---
abstract class AppEvent {}

class AppStarted extends AppEvent {}

/// Сервер ответил 401 — токен больше не действителен.
class SessionExpired extends AppEvent {}

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

  /// Выход произошёл не по кнопке, а из-за истёкшей сессии — экран показывает
  /// об этом сообщение. Взводится ровно на один эмит.
  final bool sessionExpired;

  const AppState._({
    this.status = AppStatus.unknown,
    this.sessionExpired = false,
  });

  const AppState.unknown() : this._();

  const AppState.authenticated() : this._(status: AppStatus.authenticated);

  const AppState.unauthenticated({bool sessionExpired = false})
      : this._(
          status: AppStatus.unauthenticated,
          sessionExpired: sessionExpired,
        );
}

// --- БЛОК ---
class AppBloc extends Bloc<AppEvent, AppState> {
  final StorageService _storageService;
  final AuthBloc _authBloc;
  late StreamSubscription<AuthState> _authSubscription;
  StreamSubscription<void>? _unauthorizedSubscription;

  /// Взводится при 401 и гасится первым же переходом в unauthenticated.
  bool _sessionExpiredPending = false;

  AppBloc({
    required StorageService storageService,
    required AuthBloc authBloc,
    Stream<void>? unauthorizedStream,
  })  : _storageService = storageService,
        _authBloc = authBloc,
        super(const AppState.unknown()) {
    // Подписываемся на изменения в AuthBloc
    _authSubscription = _authBloc.stream.listen((authState) {
      add(_AuthenticationStatusChanged(authState));
    });

    // 401 от любого запроса — выкидываем на экран входа.
    _unauthorizedSubscription =
        unauthorizedStream?.listen((_) => add(SessionExpired()));

    on<AppStarted>(_onAppStarted);
    on<SessionExpired>(_onSessionExpired);
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

  void _onSessionExpired(SessionExpired event, Emitter<AppState> emit) {
    // Пользователь и так не в системе — второй раз выкидывать некуда.
    if (state.status == AppStatus.unauthenticated) return;

    _sessionExpiredPending = true;
    // Логаут почистит токен, роль и подписки на push; сам переход на экран
    // входа произойдёт в _onAuthenticationStatusChanged.
    _authBloc.add(LogoutEvent());
  }

  void _onAuthenticationStatusChanged(
      _AuthenticationStatusChanged event, Emitter<AppState> emit) {
    if (event.authState is AuthSuccess) {
      _sessionExpiredPending = false;
      emit(const AppState.authenticated());
    } else if (event.authState is AuthInitial ||
        event.authState is AuthFailure) {
      final expired = _sessionExpiredPending;
      _sessionExpiredPending = false;
      emit(AppState.unauthenticated(sessionExpired: expired));
    }
    // AuthLoading — не эмитим, остаёмся в unknown (показывается спиннер)
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    _unauthorizedSubscription?.cancel();
    return super.close();
  }
}