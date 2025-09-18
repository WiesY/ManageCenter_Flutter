import 'package:flutter/material.dart';

class ParameterGroup {
  final int id;
  final String name;
  final List<int> parameterIds; // Список ID параметров в группе
  final String? color; // Цвет в формате #RRGGBBAA
  final String? iconFileName; // Имя файла иконки
  bool isVisible;
  bool isExpanded;

  ParameterGroup({
    required this.id,
    required this.name,
    this.parameterIds = const [],
    this.color,
    this.iconFileName,
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
      color: json['color'] as String?,
      iconFileName: json['iconFileName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parameterIds': parameterIds,
      'color': color,
      'iconFileName': iconFileName,
    };
  }

  // Создание копии с изменениями
  ParameterGroup copyWith({
    int? id,
    String? name,
    List<int>? parameterIds,
    String? color,
    String? iconFileName,
    bool? isVisible,
    bool? isExpanded,
  }) {
    return ParameterGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      parameterIds: parameterIds ?? this.parameterIds,
      color: color ?? this.color,
      iconFileName: iconFileName ?? this.iconFileName,
      isVisible: isVisible ?? this.isVisible,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  // Получение объекта Color из строки цвета
  Color getColorObject() {
    if (color == null || color!.isEmpty) {
      return Colors.blue; // Цвет по умолчанию
    }
    
    try {
      if (color!.startsWith('#') && color!.length == 9) {
        final hexColor = color!.substring(1);
        final r = int.parse(hexColor.substring(0, 2), radix: 16);
        final g = int.parse(hexColor.substring(2, 4), radix: 16);
        final b = int.parse(hexColor.substring(4, 6), radix: 16);
        final a = int.parse(hexColor.substring(6, 8), radix: 16);
        return Color.fromARGB(a, r, g, b);
      }
    } catch (e) {
      print('Ошибка при парсинге цвета: $e');
    }
    
    return Colors.blue; // Цвет по умолчанию в случае ошибки
  }

  // Получение строки цвета из объекта Color
  static String colorToString(Color color) {
    return '#${color.red.toRadixString(16).padLeft(2, '0')}'
        '${color.green.toRadixString(16).padLeft(2, '0')}'
        '${color.blue.toRadixString(16).padLeft(2, '0')}'
        '${color.alpha.toRadixString(16).padLeft(2, '0')}';
  }

  // Получение иконки по умолчанию
  IconData getDefaultIcon() {
    return Icons.folder;
  }

  @override
  String toString() {
    return 'ParameterGroup{id: $id, name: $name, parameterIds: $parameterIds, color: $color, iconFileName: $iconFileName}';
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