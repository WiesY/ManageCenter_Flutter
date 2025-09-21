
import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
        primaryColor: Colors.blue.shade700,
      ),
      child: BottomNavigationBar(
        elevation: 8,
        items: [
          _buildNavItem(Icons.home_outlined, Icons.home, 'Главная'),
          _buildNavItem(Icons.analytics_outlined, Icons.analytics, 'Аналитика'),
          _buildNavItem(Icons.message_outlined, Icons.message, 'Журнал'),
          _buildNavItem(Icons.settings_outlined, Icons.settings, 'Настройки'),
        ],
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.blue.shade700),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(activeIcon, color: Colors.blue.shade700),
      ),
      label: label,
    );
  }
}