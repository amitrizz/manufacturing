import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../constants/app_colors.dart';

part 'maintenance.freezed.dart';
part 'maintenance.g.dart';

@freezed
class MaintenanceOrder with _$MaintenanceOrder {
  const MaintenanceOrder._();

  const factory MaintenanceOrder({
    required String id,
    required String machineId,
    String? machineCode,
    required String orderType,
    required String priority,
    required String status,
    String? assignedTo,
    required String description,
    int? scheduledDate,
    int? completedAt,
    required int createdAt,
    required int updatedAt,
  }) = _MaintenanceOrder;

  factory MaintenanceOrder.fromJson(Map<String, dynamic> json) => _$MaintenanceOrderFromJson(json);
  
  Color get priorityColor {
    switch (priority) {
      case 'LOW':
        return const Color(0xFF64748B);
      case 'MEDIUM':
        return const Color(0xFF2563EB);
      case 'HIGH':
        return const Color(0xFFF59E0B);
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }
  
  Color get statusColor => AppColors.getStatusColor(status);
}

@freezed
class MaintenanceHistory with _$MaintenanceHistory {
  const factory MaintenanceHistory({
    required String id,
    required String machineId,
    String? maintenanceOrderId,
    required int performedAt,
    required String summary,
    double? cost,
    required int createdAt,
  }) = _MaintenanceHistory;

  factory MaintenanceHistory.fromJson(Map<String, dynamic> json) => _$MaintenanceHistoryFromJson(json);
}