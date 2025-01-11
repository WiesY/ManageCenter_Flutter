class Boiler {
  final BoilerData boiler;
  final BoilerLastData? lastData;

  Boiler({
    required this.boiler,
    this.lastData,
  });

  factory Boiler.fromJson(Map<String, dynamic> json) {
    return Boiler(
      boiler: BoilerData.fromJson(json['boiler']),
      lastData: json['lastData'] != null
          ? BoilerLastData.fromJson(json['lastData'])
          : null,
    );
  }

  // Добавляем геттеры для удобного доступа к полям boiler
  bool get isDisabled => boiler.isDisabled;
  bool get isHeatingSeason => boiler.isHeatingSeason;
  bool get isModule => boiler.isModule;
  bool get isAutomated => boiler.isAutomated;
  int get id => boiler.id;
  int get districtId => boiler.districtId;
}

class BoilerData {
  final int id;
  final String name;
  final String shortName;
  final int districtId;
  final int responsibleUserId;
  final bool isDisabled;
  final bool isHeatingSeason;
  final bool isModule;
  final bool isAutomated;

  BoilerData({
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

  factory BoilerData.fromJson(Map<String, dynamic> json) {
    return BoilerData(
      id: json['id'] as int,
      name: json['name'] as String,
      shortName: json['shortName'] as String,
      districtId: json['districtId'] as int,
      responsibleUserId: json['responsibleUserId'] as int,
      isDisabled: json['isDisabled'] as bool,
      isHeatingSeason: json['isHeatingSeason'] as bool,
      isModule: json['isModule'] as bool,
      isAutomated: json['isAutomated'] as bool,
    );
  }
}

class BoilerLastData {
  final int boilerId;
  final int userId;
  final DateTime submitDateTime;
  final DateTime particularDateTime;
  final double param1;
  final double param2;
  final double param3;
  final double param4;
  final double param5;
  final double param6;
  final double param7;
  final double param8;
  final double param9;
  final double param10;
  final double param18;
  final double param19;
  final double param20;
  final List<Param22> param22;

  BoilerLastData({
    required this.boilerId,
    required this.userId,
    required this.submitDateTime,
    required this.particularDateTime,
    required this.param1,
    required this.param2,
    required this.param3,
    required this.param4,
    required this.param5,
    required this.param6,
    required this.param7,
    required this.param8,
    required this.param9,
    required this.param10,
    required this.param18,
    required this.param19,
    required this.param20,
    required this.param22,
  });

  factory BoilerLastData.fromJson(Map<String, dynamic> json) {
    return BoilerLastData(
      boilerId: json['boilerId'] as int,
      userId: json['userId'] as int,
      submitDateTime: DateTime.parse(json['submitDateTime'] as String),
      particularDateTime: DateTime.parse(json['particularDateTime'] as String),
      param1: (json['param1'] as num).toDouble(),
      param2: (json['param2'] as num).toDouble(),
      param3: (json['param3'] as num).toDouble(),
      param4: (json['param4'] as num).toDouble(),
      param5: (json['param5'] as num).toDouble(),
      param6: (json['param6'] as num).toDouble(),
      param7: (json['param7'] as num).toDouble(),
      param8: (json['param8'] as num).toDouble(),
      param9: (json['param9'] as num).toDouble(),
      param10: (json['param10'] as num).toDouble(),
      param18: (json['param18'] as num).toDouble(),
      param19: (json['param19'] as num).toDouble(),
      param20: (json['param20'] as num).toDouble(),
      param22: (json['param22'] as List<dynamic>)
          .map((e) => Param22.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Param22 {
  final int id;
  final String name;
  final double power;
  final int type;
  final bool isActive;

  Param22({
    required this.id,
    required this.name,
    required this.power,
    required this.type,
    required this.isActive,
  });

  factory Param22.fromJson(Map<String, dynamic> json) {
    return Param22(
      id: json['id'] as int,
      name: json['name'] as String,
      power: (json['power'] as num).toDouble(),
      type: json['type'] as int,
      isActive: json['isActive'] as bool,
    );
  }
}
