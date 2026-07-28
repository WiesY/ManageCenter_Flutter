import 'package:flutter/material.dart';

/// Цвета, которых нет в [ColorScheme]: статусы объектов, аварии, графики.
///
/// Подключается к [ThemeData.extensions] и достаётся через `context.appColors`
/// — так один и тот же «зелёный ОК» автоматически берёт нужный оттенок для
/// светлой и тёмной темы.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  // Норма / успех
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  // Предупреждение
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  // Информация
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  // Архивные / неактивные объекты
  final Color archived;
  final Color onArchived;
  final Color archivedContainer;
  final Color onArchivedContainer;

  /// Фон «плиток» и вложенных блоков внутри карточки.
  final Color neutralSurface;

  /// Цвет теней у карточек и всплывающих панелей.
  final Color cardShadow;

  // Графики
  final Color chartGrid;
  final Color chartAxis;
  final Color chartTooltipBackground;
  final Color onChartTooltip;
  final List<Color> chartSeries;

  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.archived,
    required this.onArchived,
    required this.archivedContainer,
    required this.onArchivedContainer,
    required this.neutralSurface,
    required this.cardShadow,
    required this.chartGrid,
    required this.chartAxis,
    required this.chartTooltipBackground,
    required this.onChartTooltip,
    required this.chartSeries,
  });

  static const light = AppSemanticColors(
    success: Color(0xFF2E7D32),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFE6F4EA),
    onSuccessContainer: Color(0xFF1B5E20),
    warning: Color(0xFFE07C00),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFF3E0),
    onWarningContainer: Color(0xFF8A4B00),
    info: Color(0xFF0277BD),
    onInfo: Color(0xFFFFFFFF),
    infoContainer: Color(0xFFE3F2FD),
    onInfoContainer: Color(0xFF01579B),
    archived: Color(0xFF8A94A6),
    onArchived: Color(0xFFFFFFFF),
    archivedContainer: Color(0xFFEEF1F5),
    onArchivedContainer: Color(0xFF5A6473),
    neutralSurface: Color(0xFFF1F4F8),
    cardShadow: Color(0x1A0F172A),
    chartGrid: Color(0xFFE2E8F0),
    chartAxis: Color(0xFF64748B),
    chartTooltipBackground: Color(0xFF2D3748),
    onChartTooltip: Color(0xFFFFFFFF),
    chartSeries: [
      Color(0xFF1976D2),
      Color(0xFF2E7D32),
      Color(0xFFE07C00),
      Color(0xFF7B1FA2),
      Color(0xFF00838F),
      Color(0xFFC62828),
      Color(0xFF5D4037),
      Color(0xFF455A64),
    ],
  );

  static const dark = AppSemanticColors(
    success: Color(0xFF66BB6A),
    onSuccess: Color(0xFF0A2E12),
    successContainer: Color(0xFF1B3524),
    onSuccessContainer: Color(0xFF9BE0AB),
    warning: Color(0xFFFFB74D),
    onWarning: Color(0xFF3A2500),
    warningContainer: Color(0xFF3B2C12),
    onWarningContainer: Color(0xFFFFD79B),
    info: Color(0xFF4FC3F7),
    onInfo: Color(0xFF00293B),
    infoContainer: Color(0xFF13303D),
    onInfoContainer: Color(0xFFA9E1F9),
    archived: Color(0xFF7C8797),
    onArchived: Color(0xFF10151C),
    archivedContainer: Color(0xFF272C34),
    onArchivedContainer: Color(0xFFB4BECC),
    neutralSurface: Color(0xFF23272E),
    cardShadow: Color(0x66000000),
    chartGrid: Color(0xFF2C333C),
    chartAxis: Color(0xFF8A94A3),
    chartTooltipBackground: Color(0xFF2E343C),
    onChartTooltip: Color(0xFFE6E9EE),
    chartSeries: [
      Color(0xFF64B5F6),
      Color(0xFF81C784),
      Color(0xFFFFB74D),
      Color(0xFFBA8FDB),
      Color(0xFF4DD0E1),
      Color(0xFFEF9A9A),
      Color(0xFFBCAAA4),
      Color(0xFF90A4AE),
    ],
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? archived,
    Color? onArchived,
    Color? archivedContainer,
    Color? onArchivedContainer,
    Color? neutralSurface,
    Color? cardShadow,
    Color? chartGrid,
    Color? chartAxis,
    Color? chartTooltipBackground,
    Color? onChartTooltip,
    List<Color>? chartSeries,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      archived: archived ?? this.archived,
      onArchived: onArchived ?? this.onArchived,
      archivedContainer: archivedContainer ?? this.archivedContainer,
      onArchivedContainer: onArchivedContainer ?? this.onArchivedContainer,
      neutralSurface: neutralSurface ?? this.neutralSurface,
      cardShadow: cardShadow ?? this.cardShadow,
      chartGrid: chartGrid ?? this.chartGrid,
      chartAxis: chartAxis ?? this.chartAxis,
      chartTooltipBackground:
          chartTooltipBackground ?? this.chartTooltipBackground,
      onChartTooltip: onChartTooltip ?? this.onChartTooltip,
      chartSeries: chartSeries ?? this.chartSeries,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      archived: Color.lerp(archived, other.archived, t)!,
      onArchived: Color.lerp(onArchived, other.onArchived, t)!,
      archivedContainer:
          Color.lerp(archivedContainer, other.archivedContainer, t)!,
      onArchivedContainer:
          Color.lerp(onArchivedContainer, other.onArchivedContainer, t)!,
      neutralSurface: Color.lerp(neutralSurface, other.neutralSurface, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      chartAxis: Color.lerp(chartAxis, other.chartAxis, t)!,
      chartTooltipBackground:
          Color.lerp(chartTooltipBackground, other.chartTooltipBackground, t)!,
      onChartTooltip: Color.lerp(onChartTooltip, other.onChartTooltip, t)!,
      chartSeries: [
        for (var i = 0; i < chartSeries.length; i++)
          Color.lerp(
            chartSeries[i],
            i < other.chartSeries.length ? other.chartSeries[i] : chartSeries[i],
            t,
          )!,
      ],
    );
  }
}
