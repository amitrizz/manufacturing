// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MaterialImpl _$$MaterialImplFromJson(Map<String, dynamic> json) =>
    _$MaterialImpl(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      unit: json['unit'] as String,
      currentStock: (json['currentStock'] as num).toDouble(),
      minimumStock: (json['minimumStock'] as num).toDouble(),
      maximumStock: (json['maximumStock'] as num).toDouble(),
      unitCost: (json['unitCost'] as num?)?.toDouble(),
      companyId: json['companyId'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$MaterialImplToJson(_$MaterialImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'category': instance.category,
      'unit': instance.unit,
      'currentStock': instance.currentStock,
      'minimumStock': instance.minimumStock,
      'maximumStock': instance.maximumStock,
      'unitCost': instance.unitCost,
      'companyId': instance.companyId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String?,
      unit: json['unit'] as String,
      description: json['description'] as String?,
      standardRate: (json['standardRate'] as num?)?.toDouble(),
      companyId: json['companyId'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'categoryId': instance.categoryId,
      'unit': instance.unit,
      'description': instance.description,
      'standardRate': instance.standardRate,
      'companyId': instance.companyId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$ProductCategoryImpl _$$ProductCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProductCategoryImpl(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
    );

Map<String, dynamic> _$$ProductCategoryImplToJson(
        _$ProductCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'createdAt': instance.createdAt,
    };

_$BomImpl _$$BomImplFromJson(Map<String, dynamic> json) => _$BomImpl(
      id: json['id'] as String,
      productId: json['productId'] as String,
      version: json['version'] as String,
      isActive: json['isActive'] as bool?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$BomImplToJson(_$BomImpl instance) => <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'version': instance.version,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$BomItemImpl _$$BomItemImplFromJson(Map<String, dynamic> json) =>
    _$BomItemImpl(
      id: json['id'] as String,
      bomId: json['bomId'] as String,
      materialId: json['materialId'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      materialCode: json['materialCode'] as String?,
      materialName: json['materialName'] as String?,
    );

Map<String, dynamic> _$$BomItemImplToJson(_$BomItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bomId': instance.bomId,
      'materialId': instance.materialId,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'materialCode': instance.materialCode,
      'materialName': instance.materialName,
    };

_$StockTransactionImpl _$$StockTransactionImplFromJson(
        Map<String, dynamic> json) =>
    _$StockTransactionImpl(
      id: json['id'] as String,
      materialId: json['materialId'] as String,
      materialCode: json['materialCode'] as String?,
      materialName: json['materialName'] as String?,
      productName: json['productName'] as String?,
      transactionType: json['transactionType'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      unit: json['unit'] as String,
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as String?,
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
    );

Map<String, dynamic> _$$StockTransactionImplToJson(
        _$StockTransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'materialId': instance.materialId,
      'materialCode': instance.materialCode,
      'materialName': instance.materialName,
      'productName': instance.productName,
      'transactionType': instance.transactionType,
      'quantity': instance.quantity,
      'balanceAfter': instance.balanceAfter,
      'unit': instance.unit,
      'referenceType': instance.referenceType,
      'referenceId': instance.referenceId,
      'notes': instance.notes,
      'createdAt': instance.createdAt,
    };
