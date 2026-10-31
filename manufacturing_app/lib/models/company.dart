import 'package:freezed_annotation/freezed_annotation.dart';

part 'company.freezed.dart';
part 'company.g.dart';

@freezed
class Company with _$Company {
  const factory Company({
    required String id,
    required String code,
    required String name,
    String? gstNumber,
    String? phone,
    String? email,
    String? address,
    String? currency,
    String? fiscalYearStart,
    required int createdAt,
    required int updatedAt,
  }) = _Company;

  factory Company.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json);
    final normalized = {
      ...raw,
      'id': (raw['id'] ?? raw['_id'])?.toString() ?? '',
      'code': (raw['code'] ?? raw['company_code'] ?? raw['name'] ?? '').toString().toUpperCase(),
      'name': (raw['name'] ?? raw['code'] ?? 'Company').toString(),
      'createdAt': (raw['createdAt'] ?? raw['created_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      'updatedAt': (raw['updatedAt'] ?? raw['updated_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    };
    return _$CompanyFromJson(normalized);
  }
}

@freezed
class CompanyRole with _$CompanyRole {
  const factory CompanyRole({
    required String id,
    required String code,
    required String name,
    String? description,
    List<String>? permissions,
    required int createdAt,
    required int updatedAt,
  }) = _CompanyRole;

  factory CompanyRole.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json);
    final normalized = {
      ...raw,
      'id': (raw['id'] ?? raw['_id'])?.toString() ?? '',
      'code': (raw['code'] ?? raw['name'] ?? '').toString().toUpperCase(),
      'name': (raw['name'] ?? 'Role').toString(),
      'permissions': (raw['permissions'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
      'createdAt': (raw['createdAt'] ?? raw['created_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      'updatedAt': (raw['updatedAt'] ?? raw['updated_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    };
    return _$CompanyRoleFromJson(normalized);
  }
}