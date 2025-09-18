import 'package:manage_center/models/boiler_parameter_model.dart';

class BoilerParameterValue {
  final int id;
  final BoilerParameter parameter;
  final DateTime receiptDate;
  final String value;

  BoilerParameterValue({
    required this.id,
    required this.parameter,
    required this.receiptDate,
    required this.value,
  });

  factory BoilerParameterValue.fromJson(Map<String, dynamic> json) {
    return BoilerParameterValue(
      id: json['id'] ?? 0,
      parameter: BoilerParameter.fromJson(json['parameter'] ?? {}),
      receiptDate: DateTime.parse(json['receiptDate'] ?? DateTime.now().toIso8601String()),
      value: json['value']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parameter': parameter.toJson(),
      'receiptDate': receiptDate.toIso8601String(),
      'value': value,
    };
  }

  // Получить значение как строку для отображения
  String get displayValue {
    if (value.isEmpty) return 'N/A';

    switch (parameter.valueType.toLowerCase()) {
      case 'double':
      case 'float':
        final doubleValue = double.tryParse(value);
        return doubleValue?.toStringAsFixed(2) ?? value;
      case 'int':
      case 'integer':
        return value;
      case 'bool':
      case 'boolean':
        return value.toLowerCase() == 'true' ? 'Да' : 'Нет';
      default:
        return value;
    }
  }

  // Для удобства доступа к описанию параметра
  String get name => parameter.name;
  int get parameterId => parameter.id;
  String get valueType => parameter.valueType;

  @override
  String toString() {
    return 'BoilerParameterValue{id: $id, parameter: $parameter, receiptDate: $receiptDate, value: $value}';
  }
}
