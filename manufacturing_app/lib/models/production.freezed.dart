// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'production.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProductionPlan _$ProductionPlanFromJson(Map<String, dynamic> json) {
  return _ProductionPlan.fromJson(json);
}

/// @nodoc
mixin _$ProductionPlan {
  String get id => throw _privateConstructorUsedError;
  String get planNumber => throw _privateConstructorUsedError;
  String get productId => throw _privateConstructorUsedError;
  String? get productCode => throw _privateConstructorUsedError;
  String? get productName => throw _privateConstructorUsedError;
  double get targetQuantity => throw _privateConstructorUsedError;
  String get lineId => throw _privateConstructorUsedError;
  String? get lineCode => throw _privateConstructorUsedError;
  int get startDate => throw _privateConstructorUsedError;
  int get expectedCompletion => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get companyId => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProductionPlanCopyWith<ProductionPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductionPlanCopyWith<$Res> {
  factory $ProductionPlanCopyWith(
          ProductionPlan value, $Res Function(ProductionPlan) then) =
      _$ProductionPlanCopyWithImpl<$Res, ProductionPlan>;
  @useResult
  $Res call(
      {String id,
      String planNumber,
      String productId,
      String? productCode,
      String? productName,
      double targetQuantity,
      String lineId,
      String? lineCode,
      int startDate,
      int expectedCompletion,
      String priority,
      String status,
      String? notes,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$ProductionPlanCopyWithImpl<$Res, $Val extends ProductionPlan>
    implements $ProductionPlanCopyWith<$Res> {
  _$ProductionPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planNumber = null,
    Object? productId = null,
    Object? productCode = freezed,
    Object? productName = freezed,
    Object? targetQuantity = null,
    Object? lineId = null,
    Object? lineCode = freezed,
    Object? startDate = null,
    Object? expectedCompletion = null,
    Object? priority = null,
    Object? status = null,
    Object? notes = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      planNumber: null == planNumber
          ? _value.planNumber
          : planNumber // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      productCode: freezed == productCode
          ? _value.productCode
          : productCode // ignore: cast_nullable_to_non_nullable
              as String?,
      productName: freezed == productName
          ? _value.productName
          : productName // ignore: cast_nullable_to_non_nullable
              as String?,
      targetQuantity: null == targetQuantity
          ? _value.targetQuantity
          : targetQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      lineId: null == lineId
          ? _value.lineId
          : lineId // ignore: cast_nullable_to_non_nullable
              as String,
      lineCode: freezed == lineCode
          ? _value.lineCode
          : lineCode // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as int,
      expectedCompletion: null == expectedCompletion
          ? _value.expectedCompletion
          : expectedCompletion // ignore: cast_nullable_to_non_nullable
              as int,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ProductionPlanImplCopyWith<$Res>
    implements $ProductionPlanCopyWith<$Res> {
  factory _$$ProductionPlanImplCopyWith(_$ProductionPlanImpl value,
          $Res Function(_$ProductionPlanImpl) then) =
      __$$ProductionPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String planNumber,
      String productId,
      String? productCode,
      String? productName,
      double targetQuantity,
      String lineId,
      String? lineCode,
      int startDate,
      int expectedCompletion,
      String priority,
      String status,
      String? notes,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$ProductionPlanImplCopyWithImpl<$Res>
    extends _$ProductionPlanCopyWithImpl<$Res, _$ProductionPlanImpl>
    implements _$$ProductionPlanImplCopyWith<$Res> {
  __$$ProductionPlanImplCopyWithImpl(
      _$ProductionPlanImpl _value, $Res Function(_$ProductionPlanImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planNumber = null,
    Object? productId = null,
    Object? productCode = freezed,
    Object? productName = freezed,
    Object? targetQuantity = null,
    Object? lineId = null,
    Object? lineCode = freezed,
    Object? startDate = null,
    Object? expectedCompletion = null,
    Object? priority = null,
    Object? status = null,
    Object? notes = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ProductionPlanImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      planNumber: null == planNumber
          ? _value.planNumber
          : planNumber // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      productCode: freezed == productCode
          ? _value.productCode
          : productCode // ignore: cast_nullable_to_non_nullable
              as String?,
      productName: freezed == productName
          ? _value.productName
          : productName // ignore: cast_nullable_to_non_nullable
              as String?,
      targetQuantity: null == targetQuantity
          ? _value.targetQuantity
          : targetQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      lineId: null == lineId
          ? _value.lineId
          : lineId // ignore: cast_nullable_to_non_nullable
              as String,
      lineCode: freezed == lineCode
          ? _value.lineCode
          : lineCode // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as int,
      expectedCompletion: null == expectedCompletion
          ? _value.expectedCompletion
          : expectedCompletion // ignore: cast_nullable_to_non_nullable
              as int,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
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
class _$ProductionPlanImpl implements _ProductionPlan {
  const _$ProductionPlanImpl(
      {required this.id,
      required this.planNumber,
      required this.productId,
      this.productCode,
      this.productName,
      required this.targetQuantity,
      required this.lineId,
      this.lineCode,
      required this.startDate,
      required this.expectedCompletion,
      required this.priority,
      required this.status,
      this.notes,
      this.companyId,
      required this.createdAt,
      required this.updatedAt});

  factory _$ProductionPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductionPlanImplFromJson(json);

  @override
  final String id;
  @override
  final String planNumber;
  @override
  final String productId;
  @override
  final String? productCode;
  @override
  final String? productName;
  @override
  final double targetQuantity;
  @override
  final String lineId;
  @override
  final String? lineCode;
  @override
  final int startDate;
  @override
  final int expectedCompletion;
  @override
  final String priority;
  @override
  final String status;
  @override
  final String? notes;
  @override
  final String? companyId;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'ProductionPlan(id: $id, planNumber: $planNumber, productId: $productId, productCode: $productCode, productName: $productName, targetQuantity: $targetQuantity, lineId: $lineId, lineCode: $lineCode, startDate: $startDate, expectedCompletion: $expectedCompletion, priority: $priority, status: $status, notes: $notes, companyId: $companyId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductionPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.planNumber, planNumber) ||
                other.planNumber == planNumber) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.productCode, productCode) ||
                other.productCode == productCode) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.targetQuantity, targetQuantity) ||
                other.targetQuantity == targetQuantity) &&
            (identical(other.lineId, lineId) || other.lineId == lineId) &&
            (identical(other.lineCode, lineCode) ||
                other.lineCode == lineCode) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.expectedCompletion, expectedCompletion) ||
                other.expectedCompletion == expectedCompletion) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.companyId, companyId) ||
                other.companyId == companyId) &&
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
      planNumber,
      productId,
      productCode,
      productName,
      targetQuantity,
      lineId,
      lineCode,
      startDate,
      expectedCompletion,
      priority,
      status,
      notes,
      companyId,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductionPlanImplCopyWith<_$ProductionPlanImpl> get copyWith =>
      __$$ProductionPlanImplCopyWithImpl<_$ProductionPlanImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductionPlanImplToJson(
      this,
    );
  }
}

abstract class _ProductionPlan implements ProductionPlan {
  const factory _ProductionPlan(
      {required final String id,
      required final String planNumber,
      required final String productId,
      final String? productCode,
      final String? productName,
      required final double targetQuantity,
      required final String lineId,
      final String? lineCode,
      required final int startDate,
      required final int expectedCompletion,
      required final String priority,
      required final String status,
      final String? notes,
      final String? companyId,
      required final int createdAt,
      required final int updatedAt}) = _$ProductionPlanImpl;

  factory _ProductionPlan.fromJson(Map<String, dynamic> json) =
      _$ProductionPlanImpl.fromJson;

  @override
  String get id;
  @override
  String get planNumber;
  @override
  String get productId;
  @override
  String? get productCode;
  @override
  String? get productName;
  @override
  double get targetQuantity;
  @override
  String get lineId;
  @override
  String? get lineCode;
  @override
  int get startDate;
  @override
  int get expectedCompletion;
  @override
  String get priority;
  @override
  String get status;
  @override
  String? get notes;
  @override
  String? get companyId;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ProductionPlanImplCopyWith<_$ProductionPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProductionOrder _$ProductionOrderFromJson(Map<String, dynamic> json) {
  return _ProductionOrder.fromJson(json);
}

/// @nodoc
mixin _$ProductionOrder {
  String get id => throw _privateConstructorUsedError;
  String get orderNumber => throw _privateConstructorUsedError;
  String? get planId => throw _privateConstructorUsedError;
  String get productId => throw _privateConstructorUsedError;
  String? get productCode => throw _privateConstructorUsedError;
  String? get productName => throw _privateConstructorUsedError;
  String get lineId => throw _privateConstructorUsedError;
  String? get lineCode => throw _privateConstructorUsedError;
  String? get machineId => throw _privateConstructorUsedError;
  String? get machineCode => throw _privateConstructorUsedError;
  List<String>? get assignedMachines => throw _privateConstructorUsedError;
  List<String>? get assignedWorkers => throw _privateConstructorUsedError;
  double get targetQuantity => throw _privateConstructorUsedError;
  double get producedQuantity => throw _privateConstructorUsedError;
  double get rejectedQuantity => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get qcStatus => throw _privateConstructorUsedError;
  String? get qcNotes => throw _privateConstructorUsedError;
  int? get qcInspectedAt => throw _privateConstructorUsedError;
  String? get qcInspector => throw _privateConstructorUsedError;
  int? get startDate => throw _privateConstructorUsedError;
  int? get dueDate => throw _privateConstructorUsedError;
  int? get startedAt => throw _privateConstructorUsedError;
  int? get completedAt => throw _privateConstructorUsedError;
  String? get companyId => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProductionOrderCopyWith<ProductionOrder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductionOrderCopyWith<$Res> {
  factory $ProductionOrderCopyWith(
          ProductionOrder value, $Res Function(ProductionOrder) then) =
      _$ProductionOrderCopyWithImpl<$Res, ProductionOrder>;
  @useResult
  $Res call(
      {String id,
      String orderNumber,
      String? planId,
      String productId,
      String? productCode,
      String? productName,
      String lineId,
      String? lineCode,
      String? machineId,
      String? machineCode,
      List<String>? assignedMachines,
      List<String>? assignedWorkers,
      double targetQuantity,
      double producedQuantity,
      double rejectedQuantity,
      String priority,
      String status,
      String? qcStatus,
      String? qcNotes,
      int? qcInspectedAt,
      String? qcInspector,
      int? startDate,
      int? dueDate,
      int? startedAt,
      int? completedAt,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$ProductionOrderCopyWithImpl<$Res, $Val extends ProductionOrder>
    implements $ProductionOrderCopyWith<$Res> {
  _$ProductionOrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderNumber = null,
    Object? planId = freezed,
    Object? productId = null,
    Object? productCode = freezed,
    Object? productName = freezed,
    Object? lineId = null,
    Object? lineCode = freezed,
    Object? machineId = freezed,
    Object? machineCode = freezed,
    Object? assignedMachines = freezed,
    Object? assignedWorkers = freezed,
    Object? targetQuantity = null,
    Object? producedQuantity = null,
    Object? rejectedQuantity = null,
    Object? priority = null,
    Object? status = null,
    Object? qcStatus = freezed,
    Object? qcNotes = freezed,
    Object? qcInspectedAt = freezed,
    Object? qcInspector = freezed,
    Object? startDate = freezed,
    Object? dueDate = freezed,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      planId: freezed == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String?,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      productCode: freezed == productCode
          ? _value.productCode
          : productCode // ignore: cast_nullable_to_non_nullable
              as String?,
      productName: freezed == productName
          ? _value.productName
          : productName // ignore: cast_nullable_to_non_nullable
              as String?,
      lineId: null == lineId
          ? _value.lineId
          : lineId // ignore: cast_nullable_to_non_nullable
              as String,
      lineCode: freezed == lineCode
          ? _value.lineCode
          : lineCode // ignore: cast_nullable_to_non_nullable
              as String?,
      machineId: freezed == machineId
          ? _value.machineId
          : machineId // ignore: cast_nullable_to_non_nullable
              as String?,
      machineCode: freezed == machineCode
          ? _value.machineCode
          : machineCode // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedMachines: freezed == assignedMachines
          ? _value.assignedMachines
          : assignedMachines // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      assignedWorkers: freezed == assignedWorkers
          ? _value.assignedWorkers
          : assignedWorkers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      targetQuantity: null == targetQuantity
          ? _value.targetQuantity
          : targetQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      producedQuantity: null == producedQuantity
          ? _value.producedQuantity
          : producedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      rejectedQuantity: null == rejectedQuantity
          ? _value.rejectedQuantity
          : rejectedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      qcStatus: freezed == qcStatus
          ? _value.qcStatus
          : qcStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      qcNotes: freezed == qcNotes
          ? _value.qcNotes
          : qcNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      qcInspectedAt: freezed == qcInspectedAt
          ? _value.qcInspectedAt
          : qcInspectedAt // ignore: cast_nullable_to_non_nullable
              as int?,
      qcInspector: freezed == qcInspector
          ? _value.qcInspector
          : qcInspector // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as int?,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as int?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as int?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ProductionOrderImplCopyWith<$Res>
    implements $ProductionOrderCopyWith<$Res> {
  factory _$$ProductionOrderImplCopyWith(_$ProductionOrderImpl value,
          $Res Function(_$ProductionOrderImpl) then) =
      __$$ProductionOrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String orderNumber,
      String? planId,
      String productId,
      String? productCode,
      String? productName,
      String lineId,
      String? lineCode,
      String? machineId,
      String? machineCode,
      List<String>? assignedMachines,
      List<String>? assignedWorkers,
      double targetQuantity,
      double producedQuantity,
      double rejectedQuantity,
      String priority,
      String status,
      String? qcStatus,
      String? qcNotes,
      int? qcInspectedAt,
      String? qcInspector,
      int? startDate,
      int? dueDate,
      int? startedAt,
      int? completedAt,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$ProductionOrderImplCopyWithImpl<$Res>
    extends _$ProductionOrderCopyWithImpl<$Res, _$ProductionOrderImpl>
    implements _$$ProductionOrderImplCopyWith<$Res> {
  __$$ProductionOrderImplCopyWithImpl(
      _$ProductionOrderImpl _value, $Res Function(_$ProductionOrderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderNumber = null,
    Object? planId = freezed,
    Object? productId = null,
    Object? productCode = freezed,
    Object? productName = freezed,
    Object? lineId = null,
    Object? lineCode = freezed,
    Object? machineId = freezed,
    Object? machineCode = freezed,
    Object? assignedMachines = freezed,
    Object? assignedWorkers = freezed,
    Object? targetQuantity = null,
    Object? producedQuantity = null,
    Object? rejectedQuantity = null,
    Object? priority = null,
    Object? status = null,
    Object? qcStatus = freezed,
    Object? qcNotes = freezed,
    Object? qcInspectedAt = freezed,
    Object? qcInspector = freezed,
    Object? startDate = freezed,
    Object? dueDate = freezed,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ProductionOrderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      planId: freezed == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String?,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      productCode: freezed == productCode
          ? _value.productCode
          : productCode // ignore: cast_nullable_to_non_nullable
              as String?,
      productName: freezed == productName
          ? _value.productName
          : productName // ignore: cast_nullable_to_non_nullable
              as String?,
      lineId: null == lineId
          ? _value.lineId
          : lineId // ignore: cast_nullable_to_non_nullable
              as String,
      lineCode: freezed == lineCode
          ? _value.lineCode
          : lineCode // ignore: cast_nullable_to_non_nullable
              as String?,
      machineId: freezed == machineId
          ? _value.machineId
          : machineId // ignore: cast_nullable_to_non_nullable
              as String?,
      machineCode: freezed == machineCode
          ? _value.machineCode
          : machineCode // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedMachines: freezed == assignedMachines
          ? _value._assignedMachines
          : assignedMachines // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      assignedWorkers: freezed == assignedWorkers
          ? _value._assignedWorkers
          : assignedWorkers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      targetQuantity: null == targetQuantity
          ? _value.targetQuantity
          : targetQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      producedQuantity: null == producedQuantity
          ? _value.producedQuantity
          : producedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      rejectedQuantity: null == rejectedQuantity
          ? _value.rejectedQuantity
          : rejectedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      qcStatus: freezed == qcStatus
          ? _value.qcStatus
          : qcStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      qcNotes: freezed == qcNotes
          ? _value.qcNotes
          : qcNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      qcInspectedAt: freezed == qcInspectedAt
          ? _value.qcInspectedAt
          : qcInspectedAt // ignore: cast_nullable_to_non_nullable
              as int?,
      qcInspector: freezed == qcInspector
          ? _value.qcInspector
          : qcInspector // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as int?,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as int?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as int?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
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
class _$ProductionOrderImpl extends _ProductionOrder {
  const _$ProductionOrderImpl(
      {required this.id,
      required this.orderNumber,
      this.planId,
      required this.productId,
      this.productCode,
      this.productName,
      required this.lineId,
      this.lineCode,
      this.machineId,
      this.machineCode,
      final List<String>? assignedMachines,
      final List<String>? assignedWorkers,
      required this.targetQuantity,
      required this.producedQuantity,
      required this.rejectedQuantity,
      required this.priority,
      required this.status,
      this.qcStatus,
      this.qcNotes,
      this.qcInspectedAt,
      this.qcInspector,
      this.startDate,
      this.dueDate,
      this.startedAt,
      this.completedAt,
      this.companyId,
      required this.createdAt,
      required this.updatedAt})
      : _assignedMachines = assignedMachines,
        _assignedWorkers = assignedWorkers,
        super._();

  factory _$ProductionOrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductionOrderImplFromJson(json);

  @override
  final String id;
  @override
  final String orderNumber;
  @override
  final String? planId;
  @override
  final String productId;
  @override
  final String? productCode;
  @override
  final String? productName;
  @override
  final String lineId;
  @override
  final String? lineCode;
  @override
  final String? machineId;
  @override
  final String? machineCode;
  final List<String>? _assignedMachines;
  @override
  List<String>? get assignedMachines {
    final value = _assignedMachines;
    if (value == null) return null;
    if (_assignedMachines is EqualUnmodifiableListView)
      return _assignedMachines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _assignedWorkers;
  @override
  List<String>? get assignedWorkers {
    final value = _assignedWorkers;
    if (value == null) return null;
    if (_assignedWorkers is EqualUnmodifiableListView) return _assignedWorkers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final double targetQuantity;
  @override
  final double producedQuantity;
  @override
  final double rejectedQuantity;
  @override
  final String priority;
  @override
  final String status;
  @override
  final String? qcStatus;
  @override
  final String? qcNotes;
  @override
  final int? qcInspectedAt;
  @override
  final String? qcInspector;
  @override
  final int? startDate;
  @override
  final int? dueDate;
  @override
  final int? startedAt;
  @override
  final int? completedAt;
  @override
  final String? companyId;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'ProductionOrder(id: $id, orderNumber: $orderNumber, planId: $planId, productId: $productId, productCode: $productCode, productName: $productName, lineId: $lineId, lineCode: $lineCode, machineId: $machineId, machineCode: $machineCode, assignedMachines: $assignedMachines, assignedWorkers: $assignedWorkers, targetQuantity: $targetQuantity, producedQuantity: $producedQuantity, rejectedQuantity: $rejectedQuantity, priority: $priority, status: $status, qcStatus: $qcStatus, qcNotes: $qcNotes, qcInspectedAt: $qcInspectedAt, qcInspector: $qcInspector, startDate: $startDate, dueDate: $dueDate, startedAt: $startedAt, completedAt: $completedAt, companyId: $companyId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductionOrderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.productCode, productCode) ||
                other.productCode == productCode) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.lineId, lineId) || other.lineId == lineId) &&
            (identical(other.lineCode, lineCode) ||
                other.lineCode == lineCode) &&
            (identical(other.machineId, machineId) ||
                other.machineId == machineId) &&
            (identical(other.machineCode, machineCode) ||
                other.machineCode == machineCode) &&
            const DeepCollectionEquality()
                .equals(other._assignedMachines, _assignedMachines) &&
            const DeepCollectionEquality()
                .equals(other._assignedWorkers, _assignedWorkers) &&
            (identical(other.targetQuantity, targetQuantity) ||
                other.targetQuantity == targetQuantity) &&
            (identical(other.producedQuantity, producedQuantity) ||
                other.producedQuantity == producedQuantity) &&
            (identical(other.rejectedQuantity, rejectedQuantity) ||
                other.rejectedQuantity == rejectedQuantity) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.qcStatus, qcStatus) ||
                other.qcStatus == qcStatus) &&
            (identical(other.qcNotes, qcNotes) || other.qcNotes == qcNotes) &&
            (identical(other.qcInspectedAt, qcInspectedAt) ||
                other.qcInspectedAt == qcInspectedAt) &&
            (identical(other.qcInspector, qcInspector) ||
                other.qcInspector == qcInspector) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
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
        orderNumber,
        planId,
        productId,
        productCode,
        productName,
        lineId,
        lineCode,
        machineId,
        machineCode,
        const DeepCollectionEquality().hash(_assignedMachines),
        const DeepCollectionEquality().hash(_assignedWorkers),
        targetQuantity,
        producedQuantity,
        rejectedQuantity,
        priority,
        status,
        qcStatus,
        qcNotes,
        qcInspectedAt,
        qcInspector,
        startDate,
        dueDate,
        startedAt,
        completedAt,
        companyId,
        createdAt,
        updatedAt
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductionOrderImplCopyWith<_$ProductionOrderImpl> get copyWith =>
      __$$ProductionOrderImplCopyWithImpl<_$ProductionOrderImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductionOrderImplToJson(
      this,
    );
  }
}

abstract class _ProductionOrder extends ProductionOrder {
  const factory _ProductionOrder(
      {required final String id,
      required final String orderNumber,
      final String? planId,
      required final String productId,
      final String? productCode,
      final String? productName,
      required final String lineId,
      final String? lineCode,
      final String? machineId,
      final String? machineCode,
      final List<String>? assignedMachines,
      final List<String>? assignedWorkers,
      required final double targetQuantity,
      required final double producedQuantity,
      required final double rejectedQuantity,
      required final String priority,
      required final String status,
      final String? qcStatus,
      final String? qcNotes,
      final int? qcInspectedAt,
      final String? qcInspector,
      final int? startDate,
      final int? dueDate,
      final int? startedAt,
      final int? completedAt,
      final String? companyId,
      required final int createdAt,
      required final int updatedAt}) = _$ProductionOrderImpl;
  const _ProductionOrder._() : super._();

  factory _ProductionOrder.fromJson(Map<String, dynamic> json) =
      _$ProductionOrderImpl.fromJson;

  @override
  String get id;
  @override
  String get orderNumber;
  @override
  String? get planId;
  @override
  String get productId;
  @override
  String? get productCode;
  @override
  String? get productName;
  @override
  String get lineId;
  @override
  String? get lineCode;
  @override
  String? get machineId;
  @override
  String? get machineCode;
  @override
  List<String>? get assignedMachines;
  @override
  List<String>? get assignedWorkers;
  @override
  double get targetQuantity;
  @override
  double get producedQuantity;
  @override
  double get rejectedQuantity;
  @override
  String get priority;
  @override
  String get status;
  @override
  String? get qcStatus;
  @override
  String? get qcNotes;
  @override
  int? get qcInspectedAt;
  @override
  String? get qcInspector;
  @override
  int? get startDate;
  @override
  int? get dueDate;
  @override
  int? get startedAt;
  @override
  int? get completedAt;
  @override
  String? get companyId;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ProductionOrderImplCopyWith<_$ProductionOrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProductionEntry _$ProductionEntryFromJson(Map<String, dynamic> json) {
  return _ProductionEntry.fromJson(json);
}

/// @nodoc
mixin _$ProductionEntry {
  String get id => throw _privateConstructorUsedError;
  String get productionOrderId => throw _privateConstructorUsedError;
  String? get machineId => throw _privateConstructorUsedError;
  String? get operatorId => throw _privateConstructorUsedError;
  double get goodQuantity => throw _privateConstructorUsedError;
  double get rejectedQuantity => throw _privateConstructorUsedError;
  double? get scrapQuantity => throw _privateConstructorUsedError;
  String? get rejectionReason => throw _privateConstructorUsedError;
  int get entryTimestamp => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProductionEntryCopyWith<ProductionEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductionEntryCopyWith<$Res> {
  factory $ProductionEntryCopyWith(
          ProductionEntry value, $Res Function(ProductionEntry) then) =
      _$ProductionEntryCopyWithImpl<$Res, ProductionEntry>;
  @useResult
  $Res call(
      {String id,
      String productionOrderId,
      String? machineId,
      String? operatorId,
      double goodQuantity,
      double rejectedQuantity,
      double? scrapQuantity,
      String? rejectionReason,
      int entryTimestamp,
      int createdAt});
}

/// @nodoc
class _$ProductionEntryCopyWithImpl<$Res, $Val extends ProductionEntry>
    implements $ProductionEntryCopyWith<$Res> {
  _$ProductionEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productionOrderId = null,
    Object? machineId = freezed,
    Object? operatorId = freezed,
    Object? goodQuantity = null,
    Object? rejectedQuantity = null,
    Object? scrapQuantity = freezed,
    Object? rejectionReason = freezed,
    Object? entryTimestamp = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      productionOrderId: null == productionOrderId
          ? _value.productionOrderId
          : productionOrderId // ignore: cast_nullable_to_non_nullable
              as String,
      machineId: freezed == machineId
          ? _value.machineId
          : machineId // ignore: cast_nullable_to_non_nullable
              as String?,
      operatorId: freezed == operatorId
          ? _value.operatorId
          : operatorId // ignore: cast_nullable_to_non_nullable
              as String?,
      goodQuantity: null == goodQuantity
          ? _value.goodQuantity
          : goodQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      rejectedQuantity: null == rejectedQuantity
          ? _value.rejectedQuantity
          : rejectedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      scrapQuantity: freezed == scrapQuantity
          ? _value.scrapQuantity
          : scrapQuantity // ignore: cast_nullable_to_non_nullable
              as double?,
      rejectionReason: freezed == rejectionReason
          ? _value.rejectionReason
          : rejectionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      entryTimestamp: null == entryTimestamp
          ? _value.entryTimestamp
          : entryTimestamp // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProductionEntryImplCopyWith<$Res>
    implements $ProductionEntryCopyWith<$Res> {
  factory _$$ProductionEntryImplCopyWith(_$ProductionEntryImpl value,
          $Res Function(_$ProductionEntryImpl) then) =
      __$$ProductionEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String productionOrderId,
      String? machineId,
      String? operatorId,
      double goodQuantity,
      double rejectedQuantity,
      double? scrapQuantity,
      String? rejectionReason,
      int entryTimestamp,
      int createdAt});
}

/// @nodoc
class __$$ProductionEntryImplCopyWithImpl<$Res>
    extends _$ProductionEntryCopyWithImpl<$Res, _$ProductionEntryImpl>
    implements _$$ProductionEntryImplCopyWith<$Res> {
  __$$ProductionEntryImplCopyWithImpl(
      _$ProductionEntryImpl _value, $Res Function(_$ProductionEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productionOrderId = null,
    Object? machineId = freezed,
    Object? operatorId = freezed,
    Object? goodQuantity = null,
    Object? rejectedQuantity = null,
    Object? scrapQuantity = freezed,
    Object? rejectionReason = freezed,
    Object? entryTimestamp = null,
    Object? createdAt = null,
  }) {
    return _then(_$ProductionEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      productionOrderId: null == productionOrderId
          ? _value.productionOrderId
          : productionOrderId // ignore: cast_nullable_to_non_nullable
              as String,
      machineId: freezed == machineId
          ? _value.machineId
          : machineId // ignore: cast_nullable_to_non_nullable
              as String?,
      operatorId: freezed == operatorId
          ? _value.operatorId
          : operatorId // ignore: cast_nullable_to_non_nullable
              as String?,
      goodQuantity: null == goodQuantity
          ? _value.goodQuantity
          : goodQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      rejectedQuantity: null == rejectedQuantity
          ? _value.rejectedQuantity
          : rejectedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      scrapQuantity: freezed == scrapQuantity
          ? _value.scrapQuantity
          : scrapQuantity // ignore: cast_nullable_to_non_nullable
              as double?,
      rejectionReason: freezed == rejectionReason
          ? _value.rejectionReason
          : rejectionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      entryTimestamp: null == entryTimestamp
          ? _value.entryTimestamp
          : entryTimestamp // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductionEntryImpl implements _ProductionEntry {
  const _$ProductionEntryImpl(
      {required this.id,
      required this.productionOrderId,
      this.machineId,
      this.operatorId,
      required this.goodQuantity,
      required this.rejectedQuantity,
      this.scrapQuantity,
      this.rejectionReason,
      required this.entryTimestamp,
      required this.createdAt});

  factory _$ProductionEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductionEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String productionOrderId;
  @override
  final String? machineId;
  @override
  final String? operatorId;
  @override
  final double goodQuantity;
  @override
  final double rejectedQuantity;
  @override
  final double? scrapQuantity;
  @override
  final String? rejectionReason;
  @override
  final int entryTimestamp;
  @override
  final int createdAt;

  @override
  String toString() {
    return 'ProductionEntry(id: $id, productionOrderId: $productionOrderId, machineId: $machineId, operatorId: $operatorId, goodQuantity: $goodQuantity, rejectedQuantity: $rejectedQuantity, scrapQuantity: $scrapQuantity, rejectionReason: $rejectionReason, entryTimestamp: $entryTimestamp, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductionEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.productionOrderId, productionOrderId) ||
                other.productionOrderId == productionOrderId) &&
            (identical(other.machineId, machineId) ||
                other.machineId == machineId) &&
            (identical(other.operatorId, operatorId) ||
                other.operatorId == operatorId) &&
            (identical(other.goodQuantity, goodQuantity) ||
                other.goodQuantity == goodQuantity) &&
            (identical(other.rejectedQuantity, rejectedQuantity) ||
                other.rejectedQuantity == rejectedQuantity) &&
            (identical(other.scrapQuantity, scrapQuantity) ||
                other.scrapQuantity == scrapQuantity) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason) &&
            (identical(other.entryTimestamp, entryTimestamp) ||
                other.entryTimestamp == entryTimestamp) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      productionOrderId,
      machineId,
      operatorId,
      goodQuantity,
      rejectedQuantity,
      scrapQuantity,
      rejectionReason,
      entryTimestamp,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductionEntryImplCopyWith<_$ProductionEntryImpl> get copyWith =>
      __$$ProductionEntryImplCopyWithImpl<_$ProductionEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductionEntryImplToJson(
      this,
    );
  }
}

abstract class _ProductionEntry implements ProductionEntry {
  const factory _ProductionEntry(
      {required final String id,
      required final String productionOrderId,
      final String? machineId,
      final String? operatorId,
      required final double goodQuantity,
      required final double rejectedQuantity,
      final double? scrapQuantity,
      final String? rejectionReason,
      required final int entryTimestamp,
      required final int createdAt}) = _$ProductionEntryImpl;

  factory _ProductionEntry.fromJson(Map<String, dynamic> json) =
      _$ProductionEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get productionOrderId;
  @override
  String? get machineId;
  @override
  String? get operatorId;
  @override
  double get goodQuantity;
  @override
  double get rejectedQuantity;
  @override
  double? get scrapQuantity;
  @override
  String? get rejectionReason;
  @override
  int get entryTimestamp;
  @override
  int get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ProductionEntryImplCopyWith<_$ProductionEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
