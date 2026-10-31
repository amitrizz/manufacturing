// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MaintenanceOrderImpl _$$MaintenanceOrderImplFromJson(
        Map<String, dynamic> json) =>
    _$MaintenanceOrderImpl(
      id: json['id'] as String,
      machineId: json['machineId'] as String,
      machineCode: json['machineCode'] as String?,
      orderType: json['orderType'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      assignedTo: json['assignedTo'] as String?,
      description: json['description'] as String,
      scheduledDate: (json['scheduledDate'] as num?)?.toInt(),
      completedAt: (json['completedAt'] as num?)?.toInt(),
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$MaintenanceOrderImplToJson(
        _$MaintenanceOrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'machineId': instance.machineId,
      'machineCode': instance.machineCode,
      'orderType': instance.orderType,
      'priority': instance.priority,
      'status': instance.status,
      'assignedTo': instance.assignedTo,
      'description': instance.description,
      'scheduledDate': instance.scheduledDate,
      'completedAt': instance.completedAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$MaintenanceHistoryImpl _$$MaintenanceHistoryImplFromJson(
        Map<String, dynamic> json) =>
    _$MaintenanceHistoryImpl(
      id: json['id'] as String,
      machineId: json['machineId'] as String,
      maintenanceOrderId: json['maintenanceOrderId'] as String?,
      performedAt: (json['performedAt'] as num).toInt(),
      summary: json['summary'] as String,
      cost: (json['cost'] as num?)?.toDouble(),
      createdAt: (json['createdAt'] as num).toInt(),
    );

Map<String, dynamic> _$$MaintenanceHistoryImplToJson(
        _$MaintenanceHistoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'machineId': instance.machineId,
      'maintenanceOrderId': instance.maintenanceOrderId,
      'performedAt': instance.performedAt,
      'summary': instance.summary,
      'cost': instance.cost,
      'createdAt': instance.createdAt,
    };
