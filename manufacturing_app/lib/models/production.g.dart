// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductionPlanImpl _$$ProductionPlanImplFromJson(Map<String, dynamic> json) =>
    _$ProductionPlanImpl(
      id: json['id'] as String,
      planNumber: json['planNumber'] as String,
      productId: json['productId'] as String,
      productCode: json['productCode'] as String?,
      productName: json['productName'] as String?,
      targetQuantity: (json['targetQuantity'] as num).toDouble(),
      lineId: json['lineId'] as String,
      lineCode: json['lineCode'] as String?,
      startDate: (json['startDate'] as num).toInt(),
      expectedCompletion: (json['expectedCompletion'] as num).toInt(),
      priority: json['priority'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      companyId: json['companyId'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$ProductionPlanImplToJson(
        _$ProductionPlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'planNumber': instance.planNumber,
      'productId': instance.productId,
      'productCode': instance.productCode,
      'productName': instance.productName,
      'targetQuantity': instance.targetQuantity,
      'lineId': instance.lineId,
      'lineCode': instance.lineCode,
      'startDate': instance.startDate,
      'expectedCompletion': instance.expectedCompletion,
      'priority': instance.priority,
      'status': instance.status,
      'notes': instance.notes,
      'companyId': instance.companyId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$ProductionOrderImpl _$$ProductionOrderImplFromJson(
        Map<String, dynamic> json) =>
    _$ProductionOrderImpl(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      planId: json['planId'] as String?,
      productId: json['productId'] as String,
      productCode: json['productCode'] as String?,
      productName: json['productName'] as String?,
      lineId: json['lineId'] as String,
      lineCode: json['lineCode'] as String?,
      machineId: json['machineId'] as String?,
      machineCode: json['machineCode'] as String?,
      assignedMachines: (json['assignedMachines'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      assignedWorkers: (json['assignedWorkers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      targetQuantity: (json['targetQuantity'] as num).toDouble(),
      producedQuantity: (json['producedQuantity'] as num).toDouble(),
      rejectedQuantity: (json['rejectedQuantity'] as num).toDouble(),
      priority: json['priority'] as String,
      status: json['status'] as String,
      qcStatus: json['qcStatus'] as String?,
      qcNotes: json['qcNotes'] as String?,
      qcInspectedAt: (json['qcInspectedAt'] as num?)?.toInt(),
      qcInspector: json['qcInspector'] as String?,
      startDate: (json['startDate'] as num?)?.toInt(),
      dueDate: (json['dueDate'] as num?)?.toInt(),
      startedAt: (json['startedAt'] as num?)?.toInt(),
      completedAt: (json['completedAt'] as num?)?.toInt(),
      companyId: json['companyId'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$ProductionOrderImplToJson(
        _$ProductionOrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderNumber': instance.orderNumber,
      'planId': instance.planId,
      'productId': instance.productId,
      'productCode': instance.productCode,
      'productName': instance.productName,
      'lineId': instance.lineId,
      'lineCode': instance.lineCode,
      'machineId': instance.machineId,
      'machineCode': instance.machineCode,
      'assignedMachines': instance.assignedMachines,
      'assignedWorkers': instance.assignedWorkers,
      'targetQuantity': instance.targetQuantity,
      'producedQuantity': instance.producedQuantity,
      'rejectedQuantity': instance.rejectedQuantity,
      'priority': instance.priority,
      'status': instance.status,
      'qcStatus': instance.qcStatus,
      'qcNotes': instance.qcNotes,
      'qcInspectedAt': instance.qcInspectedAt,
      'qcInspector': instance.qcInspector,
      'startDate': instance.startDate,
      'dueDate': instance.dueDate,
      'startedAt': instance.startedAt,
      'completedAt': instance.completedAt,
      'companyId': instance.companyId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$ProductionEntryImpl _$$ProductionEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProductionEntryImpl(
      id: json['id'] as String,
      productionOrderId: json['productionOrderId'] as String,
      machineId: json['machineId'] as String?,
      operatorId: json['operatorId'] as String?,
      goodQuantity: (json['goodQuantity'] as num).toDouble(),
      rejectedQuantity: (json['rejectedQuantity'] as num).toDouble(),
      scrapQuantity: (json['scrapQuantity'] as num?)?.toDouble(),
      rejectionReason: json['rejectionReason'] as String?,
      entryTimestamp: (json['entryTimestamp'] as num).toInt(),
      createdAt: (json['createdAt'] as num).toInt(),
    );

Map<String, dynamic> _$$ProductionEntryImplToJson(
        _$ProductionEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productionOrderId': instance.productionOrderId,
      'machineId': instance.machineId,
      'operatorId': instance.operatorId,
      'goodQuantity': instance.goodQuantity,
      'rejectedQuantity': instance.rejectedQuantity,
      'scrapQuantity': instance.scrapQuantity,
      'rejectionReason': instance.rejectionReason,
      'entryTimestamp': instance.entryTimestamp,
      'createdAt': instance.createdAt,
    };
