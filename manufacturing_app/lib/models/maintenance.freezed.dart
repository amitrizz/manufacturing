// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maintenance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MaintenanceOrder _$MaintenanceOrderFromJson(Map<String, dynamic> json) {
  return _MaintenanceOrder.fromJson(json);
}

/// @nodoc
mixin _$MaintenanceOrder {
  String get id => throw _privateConstructorUsedError;
  String get machineId => throw _privateConstructorUsedError;
  String? get machineCode => throw _privateConstructorUsedError;
  String get orderType => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get assignedTo => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int? get scheduledDate => throw _privateConstructorUsedError;
  int? get completedAt => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MaintenanceOrderCopyWith<MaintenanceOrder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaintenanceOrderCopyWith<$Res> {
  factory $MaintenanceOrderCopyWith(
          MaintenanceOrder value, $Res Function(MaintenanceOrder) then) =
      _$MaintenanceOrderCopyWithImpl<$Res, MaintenanceOrder>;
  @useResult
  $Res call(
      {String id,
      String machineId,
      String? machineCode,
      String orderType,
      String priority,
      String status,
      String? assignedTo,
      String description,
      int? scheduledDate,
      int? completedAt,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$MaintenanceOrderCopyWithImpl<$Res, $Val extends MaintenanceOrder>
    implements $MaintenanceOrderCopyWith<$Res> {
  _$MaintenanceOrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? machineId = null,
    Object? machineCode = freezed,
    Object? orderType = null,
    Object? priority = null,
    Object? status = null,
    Object? assignedTo = freezed,
    Object? description = null,
    Object? scheduledDate = freezed,
    Object? completedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
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
      machineCode: freezed == machineCode
          ? _value.machineCode
          : machineCode // ignore: cast_nullable_to_non_nullable
              as String?,
      orderType: null == orderType
          ? _value.orderType
          : orderType // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      assignedTo: freezed == assignedTo
          ? _value.assignedTo
          : assignedTo // ignore: cast_nullable_to_non_nullable
              as String?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      scheduledDate: freezed == scheduledDate
          ? _value.scheduledDate
          : scheduledDate // ignore: cast_nullable_to_non_nullable
              as int?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as int?,
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
abstract class _$$MaintenanceOrderImplCopyWith<$Res>
    implements $MaintenanceOrderCopyWith<$Res> {
  factory _$$MaintenanceOrderImplCopyWith(_$MaintenanceOrderImpl value,
          $Res Function(_$MaintenanceOrderImpl) then) =
      __$$MaintenanceOrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String machineId,
      String? machineCode,
      String orderType,
      String priority,
      String status,
      String? assignedTo,
      String description,
      int? scheduledDate,
      int? completedAt,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$MaintenanceOrderImplCopyWithImpl<$Res>
    extends _$MaintenanceOrderCopyWithImpl<$Res, _$MaintenanceOrderImpl>
    implements _$$MaintenanceOrderImplCopyWith<$Res> {
  __$$MaintenanceOrderImplCopyWithImpl(_$MaintenanceOrderImpl _value,
      $Res Function(_$MaintenanceOrderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? machineId = null,
    Object? machineCode = freezed,
    Object? orderType = null,
    Object? priority = null,
    Object? status = null,
    Object? assignedTo = freezed,
    Object? description = null,
    Object? scheduledDate = freezed,
    Object? completedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$MaintenanceOrderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      machineId: null == machineId
          ? _value.machineId
          : machineId // ignore: cast_nullable_to_non_nullable
              as String,
      machineCode: freezed == machineCode
          ? _value.machineCode
          : machineCode // ignore: cast_nullable_to_non_nullable
              as String?,
      orderType: null == orderType
          ? _value.orderType
          : orderType // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      assignedTo: freezed == assignedTo
          ? _value.assignedTo
          : assignedTo // ignore: cast_nullable_to_non_nullable
              as String?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      scheduledDate: freezed == scheduledDate
          ? _value.scheduledDate
          : scheduledDate // ignore: cast_nullable_to_non_nullable
              as int?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as int?,
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
class _$MaintenanceOrderImpl extends _MaintenanceOrder {
  const _$MaintenanceOrderImpl(
      {required this.id,
      required this.machineId,
      this.machineCode,
      required this.orderType,
      required this.priority,
      required this.status,
      this.assignedTo,
      required this.description,
      this.scheduledDate,
      this.completedAt,
      required this.createdAt,
      required this.updatedAt})
      : super._();

  factory _$MaintenanceOrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaintenanceOrderImplFromJson(json);

  @override
  final String id;
  @override
  final String machineId;
  @override
  final String? machineCode;
  @override
  final String orderType;
  @override
  final String priority;
  @override
  final String status;
  @override
  final String? assignedTo;
  @override
  final String description;
  @override
  final int? scheduledDate;
  @override
  final int? completedAt;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'MaintenanceOrder(id: $id, machineId: $machineId, machineCode: $machineCode, orderType: $orderType, priority: $priority, status: $status, assignedTo: $assignedTo, description: $description, scheduledDate: $scheduledDate, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaintenanceOrderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.machineId, machineId) ||
                other.machineId == machineId) &&
            (identical(other.machineCode, machineCode) ||
                other.machineCode == machineCode) &&
            (identical(other.orderType, orderType) ||
                other.orderType == orderType) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.assignedTo, assignedTo) ||
                other.assignedTo == assignedTo) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.scheduledDate, scheduledDate) ||
                other.scheduledDate == scheduledDate) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      machineId,
      machineCode,
      orderType,
      priority,
      status,
      assignedTo,
      description,
      scheduledDate,
      completedAt,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MaintenanceOrderImplCopyWith<_$MaintenanceOrderImpl> get copyWith =>
      __$$MaintenanceOrderImplCopyWithImpl<_$MaintenanceOrderImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MaintenanceOrderImplToJson(
      this,
    );
  }
}

abstract class _MaintenanceOrder extends MaintenanceOrder {
  const factory _MaintenanceOrder(
      {required final String id,
      required final String machineId,
      final String? machineCode,
      required final String orderType,
      required final String priority,
      required final String status,
      final String? assignedTo,
      required final String description,
      final int? scheduledDate,
      final int? completedAt,
      required final int createdAt,
      required final int updatedAt}) = _$MaintenanceOrderImpl;
  const _MaintenanceOrder._() : super._();

  factory _MaintenanceOrder.fromJson(Map<String, dynamic> json) =
      _$MaintenanceOrderImpl.fromJson;

  @override
  String get id;
  @override
  String get machineId;
  @override
  String? get machineCode;
  @override
  String get orderType;
  @override
  String get priority;
  @override
  String get status;
  @override
  String? get assignedTo;
  @override
  String get description;
  @override
  int? get scheduledDate;
  @override
  int? get completedAt;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$MaintenanceOrderImplCopyWith<_$MaintenanceOrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MaintenanceHistory _$MaintenanceHistoryFromJson(Map<String, dynamic> json) {
  return _MaintenanceHistory.fromJson(json);
}

/// @nodoc
mixin _$MaintenanceHistory {
  String get id => throw _privateConstructorUsedError;
  String get machineId => throw _privateConstructorUsedError;
  String? get maintenanceOrderId => throw _privateConstructorUsedError;
  int get performedAt => throw _privateConstructorUsedError;
  String get summary => throw _privateConstructorUsedError;
  double? get cost => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MaintenanceHistoryCopyWith<MaintenanceHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaintenanceHistoryCopyWith<$Res> {
  factory $MaintenanceHistoryCopyWith(
          MaintenanceHistory value, $Res Function(MaintenanceHistory) then) =
      _$MaintenanceHistoryCopyWithImpl<$Res, MaintenanceHistory>;
  @useResult
  $Res call(
      {String id,
      String machineId,
      String? maintenanceOrderId,
      int performedAt,
      String summary,
      double? cost,
      int createdAt});
}

/// @nodoc
class _$MaintenanceHistoryCopyWithImpl<$Res, $Val extends MaintenanceHistory>
    implements $MaintenanceHistoryCopyWith<$Res> {
  _$MaintenanceHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? machineId = null,
    Object? maintenanceOrderId = freezed,
    Object? performedAt = null,
    Object? summary = null,
    Object? cost = freezed,
    Object? createdAt = null,
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
      maintenanceOrderId: freezed == maintenanceOrderId
          ? _value.maintenanceOrderId
          : maintenanceOrderId // ignore: cast_nullable_to_non_nullable
              as String?,
      performedAt: null == performedAt
          ? _value.performedAt
          : performedAt // ignore: cast_nullable_to_non_nullable
              as int,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String,
      cost: freezed == cost
          ? _value.cost
          : cost // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MaintenanceHistoryImplCopyWith<$Res>
    implements $MaintenanceHistoryCopyWith<$Res> {
  factory _$$MaintenanceHistoryImplCopyWith(_$MaintenanceHistoryImpl value,
          $Res Function(_$MaintenanceHistoryImpl) then) =
      __$$MaintenanceHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String machineId,
      String? maintenanceOrderId,
      int performedAt,
      String summary,
      double? cost,
      int createdAt});
}

/// @nodoc
class __$$MaintenanceHistoryImplCopyWithImpl<$Res>
    extends _$MaintenanceHistoryCopyWithImpl<$Res, _$MaintenanceHistoryImpl>
    implements _$$MaintenanceHistoryImplCopyWith<$Res> {
  __$$MaintenanceHistoryImplCopyWithImpl(_$MaintenanceHistoryImpl _value,
      $Res Function(_$MaintenanceHistoryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? machineId = null,
    Object? maintenanceOrderId = freezed,
    Object? performedAt = null,
    Object? summary = null,
    Object? cost = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$MaintenanceHistoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      machineId: null == machineId
          ? _value.machineId
          : machineId // ignore: cast_nullable_to_non_nullable
              as String,
      maintenanceOrderId: freezed == maintenanceOrderId
          ? _value.maintenanceOrderId
          : maintenanceOrderId // ignore: cast_nullable_to_non_nullable
              as String?,
      performedAt: null == performedAt
          ? _value.performedAt
          : performedAt // ignore: cast_nullable_to_non_nullable
              as int,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String,
      cost: freezed == cost
          ? _value.cost
          : cost // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MaintenanceHistoryImpl implements _MaintenanceHistory {
  const _$MaintenanceHistoryImpl(
      {required this.id,
      required this.machineId,
      this.maintenanceOrderId,
      required this.performedAt,
      required this.summary,
      this.cost,
      required this.createdAt});

  factory _$MaintenanceHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaintenanceHistoryImplFromJson(json);

  @override
  final String id;
  @override
  final String machineId;
  @override
  final String? maintenanceOrderId;
  @override
  final int performedAt;
  @override
  final String summary;
  @override
  final double? cost;
  @override
  final int createdAt;

  @override
  String toString() {
    return 'MaintenanceHistory(id: $id, machineId: $machineId, maintenanceOrderId: $maintenanceOrderId, performedAt: $performedAt, summary: $summary, cost: $cost, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaintenanceHistoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.machineId, machineId) ||
                other.machineId == machineId) &&
            (identical(other.maintenanceOrderId, maintenanceOrderId) ||
                other.maintenanceOrderId == maintenanceOrderId) &&
            (identical(other.performedAt, performedAt) ||
                other.performedAt == performedAt) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, machineId,
      maintenanceOrderId, performedAt, summary, cost, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MaintenanceHistoryImplCopyWith<_$MaintenanceHistoryImpl> get copyWith =>
      __$$MaintenanceHistoryImplCopyWithImpl<_$MaintenanceHistoryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MaintenanceHistoryImplToJson(
      this,
    );
  }
}

abstract class _MaintenanceHistory implements MaintenanceHistory {
  const factory _MaintenanceHistory(
      {required final String id,
      required final String machineId,
      final String? maintenanceOrderId,
      required final int performedAt,
      required final String summary,
      final double? cost,
      required final int createdAt}) = _$MaintenanceHistoryImpl;

  factory _MaintenanceHistory.fromJson(Map<String, dynamic> json) =
      _$MaintenanceHistoryImpl.fromJson;

  @override
  String get id;
  @override
  String get machineId;
  @override
  String? get maintenanceOrderId;
  @override
  int get performedAt;
  @override
  String get summary;
  @override
  double? get cost;
  @override
  int get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$MaintenanceHistoryImplCopyWith<_$MaintenanceHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
