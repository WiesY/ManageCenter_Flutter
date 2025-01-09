import 'package:flutter_bloc/flutter_bloc.dart';

enum AppStatus { initial, authenticated, unauthenticated }

class AppState {
  final AppStatus status;
  
  AppState({this.status = AppStatus.initial});
}

abstract class AppEvent {}

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(AppState()) {
    on<AppEvent>((event, emit) {
      // Обработка событий
    });
  }
}