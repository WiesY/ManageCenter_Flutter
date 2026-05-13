import 'package:manage_center/models/boiler_type_model.dart';
import 'package:manage_center/models/district_model.dart';

class BoilerListItem {
  final int id;
  final String name;
  final District district;
  final BoilerType boilerType;
  final bool hasConnection;
  final bool isEmergency;

  BoilerListItem({
    required this.id,
    required this.name,
    required this.district,
    required this.boilerType,
    required this.hasConnection,
    required this.isEmergency,
  });

  factory BoilerListItem.fromJson(Map<String, dynamic> json) {
    return BoilerListItem(
      id: json['id'] as int,
      name: json['name'] as String,
      district: District.fromJson(json['district'] as Map<String, dynamic>),
      boilerType: BoilerType.fromJson(json['boilerType'] as Map<String, dynamic>),
      hasConnection: json['hasConnectionToBoiler'] as bool,
      isEmergency: json['isEmergency'] as bool,
    );
  }

  BoilerListItem copyWith({
    int? id,
    String? name,
    District? district,
    BoilerType? boilerType,
    bool? hasConnection,
    bool? isEmergency,
  }) {
    return BoilerListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      district: district ?? this.district,
      boilerType: boilerType ?? this.boilerType,
      hasConnection: hasConnection ?? this.hasConnection,
      isEmergency: isEmergency ?? this.isEmergency,
    );
  }
}