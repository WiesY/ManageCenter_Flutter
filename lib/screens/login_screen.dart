import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/boilers_bloc.dart';
import 'package:manage_center/screens/dashboard_screen.dart';
import 'package:manage_center/screens/navigation/main_navigation_screen.dart';
import 'package:manage_center/screens/operator_screens/operator_screen.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  final bool _enableBiometric = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final authBloc = context.read<AuthBloc>();
    bool isAvailable = await authBloc.isBiometricAvailable();
    bool isEnabled = await authBloc.isBiometricEnabled();

    setState(() {
      _isBiometricAvailable = isAvailable;
      _isBiometricEnabled = isEnabled;
    });

    // Если биометрия включена, автоматически пытаемся войти
    if (_isBiometricEnabled) {
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    context.read<AuthBloc>().add(BiometricLoginEvent());
  }

// Метод для предложения сохранить учетные данные
void _promptToSaveCredentials() {
  if (_loginController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
    // Небольшая задержка перед вызовом диалога сохранения
    Future.delayed(const Duration(milliseconds: 100), () {
      TextInput.finishAutofillContext(shouldSave: true);
    });
  }
}

  void _onAuth() {
    _promptToSaveCredentials();
    if (_loginController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      // Запрос на авторизацию (finishAutofillContext уже вызван ранее)
      context.read<AuthBloc>().add(LoginEvent(
            login: _loginController.text,
            password: _passwordController.text,
            rememberMe: _rememberMe,
            enableBiometric: _enableBiometric,
          ));
    } else {
      // Показываем SnackBar через postFrameCallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заполните все поля')),
        );
      });
    }
  }

  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthLoading || state is BiometricAuthLoading) {
          // Показать индикатор загрузки
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
        } else if (state is AuthSuccess) {
          // Закрыть диалог загрузки если он открыт
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          // Перенаправление в зависимости от роли
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => state.userInfo.role?.name == 'Оператор'
                  ? const OperatorScreen()
                  : BlocProvider(
                      create: (context) => BoilersBloc(
                        apiService: context.read<ApiService>(),
                        storageService: context.read<StorageService>(),
                      )..add(FetchBoilers()), // Сразу запрашиваем данные
                      child: const MainNavigationScreen(),
                    ),
            ),
          );
        } else if (state is AuthFailure) {
          // Закрыть диалог загрузки если он открыт
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          // Показать ошибку через postFrameCallback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          });
        } else if (state is BiometricNotAvailable) {
          // Закрыть диалог загрузки если он открыт
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Биометрическая аутентификация недоступна на этом устройстве')),
            );
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                // Логотип или иконка
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.thermostat,
                    size: 40,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 32),
                // Заголовок
                const Text(
                  'Автоматизированная система контроля параметров объектов водоснабжения',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'МУП "Истринская теплосеть"',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                // Поля ввода
                AutofillGroup(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 5),
                        child: TextField(
                          controller: _loginController,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Логин',
                            border: InputBorder.none,
                            icon: Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 5),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (value) {
                            // Предлагаем сохранить учетные данные перед авторизацией
                            //_promptToSaveCredentials();
                            _onAuth();
                          },
                          decoration: InputDecoration(
                            hintText: 'Пароль',
                            border: InputBorder.none,
                            icon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Запомнить пароль и Забыли пароль
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? true;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: BorderSide(color: Colors.grey.shade400),
                              activeColor: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Запомнить пароль',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),
                // Биометрическая аутентификация (если доступна)
                // if (_isBiometricAvailable && !_isBiometricEnabled)
                //   Padding(
                //    padding: const EdgeInsets.only(top: 16.0),
                //    child: Row(
                //    children: [
                //    SizedBox(
                //    height: 24,
                //    width: 24,
                //    child: Checkbox(
                //    value: _enableBiometric,
                //    onChanged: (value) {
                //    setState(() {
                //    _enableBiometric = value ?? false;
                //    });
                //    },
                //    shape: RoundedRectangleBorder(
                //    borderRadius: BorderRadius.circular(4),
                //    ),
                //    side: BorderSide(color: Colors.grey.shade400),
                //    activeColor: Colors.blue.shade700,
                //    ),
                //    ),
                //    const SizedBox(width: 12),
                //    Text(
                //    'Использовать биометрию для входа',
                //    style: TextStyle(
                //    color: Colors.grey[600],
                //    fontSize: 14,
                //    ),
                //    ),
                //    ],
                //    ),
                //   ),

                const SizedBox(height: 32),
                // Кнопка входа
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      // Предлагаем сохранить учетные данные перед авторизацией
                      _promptToSaveCredentials();
                      _onAuth();
                    },
                    child: const Text(
                      'Войти',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Кнопка биометрической аутентификации
                // if (_isBiometricAvailable)
                //   Padding(
                //    padding: const EdgeInsets.only(top: 16.0),
                //    child: SizedBox(
                //    width: double.infinity,
                //    height: 56,
                //    child: OutlinedButton.icon(
                //    style: OutlinedButton.styleFrom(
                //    foregroundColor: Colors.blue.shade700,
                //    side: BorderSide(color: Colors.blue.shade700),
                //    shape: RoundedRectangleBorder(
                //    borderRadius: BorderRadius.circular(16),
                //    ),
                //    ),
                //    onPressed: _authenticateWithBiometrics,
                //    icon: const Icon(Icons.fingerprint),
                //    label: const Text(
                //    'Войти с биометрией',
                //    style: TextStyle(
                //    fontSize: 16,
                //    fontWeight: FontWeight.w600,
                //    ),
                //    ),
                //    ),
                //    ),
                //   ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
