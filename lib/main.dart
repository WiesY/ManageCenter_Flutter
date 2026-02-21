import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/app_lifecycle_manager.dart';
import 'package:manage_center/bloc/analytics_bloc.dart';
import 'package:manage_center/bloc/app_bloc.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/bloc/boiler_types_bloc.dart';
import 'package:manage_center/bloc/boilers_bloc.dart';
import 'package:manage_center/bloc/change_password_bloc.dart';
import 'package:manage_center/bloc/districts_bloc.dart';
import 'package:manage_center/bloc/incidents_bloc.dart';
import 'package:manage_center/bloc/parameter_groups_bloc.dart';
import 'package:manage_center/bloc/roles_bloc.dart';
import 'package:manage_center/bloc/user_profile_bloc.dart';
import 'package:manage_center/bloc/users_bloc.dart';
import 'package:manage_center/screens/login_screen.dart';
import 'package:manage_center/screens/navigation/main_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/push_notification_service.dart';
import 'services/storage_service.dart';
import 'bloc/auth_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<int?> switchTabNotifier = ValueNotifier<int?>(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- ИНИЦИАЛИЗАЦИЯ FIREBASE ---
  if (!Platform.isWindows) {
    log("🏁 [MAIN] Запуск инициализации Firebase...");
    try {
      await PushNotificationService().initialize();
    } catch (e) {
      log("❌ [MAIN] Ошибка инициализации Firebase: $e");
    }
  } else {
    log("🖥️ [MAIN] Запуск на Windows - Firebase отключен.");
  }

  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  final apiService = ApiService();

  final tokenTest = await storageService.getToken();
  log("🔑 Текущий токен API: $tokenTest");

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
          BlocProvider<ParameterGroupsBloc>(
            create: (context) => ParameterGroupsBloc(
              apiService: context.read<ApiService>(),
              storageService: context.read<StorageService>(),
            ),
          ),
          BlocProvider<AnalyticsBloc>(
            create: (context) => AnalyticsBloc(
              apiService: context.read<ApiService>(),
              storageService: context.read<StorageService>(),
            ),
          ),
          BlocProvider<AppBloc>(
            create: (context) => AppBloc(
              storageService: storageService,
              authBloc: context.read<AuthBloc>(),
            )..add(AppStarted()),
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
          BlocProvider<ChangePasswordBloc>(
            create: (context) => ChangePasswordBloc(
              apiService: context.read<ApiService>(),
              storageService: context.read<StorageService>(),
            ),
          ),
          BlocProvider<UserProfileBloc>(
            create: (context) => UserProfileBloc(
              apiService: context.read<ApiService>(),
              storageService: context.read<StorageService>(),
            ),
          ),
          BlocProvider<IncidentsBloc>(
            create: (context) => IncidentsBloc(
              apiService: context.read<ApiService>(),
              storageService: context.read<StorageService>(),
            )..add(IncidentsInitEvent()),
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
    return AppLifecycleManager(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.unknown,
          },
          scrollbars: kIsWeb ||
              Platform.isWindows ||
              Platform.isLinux ||
              Platform.isMacOS,
        ),
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
          dividerColor: Colors.transparent,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          dividerColor: Colors.transparent,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        home: BlocBuilder<AppBloc, AppState>(
          builder: (context, state) {
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
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}