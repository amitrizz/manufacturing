// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StaffImpl _$$StaffImplFromJson(Map<String, dynamic> json) => _$StaffImpl(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      roleId: json['roleId'] as String?,
      department: json['department'] as String?,
      shift: json['shift'] as String,
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      status: json['status'] as String,
      joinedDate: (json['joinedDate'] as num?)?.toInt(),
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$StaffImplToJson(_$StaffImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employeeId': instance.employeeId,
      'name': instance.name,
      'phone': instance.phone,
      'email': instance.email,
      'roleId': instance.roleId,
      'department': instance.department,
      'shift': instance.shift,
      'hourlyRate': instance.hourlyRate,
      'status': instance.status,
      'joinedDate': instance.joinedDate,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$StaffAttendanceImpl _$$StaffAttendanceImplFromJson(
        Map<String, dynamic> json) =>
    _$StaffAttendanceImpl(
      id: json['id'] as String,
      staffId: json['staffId'] as String,
      staffName: json['staffName'] as String?,
      employeeId: json['employeeId'] as String?,
      role: json['role'] as String?,
      shift: json['shift'] as String?,
      date: json['date'] as String,
      status: json['status'] as String,
      checkIn: (json['checkIn'] as num?)?.toInt(),
      checkOut: (json['checkOut'] as num?)?.toInt(),
      overtimeHours: (json['overtimeHours'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$StaffAttendanceImplToJson(
        _$StaffAttendanceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'staffId': instance.staffId,
      'staffName': instance.staffName,
      'employeeId': instance.employeeId,
      'role': instance.role,
      'shift': instance.shift,
      'date': instance.date,
      'status': instance.status,
      'checkIn': instance.checkIn,
      'checkOut': instance.checkOut,
      'overtimeHours': instance.overtimeHours,
      'notes': instance.notes,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
