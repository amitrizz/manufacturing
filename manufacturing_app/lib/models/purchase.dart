import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase.freezed.dart';
part 'purchase.g.dart';

@freezed
class Supplier with _$Supplier {
  const factory Supplier({
    required String id,
    String? code,
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    String? suppliedItems,
    double? rating,
    String? notes,
    int? isActive,
    String? companyId,
    required int createdAt,
    required int updatedAt,
  }) = _Supplier;

  factory Supplier.fromJson(Map<String, dynamic> json) => _$SupplierFromJson(json);
}

@freezed
class Customer with _$Customer {
  const factory Customer({
    required String id,
    String? code,
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    String? companyId,
    required int createdAt,
    required int updatedAt,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);
}

@freezed
class PurchaseRequest with _$PurchaseRequest {
  const factory PurchaseRequest({
    required String id,
    required String requestNumber,
    required String materialId,
    String? materialCode,
    String? materialName,
    String? materialUnit,
    required double quantity,
    int? requiredByDate,
    String? linkedOrderId,
    String? orderNumber,
    String? reason,
    required String status,
    required int createdAt,
    required int updatedAt,
  }) = _PurchaseRequest;

  factory PurchaseRequest.fromJson(Map<String, dynamic> json) => _$PurchaseRequestFromJson(json);
}

@freezed
class PurchaseOrder with _$PurchaseOrder {
  const factory PurchaseOrder({
    required String id,
    required String poNumber,
    required String supplierId,
    String? supplierName,
    String? supplierCode,
    required String status,
    required double totalAmount,
    required int orderDate,
    int? expectedDeliveryDate,
    String? terms,
    String? notes,
    required int createdAt,
    required int updatedAt,
  }) = _PurchaseOrder;

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) => _$PurchaseOrderFromJson(json);
}

@freezed
class PurchaseOrderItem with _$PurchaseOrderItem {
  const factory PurchaseOrderItem({
    required String id,
    required String poId,
    required String materialId,
    String? materialCode,
    String? materialName,
    String? unit,
    required double quantity,
    required double unitPrice,
    required double totalPrice,
    required double receivedQuantity,
    String? notes,
    required int createdAt,
    required int updatedAt,
  }) = _PurchaseOrderItem;

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) => _$PurchaseOrderItemFromJson(json);
}

@freezed
class GrnReceipt with _$GrnReceipt {
  const factory GrnReceipt({
    required String id,
    required String grnNumber,
    String? poId,
    String? poNumber,
    String? supplierId,
    String? supplierName,
    String? invoiceNumber,
    String? notes,
    required int receivedAt,
    int? receivedDate,
    int? createdAt,
    double? totalQty,
    String? itemsSummary,
    List<GrnItem>? items,
  }) = _GrnReceipt;

  factory GrnReceipt.fromJson(Map<String, dynamic> json) => _$GrnReceiptFromJson(json);
}

@freezed
class GrnItem with _$GrnItem {
  const factory GrnItem({
    required String materialId,
    String? materialCode,
    String? materialName,
    String? unit,
    double? quantity,
    required double receivedQuantity,
  }) = _GrnItem;

  factory GrnItem.fromJson(Map<String, dynamic> json) => _$GrnItemFromJson(json);
}

@freezed
class GrnReceivePayload with _$GrnReceivePayload {
  const factory GrnReceivePayload({
    String? poId,
    String? supplierId,
    String? invoiceNumber,
    String? notes,
    required List<GrnReceiveItem> receivedItems,
  }) = _GrnReceivePayload;

  factory GrnReceivePayload.fromJson(Map<String, dynamic> json) => _$GrnReceivePayloadFromJson(json);
}

@freezed
class GrnReceiveItem with _$GrnReceiveItem {
  const factory GrnReceiveItem({
    required String materialId,
    required double receivedQty,
  }) = _GrnReceiveItem;

  factory GrnReceiveItem.fromJson(Map<String, dynamic> json) => _$GrnReceiveItemFromJson(json);
}