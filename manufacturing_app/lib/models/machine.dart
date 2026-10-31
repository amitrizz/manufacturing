import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../constants/app_colors.dart';

part 'machine.freezed.dart';
part 'machine.g.dart';

@freezed
class Machine with _$Machine {
  const Machine._();

  const factory Machine({
    required String id,
    required String code,
    required String name,
    required String machineType,
    required String lineId,
    String? lineCode,
    String? lineName,
    required String status,
    String? currentProductId,
    String? productCode,
    String? productName,
    String? currentOperator,
    required double efficiency,
    required int runtimeSeconds,
    required int downtimeSeconds,
    int? lastMaintenanceAt,
    int? nextMaintenanceAt,
    String? companyId,
    required int createdAt,
    required int updatedAt,
  }) = _Machine;

  factory Machine.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json);
    final normalized = <String, dynamic>{
      'id': (raw['id'] ?? raw['_id'])?.toString() ?? '',
      'code': raw['code'] ?? '',
      'name': raw['name'] ?? '',
      'machineType': raw['machineType'] ?? raw['machine_type'] ?? 'General',
      'lineId': (raw['lineId'] ?? raw['line_id'])?.toString() ?? 'line-1',
      'lineCode': raw['lineCode'] ?? raw['line_code'],
      'lineName': raw['lineName'] ?? raw['line_name'],
      'status': raw['status'] ?? 'IDLE',
      'currentProductId': (raw['currentProductId'] ?? raw['current_product_id'])?.toString(),
      'productCode': raw['productCode'] ?? raw['product_code'],
      'productName': raw['productName'] ?? raw['product_name'],
      'currentOperator': raw['currentOperator'] ?? raw['current_operator'],
      'efficiency': (raw['efficiency'] as num?)?.toDouble() ?? 0.0,
      'runtimeSeconds': (raw['runtimeSeconds'] ?? raw['runtime_seconds'] as num?)?.toInt() ?? 0,
      'downtimeSeconds': (raw['downtimeSeconds'] ?? raw['downtime_seconds'] as num?)?.toInt() ?? 0,
      'lastMaintenanceAt': (raw['lastMaintenanceAt'] ?? raw['last_maintenance_at'] as num?)?.toInt(),
      'nextMaintenanceAt': (raw['nextMaintenanceAt'] ?? raw['next_maintenance_at'] as num?)?.toInt(),
      'companyId': raw['companyId'] ?? raw['company_id'],
      'createdAt': (raw['createdAt'] ?? raw['created_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      'updatedAt': (raw['updatedAt'] ?? raw['updated_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    };
    return _$MachineFromJson(normalized);
  }
  
  // Helper getters
  Color get statusColor => AppColors.getStatusColor(status);
  
  String get statusDisplayName {
    switch (status) {
      case 'RUNNING':
        return 'Running';
      case 'IDLE':
        return 'Idle';
      case 'BREAKDOWN':
        return 'Breakdown';
      case 'MAINTENANCE':
        return 'Maintenance';
      case 'OFFLINE':
        return 'Offline';
      case 'STOPPED':
        return 'Stopped';
      default:
        return status;
    }
  }
}

@freezed
class MachineDowntime with _$MachineDowntime {
  const factory MachineDowntime({
    required String id,
    required String machineId,
    required String reason,
    required int startTime,
    int? endTime,
    required int createdAt,
    String? companyId,
  }) = _MachineDowntime;

  factory MachineDowntime.fromJson(Map<String, dynamic> json) => _$MachineDowntimeFromJson(json);
}

@freezed
class ProductionLine with _$ProductionLine {
  const factory ProductionLine({
    required String id,
    required String code,
    required String name,
    String? description,
    String? companyId,
    required int createdAt,
    required int updatedAt,
  }) = _ProductionLine;

  factory ProductionLine.fromJson(Map<String, dynamic> json) => _$ProductionLineFromJson(json);
}