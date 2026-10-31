import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'quality.freezed.dart';
part 'quality.g.dart';

@freezed
class QualityInspection with _$QualityInspection {
  const QualityInspection._();

  const factory QualityInspection({
    required String id,
    required String inspectionNumber,
    required String productionOrderId,
    String? inspectorId,
    required double quantity,
    double? sampleSize,
    required double rejectedQuantity,
    String? result,
    required String status,
    String? remarks,
    required int createdAt,
    required int updatedAt,
  }) = _QualityInspection;

  factory QualityInspection.fromJson(Map<String, dynamic> json) => _$QualityInspectionFromJson(json);
  
  Color get resultColor {
    switch (result?.toUpperCase()) {
      case 'PASS':
      case 'PASSED':
        return const Color(0xFF16A34A);
      case 'FAIL':
      case 'FAILED':
        return const Color(0xFFDC2626);
      case 'REWORK':
        return const Color(0xFFF59E0B);
      case 'PARTIAL_PASS':
        return const Color(0xFF0284C7);
      default:
        return const Color(0xFF64748B);
    }
  }
}

@freezed
class QualityResult with _$QualityResult {
  const factory QualityResult({
    required String id,
    required String inspectionId,
    required String parameter,
    String? expectedValue,
    String? actualValue,
    required String result,
    String? remarks,
    required int createdAt,
  }) = _QualityResult;

  factory QualityResult.fromJson(Map<String, dynamic> json) => _$QualityResultFromJson(json);
}

@freezed
class ReworkOrder with _$ReworkOrder {
  const factory ReworkOrder({
    required String id,
    required String reworkNumber,
    required String inspectionId,
    required double quantity,
    required String status,
    String? notes,
    required int createdAt,
    required int updatedAt,
  }) = _ReworkOrder;

  factory ReworkOrder.fromJson(Map<String, dynamic> json) => _$ReworkOrderFromJson(json);
}