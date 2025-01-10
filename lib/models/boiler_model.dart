class Boiler {
  final int id;
  final String name;
  final String shortName;
  final int districtId;
  final int responsibleUserId;
  final bool isDisabled;
  final bool isHeatingSeason;
  final bool isModule;
  final bool isAutomated;

  Boiler({
    required this.id,
    required this.name,
    required this.shortName,
    required this.districtId,
    required this.responsibleUserId,
    required this.isDisabled,
    required this.isHeatingSeason,
    required this.isModule,
    required this.isAutomated,
  });

  factory Boiler.fromJson(Map<String, dynamic> json) {
    return Boiler(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      shortName: json['shortName']?.toString() ?? '',
      districtId: json['districtId'] ?? 0,
      responsibleUserId: json['responsibleUserId'] ?? 0,
      isDisabled: json['isDisabled'] ?? false,
      isHeatingSeason: json['isHeatingSeason'] ?? false,
      isModule: json['isModule'] ?? false,
      isAutomated: json['isAutomated'] ?? false,
    );
  }

  @override
  String toString() {
    return 'Boiler(id: $id, name: $name, shortName: $shortName, districtId: $districtId)';
  }
}
