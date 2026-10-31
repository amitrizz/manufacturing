import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../constants/app_colors.dart';

part 'production.freezed.dart';
part 'production.g.dart';

int? _safeInt(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  if (val is String) {
    final n = num.tryParse(val);
    if (n != null) return n.toInt();
    final d = DateTime.tryParse(val);
    if (d != null) return d.millisecondsSinceEpoch;
  }
  return null;
}

double? _safeDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

@freezed
class ProductionPlan with _$ProductionPlan {
  const factory ProductionPlan({
    required String id,
    required String planNumber,
    required String productId,
    String? productCode,
    String? productName,
    required double targetQuantity,
    required String lineId,
    String? lineCode,
    required int startDate,
    required int expectedCompletion,
    required String priority,
    required String status,
    String? notes,
    String? companyId,
    required int createdAt,
    required int updatedAt,
  }) = _ProductionPlan;

  factory ProductionPlan.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json);
    final normalized = <String, dynamic>{
      'id': (raw['id'] ?? raw['_id'])?.toString() ?? '',
      'planNumber': raw['planNumber'] ?? raw['plan_number'] ?? 'PLAN-001',
      'productId': (raw['productId'] ?? raw['product_id'])?.toString() ?? '',
      'productCode': raw['productCode'] ?? raw['product_code'],
      'productName': raw['productName'] ?? raw['product_name'],
      'targetQuantity': _safeDouble(raw['targetQuantity'] ?? raw['target_quantity']) ?? 0.0,
      'lineId': (raw['lineId'] ?? raw['line_id'])?.toString() ?? 'line-1',
      'lineCode': raw['lineCode'] ?? raw['line_code'],
      'startDate': _safeInt(raw['startDate'] ?? raw['start_date']) ?? DateTime.now().millisecondsSinceEpoch,
      'expectedCompletion': _safeInt(raw['expectedCompletion'] ?? raw['expected_completion']) ?? DateTime.now().millisecondsSinceEpoch,
      'priority': raw['priority'] ?? 'MEDIUM',
      'status': raw['status'] ?? 'PLANNED',
      'notes': raw['notes'],
      'companyId': raw['companyId'] ?? raw['company_id'],
      'createdAt': _safeInt(raw['createdAt'] ?? raw['created_at']) ?? DateTime.now().millisecondsSinceEpoch,
      'updatedAt': _safeInt(raw['updatedAt'] ?? raw['updated_at']) ?? DateTime.now().millisecondsSinceEpoch,
    };
    return _$ProductionPlanFromJson(normalized);
  }
}

@freezed
class ProductionOrder with _$ProductionOrder {
  const ProductionOrder._();

  const factory ProductionOrder({
    required String id,
    required String orderNumber,
    String? planId,
    required String productId,
    String? productCode,
    String? productName,
    required String lineId,
    String? lineCode,
    String? machineId,
    String? machineCode,
    List<String>? assignedMachines,
    List<String>? assignedWorkers,
    required double targetQuantity,
    required double producedQuantity,
    required double rejectedQuantity,
    required String priority,
    required String status,
    String? qcStatus,
    String? qcNotes,
    int? qcInspectedAt,
    String? qcInspector,
    int? startDate,
    int? dueDate,
    int? startedAt,
    int? completedAt,
    String? companyId,
    required int createdAt,
    required int updatedAt,
  }) = _ProductionOrder;

  factory ProductionOrder.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json);
    final normalized = <String, dynamic>{
      'id': (raw['id'] ?? raw['_id'])?.toString() ?? '',
      'orderNumber': raw['orderNumber'] ?? raw['order_number'] ?? raw['code'] ?? 'ORD-001',
      'planId': raw['planId'] ?? raw['plan_id'],
      'productId': (raw['productId'] ?? raw['product_id'])?.toString() ?? '',
      'productCode': raw['productCode'] ?? raw['product_code'],
      'productName': raw['productName'] ?? raw['product_name'],
      'lineId': (raw['lineId'] ?? raw['line_id'])?.toString() ?? 'line-1',
      'lineCode': raw['lineCode'] ?? raw['line_code'],
      'machineId': (raw['machineId'] ?? raw['machine_id'])?.toString(),
      'machineCode': raw['machineCode'] ?? raw['machine_code'],
      'assignedMachines': (raw['assignedMachines'] ?? raw['assigned_machines'] as List?)?.map((e) => e.toString()).toList(),
      'assignedWorkers': (raw['assignedWorkers'] ?? raw['assigned_workers'] as List?)?.map((e) => e.toString()).toList(),
      'targetQuantity': _safeDouble(raw['targetQuantity'] ?? raw['target_quantity']) ?? 0.0,
      'producedQuantity': _safeDouble(raw['producedQuantity'] ?? raw['produced_quantity']) ?? 0.0,
      'rejectedQuantity': _safeDouble(raw['rejectedQuantity'] ?? raw['rejected_quantity']) ?? 0.0,
      'priority': raw['priority'] ?? 'MEDIUM',
      'status': raw['status'] ?? 'PENDING',
      'qcStatus': raw['qcStatus'] ?? raw['qc_status'],
      'qcNotes': raw['qcNotes'] ?? raw['qc_notes'],
      'qcInspectedAt': _safeInt(raw['qcInspectedAt'] ?? raw['qc_inspected_at']),
      'qcInspector': raw['qcInspector'] ?? raw['qc_inspector'],
      'startDate': _safeInt(raw['startDate'] ?? raw['start_date']),
      'dueDate': _safeInt(raw['dueDate'] ?? raw['due_date']),
      'startedAt': _safeInt(raw['startedAt'] ?? raw['started_at']),
      'completedAt': _safeInt(raw['completedAt'] ?? raw['completed_at']),
      'companyId': raw['companyId'] ?? raw['company_id'],
      'createdAt': _safeInt(raw['createdAt'] ?? raw['created_at']) ?? DateTime.now().millisecondsSinceEpoch,
      'updatedAt': _safeInt(raw['updatedAt'] ?? raw['updated_at']) ?? DateTime.now().millisecondsSinceEpoch,
    };
    return _$ProductionOrderFromJson(normalized);
  }
  
  // Helper getters
  double get progressPercent => targetQuantity > 0 
      ? (producedQuantity / targetQuantity * 100).clamp(0, 100) 
      : 0;
  
  Color get statusColor => AppColors.getStatusColor(status);
  
  String get statusDisplayName {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'DELAYED':
        return 'Delayed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

@freezed
class ProductionEntry with _$ProductionEntry {
  const factory ProductionEntry({
    required String id,
    required String productionOrderId,
    String? machineId,
    String? operatorId,
    required double goodQuantity,
    required double rejectedQuantity,
    double? scrapQuantity,
    String? rejectionReason,
    required int entryTimestamp,
    required int createdAt,
  }) = _ProductionEntry;

  factory ProductionEntry.fromJson(Map<String, dynamic> json) => _$ProductionEntryFromJson(json);
}

enum PlanStatus {
  planned,
  inProgress,
  completed,
  delayed,
  cancelled,
}

enum OrderStatus {
  pending,
  inProgress,
  completed,
  delayed,
  cancelled,
}

enum Priority {
  low,
  medium,
  high,
  critical,
}