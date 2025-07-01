import 'package:manage_center/models/role_model.dart';

class UserInfo {
  final int id;
  final String name;
  final Role role;

  UserInfo({
    required this.id,
    required this.name,
    required this.role,
  });

  // Этот конструктор создает UserInfo из JSON, используя Role.fromJson для вложенного объекта
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      role: Role.fromJson(json['role'] as Map<String, dynamic>),
    );
  }
}