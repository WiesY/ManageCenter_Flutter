import 'package:flutter/material.dart';
import 'package:manage_center/theme/app_theme.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  /// Кол-во активных аварий для бейджа на вкладке "Журнал"
  final int activeIncidentsCount;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.activeIncidentsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        decoration: BoxDecoration(
          color: (isDark ? colors.surfaceContainerHigh : colors.surface)
              .withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: context.appColors.cardShadow,
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border.all(
            color: colors.outlineVariant,
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Главная',
                index: 0,
              ),
              _buildNavItem(
                context,
                icon: Icons.analytics_outlined,
                selectedIcon: Icons.analytics,
                label: 'Аналитика',
                index: 1,
              ),
              _buildNavItem(
                context,
                icon: Icons.message_outlined,
                selectedIcon: Icons.message,
                label: 'Журнал',
                index: 2,
                badgeCount: activeIncidentsCount,
              ),
//               _buildNavItem(
//                 context,
//   icon: Icons.water_drop_outlined,
//   selectedIcon: Icons.water_drop,
//   label: 'Потери',
//   index: 3,
// ),
              _buildNavItem(
                context,
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Настройки',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    int? badgeCount,
  }) {
    final isSelected = currentIndex == index;
    final colors = context.colors;
    final itemColor = isSelected ? colors.primary : colors.onSurfaceVariant;

    final showBadge = (badgeCount ?? 0) > 0;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(vertical: 6),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    color: itemColor,
                    size: 25,
                  ),
                  if (showBadge)
                    Positioned(
                      right: -10,
                      top: -6,
                      child: _Badge(count: badgeCount!),
                    ),
                ],
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: itemColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.error,
        borderRadius: BorderRadius.circular(999),
        // Обводка цветом панели — бейдж «вырезается» из неё, а не висит пятном.
        border: Border.all(
          color: context.isDark ? colors.surfaceContainerHigh : colors.surface,
          width: 1.5,
        ),
      ),
      constraints: const BoxConstraints(minWidth: 18),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.onError,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}