// Основной класс для котельной с данными
class BoilerWithLastData {
  final Boiler boiler;
  final BoilerLastData? lastData;

  BoilerWithLastData({
    required this.boiler,
    this.lastData,
  });

  factory BoilerWithLastData.fromJson(Map<String, dynamic> json) {
    return BoilerWithLastData(
      boiler: Boiler.fromJson(json['boiler'] ?? {}),
      lastData: json['lastData'] != null
          ? BoilerLastData.fromJson(json['lastData'])
          : null,
    );
  }
}

// Класс для базовой информации о котельной
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
}

// Класс для последних данных котельной
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
  final List<BoilerParam22> param22;

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
      boilerId: json['boilerId'] ?? 0,
      userId: json['userId'] ?? 0,
      submitDateTime: DateTime.parse(
          json['submitDateTime'] ?? DateTime.now().toIso8601String()),
      particularDateTime: DateTime.parse(
          json['particularDateTime'] ?? DateTime.now().toIso8601String()),
      param1: (json['param1'] ?? 0).toDouble(),
      param2: (json['param2'] ?? 0).toDouble(),
      param3: (json['param3'] ?? 0).toDouble(),
      param4: (json['param4'] ?? 0).toDouble(),
      param5: (json['param5'] ?? 0).toDouble(),
      param6: (json['param6'] ?? 0).toDouble(),
      param7: (json['param7'] ?? 0).toDouble(),
      param8: (json['param8'] ?? 0).toDouble(),
      param9: (json['param9'] ?? 0).toDouble(),
      param10: (json['param10'] ?? 0).toDouble(),
      param18: (json['param18'] ?? 0).toDouble(),
      param19: (json['param19'] ?? 0).toDouble(),
      param20: (json['param20'] ?? 0).toDouble(),
      param22: (json['param22'] as List<dynamic>?)
              ?.map((e) => BoilerParam22.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// Класс для параметра param22
class BoilerParam22 {
  final int id;
  final String name;
  final double power;
  final int type;
  final bool isActive;

  BoilerParam22({
    required this.id,
    required this.name,
    required this.power,
    required this.type,
    required this.isActive,
  });

  factory BoilerParam22.fromJson(Map<String, dynamic> json) {
    return BoilerParam22(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      power: (json['power'] ?? 0).toDouble(),
      type: json['type'] ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }
}
