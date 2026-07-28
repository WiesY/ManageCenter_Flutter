import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manage_center/theme/app_semantic_colors.dart';

export 'package:manage_center/theme/app_semantic_colors.dart';

/// Светлая и тёмная темы приложения.
///
/// Компонентные темы (AppBar, Card, поля ввода, диалоги…) заданы явно, поэтому
/// экранам не нужно красить виджеты вручную — достаточно не передавать цвет.
class AppTheme {
  const AppTheme._();

  /// Базовый фирменный синий.
  static const seed = Color(0xFF1976D2);

  static const _lightScaffold = Color(0xFFF5F7FA);
  static const _darkScaffold = Color(0xFF101317);

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  ).copyWith(
    primary: seed,
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFFD6E7FA),
    onPrimaryContainer: const Color(0xFF0B3C74),
    secondary: const Color(0xFF3F6392),
    onSecondary: const Color(0xFFFFFFFF),
    secondaryContainer: const Color(0xFFE0E8F5),
    onSecondaryContainer: const Color(0xFF213A5C),
    tertiary: const Color(0xFF00838F),
    onTertiary: const Color(0xFFFFFFFF),
    error: const Color(0xFFD32F2F),
    onError: const Color(0xFFFFFFFF),
    errorContainer: const Color(0xFFFDE7E7),
    onErrorContainer: const Color(0xFF8E1414),
    surface: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF1F2937),
    onSurfaceVariant: const Color(0xFF64748B),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFF8FAFC),
    surfaceContainer: const Color(0xFFF1F5F9),
    surfaceContainerHigh: const Color(0xFFE8EDF3),
    surfaceContainerHighest: const Color(0xFFE2E8F0),
    outline: const Color(0xFFCBD5E1),
    outlineVariant: const Color(0xFFE2E8F0),
    inverseSurface: const Color(0xFF2D3748),
    onInverseSurface: const Color(0xFFF8FAFC),
    inversePrimary: const Color(0xFF9CC7F5),
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF64B5F6),
    onPrimary: const Color(0xFF06294A),
    primaryContainer: const Color(0xFF17436E),
    onPrimaryContainer: const Color(0xFFCFE4FF),
    secondary: const Color(0xFF9FC0E8),
    onSecondary: const Color(0xFF12283F),
    secondaryContainer: const Color(0xFF243A52),
    onSecondaryContainer: const Color(0xFFD3E3F7),
    tertiary: const Color(0xFF4DD0E1),
    onTertiary: const Color(0xFF00363D),
    error: const Color(0xFFEF5350),
    onError: const Color(0xFF3A0A0A),
    errorContainer: const Color(0xFF3B2222),
    onErrorContainer: const Color(0xFFFFB4AB),
    surface: const Color(0xFF16191E),
    onSurface: const Color(0xFFE6E9EE),
    onSurfaceVariant: const Color(0xFF9AA5B4),
    surfaceContainerLowest: const Color(0xFF0D1014),
    surfaceContainerLow: const Color(0xFF1A1E23),
    surfaceContainer: const Color(0xFF1E2228),
    surfaceContainerHigh: const Color(0xFF262B32),
    surfaceContainerHighest: const Color(0xFF2E343C),
    outline: const Color(0xFF3A424C),
    outlineVariant: const Color(0xFF2A3037),
    inverseSurface: const Color(0xFFE6E9EE),
    onInverseSurface: const Color(0xFF1A1E23),
    inversePrimary: const Color(0xFF1565C0),
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
  );

  /// Контрастный цвет текста/иконок поверх произвольной подложки.
  ///
  /// Нужен там, где цвет фона приходит извне (статус объекта, цвет группы
  /// параметров из API) и «просто белый» не всегда читается.
  static Color contrastOn(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF10151C);

  /// Насыщенная подложка под белый текст.
  ///
  /// Цвета групп параметров задаёт пользователь, среди них попадаются светлые
  /// (лайм, амбер). Вместо того чтобы менять цвет надписи на тёмный — и
  /// получать чипы вперемешку с белыми и чёрными подписями — затемняем сам
  /// фон до уровня, на котором белый читается везде.
  static Color solidAccent(Color color) {
    var result = color;
    var guard = 0;
    while (result.computeLuminance() > 0.35 && guard < 8) {
      result = Color.lerp(result, const Color(0xFF000000), 0.18)!;
      guard++;
    }
    return result;
  }

  /// Цвет надписей и иконок поверх [solidAccent].
  static const Color onSolidAccent = Color(0xFFFFFFFF);

  /// Пользовательский цвет, пригодный как цвет иконки или текста на фоне
  /// приложения: слишком светлые оттенки темнеют в светлой теме, слишком
  /// тёмные — светлеют в тёмной.
  static Color accentOnSurface(Color color, Brightness brightness) {
    var result = color;
    var guard = 0;
    if (brightness == Brightness.dark) {
      while (result.computeLuminance() < 0.25 && guard < 8) {
        result = Color.lerp(result, const Color(0xFFFFFFFF), 0.2)!;
        guard++;
      }
    } else {
      while (result.computeLuminance() > 0.5 && guard < 8) {
        result = Color.lerp(result, const Color(0xFF000000), 0.18)!;
        guard++;
      }
    }
    return result;
  }

  static final ThemeData light = _build(
    scheme: _lightScheme,
    semantic: AppSemanticColors.light,
    scaffoldBackground: _lightScaffold,
  );

  static final ThemeData dark = _build(
    scheme: _darkScheme,
    semantic: AppSemanticColors.dark,
    scaffoldBackground: _darkScaffold,
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required AppSemanticColors semantic,
    required Color scaffoldBackground,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    // Шапка: в светлой теме — фирменный синий, в тёмной — тёмная поверхность
    // (синий на тёмном фоне читается тяжело и «жжёт» глаза ночью).
    final appBarBackground = isDark ? scheme.surfaceContainer : scheme.primary;
    final appBarForeground = isDark ? scheme.onSurface : scheme.onPrimary;

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBackground,
      // Заголовок AppBar: размер и начертание задаём здесь, цвет подставит
      // сам AppBar из своего foregroundColor.
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Сохраняем прежнее поведение: ExpansionTile и DataTable не рисуют
      // собственные разделители. Явный Divider() цвет берёт из dividerTheme.
      dividerColor: Colors.transparent,
      extensions: [semantic],
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        surfaceTintColor: Colors.transparent,
        shadowColor: semantic.cardShadow,
        elevation: 0,
        scrolledUnderElevation: isDark ? 0 : 2,
        centerTitle: true,
        // iconTheme/actionsIconTheme намеренно не задаём: AppBar берёт их из
        // темы как есть, игнорируя собственный foregroundColor. Экраны с
        // шапкой под цвет фона (журнал аварий, аналитика) получали из-за
        // этого белые иконки на светлой подложке. Без них AppBar красит
        // иконки своим foregroundColor — то есть тем, что задано ниже.
        // titleTextStyle намеренно не задаём: AppBar применяет цвет из
        // foregroundColor только к стилю по умолчанию. Стиль из темы он берёт
        // как есть — и экраны с прозрачной шапкой получали белый заголовок на
        // светлом фоне. Размер и начертание задаём через textTheme.titleLarge.
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: scaffoldBackground,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? scheme.surfaceContainer : scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: semantic.cardShadow,
        elevation: isDark ? 0 : 2,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark
              ? BorderSide(color: scheme.outlineVariant)
              : BorderSide.none,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 15,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerLow : scheme.surface,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          elevation: isDark ? 0 : 1,
          shadowColor: semantic.cardShadow,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: isDark ? 0 : 4,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        subtitleTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            isDark ? scheme.surfaceContainerHigh : scheme.surface,
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.24),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.18),
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return isDark ? scheme.outline : scheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return scheme.outline;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 1.6),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.outline;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primaryContainer;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimaryContainer;
            }
            return scheme.onSurfaceVariant;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: Colors.transparent,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: scheme.primary,
        collapsedIconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.28),
        selectionHandleColor: scheme.primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? scheme.surfaceContainer : scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? scheme.surfaceContainer : scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : scheme.surface,
      ),
    );
  }
}

/// Короткий доступ к теме: `context.colors`, `context.appColors`, `context.isDark`.
extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get textStyles => Theme.of(this).textTheme;

  AppSemanticColors get appColors =>
      Theme.of(this).extension<AppSemanticColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppSemanticColors.dark
          : AppSemanticColors.light);

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
