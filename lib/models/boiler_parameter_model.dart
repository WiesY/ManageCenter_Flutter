class BoilerParameter {
  final int id;
  final String paramDescription;
  final String valueType;
  final int? groupId; // ID группы, к которой принадлежит параметр

  BoilerParameter({
    required this.id,
    required this.paramDescription,
    required this.valueType,
    this.groupId,
  });

  factory BoilerParameter.fromJson(Map<String, dynamic> json) {
    return BoilerParameter(
      id: json['id'] ?? 0,
      paramDescription: json['paramDescription']?.toString() ?? '',
      valueType: json['valueType']?.toString() ?? '',
      groupId: json['groupId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paramDescription': paramDescription,
      'valueType': valueType,
      'groupId': groupId,
    };
  }

  // Создание копии с изменениями
  BoilerParameter copyWith({
    int? id,
    String? paramDescription,
    String? valueType,
    int? groupId,
  }) {
    return BoilerParameter(
      id: id ?? this.id,
      paramDescription: paramDescription ?? this.paramDescription,
      valueType: valueType ?? this.valueType,
      groupId: groupId ?? this.groupId,
    );
  }

  @override
  String toString() {
    return 'BoilerParameter{id: $id, paramDescription: $paramDescription, valueType: $valueType, groupId: $groupId}';
  }
}