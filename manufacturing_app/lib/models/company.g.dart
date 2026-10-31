// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompanyImpl _$$CompanyImplFromJson(Map<String, dynamic> json) =>
    _$CompanyImpl(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      gstNumber: json['gstNumber'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      currency: json['currency'] as String?,
      fiscalYearStart: json['fiscalYearStart'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$CompanyImplToJson(_$CompanyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'gstNumber': instance.gstNumber,
      'phone': instance.phone,
      'email': instance.email,
      'address': instance.address,
      'currency': instance.currency,
      'fiscalYearStart': instance.fiscalYearStart,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$CompanyRoleImpl _$$CompanyRoleImplFromJson(Map<String, dynamic> json) =>
    _$CompanyRoleImpl(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$CompanyRoleImplToJson(_$CompanyRoleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'description': instance.description,
      'permissions': instance.permissions,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
