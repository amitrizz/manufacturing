// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SupplierImpl _$$SupplierImplFromJson(Map<String, dynamic> json) =>
    _$SupplierImpl(
      id: json['id'] as String,
      code: json['code'] as String?,
      name: json['name'] as String,
      contactPerson: json['contactPerson'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      gstNumber: json['gstNumber'] as String?,
      suppliedItems: json['suppliedItems'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      isActive: (json['isActive'] as num?)?.toInt(),
      companyId: json['companyId'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$SupplierImplToJson(_$SupplierImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'contactPerson': instance.contactPerson,
      'phone': instance.phone,
      'email': instance.email,
      'address': instance.address,
      'gstNumber': instance.gstNumber,
      'suppliedItems': instance.suppliedItems,
      'rating': instance.rating,
      'notes': instance.notes,
      'isActive': instance.isActive,
      'companyId': instance.companyId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$CustomerImpl _$$CustomerImplFromJson(Map<String, dynamic> json) =>
    _$CustomerImpl(
      id: json['id'] as String,
      code: json['code'] as String?,
      name: json['name'] as String,
      contactPerson: json['contactPerson'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      gstNumber: json['gstNumber'] as String?,
      companyId: json['companyId'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$CustomerImplToJson(_$CustomerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'contactPerson': instance.contactPerson,
      'phone': instance.phone,
      'email': instance.email,
      'address': instance.address,
      'gstNumber': instance.gstNumber,
      'companyId': instance.companyId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$PurchaseRequestImpl _$$PurchaseRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$PurchaseRequestImpl(
      id: json['id'] as String,
      requestNumber: json['requestNumber'] as String,
      materialId: json['materialId'] as String,
      materialCode: json['materialCode'] as String?,
      materialName: json['materialName'] as String?,
      materialUnit: json['materialUnit'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      requiredByDate: (json['requiredByDate'] as num?)?.toInt(),
      linkedOrderId: json['linkedOrderId'] as String?,
      orderNumber: json['orderNumber'] as String?,
      reason: json['reason'] as String?,
      status: json['status'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$PurchaseRequestImplToJson(
        _$PurchaseRequestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requestNumber': instance.requestNumber,
      'materialId': instance.materialId,
      'materialCode': instance.materialCode,
      'materialName': instance.materialName,
      'materialUnit': instance.materialUnit,
      'quantity': instance.quantity,
      'requiredByDate': instance.requiredByDate,
      'linkedOrderId': instance.linkedOrderId,
      'orderNumber': instance.orderNumber,
      'reason': instance.reason,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$PurchaseOrderImpl _$$PurchaseOrderImplFromJson(Map<String, dynamic> json) =>
    _$PurchaseOrderImpl(
      id: json['id'] as String,
      poNumber: json['poNumber'] as String,
      supplierId: json['supplierId'] as String,
      supplierName: json['supplierName'] as String?,
      supplierCode: json['supplierCode'] as String?,
      status: json['status'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      orderDate: (json['orderDate'] as num).toInt(),
      expectedDeliveryDate: (json['expectedDeliveryDate'] as num?)?.toInt(),
      terms: json['terms'] as String?,
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$PurchaseOrderImplToJson(_$PurchaseOrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'poNumber': instance.poNumber,
      'supplierId': instance.supplierId,
      'supplierName': instance.supplierName,
      'supplierCode': instance.supplierCode,
      'status': instance.status,
      'totalAmount': instance.totalAmount,
      'orderDate': instance.orderDate,
      'expectedDeliveryDate': instance.expectedDeliveryDate,
      'terms': instance.terms,
      'notes': instance.notes,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$PurchaseOrderItemImpl _$$PurchaseOrderItemImplFromJson(
        Map<String, dynamic> json) =>
    _$PurchaseOrderItemImpl(
      id: json['id'] as String,
      poId: json['poId'] as String,
      materialId: json['materialId'] as String,
      materialCode: json['materialCode'] as String?,
      materialName: json['materialName'] as String?,
      unit: json['unit'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      receivedQuantity: (json['receivedQuantity'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$PurchaseOrderItemImplToJson(
        _$PurchaseOrderItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'poId': instance.poId,
      'materialId': instance.materialId,
      'materialCode': instance.materialCode,
      'materialName': instance.materialName,
      'unit': instance.unit,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'totalPrice': instance.totalPrice,
      'receivedQuantity': instance.receivedQuantity,
      'notes': instance.notes,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$GrnReceiptImpl _$$GrnReceiptImplFromJson(Map<String, dynamic> json) =>
    _$GrnReceiptImpl(
      id: json['id'] as String,
      grnNumber: json['grnNumber'] as String,
      poId: json['poId'] as String?,
      poNumber: json['poNumber'] as String?,
      supplierId: json['supplierId'] as String?,
      supplierName: json['supplierName'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      notes: json['notes'] as String?,
      receivedAt: (json['receivedAt'] as num).toInt(),
      receivedDate: (json['receivedDate'] as num?)?.toInt(),
      createdAt: (json['createdAt'] as num?)?.toInt(),
      totalQty: (json['totalQty'] as num?)?.toDouble(),
      itemsSummary: json['itemsSummary'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => GrnItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$GrnReceiptImplToJson(_$GrnReceiptImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'grnNumber': instance.grnNumber,
      'poId': instance.poId,
      'poNumber': instance.poNumber,
      'supplierId': instance.supplierId,
      'supplierName': instance.supplierName,
      'invoiceNumber': instance.invoiceNumber,
      'notes': instance.notes,
      'receivedAt': instance.receivedAt,
      'receivedDate': instance.receivedDate,
      'createdAt': instance.createdAt,
      'totalQty': instance.totalQty,
      'itemsSummary': instance.itemsSummary,
      'items': instance.items,
    };

_$GrnItemImpl _$$GrnItemImplFromJson(Map<String, dynamic> json) =>
    _$GrnItemImpl(
      materialId: json['materialId'] as String,
      materialCode: json['materialCode'] as String?,
      materialName: json['materialName'] as String?,
      unit: json['unit'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      receivedQuantity: (json['receivedQuantity'] as num).toDouble(),
    );

Map<String, dynamic> _$$GrnItemImplToJson(_$GrnItemImpl instance) =>
    <String, dynamic>{
      'materialId': instance.materialId,
      'materialCode': instance.materialCode,
      'materialName': instance.materialName,
      'unit': instance.unit,
      'quantity': instance.quantity,
      'receivedQuantity': instance.receivedQuantity,
    };

_$GrnReceivePayloadImpl _$$GrnReceivePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$GrnReceivePayloadImpl(
      poId: json['poId'] as String?,
      supplierId: json['supplierId'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      notes: json['notes'] as String?,
      receivedItems: (json['receivedItems'] as List<dynamic>)
          .map((e) => GrnReceiveItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$GrnReceivePayloadImplToJson(
        _$GrnReceivePayloadImpl instance) =>
    <String, dynamic>{
      'poId': instance.poId,
      'supplierId': instance.supplierId,
      'invoiceNumber': instance.invoiceNumber,
      'notes': instance.notes,
      'receivedItems': instance.receivedItems,
    };

_$GrnReceiveItemImpl _$$GrnReceiveItemImplFromJson(Map<String, dynamic> json) =>
    _$GrnReceiveItemImpl(
      materialId: json['materialId'] as String,
      receivedQty: (json['receivedQty'] as num).toDouble(),
    );

Map<String, dynamic> _$$GrnReceiveItemImplToJson(
        _$GrnReceiveItemImpl instance) =>
    <String, dynamic>{
      'materialId': instance.materialId,
      'receivedQty': instance.receivedQty,
    };
