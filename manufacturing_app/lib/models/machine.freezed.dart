// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'machine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Machine _$MachineFromJson(Map<String, dynamic> json) {
  return _Machine.fromJson(json);
}

/// @nodoc
mixin _$Machine {
  String get id => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get machineType => throw _privateConstructorUsedError;
  String get lineId => throw _privateConstructorUsedError;
  String? get lineCode => throw _privateConstructorUsedError;
  String? get lineName => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get currentProductId => throw _privateConstructorUsedError;
  String? get productCode => throw _privateConstructorUsedError;
  String? get productName => throw _privateConstructorUsedError;
  String? get currentOperator => throw _privateConstructorUsedError;
  double get efficiency => throw _privateConstructorUsedError;
  int get runtimeSeconds => throw _privateConstructorUsedError;
  int get downtimeSeconds => throw _privateConstructorUsedError;
  int? get lastMaintenanceAt => throw _privateConstructorUsedError;
  int? get nextMaintenanceAt => throw _privateConstructorUsedError;
  String? get companyId => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MachineCopyWith<Machine> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MachineCopyWith<$Res> {
  factory $MachineCopyWith(Machine value, $Res Function(Machine) then) =
      _$MachineCopyWithImpl<$Res, Machine>;
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      String machineType,
      String lineId,
      String? lineCode,
      String? lineName,
      String status,
      String? currentProductId,
      String? productCode,
      String? productName,
      String? currentOperator,
      double efficiency,
      int runtimeSeconds,
      int downtimeSeconds,
      int? lastMaintenanceAt,
      int? nextMaintenanceAt,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$MachineCopyWithImpl<$Res, $Val extends Machine>
    implements $MachineCopyWith<$Res> {
  _$MachineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? machineType = null,
    Object? lineId = null,
    Object? lineCode = freezed,
    Object? lineName = freezed,
    Object? status = null,
    Object? currentProductId = freezed,
    Object? productCode = freezed,
    Object? productName = freezed,
    Object? currentOperator = freezed,
    Object? efficiency = null,
    Object? runtimeSeconds = null,
    Object? downtimeSeconds = null,
    Object? lastMaintenanceAt = freezed,
    Object? nextMaintenanceAt = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      machineType: null == machineType
          ? _value.machineType
          : machineType // ignore: cast_nullable_to_non_nullable
              as String,
      lineId: null == lineId
          ? _value.lineId
          : lineId // ignore: cast_nullable_to_non_nullable
              as String,
      lineCode: freezed == lineCode
          ? _value.lineCode
          : lineCode // ignore: cast_nullable_to_non_nullable
              as String?,
      lineName: freezed == lineName
          ? _value.lineName
          : lineName // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      currentProductId: freezed == currentProductId
          ? _value.currentProductId
          : currentProductId // ignore: cast_nullable_to_non_nullable
              as String?,
      productCode: freezed == productCode
          ? _value.productCode
          : productCode // ignore: cast_nullable_to_non_nullable
              as String?,
      productName: freezed == productName
          ? _value.productName
          : productName // ignore: cast_nullable_to_non_nullable
              as String?,
      currentOperator: freezed == currentOperator
          ? _value.currentOperator
          : currentOperator // ignore: cast_nullable_to_non_nullable
              as String?,
      efficiency: null == efficiency
          ? _value.efficiency
          : efficiency // ignore: cast_nullable_to_non_nullable
              as double,
      runtimeSeconds: null == runtimeSeconds
          ? _value.runtimeSeconds
          : runtimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      downtimeSeconds: null == downtimeSeconds
          ? _value.downtimeSeconds
          : downtimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      lastMaintenanceAt: freezed == lastMaintenanceAt
          ? _value.lastMaintenanceAt
          : lastMaintenanceAt // ignore: cast_nullable_to_non_nullable
              as int?,
      nextMaintenanceAt: freezed == nextMaintenanceAt
          ? _value.nextMaintenanceAt
          : nextMaintenanceAt // ignore: cast_nullable_to_non_nullable
              as int?,
      companyId: freezed == companyId
          ? _value.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MachineImplCopyWith<$Res> implements $MachineCopyWith<$Res> {
  factory _$$MachineImplCopyWith(
          _$MachineImpl value, $Res Function(_$MachineImpl) then) =
      __$$MachineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      String machineType,
      String lineId,
      String? lineCode,
      String? lineName,
      String status,
      String? currentProductId,
      String? productCode,
      String? productName,
      String? currentOperator,
      double efficiency,
      int runtimeSeconds,
      int downtimeSeconds,
      int? lastMaintenanceAt,
      int? nextMaintenanceAt,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$MachineImplCopyWithImpl<$Res>
    extends _$MachineCopyWithImpl<$Res, _$MachineImpl>
    implements _$$MachineImplCopyWith<$Res> {
  __$$MachineImplCopyWithImpl(
      _$MachineImpl _value, $Res Function(_$MachineImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? machineType = null,
    Object? lineId = null,
    Object? lineCode = freezed,
    Object? lineName = freezed,
    Object? status = null,
    Object? currentProductId = freezed,
    Object? productCode = freezed,
    Object? productName = freezed,
    Object? currentOperator = freezed,
    Object? efficiency = null,
    Object? runtimeSeconds = null,
    Object? downtimeSeconds = null,
    Object? lastMaintenanceAt = freezed,
    Object? nextMaintenanceAt = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$MachineImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      machineType: null == machineType
          ? _value.machineType
          : machineType // ignore: cast_nullable_to_non_nullable
              as String,
      lineId: null == lineId
          ? _value.lineId
          : lineId // ignore: cast_nullable_to_non_nullable
              as String,
      lineCode: freezed == lineCode
          ? _value.lineCode
          : lineCode // ignore: cast_nullable_to_non_nullable
              as String?,
      lineName: freezed == lineName
          ? _value.lineName
          : lineName // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      currentProductId: freezed == currentProductId
          ? _value.currentProductId
          : currentProductId // ignore: cast_nullable_to_non_nullable
              as String?,
      productCode: freezed == productCode
          ? _value.productCode
          : productCode // ignore: cast_nullable_to_non_nullable
              as String?,
      productName: freezed == productName
          ? _value.productName
          : productName // ignore: cast_nullable_to_non_nullable
              as String?,
      currentOperator: freezed == currentOperator
          ? _value.currentOperator
          : currentOperator // ignore: cast_nullable_to_non_nullable
              as String?,
      efficiency: null == efficiency
          ? _value.efficiency
          : efficiency // ignore: cast_nullable_to_non_nullable
              as double,
      runtimeSeconds: null == runtimeSeconds
          ? _value.runtimeSeconds
          : runtimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      downtimeSeconds: null == downtimeSeconds
          ? _value.downtimeSeconds
          : downtimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      lastMaintenanceAt: freezed == lastMaintenanceAt
          ? _value.lastMaintenanceAt
          : lastMaintenanceAt // ignore: cast_nullable_to_non_nullable
              as int?,
      nextMaintenanceAt: freezed == nextMaintenanceAt
          ? _value.nextMaintenanceAt
          : nextMaintenanceAt // ignore: cast_nullable_to_non_nullable
              as int?,
      companyId: freezed == companyId
          ? _value.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MachineImpl extends _Machine {
  const _$MachineImpl(
      {required this.id,
      required this.code,
      required this.name,
      required this.machineType,
      required this.lineId,
      this.lineCode,
      this.lineName,
      required this.status,
      this.currentProductId,
      this.productCode,
      this.productName,
      this.currentOperator,
      required this.efficiency,
      required this.runtimeSeconds,
      required this.downtimeSeconds,
      this.lastMaintenanceAt,
      this.nextMaintenanceAt,
      this.companyId,
      required this.createdAt,
      required this.updatedAt})
      : super._();

  factory _$MachineImpl.fromJson(Map<String, dynamic> json) =>
      _$$MachineImplFromJson(json);

  @override
  final String id;
  @override
  final String code;
  @override
  final String name;
  @override
  final String machineType;
  @override
  final String lineId;
  @override
  final String? lineCode;
  @override
  final String? lineName;
  @override
  final String status;
  @override
  final String? currentProductId;
  @override
  final String? productCode;
  @override
  final String? productName;
  @override
  final String? currentOperator;
  @override
  final double efficiency;
  @override
  final int runtimeSeconds;
  @override
  final int downtimeSeconds;
  @override
  final int? lastMaintenanceAt;
  @override
  final int? nextMaintenanceAt;
  @override
  final String? companyId;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'Machine(id: $id, code: $code, name: $name, machineType: $machineType, lineId: $lineId, lineCode: $lineCode, lineName: $lineName, status: $status, currentProductId: $currentProductId, productCode: $productCode, productName: $productName, currentOperator: $currentOperator, efficiency: $efficiency, runtimeSeconds: $runtimeSeconds, downtimeSeconds: $downtimeSeconds, lastMaintenanceAt: $lastMaintenanceAt, nextMaintenanceAt: $nextMaintenanceAt, companyId: $companyId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MachineImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.machineType, machineType) ||
                other.machineType == machineType) &&
            (identical(other.lineId, lineId) || other.lineId == lineId) &&
            (identical(other.lineCode, lineCode) ||
                other.lineCode == lineCode) &&
            (identical(other.lineName, lineName) ||
                other.lineName == lineName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currentProductId, currentProductId) ||
                other.currentProductId == currentProductId) &&
            (identical(other.productCode, productCode) ||
                other.productCode == productCode) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.currentOperator, currentOperator) ||
                other.currentOperator == currentOperator) &&
            (identical(other.efficiency, efficiency) ||
                other.efficiency == efficiency) &&
            (identical(other.runtimeSeconds, runtimeSeconds) ||
                other.runtimeSeconds == runtimeSeconds) &&
            (identical(other.downtimeSeconds, downtimeSeconds) ||
                other.downtimeSeconds == downtimeSeconds) &&
            (identical(other.lastMaintenanceAt, lastMaintenanceAt) ||
                other.lastMaintenanceAt == lastMaintenanceAt) &&
            (identical(other.nextMaintenanceAt, nextMaintenanceAt) ||
                other.nextMaintenanceAt == nextMaintenanceAt) &&
            (identical(other.companyId, companyId) ||
                other.companyId == companyId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        code,
        name,
        machineType,
        lineId,
        lineCode,
        lineName,
        status,
        currentProductId,
        productCode,
        productName,
        currentOperator,
        efficiency,
        runtimeSeconds,
        downtimeSeconds,
        lastMaintenanceAt,
        nextMaintenanceAt,
        companyId,
        createdAt,
        updatedAt
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MachineImplCopyWith<_$MachineImpl> get copyWith =>
      __$$MachineImplCopyWithImpl<_$MachineImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MachineImplToJson(
      this,
    );
  }
}

abstract class _Machine extends Machine {
  const factory _Machine(
      {required final String id,
      required final String code,
      required final String name,
      required final String machineType,
      required final String lineId,
      final String? lineCode,
      final String? lineName,
      required final String status,
      final String? currentProductId,
      final String? productCode,
      final String? productName,
      final String? currentOperator,
      required final double efficiency,
      required final int runtimeSeconds,
      required final int downtimeSeconds,
      final int? lastMaintenanceAt,
      final int? nextMaintenanceAt,
      final String? companyId,
      required final int createdAt,
      required final int updatedAt}) = _$MachineImpl;
  const _Machine._() : super._();

  factory _Machine.fromJson(Map<String, dynamic> json) = _$MachineImpl.fromJson;

  @override
  String get id;
  @override
  String get code;
  @override
  String get name;
  @override
  String get machineType;
  @override
  String get lineId;
  @override
  String? get lineCode;
  @override
  String? get lineName;
  @override
  String get status;
  @override
  String? get currentProductId;
  @override
  String? get productCode;
  @override
  String? get productName;
  @override
  String? get currentOperator;
  @override
  double get efficiency;
  @override
  int get runtimeSeconds;
  @override
  int get downtimeSeconds;
  @override
  int? get lastMaintenanceAt;
  @override
  int? get nextMaintenanceAt;
  @override
  String? get companyId;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$MachineImplCopyWith<_$MachineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MachineDowntime _$MachineDowntimeFromJson(Map<String, dynamic> json) {
  return _MachineDowntime.fromJson(json);
}

/// @nodoc
mixin _$MachineDowntime {
  String get id => throw _privateConstructorUsedError;
  String get machineId => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  int get startTime => throw _privateConstructorUsedError;
  int? get endTime => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  String? get companyId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MachineDowntimeCopyWith<MachineDowntime> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MachineDowntimeCopyWith<$Res> {
  factory $MachineDowntimeCopyWith(
          MachineDowntime value, $Res Function(MachineDowntime) then) =
      _$MachineDowntimeCopyWithImpl<$Res, MachineDowntime>;
  @useResult
  $Res call(
      {String id,
      String machineId,
      String reason,
      int startTime,
      int? endTime,
      int createdAt,
      String? companyId});
}

/// @nodoc
class _$MachineDowntimeCopyWithImpl<$Res, $Val extends MachineDowntime>
    implements $MachineDowntimeCopyWith<$Res> {
  _$MachineDowntimeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? machineId = null,
    Object? reason = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? createdAt = null,
    Object? companyId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      machineId: null == machineId
          ? _value.machineId
          : machineId // ignore: cast_nullable_to_non_nullable
              as String,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as int,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      companyId: freezed == companyId
          ? _value.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MachineDowntimeImplCopyWith<$Res>
    implements $MachineDowntimeCopyWith<$Res> {
  factory _$$MachineDowntimeImplCopyWith(_$MachineDowntimeImpl value,
          $Res Function(_$MachineDowntimeImpl) then) =
      __$$MachineDowntimeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String machineId,
      String reason,
      int startTime,
      int? endTime,
      int createdAt,
      String? companyId});
}

/// @nodoc
class __$$MachineDowntimeImplCopyWithImpl<$Res>
    extends _$MachineDowntimeCopyWithImpl<$Res, _$MachineDowntimeImpl>
    implements _$$MachineDowntimeImplCopyWith<$Res> {
  __$$MachineDowntimeImplCopyWithImpl(
      _$MachineDowntimeImpl _value, $Res Function(_$MachineDowntimeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? machineId = null,
    Object? reason = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? createdAt = null,
    Object? companyId = freezed,
  }) {
    return _then(_$MachineDowntimeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      machineId: null == machineId
          ? _value.machineId
          : machineId // ignore: cast_nullable_to_non_nullable
              as String,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as int,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      companyId: freezed == companyId
          ? _value.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MachineDowntimeImpl implements _MachineDowntime {
  const _$MachineDowntimeImpl(
      {required this.id,
      required this.machineId,
      required this.reason,
      required this.startTime,
      this.endTime,
      required this.createdAt,
      this.companyId});

  factory _$MachineDowntimeImpl.fromJson(Map<String, dynamic> json) =>
      _$$MachineDowntimeImplFromJson(json);

  @override
  final String id;
  @override
  final String machineId;
  @override
  final String reason;
  @override
  final int startTime;
  @override
  final int? endTime;
  @override
  final int createdAt;
  @override
  final String? companyId;

  @override
  String toString() {
    return 'MachineDowntime(id: $id, machineId: $machineId, reason: $reason, startTime: $startTime, endTime: $endTime, createdAt: $createdAt, companyId: $companyId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MachineDowntimeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.machineId, machineId) ||
                other.machineId == machineId) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.companyId, companyId) ||
                other.companyId == companyId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, machineId, reason, startTime,
      endTime, createdAt, companyId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MachineDowntimeImplCopyWith<_$MachineDowntimeImpl> get copyWith =>
      __$$MachineDowntimeImplCopyWithImpl<_$MachineDowntimeImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MachineDowntimeImplToJson(
      this,
    );
  }
}

abstract class _MachineDowntime implements MachineDowntime {
  const factory _MachineDowntime(
      {required final String id,
      required final String machineId,
      required final String reason,
      required final int startTime,
      final int? endTime,
      required final int createdAt,
      final String? companyId}) = _$MachineDowntimeImpl;

  factory _MachineDowntime.fromJson(Map<String, dynamic> json) =
      _$MachineDowntimeImpl.fromJson;

  @override
  String get id;
  @override
  String get machineId;
  @override
  String get reason;
  @override
  int get startTime;
  @override
  int? get endTime;
  @override
  int get createdAt;
  @override
  String? get companyId;
  @override
  @JsonKey(ignore: true)
  _$$MachineDowntimeImplCopyWith<_$MachineDowntimeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProductionLine _$ProductionLineFromJson(Map<String, dynamic> json) {
  return _ProductionLine.fromJson(json);
}

/// @nodoc
mixin _$ProductionLine {
  String get id => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get companyId => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProductionLineCopyWith<ProductionLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductionLineCopyWith<$Res> {
  factory $ProductionLineCopyWith(
          ProductionLine value, $Res Function(ProductionLine) then) =
      _$ProductionLineCopyWithImpl<$Res, ProductionLine>;
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      String? description,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$ProductionLineCopyWithImpl<$Res, $Val extends ProductionLine>
    implements $ProductionLineCopyWith<$Res> {
  _$ProductionLineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? description = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      companyId: freezed == companyId
          ? _value.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProductionLineImplCopyWith<$Res>
    implements $ProductionLineCopyWith<$Res> {
  factory _$$ProductionLineImplCopyWith(_$ProductionLineImpl value,
          $Res Function(_$ProductionLineImpl) then) =
      __$$ProductionLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      String? description,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$ProductionLineImplCopyWithImpl<$Res>
    extends _$ProductionLineCopyWithImpl<$Res, _$ProductionLineImpl>
    implements _$$ProductionLineImplCopyWith<$Res> {
  __$$ProductionLineImplCopyWithImpl(
      _$ProductionLineImpl _value, $Res Function(_$ProductionLineImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? description = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ProductionLineImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      companyId: freezed == companyId
          ? _value.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductionLineImpl implements _ProductionLine {
  const _$ProductionLineImpl(
      {required this.id,
      required this.code,
      required this.name,
      this.description,
      this.companyId,
      required this.createdAt,
      required this.updatedAt});

  factory _$ProductionLineImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductionLineImplFromJson(json);

  @override
  final String id;
  @override
  final String code;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String? companyId;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'ProductionLine(id: $id, code: $code, name: $name, description: $description, companyId: $companyId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductionLineImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.companyId, companyId) ||
                other.companyId == companyId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, code, name, description,
      companyId, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductionLineImplCopyWith<_$ProductionLineImpl> get copyWith =>
      __$$ProductionLineImplCopyWithImpl<_$ProductionLineImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductionLineImplToJson(
      this,
    );
  }
}

abstract class _ProductionLine implements ProductionLine {
  const factory _ProductionLine(
      {required final String id,
      required final String code,
      required final String name,
      final String? description,
      final String? companyId,
      required final int createdAt,
      required final int updatedAt}) = _$ProductionLineImpl;

  factory _ProductionLine.fromJson(Map<String, dynamic> json) =
      _$ProductionLineImpl.fromJson;

  @override
  String get id;
  @override
  String get code;
  @override
  String get name;
  @override
  String? get description;
  @override
  String? get companyId;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ProductionLineImplCopyWith<_$ProductionLineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
