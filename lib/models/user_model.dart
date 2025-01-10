class User {
  final String id;
  final String username;
  final String? token;

  User({
    required this.id,
    required this.username,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'],
      token: json['token'],
    );
  }
}