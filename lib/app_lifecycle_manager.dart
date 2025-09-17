import 'package:flutter/material.dart';
import 'package:manage_center/services/storage_service.dart';

class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  //final StorageService storageService;

  const AppLifecycleManager({
    Key? key,
    required this.child,
    //required this.storageService,
  }) : super(key: key);

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

   @override
   void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
  //     _checkAndClearSessionToken();
    }
   }

  // Future<void> _checkAndClearSessionToken() async {
  //   Проверяем, является ли токен сессионным
  //   bool isSessionToken = await widget.storageService.isSessionToken();
  //   bool isBiometricEnabled = await widget.storageService.isBiometricEnabled();
    
  //   Если токен сессионный и биометрия включена, удаляем токен
  //   if (isSessionToken && isBiometricEnabled) {
  //     await widget.storageService.deleteToken();
  //     Не удаляем биометрические учетные данные, чтобы пользователь мог войти снова
  //   }
  // }

   @override
   Widget build(BuildContext context) {
     return widget.child;
   }
}