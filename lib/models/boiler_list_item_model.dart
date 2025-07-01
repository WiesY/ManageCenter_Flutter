class BoilerListItem {
  final int id;
  final String name;
  final District district;
  final BoilerType boilerType;

  BoilerListItem({
    required this.id,
    required this.name,
    required this.district,
    required this.boilerType,
  });

  factory BoilerListItem.fromJson(Map<String, dynamic> json) {
    return BoilerListItem(
      id: json['id'] as int,
      name: json['name'] as String,
      district: District.fromJson(json['district'] as Map<String, dynamic>),
      boilerType: BoilerType.fromJson(json['boilerType'] as Map<String, dynamic>),
    );
  }
}

class BoilerType {
  final int id;
  final String name;

  BoilerType({required this.id, required this.name});

  factory BoilerType.fromJson(Map<String, dynamic> json) {
    return BoilerType(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class District {
  final int id;
  final String name;

  District({required this.id, required this.name});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}