// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'common.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationImpl _$$NotificationImplFromJson(Map<String, dynamic> json) =>
    _$NotificationImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      severity: json['severity'] as String,
      isRead: (json['isRead'] as num).toInt(),
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
    );

Map<String, dynamic> _$$NotificationImplToJson(_$NotificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'severity': instance.severity,
      'isRead': instance.isRead,
      'referenceType': instance.referenceType,
      'referenceId': instance.referenceId,
      'createdAt': instance.createdAt,
    };

_$UnitImpl _$$UnitImplFromJson(Map<String, dynamic> json) => _$UnitImpl(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      category: json['category'] as String,
      precision: (json['precision'] as num).toInt(),
      isCustom: json['isCustom'] as bool?,
      description: json['description'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$UnitImplToJson(_$UnitImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'symbol': instance.symbol,
      'category': instance.category,
      'precision': instance.precision,
      'isCustom': instance.isCustom,
      'description': instance.description,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$PaginationImpl _$$PaginationImplFromJson(Map<String, dynamic> json) =>
    _$PaginationImpl(
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      skip: (json['skip'] as num).toInt(),
      hasMore: json['hasMore'] as bool,
    );

Map<String, dynamic> _$$PaginationImplToJson(_$PaginationImpl instance) =>
    <String, dynamic>{
      'total': instance.total,
      'limit': instance.limit,
      'skip': instance.skip,
      'hasMore': instance.hasMore,
    };

_$ApiErrorImpl _$$ApiErrorImplFromJson(Map<String, dynamic> json) =>
    _$ApiErrorImpl(
      error: json['error'] as String,
      status: (json['status'] as num?)?.toInt(),
      details: json['details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$ApiErrorImplToJson(_$ApiErrorImpl instance) =>
    <String, dynamic>{
      'error': instance.error,
      'status': instance.status,
      'details': instance.details,
    };

_$HealthResponseImpl _$$HealthResponseImplFromJson(Map<String, dynamic> json) =>
    _$HealthResponseImpl(
      status: json['status'] as String,
      database: json['database'] as String,
      collectionsCount: (json['collectionsCount'] as num).toInt(),
      version: json['version'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
    );

Map<String, dynamic> _$$HealthResponseImplToJson(
        _$HealthResponseImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'database': instance.database,
      'collectionsCount': instance.collectionsCount,
      'version': instance.version,
      'timestamp': instance.timestamp,
    };
