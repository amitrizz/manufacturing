import 'package:freezed_annotation/freezed_annotation.dart';

part 'staff.freezed.dart';
part 'staff.g.dart';

@freezed
class Staff with _$Staff {
  const factory Staff({
    required String id,
    required String employeeId,
    required String name,
    required String phone,
    String? email,
    String? roleId,
    String? department,
    required String shift,
    required double hourlyRate,
    required String status,
    int? joinedDate,
    required int createdAt,
    required int updatedAt,
  }) = _Staff;

  factory Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);
}

@freezed
class StaffAttendance with _$StaffAttendance {
  const factory StaffAttendance({
    required String id,
    required String staffId,
    String? staffName,
    String? employeeId,
    String? role,
    String? shift,
    required String date,
    required String status,
    int? checkIn,
    int? checkOut,
    required double overtimeHours,
    String? notes,
    required int createdAt,
    required int updatedAt,
  }) = _StaffAttendance;

  factory StaffAttendance.fromJson(Map<String, dynamic> json) => _$StaffAttendanceFromJson(json);
}

enum StaffRole {
  operator,
  supervisor,
  technician,
  qualityInspector,
  manager,
  admin,
}

enum AttendanceStatus {
  present,
  halfDay,
  leave,
  absent,
}