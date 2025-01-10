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
}//теперь давай сделаем так чтобы если мы авторизовались и пользователь поставил при авторизации галочку на "запомнить пароль", то у него при повторном запуске приложения не просило снова авторизоваться, а сразу как бы авторизованным кидало на главную страницу (в нашем случае пока что это dashboard_screen). То есть по идее нам нужно токен пользователя (который мы сохраняем локально). я правильно понимаю?