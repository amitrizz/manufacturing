import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard.freezed.dart';
part 'dashboard.g.dart';

@freezed
class DashboardKpis with _$DashboardKpis {
  const factory DashboardKpis({
    required double target,
    required double produced,
    required int achievement,
    required int qualityRate,
    required int machineAvailability,
    required double downtimeHours,
    required Map<String, int> machineStatusCounts,
    required List<LineProgress> lineProgress,
  }) = _DashboardKpis;

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    final statusCountsRaw = json['machineStatusCounts'] ?? json['machine_status_counts'];
    final statusMap = <String, int>{
      'RUNNING': 0,
      'BREAKDOWN': 0,
      'MAINTENANCE': 0,
      'IDLE': 0,
    };
    if (statusCountsRaw is Map) {
      statusCountsRaw.forEach((k, v) {
        if (v is num) {
          statusMap[k.toString()] = v.toInt();
        }
      });
    }

    final lineProgressRaw = json['lineProgress'] ?? json['line_progress'];
    final lineList = <LineProgress>[];
    if (lineProgressRaw is List) {
      for (final item in lineProgressRaw) {
        if (item is Map<String, dynamic>) {
          lineList.add(LineProgress.fromJson(item));
        } else if (item is Map) {
          lineList.add(LineProgress.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return DashboardKpis(
      target: (json['target'] as num?)?.toDouble() ?? 0.0,
      produced: (json['produced'] as num?)?.toDouble() ?? 0.0,
      achievement: (json['achievement'] as num?)?.toInt() ?? 0,
      qualityRate: (json['qualityRate'] ?? json['quality_rate'] as num?)?.toInt() ?? 100,
      machineAvailability: (json['machineAvailability'] ?? json['machine_availability'] as num?)?.toInt() ?? 0,
      downtimeHours: (json['downtimeHours'] ?? json['downtime_hours'] as num?)?.toDouble() ?? 0.0,
      machineStatusCounts: statusMap,
      lineProgress: lineList,
    );
  }
}

@freezed
class LineProgress with _$LineProgress {
  const factory LineProgress({
    required String lineCode,
    String? lineName,
    required double produced,
    required int pct,
  }) = _LineProgress;

  factory LineProgress.fromJson(Map<String, dynamic> json) => LineProgress(
        lineCode: (json['lineCode'] ?? json['line_code'] ?? '').toString(),
        lineName: (json['lineName'] ?? json['line_name'])?.toString(),
        produced: (json['produced'] as num?)?.toDouble() ?? 0.0,
        pct: (json['pct'] as num?)?.toInt() ?? 0,
      );
}

@freezed
class MachineStats with _$MachineStats {
  const factory MachineStats({
    required int running,
    required int breakdown,
    required int maintenance,
    required int idle,
    required int total,
  }) = _MachineStats;

  factory MachineStats.fromJson(Map<String, dynamic> json) => MachineStats(
        running: (json['running'] as num?)?.toInt() ?? 0,
        breakdown: (json['breakdown'] as num?)?.toInt() ?? 0,
        maintenance: (json['maintenance'] as num?)?.toInt() ?? 0,
        idle: (json['idle'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

@freezed
class AttendanceStats with _$AttendanceStats {
  const factory AttendanceStats({
    required int total,
    required int present,
    required int halfDay,
    required int leave,
    required int absent,
    required int rate,
  }) = _AttendanceStats;

  factory AttendanceStats.fromJson(Map<String, dynamic> json) => AttendanceStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        present: (json['present'] as num?)?.toInt() ?? 0,
        halfDay: (json['halfDay'] ?? json['half_day'] as num?)?.toInt() ?? 0,
        leave: (json['leave'] as num?)?.toInt() ?? 0,
        absent: (json['absent'] as num?)?.toInt() ?? 0,
        rate: (json['rate'] as num?)?.toInt() ?? 0,
      );
}

@freezed
class MonthlyData with _$MonthlyData {
  const factory MonthlyData({
    required String month,
    required int year,
    required int target,
    required int produced,
    required int pct,
  }) = _MonthlyData;

  factory MonthlyData.fromJson(Map<String, dynamic> json) => MonthlyData(
        month: (json['month'] ?? '').toString(),
        year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
        target: (json['target'] as num?)?.toInt() ?? 0,
        produced: (json['produced'] as num?)?.toInt() ?? 0,
        pct: (json['pct'] as num?)?.toInt() ?? 0,
      );
}

@freezed
class Activity with _$Activity {
  const Activity._();

  const factory Activity({
    required String id,
    required String eventType,
    required String title,
    String? description,
    String? referenceType,
    String? referenceId,
    String? companyId,
    required int timestamp,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        eventType: (json['eventType'] ?? json['event_type'] ?? 'ACTIVITY').toString(),
        title: (json['title'] ?? 'Activity').toString(),
        description: json['description']?.toString(),
        referenceType: (json['referenceType'] ?? json['reference_type'])?.toString(),
        referenceId: (json['referenceId'] ?? json['reference_id'])?.toString(),
        companyId: (json['companyId'] ?? json['company_id'])?.toString(),
        timestamp: (json['timestamp'] as num?)?.toInt() ??
            (json['created_at'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      );
  
  String get displayTime {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
  
  Color get dotColor {
    if (eventType.contains('BREAKDOWN')) return const Color(0xFFDC2626);
    if (eventType.contains('MATERIAL') || eventType.contains('STOCK')) return const Color(0xFFF59E0B);
    if (eventType.contains('DISPATCH')) return const Color(0xFF10B981);
    return const Color(0xFF2563EB);
  }
}

@freezed
class DashboardResponse with _$DashboardResponse {
  const factory DashboardResponse({
    required DashboardKpis kpis,
    required MachineStats machines,
    required AttendanceStats attendance,
    required int pendingTasksCount,
    required List<Activity> recentActivities,
    required List<MonthlyData> monthlyData,
  }) = _DashboardResponse;

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    final kpisRaw = json['kpis'];
    final machinesRaw = json['machines'];
    final attendanceRaw = json['attendance'];
    final activitiesRaw = json['recentActivities'] ?? json['recent_activities'];
    final monthlyRaw = json['monthlyData'] ?? json['monthly_data'];

    final actList = <Activity>[];
    if (activitiesRaw is List) {
      for (final a in activitiesRaw) {
        if (a is Map<String, dynamic>) {
          actList.add(Activity.fromJson(a));
        } else if (a is Map) {
          actList.add(Activity.fromJson(Map<String, dynamic>.from(a)));
        }
      }
    }

    final mList = <MonthlyData>[];
    if (monthlyRaw is List) {
      for (final m in monthlyRaw) {
        if (m is Map<String, dynamic>) {
          mList.add(MonthlyData.fromJson(m));
        } else if (m is Map) {
          mList.add(MonthlyData.fromJson(Map<String, dynamic>.from(m)));
        }
      }
    }

    return DashboardResponse(
      kpis: kpisRaw is Map
          ? DashboardKpis.fromJson(Map<String, dynamic>.from(kpisRaw))
          : const DashboardKpis(
              target: 0,
              produced: 0,
              achievement: 0,
              qualityRate: 100,
              machineAvailability: 0,
              downtimeHours: 0,
              machineStatusCounts: {'RUNNING': 0, 'BREAKDOWN': 0, 'MAINTENANCE': 0, 'IDLE': 0},
              lineProgress: [],
            ),
      machines: machinesRaw is Map
          ? MachineStats.fromJson(Map<String, dynamic>.from(machinesRaw))
          : const MachineStats(running: 0, breakdown: 0, maintenance: 0, idle: 0, total: 0),
      attendance: attendanceRaw is Map
          ? AttendanceStats.fromJson(Map<String, dynamic>.from(attendanceRaw))
          : const AttendanceStats(total: 0, present: 0, halfDay: 0, leave: 0, absent: 0, rate: 0),
      pendingTasksCount: (json['pendingTasksCount'] ?? json['pending_tasks_count'] as num?)?.toInt() ?? 0,
      recentActivities: actList,
      monthlyData: mList,
    );
  }
}