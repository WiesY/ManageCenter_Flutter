// file: parameter_group_model.dart

import 'package:flutter/foundation.dart';

@immutable
class Group {
  final int id;
  final String name;
  final String color;
  final String? iconFileName;

  // Поля для UI, которые не приходят с сервера.
  // final делает объект неизменяемым, что хорошо. 
  // Для изменения состояния (isExpanded) мы будем создавать новый объект.
  final bool isExpanded;

  const Group({
    required this.id,
    required this.name,
    required this.color,
    required this.iconFileName,
    this.isExpanded = false, // По умолчанию группа свернута
  });

  // Фабричный конструктор для создания экземпляра из JSON
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as String,
      iconFileName: json['iconFileName'] ?? '',
    );
  }

  // Метод для удобного копирования объекта с изменением некоторых полей
  // Очень пригодится для управления состоянием (например, isExpanded)
  Group copyWith({
    int? id,
    String? name,
    String? color,
    String? iconFileName,
    bool? isExpanded,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      iconFileName: iconFileName ?? this.iconFileName,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  // Для удобного вывода в консоль при отладке
  @override
  String toString() {
    return 'Group(id: $id, name: $name, isExpanded: $isExpanded)';
  }
}