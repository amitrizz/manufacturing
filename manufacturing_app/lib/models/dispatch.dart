import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../constants/app_colors.dart';

part 'dispatch.freezed.dart';
part 'dispatch.g.dart';

@freezed
class FinishedGoods with _$FinishedGoods {
  const factory FinishedGoods({
    required String id,
    required String productId,
    String? productCode,
    String? productName,
    required double producedQuantity,
    required double qualityPassedQuantity,
    required double rejectedQuantity,
    required double reworkQuantity,
    required double availableQuantity,
    required int updatedAt,
  }) = _FinishedGoods;

  factory FinishedGoods.fromJson(Map<String, dynamic> json) => _$FinishedGoodsFromJson(json);
}

@freezed
class DispatchOrder with _$DispatchOrder {
  const DispatchOrder._();

  const factory DispatchOrder({
    required String id,
    required String dispatchNumber,
    String? customerId,
    required String customerName,
    required String productId,
    String? productCode,
    String? productName,
    required double quantity,
    required String status,
    int? dispatchedAt,
    String? deliveryAddress,
    String? vehicleNumber,
    String? driverName,
    String? notes,
    required int createdAt,
    required int updatedAt,
  }) = _DispatchOrder;

  factory DispatchOrder.fromJson(Map<String, dynamic> json) => _$DispatchOrderFromJson(json);
  
  Color get statusColor => AppColors.getStatusColor(status);
}