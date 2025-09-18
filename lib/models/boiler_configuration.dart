import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/groups_model.dart';

class BoilerConfiguration {
  final List<BoilerParameter> boilerParameters;
  final List<Group> groups;

  const BoilerConfiguration({
    required this.boilerParameters,
    required this.groups,
  });

  // Фабричный конструктор для создания экземпляра из JSON
  factory BoilerConfiguration.fromJson(Map<String, dynamic> json) {
    return BoilerConfiguration(
      boilerParameters: (json['boilerParameters'] as List<dynamic>?)
          ?.map((param) => BoilerParameter.fromJson(param as Map<String, dynamic>))
          .toList() ?? [],
      groups: (json['groups'] as List<dynamic>?)
          ?.map((group) => Group.fromJson(group as Map<String, dynamic>))
          .toList() ?? [],
    );
  }}