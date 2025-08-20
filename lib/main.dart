import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/app_bloc.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/bloc/boiler_types_bloc.dart';
import 'package:manage_center/bloc/boilers_bloc.dart';
import 'package:manage_center/bloc/districts_bloc.dart';
import 'package:manage_center/bloc/roles_bloc.dart';
import 'package:manage_center/bloc/users_bloc.dart';
import 'package:manage_center/screens/login_screen.dart';
import 'package:manage_center/screens/navigation/main_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'bloc/auth_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  // Проверка, что все виджеты инициализированы до запуска приложения
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация сервисов
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  final apiService = ApiService();
  final _tokenTest = await storageService.getToken();

  print(_tokenTest);

  runApp(MyApp(
    storageService: storageService,
    apiService: apiService,
  ));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;

  const MyApp({
    super.key,
    required this.storageService,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: storageService),
        RepositoryProvider.value(value: apiService),
      ],
      child: MultiBlocProvider(
        providers: [
          // AuthBloc теперь доступен во всем приложении
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              apiService: apiService,
              storageService: storageService,
            ),
          ),
          BlocProvider<BoilerDetailBloc>(
            create: (context) => BoilerDetailBloc(
              apiService: apiService,
              storageService: storageService,
            ),
          ),
          // AppBloc зависит от AuthBloc и StorageService
          BlocProvider<AppBloc>(
            create: (context) => AppBloc(
              storageService: storageService,
              authBloc: context.read<AuthBloc>(),
            )..add(AppStarted()), // <-- Запускаем проверку при создании блока
          ),
          BlocProvider<UsersBloc>(
            create: (context) => UsersBloc(
              apiService: apiService,
              storageService: storageService,
            ),
          ),
          BlocProvider<RolesBloc>(
            create: (context) => RolesBloc(
              apiService: apiService,
              storageService: storageService,
            ),
          ),
          BlocProvider<DistrictsBloc>(
            create: (context) => DistrictsBloc(
              apiService: context.read<ApiService>(),
              storageService: context.read<StorageService>(),
            ),
          ),
          BlocProvider<BoilerTypesBloc>(
            create: (context) => BoilerTypesBloc(
              apiService: context.read<ApiService>(),
              storageService: context.read<StorageService>(),
            ),
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ru', 'RU'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          // В зависимости от статуса показываем нужный экран
          if (state.status == AppStatus.authenticated) {
            return BlocProvider<BoilersBloc>(
              create: (context) => BoilersBloc(
                apiService: context.read<ApiService>(),
                storageService: context.read<StorageService>(),
              )..add(FetchBoilers()),
              child: const MainNavigationScreen(),
            );
          }
          if (state.status == AppStatus.unauthenticated) {
            return const LoginScreen();
          }
          // Пока идет проверка, можно показывать сплэш-скрин или загрузчик
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
