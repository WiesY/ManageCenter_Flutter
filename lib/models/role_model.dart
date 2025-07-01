class Role {
  final int id;
  final String name;
  final bool canAccessAllBoilers;
  final bool canManageAccounts;
  final bool canManageBoilers;

  Role({
    required this.id,
    required this.name,
    required this.canAccessAllBoilers,
    required this.canManageAccounts,
    required this.canManageBoilers,
  });

  // Этот factory-конструктор будет создавать объект Role из JSON
  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      name: json['name'] as String,
      canAccessAllBoilers: json['canAccessAllBoilers'] as bool,
      canManageAccounts: json['canManageAccounts'] as bool,
      canManageBoilers: json['canManageBoilers'] as bool,
    );
  }
}