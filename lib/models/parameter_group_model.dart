import 'package:flutter/material.dart';

class ParameterGroup {
  final int id;
  final String name;
  final List<int> parameterIds; // Список ID параметров в группе
  final IconData icon;
  final Color color;
  bool isVisible;
  bool isExpanded;

  ParameterGroup({
    required this.id,
    required this.name,
    this.parameterIds = const [],
    this.icon = Icons.folder,
    this.color = Colors.blue,
    this.isVisible = true,
    this.isExpanded = true,
  });

  factory ParameterGroup.fromJson(Map<String, dynamic> json) {
    return ParameterGroup(
      id: json['id'] as int,
      name: json['name'] as String,
      parameterIds: json['parameterIds'] != null 
          ? List<int>.from(json['parameterIds']) 
          : [],
      icon: _getIconFromString(json['icon'] as String?),
      color: _getColorFromString(json['color'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parameterIds': parameterIds,
      'icon': _getStringFromIcon(icon),
      'color': _getStringFromColor(color),
    };
  }

  // Создание копии с изменениями
  ParameterGroup copyWith({
    int? id,
    String? name,
    List<int>? parameterIds,
    IconData? icon,
    Color? color,
    bool? isVisible,
    bool? isExpanded,
  }) {
    return ParameterGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      parameterIds: parameterIds ?? this.parameterIds,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isVisible: isVisible ?? this.isVisible,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  // Вспомогательные методы для конвертации иконок
  static IconData _getIconFromString(String? iconName) {
    switch (iconName) {
      case 'thermostat':
        return Icons.thermostat;
      case 'speed':
        return Icons.speed;
      case 'water_drop':
        return Icons.water_drop;
      case 'height':
        return Icons.height;
      case 'bolt':
        return Icons.bolt;
      case 'settings':
        return Icons.settings;
      case 'analytics':
        return Icons.analytics;
      default:
        return Icons.folder;
    }
  }

  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.thermostat) return 'thermostat';
    if (icon == Icons.speed) return 'speed';
    if (icon == Icons.water_drop) return 'water_drop';
    if (icon == Icons.height) return 'height';
    if (icon == Icons.bolt) return 'bolt';
    if (icon == Icons.settings) return 'settings';
    if (icon == Icons.analytics) return 'analytics';
    return 'folder';
  }

  // Вспомогательные методы для конвертации цветов
  static Color _getColorFromString(String? colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'cyan':
        return Colors.cyan;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  static String _getStringFromColor(Color color) {
    if (color == Colors.red) return 'red';
    if (color == Colors.blue) return 'blue';
    if (color == Colors.green) return 'green';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.cyan) return 'cyan';
    if (color == Colors.teal) return 'teal';
    return 'blue';
  }

  @override
  String toString() {
    return 'ParameterGroup{id: $id, name: $name, parameterIds: $parameterIds}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParameterGroup &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}