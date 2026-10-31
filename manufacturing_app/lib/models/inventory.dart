import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../constants/app_colors.dart';

part 'inventory.freezed.dart';
part 'inventory.g.dart';

@freezed
class Material with _$Material {
  const Material._();

  const factory Material({
    required String id,
    required String code,
    required String name,
    required String category,
    required String unit,
    required double currentStock,
    required double minimumStock,
    required double maximumStock,
    double? unitCost,
    String? companyId,
    required int createdAt,
    required int updatedAt,
  }) = _Material;

  factory Material.fromJson(Map<String, dynamic> json) => _$MaterialFromJson(json);
  
  // Helper getters
  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;
  
  double get stockPercentage => maximumStock > 0 
      ? (currentStock / maximumStock * 100).clamp(0, 100) 
      : 0;
  
  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }
  
  Color get statusColor {
    if (isOutOfStock) return AppColors.statusDanger;
    if (isLowStock) return AppColors.statusWarning;
    return AppColors.statusSuccess;
  }
}

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String code,
    required String name,
    String? categoryId,
    required String unit,
    String? description,
    double? standardRate,
    String? companyId,
    required int createdAt,
    required int updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}

@freezed
class ProductCategory with _$ProductCategory {
  const factory ProductCategory({
    required String id,
    required String code,
    required String name,
    required int createdAt,
  }) = _ProductCategory;

  factory ProductCategory.fromJson(Map<String, dynamic> json) => _$ProductCategoryFromJson(json);
}

@freezed
class Bom with _$Bom {
  const factory Bom({
    required String id,
    required String productId,
    required String version,
    bool? isActive,
    required int createdAt,
    required int updatedAt,
  }) = _Bom;

  factory Bom.fromJson(Map<String, dynamic> json) => _$BomFromJson(json);
}

@freezed
class BomItem with _$BomItem {
  const factory BomItem({
    required String id,
    required String bomId,
    required String materialId,
    required double quantity,
    required String unit,
    String? materialCode,
    String? materialName,
  }) = _BomItem;

  factory BomItem.fromJson(Map<String, dynamic> json) => _$BomItemFromJson(json);
}

@freezed
class StockTransaction with _$StockTransaction {
  const factory StockTransaction({
    required String id,
    required String materialId,
    String? materialCode,
    String? materialName,
    String? productName,
    required String transactionType,
    required double quantity,
    required double balanceAfter,
    required String unit,
    String? referenceType,
    String? referenceId,
    String? notes,
    required int createdAt,
  }) = _StockTransaction;

  factory StockTransaction.fromJson(Map<String, dynamic> json) => _$StockTransactionFromJson(json);
}