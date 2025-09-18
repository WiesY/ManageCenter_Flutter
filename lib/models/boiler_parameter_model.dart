class BoilerParameter {
  final int id;
  final String paramDescription;
  final String valueType;
  final int? groupId;
  final String? unit;
  final double? minValue;
  final double? maxValue;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BoilerParameter({
    required this.id,
    required this.paramDescription,
    required this.valueType,
    this.groupId,
    this.unit,
    this.minValue,
    this.maxValue,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory BoilerParameter.fromJson(Map<String, dynamic> json) {
    return BoilerParameter(
      id: json['id'] as int,
      paramDescription: json['paramDescription'] as String? ?? '',
      valueType: json['valueType'] as String? ?? 'string',
      groupId: json['groupId'] as int?,
      unit: json['unit'] as String?,
      minValue: json['minValue']?.toDouble(),
      maxValue: json['maxValue']?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'] as String)
        : null,
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paramDescription': paramDescription,
      'valueType': valueType,
      'groupId': groupId,
      'unit': unit,
      'minValue': minValue,
      'maxValue': maxValue,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Метод для создания копии с изменениями
  BoilerParameter copyWith({
    int? id,
    String? paramDescription,
    String? valueType,
    int? groupId,
    String? unit,
    double? minValue,
    double? maxValue,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BoilerParameter(
      id: id ?? this.id,
      paramDescription: paramDescription ?? this.paramDescription,
      valueType: valueType ?? this.valueType,
      groupId: groupId ?? this.groupId,
      unit: unit ?? this.unit,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoilerParameter &&
        other.id == id &&
        other.paramDescription == paramDescription &&
        other.valueType == valueType &&
        other.groupId == groupId &&
        other.unit == unit &&
        other.minValue == minValue &&
        other.maxValue == maxValue &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      paramDescription,
      valueType,
      groupId,
      unit,
      minValue,
      maxValue,
      isActive,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'BoilerParameter(id: $id, paramDescription: $paramDescription, valueType: $valueType, groupId: $groupId, unit: $unit, minValue: $minValue, maxValue: $maxValue, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}