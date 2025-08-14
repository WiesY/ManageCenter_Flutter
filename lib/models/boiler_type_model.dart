class BoilerType {
  final int id;
  final String name;

  BoilerType({
    required this.id,
    required this.name,
  });

  factory BoilerType.fromJson(Map<String, dynamic> json) {
    return BoilerType(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}