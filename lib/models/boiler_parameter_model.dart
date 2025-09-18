class BoilerParameter {
  final int id;
  final String name;
  final String valueType;
  final int? groupId; // ID группы, к которой принадлежит параметр (может быть null)
  BoilerParameter({
    required this.id,
    required this.name,
    required this.valueType,
    this.groupId,
  });

  factory BoilerParameter.fromJson(Map<String, dynamic> json) {
    return BoilerParameter(
    id: json['id'] ?? 0,
    name: json['name']?.toString() ?? '',
    valueType: json['valueType']?.toString() ?? '',
    groupId: json['groupId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
    'id': id,
    'name': name,
    'valueType': valueType,
    'groupId': groupId,
    };
  }

  // Создание копии с изменениями
  BoilerParameter copyWith({
    int? id,
    String? name,
    String? valueType,
    int? groupId,
  }) {
    return BoilerParameter(
    id: id ?? this.id,
    name: name ?? this.name,
    valueType: valueType ?? this.valueType,
    groupId: groupId ?? this.groupId,
    );
  }

  @override
  String toString() {
    return 'BoilerParameter{id: $id, paramDescription: $name, valueType: $valueType, groupId: $groupId}';
  }
}