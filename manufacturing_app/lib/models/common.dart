import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'common.freezed.dart';
part 'common.g.dart';

@freezed
class Notification with _$Notification {
  const Notification._();

  const factory Notification({
    required String id,
    required String title,
    required String body,
    required String severity,
    required int isRead,
    String? referenceType,
    String? referenceId,
    required int createdAt,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
  
  Color get severityColor {
    switch (severity) {
      case 'INFO':
        return const Color(0xFF2563EB);
      case 'WARNING':
        return const Color(0xFFF59E0B);
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF2563EB);
    }
  }
}

@freezed
class Unit with _$Unit {
  const factory Unit({
    required String id,
    required String code,
    required String name,
    required String symbol,
    required String category,
    required int precision,
    bool? isCustom,
    String? description,
    required int createdAt,
    required int updatedAt,
  }) = _Unit;

  factory Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);
}

class PaginatedResponse<T> {
  final List<T> data;
  final Pagination pagination;

  const PaginatedResponse({
    required this.data,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(Object?)? fromJsonT,
  ]) {
    final rawData = json['data'] as List? ?? [];
    return PaginatedResponse<T>(
      data: rawData.map((e) => fromJsonT != null ? fromJsonT(e) : e as T).toList(),
      pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>? ?? {
        'total': 0,
        'limit': 20,
        'skip': 0,
        'hasMore': false,
      }),
    );
  }
}

@freezed
class Pagination with _$Pagination {
  const factory Pagination({
    required int total,
    required int limit,
    required int skip,
    required bool hasMore,
  }) = _Pagination;

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

@freezed
class ApiError with _$ApiError {
  const factory ApiError({
    required String error,
    int? status,
    Map<String, dynamic>? details,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) => _$ApiErrorFromJson(json);
}

@freezed
class HealthResponse with _$HealthResponse {
  const factory HealthResponse({
    required String status,
    required String database,
    required int collectionsCount,
    required String version,
    required int timestamp,
  }) = _HealthResponse;

  factory HealthResponse.fromJson(Map<String, dynamic> json) => _$HealthResponseFromJson(json);
}