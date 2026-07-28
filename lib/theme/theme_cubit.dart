import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/services/storage_service.dart';

/// Хранит выбранный режим оформления и пишет его в настройки.
///
/// [ThemeMode.system] — приложение следует за настройкой ОС и переключается
/// на лету, без перезапуска.
class ThemeCubit extends Cubit<ThemeMode> {
  final StorageService _storageService;

  ThemeCubit({
    required StorageService storageService,
    ThemeMode initialMode = ThemeMode.system,
  })  : _storageService = storageService,
        super(initialMode);

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await _storageService.saveThemeMode(mode);
  }

  /// Быстрое переключение светлая ⇄ тёмная.
  ///
  /// [platformBrightness] нужна, чтобы из режима «Системная» перейти в
  /// противоположный текущей картинке, а не в тот же самый вид.
  Future<void> toggle(Brightness platformBrightness) {
    final isDarkNow = switch (state) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };
    return setMode(isDarkNow ? ThemeMode.light : ThemeMode.dark);
  }
}
