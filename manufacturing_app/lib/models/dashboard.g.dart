// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DashboardKpisImpl _$$DashboardKpisImplFromJson(Map<String, dynamic> json) =>
    _$DashboardKpisImpl(
      target: (json['target'] as num).toDouble(),
      produced: (json['produced'] as num).toDouble(),
      achievement: (json['achievement'] as num).toInt(),
      qualityRate: (json['qualityRate'] as num).toInt(),
      machineAvailability: (json['machineAvailability'] as num).toInt(),
      downtimeHours: (json['downtimeHours'] as num).toDouble(),
      machineStatusCounts:
          Map<String, int>.from(json['machineStatusCounts'] as Map),
      lineProgress: (json['lineProgress'] as List<dynamic>)
          .map((e) => LineProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$DashboardKpisImplToJson(_$DashboardKpisImpl instance) =>
    <String, dynamic>{
      'target': instance.target,
      'produced': instance.produced,
      'achievement': instance.achievement,
      'qualityRate': instance.qualityRate,
      'machineAvailability': instance.machineAvailability,
      'downtimeHours': instance.downtimeHours,
      'machineStatusCounts': instance.machineStatusCounts,
      'lineProgress': instance.lineProgress,
    };

_$LineProgressImpl _$$LineProgressImplFromJson(Map<String, dynamic> json) =>
    _$LineProgressImpl(
      lineCode: json['lineCode'] as String,
      lineName: json['lineName'] as String?,
      produced: (json['produced'] as num).toDouble(),
      pct: (json['pct'] as num).toInt(),
    );

Map<String, dynamic> _$$LineProgressImplToJson(_$LineProgressImpl instance) =>
    <String, dynamic>{
      'lineCode': instance.lineCode,
      'lineName': instance.lineName,
      'produced': instance.produced,
      'pct': instance.pct,
    };

_$MachineStatsImpl _$$MachineStatsImplFromJson(Map<String, dynamic> json) =>
    _$MachineStatsImpl(
      running: (json['running'] as num).toInt(),
      breakdown: (json['breakdown'] as num).toInt(),
      maintenance: (json['maintenance'] as num).toInt(),
      idle: (json['idle'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$$MachineStatsImplToJson(_$MachineStatsImpl instance) =>
    <String, dynamic>{
      'running': instance.running,
      'breakdown': instance.breakdown,
      'maintenance': instance.maintenance,
      'idle': instance.idle,
      'total': instance.total,
    };

_$AttendanceStatsImpl _$$AttendanceStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$AttendanceStatsImpl(
      total: (json['total'] as num).toInt(),
      present: (json['present'] as num).toInt(),
      halfDay: (json['halfDay'] as num).toInt(),
      leave: (json['leave'] as num).toInt(),
      absent: (json['absent'] as num).toInt(),
      rate: (json['rate'] as num).toInt(),
    );

Map<String, dynamic> _$$AttendanceStatsImplToJson(
        _$AttendanceStatsImpl instance) =>
    <String, dynamic>{
      'total': instance.total,
      'present': instance.present,
      'halfDay': instance.halfDay,
      'leave': instance.leave,
      'absent': instance.absent,
      'rate': instance.rate,
    };

_$MonthlyDataImpl _$$MonthlyDataImplFromJson(Map<String, dynamic> json) =>
    _$MonthlyDataImpl(
      month: json['month'] as String,
      year: (json['year'] as num).toInt(),
      target: (json['target'] as num).toInt(),
      produced: (json['produced'] as num).toInt(),
      pct: (json['pct'] as num).toInt(),
    );

Map<String, dynamic> _$$MonthlyDataImplToJson(_$MonthlyDataImpl instance) =>
    <String, dynamic>{
      'month': instance.month,
      'year': instance.year,
      'target': instance.target,
      'produced': instance.produced,
      'pct': instance.pct,
    };

_$ActivityImpl _$$ActivityImplFromJson(Map<String, dynamic> json) =>
    _$ActivityImpl(
      id: json['id'] as String,
      eventType: json['eventType'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as String?,
      companyId: json['companyId'] as String?,
      timestamp: (json['timestamp'] as num).toInt(),
    );

Map<String, dynamic> _$$ActivityImplToJson(_$ActivityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventType': instance.eventType,
      'title': instance.title,
      'description': instance.description,
      'referenceType': instance.referenceType,
      'referenceId': instance.referenceId,
      'companyId': instance.companyId,
      'timestamp': instance.timestamp,
    };

_$DashboardResponseImpl _$$DashboardResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$DashboardResponseImpl(
      kpis: DashboardKpis.fromJson(json['kpis'] as Map<String, dynamic>),
      machines: MachineStats.fromJson(json['machines'] as Map<String, dynamic>),
      attendance:
          AttendanceStats.fromJson(json['attendance'] as Map<String, dynamic>),
      pendingTasksCount: (json['pendingTasksCount'] as num).toInt(),
      recentActivities: (json['recentActivities'] as List<dynamic>)
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlyData: (json['monthlyData'] as List<dynamic>)
          .map((e) => MonthlyData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$DashboardResponseImplToJson(
        _$DashboardResponseImpl instance) =>
    <String, dynamic>{
      'kpis': instance.kpis,
      'machines': instance.machines,
      'attendance': instance.attendance,
      'pendingTasksCount': instance.pendingTasksCount,
      'recentActivities': instance.recentActivities,
      'monthlyData': instance.monthlyData,
    };
