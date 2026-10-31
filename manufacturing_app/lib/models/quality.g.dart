// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quality.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QualityInspectionImpl _$$QualityInspectionImplFromJson(
        Map<String, dynamic> json) =>
    _$QualityInspectionImpl(
      id: json['id'] as String,
      inspectionNumber: json['inspectionNumber'] as String,
      productionOrderId: json['productionOrderId'] as String,
      inspectorId: json['inspectorId'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      sampleSize: (json['sampleSize'] as num?)?.toDouble(),
      rejectedQuantity: (json['rejectedQuantity'] as num).toDouble(),
      result: json['result'] as String?,
      status: json['status'] as String,
      remarks: json['remarks'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$QualityInspectionImplToJson(
        _$QualityInspectionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'inspectionNumber': instance.inspectionNumber,
      'productionOrderId': instance.productionOrderId,
      'inspectorId': instance.inspectorId,
      'quantity': instance.quantity,
      'sampleSize': instance.sampleSize,
      'rejectedQuantity': instance.rejectedQuantity,
      'result': instance.result,
      'status': instance.status,
      'remarks': instance.remarks,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$QualityResultImpl _$$QualityResultImplFromJson(Map<String, dynamic> json) =>
    _$QualityResultImpl(
      id: json['id'] as String,
      inspectionId: json['inspectionId'] as String,
      parameter: json['parameter'] as String,
      expectedValue: json['expectedValue'] as String?,
      actualValue: json['actualValue'] as String?,
      result: json['result'] as String,
      remarks: json['remarks'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
    );

Map<String, dynamic> _$$QualityResultImplToJson(_$QualityResultImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'inspectionId': instance.inspectionId,
      'parameter': instance.parameter,
      'expectedValue': instance.expectedValue,
      'actualValue': instance.actualValue,
      'result': instance.result,
      'remarks': instance.remarks,
      'createdAt': instance.createdAt,
    };

_$ReworkOrderImpl _$$ReworkOrderImplFromJson(Map<String, dynamic> json) =>
    _$ReworkOrderImpl(
      id: json['id'] as String,
      reworkNumber: json['reworkNumber'] as String,
      inspectionId: json['inspectionId'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$ReworkOrderImplToJson(_$ReworkOrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reworkNumber': instance.reworkNumber,
      'inspectionId': instance.inspectionId,
      'quantity': instance.quantity,
      'status': instance.status,
      'notes': instance.notes,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
