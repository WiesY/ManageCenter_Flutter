class IncidentModel {
  final int id;
  final int boilerId;
  final int parameterId;
  final String description;
  final DateTime startTime;
  final bool isActive;
  final DateTime? resetTime;
  final int? resetUserId;
  final IncidentBoiler? boiler;
  final IncidentParameter? parameter;
  final IncidentResetUser? resetUser;

  IncidentModel({
    required this.id,
    required this.boilerId,
    required this.parameterId,
    required this.description,
    required this.startTime,
    required this.isActive,
    this.resetTime,
    this.resetUserId,
    this.boiler,
    this.parameter,
    this.resetUser,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] as int,
      boilerId: json['boilerId'] as int,
      parameterId: json['parameterId'] as int,
      description: json['description'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      isActive: json['isActive'] as bool,
      resetTime: json['resetTime'] != null 
          ? DateTime.parse(json['resetTime'] as String) 
          : null,
      resetUserId: json['resetUserId'] as int?,
      boiler: json['boiler'] != null 
          ? IncidentBoiler.fromJson(json['boiler'] as Map<String, dynamic>) 
          : null,
      parameter: json['parameter'] != null 
          ? IncidentParameter.fromJson(json['parameter'] as Map<String, dynamic>) 
          : null,
      resetUser: json['resetUser'] != null 
          ? IncidentResetUser.fromJson(json['resetUser'] as Map<String, dynamic>) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boilerId': boilerId,
      'parameterId': parameterId,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'isActive': isActive,
      'resetTime': resetTime?.toIso8601String(),
      'resetUserId': resetUserId,
      'boiler': boiler?.toJson(),
      'parameter': parameter?.toJson(),
      'resetUser': resetUser?.toJson(),
    };
  }

  // Вспомогательный метод для получения названия котельной
  String get boilerName => boiler?.name ?? 'Неизвестная котельная';
  
  // Вспомогательный метод для получения названия параметра
  String get parameterName => parameter?.name ?? 'Неизвестный параметр';
  
  // Вспомогательный метод для получения имени пользователя, сбросившего аварию
  String get resetUserName => resetUser?.name ?? 'Неизвестный пользователь';
}

// Вложенная модель для котельной в инциденте
class IncidentBoiler {
  final int id;
  final String name;
  final int districtId;
  final int boilerTypeId;
  final int? boilerOpcUaServerId;
  final bool hasConnectionToController;
  final int? boilerModbusInfoId;

  IncidentBoiler({
    required this.id,
    required this.name,
    required this.districtId,
    required this.boilerTypeId,
    this.boilerOpcUaServerId,
    required this.hasConnectionToController,
    this.boilerModbusInfoId,
  });

  factory IncidentBoiler.fromJson(Map<String, dynamic> json) {
    return IncidentBoiler(
      id: json['id'] as int,
      name: json['name'] as String,
      districtId: json['districtId'] as int,
      boilerTypeId: json['boilerTypeId'] as int,
      boilerOpcUaServerId: json['boilerOpcUaServerId'] as int?,
      hasConnectionToController: json['hasConnectionToController'] as bool,
      boilerModbusInfoId: json['boilerModbusInfoId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'districtId': districtId,
      'boilerTypeId': boilerTypeId,
      'boilerOpcUaServerId': boilerOpcUaServerId,
      'hasConnectionToController': hasConnectionToController,
      'boilerModbusInfoId': boilerModbusInfoId,
    };
  }
}

// Вложенная модель для параметра в инциденте
class IncidentParameter {
  final int id;
  final String name;
  final String valueType;
  final int groupId;

  IncidentParameter({
    required this.id,
    required this.name,
    required this.valueType,
    required this.groupId,
  });

  factory IncidentParameter.fromJson(Map<String, dynamic> json) {
    return IncidentParameter(
      id: json['id'] as int,
      name: json['name'] as String,
      valueType: json['valueType'] as String,
      groupId: json['groupId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'valueType': valueType,
      'groupId': groupId,
    };
  }
}

// Вложенная модель для пользователя, сбросившего аварию
class IncidentResetUser {
  final int id;
  final String login;
  final String name;
  final int roleId;

  IncidentResetUser({
    required this.id,
    required this.login,
    required this.name,
    required this.roleId,
  });

  factory IncidentResetUser.fromJson(Map<String, dynamic> json) {
    return IncidentResetUser(
      id: json['id'] as int,
      login: json['login'] as String,
      name: json['name'] as String,
      roleId: json['roleId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'login': login,
      'name': name,
      'roleId': roleId,
    };
  }
}