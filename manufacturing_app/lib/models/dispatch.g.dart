// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispatch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FinishedGoodsImpl _$$FinishedGoodsImplFromJson(Map<String, dynamic> json) =>
    _$FinishedGoodsImpl(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productCode: json['productCode'] as String?,
      productName: json['productName'] as String?,
      producedQuantity: (json['producedQuantity'] as num).toDouble(),
      qualityPassedQuantity: (json['qualityPassedQuantity'] as num).toDouble(),
      rejectedQuantity: (json['rejectedQuantity'] as num).toDouble(),
      reworkQuantity: (json['reworkQuantity'] as num).toDouble(),
      availableQuantity: (json['availableQuantity'] as num).toDouble(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$FinishedGoodsImplToJson(_$FinishedGoodsImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'productCode': instance.productCode,
      'productName': instance.productName,
      'producedQuantity': instance.producedQuantity,
      'qualityPassedQuantity': instance.qualityPassedQuantity,
      'rejectedQuantity': instance.rejectedQuantity,
      'reworkQuantity': instance.reworkQuantity,
      'availableQuantity': instance.availableQuantity,
      'updatedAt': instance.updatedAt,
    };

_$DispatchOrderImpl _$$DispatchOrderImplFromJson(Map<String, dynamic> json) =>
    _$DispatchOrderImpl(
      id: json['id'] as String,
      dispatchNumber: json['dispatchNumber'] as String,
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String,
      productId: json['productId'] as String,
      productCode: json['productCode'] as String?,
      productName: json['productName'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      status: json['status'] as String,
      dispatchedAt: (json['dispatchedAt'] as num?)?.toInt(),
      deliveryAddress: json['deliveryAddress'] as String?,
      vehicleNumber: json['vehicleNumber'] as String?,
      driverName: json['driverName'] as String?,
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$DispatchOrderImplToJson(_$DispatchOrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dispatchNumber': instance.dispatchNumber,
      'customerId': instance.customerId,
      'customerName': instance.customerName,
      'productId': instance.productId,
      'productCode': instance.productCode,
      'productName': instance.productName,
      'quantity': instance.quantity,
      'status': instance.status,
      'dispatchedAt': instance.dispatchedAt,
      'deliveryAddress': instance.deliveryAddress,
      'vehicleNumber': instance.vehicleNumber,
      'driverName': instance.driverName,
      'notes': instance.notes,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
