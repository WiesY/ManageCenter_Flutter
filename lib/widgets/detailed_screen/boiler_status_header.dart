import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manage_center/theme/app_theme.dart';
import 'package:manage_center/widgets/blinking_dot.dart';

class BoilerStatusHeader extends StatelessWidget {
  final Color statusColor;
  final String statusText;
  final int parametersCount;

  const BoilerStatusHeader({
    super.key,
    required this.statusColor,
    required this.statusText,
    required this.parametersCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDark ? colors.surfaceContainer : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: context.isDark
            ? Border.all(color: colors.outlineVariant)
            : null,
        boxShadow: [
          BoxShadow(
            color: context.appColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: BlinkingDot(color: statusColor, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Обновлено: ${DateFormat('HH:mm:ss').format(DateTime.now().toLocal())}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Всего параметров: $parametersCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}