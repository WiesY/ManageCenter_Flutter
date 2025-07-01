class BoilerParameter {
  final int id;
  final String paramDescription; // Изменено с parameterDescription
  final String valueType;

  BoilerParameter({
    required this.id,
    required this.paramDescription, // Изменено с parameterDescription
    required this.valueType,
  });

  factory BoilerParameter.fromJson(Map<String, dynamic> json) {
    return BoilerParameter(
      id: json['id'] ?? 0,
      paramDescription: json['paramDescription']?.toString() ?? '',
      valueType: json['valueType']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paramDescription': paramDescription, // Изменено с parameterDescription
      'valueType': valueType,
    };
  }

  @override
  String toString() {
    return 'BoilerParameter{id: $id, paramDescription: $paramDescription, valueType: $valueType}';
  }
}