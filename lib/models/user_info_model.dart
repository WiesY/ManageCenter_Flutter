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
      id: json['id'] as int,
      initials: json['initials'] as String,
      role: json['role'] as int,
      controlledBoilers: List<int>.from(json['controlledBoilers'] as List),
    );
  }
}