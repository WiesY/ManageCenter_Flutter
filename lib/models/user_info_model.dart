class UserInfo {
  final int id;
  final String initials;
  final int role;
  final List<int> controlledBoilers;

  UserInfo({
    required this.id,
    required this.initials,
    required this.role,
    required this.controlledBoilers,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? 0,
      initials:
          json['initials']?.toString() ?? '', // Преобразуем в String безопасно
      role: json['role'] ?? 0,
      controlledBoilers: (json['controlledBoilers'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }

  @override
  String toString() {
    return 'UserInfo(id: $id, initials: $initials, role: $role, controlledBoilers: $controlledBoilers)';
  }
}
