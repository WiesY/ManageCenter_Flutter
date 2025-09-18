import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/models/groups_model.dart';

class BoilerHistoryResponse {
  final List<BoilerParameterValue> historyNodeValues;
  final List<Group> groups;

  BoilerHistoryResponse({
    required this.historyNodeValues,
    required this.groups,
  });

  factory BoilerHistoryResponse.fromJson(Map<String, dynamic> json) {
    return BoilerHistoryResponse(
      historyNodeValues: (json['historyNodeValues'] as List<dynamic>?)
          ?.map((item) => BoilerParameterValue.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      groups: (json['groups'] as List<dynamic>?)
          ?.map((item) => Group.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}