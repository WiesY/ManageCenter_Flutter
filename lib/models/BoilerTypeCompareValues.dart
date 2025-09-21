// analytics_models.dart
import 'package:manage_center/models/boiler_list_item_model.dart';
import 'package:manage_center/models/boiler_type_model.dart';
import 'package:manage_center/models/groups_model.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';

class BoilerTypeCompareValues {
  final int boilerId;
  final String boilerName;
  final List<BoilerGroupCompareData> groups;

  BoilerTypeCompareValues({
    required this.boilerId,
    required this.boilerName,
    required this.groups,
  });

  factory BoilerTypeCompareValues.fromJson(Map<String, dynamic> json) {
    return BoilerTypeCompareValues(
      boilerId: json['boilerId'] ?? 0,
      boilerName: json['boilerName'] ?? '',
      groups: (json['groups'] as List<dynamic>?)
              ?.map((groupJson) => BoilerGroupCompareData.fromJson(groupJson))
              .toList() ?? [],
    );
  }
}

class BoilerGroupCompareData {
  final int groupId;
  final String groupName;
  final List<ParameterCompareData> parameters;

  BoilerGroupCompareData({
    required this.groupId,
    required this.groupName,
    required this.parameters,
  });

  factory BoilerGroupCompareData.fromJson(Map<String, dynamic> json) {
    return BoilerGroupCompareData(
      groupId: json['groupId'] ?? 0,
      groupName: json['groupName'] ?? '',
      parameters: (json['parameters'] as List<dynamic>?)
              ?.map((paramJson) => ParameterCompareData.fromJson(paramJson))
              .toList() ?? [],
    );
  }
}

class ParameterCompareData {
  final int parameterId;
  final String parameterName;
  final String value;
  final DateTime receiptDate;
  final String parameterValueType;

  ParameterCompareData({
    required this.parameterId,
    required this.parameterName,
    required this.value,
    required this.receiptDate,
    required this.parameterValueType,
  });

  factory ParameterCompareData.fromJson(Map<String, dynamic> json) {
    return ParameterCompareData(
      parameterId: json['parameterId'] ?? 0,
      parameterName: json['parameterName'] ?? '',
      value: json['value']?.toString() ?? '',
      receiptDate: DateTime.parse(json['receiptDate'] ?? DateTime.now().toIso8601String()),
      parameterValueType: json['parameterValueType'] ?? '',
    );
  }

  // Получить значение как строку для отображения
  String get displayValue {
    if (value.isEmpty) return 'N/A';

    switch (parameterValueType.toLowerCase()) {
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
}