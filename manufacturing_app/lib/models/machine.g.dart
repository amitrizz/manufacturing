// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MachineImpl _$$MachineImplFromJson(Map<String, dynamic> json) =>
    _$MachineImpl(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      machineType: json['machineType'] as String,
      lineId: json['lineId'] as String,
      lineCode: json['lineCode'] as String?,
      lineName: json['lineName'] as String?,
      status: json['status'] as String,
      currentProductId: json['currentProductId'] as String?,
      productCode: json['productCode'] as String?,
      productName: json['productName'] as String?,
      currentOperator: json['currentOperator'] as String?,
      efficiency: (json['efficiency'] as num).toDouble(),
      runtimeSeconds: (json['runtimeSeconds'] as num).toInt(),
      downtimeSeconds: (json['downtimeSeconds'] as num).toInt(),
      lastMaintenanceAt: (json['lastMaintenanceAt'] as num?)?.toInt(),
      nextMaintenanceAt: (json['nextMaintenanceAt'] as num?)?.toInt(),
      companyId: json['companyId'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$MachineImplToJson(_$MachineImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'machineType': instance.machineType,
      'lineId': instance.lineId,
      'lineCode': instance.lineCode,
      'lineName': instance.lineName,
      'status': instance.status,
      'currentProductId': instance.currentProductId,
      'productCode': instance.productCode,
      'productName': instance.productName,
      'currentOperator': instance.currentOperator,
      'efficiency': instance.efficiency,
      'runtimeSeconds': instance.runtimeSeconds,
      'downtimeSeconds': instance.downtimeSeconds,
      'lastMaintenanceAt': instance.lastMaintenanceAt,
      'nextMaintenanceAt': instance.nextMaintenanceAt,
      'companyId': instance.companyId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$MachineDowntimeImpl _$$MachineDowntimeImplFromJson(
        Map<String, dynamic> json) =>
    _$MachineDowntimeImpl(
      id: json['id'] as String,
      machineId: json['machineId'] as String,
      reason: json['reason'] as String,
      startTime: (json['startTime'] as num).toInt(),
      endTime: (json['endTime'] as num?)?.toInt(),
      createdAt: (json['createdAt'] as num).toInt(),
      companyId: json['companyId'] as String?,
    );

Map<String, dynamic> _$$MachineDowntimeImplToJson(
        _$MachineDowntimeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'machineId': instance.machineId,
      'reason': instance.reason,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'createdAt': instance.createdAt,
      'companyId': instance.companyId,
    };

_$ProductionLineImpl _$$ProductionLineImplFromJson(Map<String, dynamic> json) =>
    _$ProductionLineImpl(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      companyId: json['companyId'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$ProductionLineImplToJson(
        _$ProductionLineImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'description': instance.description,
      'companyId': instance.companyId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
