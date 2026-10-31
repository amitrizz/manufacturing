// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quality.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QualityInspection _$QualityInspectionFromJson(Map<String, dynamic> json) {
  return _QualityInspection.fromJson(json);
}

/// @nodoc
mixin _$QualityInspection {
  String get id => throw _privateConstructorUsedError;
  String get inspectionNumber => throw _privateConstructorUsedError;
  String get productionOrderId => throw _privateConstructorUsedError;
  String? get inspectorId => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  double? get sampleSize => throw _privateConstructorUsedError;
  double get rejectedQuantity => throw _privateConstructorUsedError;
  String? get result => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get remarks => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QualityInspectionCopyWith<QualityInspection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QualityInspectionCopyWith<$Res> {
  factory $QualityInspectionCopyWith(
          QualityInspection value, $Res Function(QualityInspection) then) =
      _$QualityInspectionCopyWithImpl<$Res, QualityInspection>;
  @useResult
  $Res call(
      {String id,
      String inspectionNumber,
      String productionOrderId,
      String? inspectorId,
      double quantity,
      double? sampleSize,
      double rejectedQuantity,
      String? result,
      String status,
      String? remarks,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$QualityInspectionCopyWithImpl<$Res, $Val extends QualityInspection>
    implements $QualityInspectionCopyWith<$Res> {
  _$QualityInspectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? inspectionNumber = null,
    Object? productionOrderId = null,
    Object? inspectorId = freezed,
    Object? quantity = null,
    Object? sampleSize = freezed,
    Object? rejectedQuantity = null,
    Object? result = freezed,
    Object? status = null,
    Object? remarks = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      inspectionNumber: null == inspectionNumber
          ? _value.inspectionNumber
          : inspectionNumber // ignore: cast_nullable_to_non_nullable
              as String,
      productionOrderId: null == productionOrderId
          ? _value.productionOrderId
          : productionOrderId // ignore: cast_nullable_to_non_nullable
              as String,
      inspectorId: freezed == inspectorId
          ? _value.inspectorId
          : inspectorId // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      sampleSize: freezed == sampleSize
          ? _value.sampleSize
          : sampleSize // ignore: cast_nullable_to_non_nullable
              as double?,
      rejectedQuantity: null == rejectedQuantity
          ? _value.rejectedQuantity
          : rejectedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
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
abstract class _$$QualityInspectionImplCopyWith<$Res>
    implements $QualityInspectionCopyWith<$Res> {
  factory _$$QualityInspectionImplCopyWith(_$QualityInspectionImpl value,
          $Res Function(_$QualityInspectionImpl) then) =
      __$$QualityInspectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String inspectionNumber,
      String productionOrderId,
      String? inspectorId,
      double quantity,
      double? sampleSize,
      double rejectedQuantity,
      String? result,
      String status,
      String? remarks,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$QualityInspectionImplCopyWithImpl<$Res>
    extends _$QualityInspectionCopyWithImpl<$Res, _$QualityInspectionImpl>
    implements _$$QualityInspectionImplCopyWith<$Res> {
  __$$QualityInspectionImplCopyWithImpl(_$QualityInspectionImpl _value,
      $Res Function(_$QualityInspectionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? inspectionNumber = null,
    Object? productionOrderId = null,
    Object? inspectorId = freezed,
    Object? quantity = null,
    Object? sampleSize = freezed,
    Object? rejectedQuantity = null,
    Object? result = freezed,
    Object? status = null,
    Object? remarks = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$QualityInspectionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      inspectionNumber: null == inspectionNumber
          ? _value.inspectionNumber
          : inspectionNumber // ignore: cast_nullable_to_non_nullable
              as String,
      productionOrderId: null == productionOrderId
          ? _value.productionOrderId
          : productionOrderId // ignore: cast_nullable_to_non_nullable
              as String,
      inspectorId: freezed == inspectorId
          ? _value.inspectorId
          : inspectorId // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      sampleSize: freezed == sampleSize
          ? _value.sampleSize
          : sampleSize // ignore: cast_nullable_to_non_nullable
              as double?,
      rejectedQuantity: null == rejectedQuantity
          ? _value.rejectedQuantity
          : rejectedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
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
class _$QualityInspectionImpl extends _QualityInspection {
  const _$QualityInspectionImpl(
      {required this.id,
      required this.inspectionNumber,
      required this.productionOrderId,
      this.inspectorId,
      required this.quantity,
      this.sampleSize,
      required this.rejectedQuantity,
      this.result,
      required this.status,
      this.remarks,
      required this.createdAt,
      required this.updatedAt})
      : super._();

  factory _$QualityInspectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$QualityInspectionImplFromJson(json);

  @override
  final String id;
  @override
  final String inspectionNumber;
  @override
  final String productionOrderId;
  @override
  final String? inspectorId;
  @override
  final double quantity;
  @override
  final double? sampleSize;
  @override
  final double rejectedQuantity;
  @override
  final String? result;
  @override
  final String status;
  @override
  final String? remarks;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'QualityInspection(id: $id, inspectionNumber: $inspectionNumber, productionOrderId: $productionOrderId, inspectorId: $inspectorId, quantity: $quantity, sampleSize: $sampleSize, rejectedQuantity: $rejectedQuantity, result: $result, status: $status, remarks: $remarks, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QualityInspectionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.inspectionNumber, inspectionNumber) ||
                other.inspectionNumber == inspectionNumber) &&
            (identical(other.productionOrderId, productionOrderId) ||
                other.productionOrderId == productionOrderId) &&
            (identical(other.inspectorId, inspectorId) ||
                other.inspectorId == inspectorId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.sampleSize, sampleSize) ||
                other.sampleSize == sampleSize) &&
            (identical(other.rejectedQuantity, rejectedQuantity) ||
                other.rejectedQuantity == rejectedQuantity) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.remarks, remarks) || other.remarks == remarks) &&
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
      inspectionNumber,
      productionOrderId,
      inspectorId,
      quantity,
      sampleSize,
      rejectedQuantity,
      result,
      status,
      remarks,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QualityInspectionImplCopyWith<_$QualityInspectionImpl> get copyWith =>
      __$$QualityInspectionImplCopyWithImpl<_$QualityInspectionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QualityInspectionImplToJson(
      this,
    );
  }
}

abstract class _QualityInspection extends QualityInspection {
  const factory _QualityInspection(
      {required final String id,
      required final String inspectionNumber,
      required final String productionOrderId,
      final String? inspectorId,
      required final double quantity,
      final double? sampleSize,
      required final double rejectedQuantity,
      final String? result,
      required final String status,
      final String? remarks,
      required final int createdAt,
      required final int updatedAt}) = _$QualityInspectionImpl;
  const _QualityInspection._() : super._();

  factory _QualityInspection.fromJson(Map<String, dynamic> json) =
      _$QualityInspectionImpl.fromJson;

  @override
  String get id;
  @override
  String get inspectionNumber;
  @override
  String get productionOrderId;
  @override
  String? get inspectorId;
  @override
  double get quantity;
  @override
  double? get sampleSize;
  @override
  double get rejectedQuantity;
  @override
  String? get result;
  @override
  String get status;
  @override
  String? get remarks;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$QualityInspectionImplCopyWith<_$QualityInspectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QualityResult _$QualityResultFromJson(Map<String, dynamic> json) {
  return _QualityResult.fromJson(json);
}

/// @nodoc
mixin _$QualityResult {
  String get id => throw _privateConstructorUsedError;
  String get inspectionId => throw _privateConstructorUsedError;
  String get parameter => throw _privateConstructorUsedError;
  String? get expectedValue => throw _privateConstructorUsedError;
  String? get actualValue => throw _privateConstructorUsedError;
  String get result => throw _privateConstructorUsedError;
  String? get remarks => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QualityResultCopyWith<QualityResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QualityResultCopyWith<$Res> {
  factory $QualityResultCopyWith(
          QualityResult value, $Res Function(QualityResult) then) =
      _$QualityResultCopyWithImpl<$Res, QualityResult>;
  @useResult
  $Res call(
      {String id,
      String inspectionId,
      String parameter,
      String? expectedValue,
      String? actualValue,
      String result,
      String? remarks,
      int createdAt});
}

/// @nodoc
class _$QualityResultCopyWithImpl<$Res, $Val extends QualityResult>
    implements $QualityResultCopyWith<$Res> {
  _$QualityResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? inspectionId = null,
    Object? parameter = null,
    Object? expectedValue = freezed,
    Object? actualValue = freezed,
    Object? result = null,
    Object? remarks = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      inspectionId: null == inspectionId
          ? _value.inspectionId
          : inspectionId // ignore: cast_nullable_to_non_nullable
              as String,
      parameter: null == parameter
          ? _value.parameter
          : parameter // ignore: cast_nullable_to_non_nullable
              as String,
      expectedValue: freezed == expectedValue
          ? _value.expectedValue
          : expectedValue // ignore: cast_nullable_to_non_nullable
              as String?,
      actualValue: freezed == actualValue
          ? _value.actualValue
          : actualValue // ignore: cast_nullable_to_non_nullable
              as String?,
      result: null == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QualityResultImplCopyWith<$Res>
    implements $QualityResultCopyWith<$Res> {
  factory _$$QualityResultImplCopyWith(
          _$QualityResultImpl value, $Res Function(_$QualityResultImpl) then) =
      __$$QualityResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String inspectionId,
      String parameter,
      String? expectedValue,
      String? actualValue,
      String result,
      String? remarks,
      int createdAt});
}

/// @nodoc
class __$$QualityResultImplCopyWithImpl<$Res>
    extends _$QualityResultCopyWithImpl<$Res, _$QualityResultImpl>
    implements _$$QualityResultImplCopyWith<$Res> {
  __$$QualityResultImplCopyWithImpl(
      _$QualityResultImpl _value, $Res Function(_$QualityResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? inspectionId = null,
    Object? parameter = null,
    Object? expectedValue = freezed,
    Object? actualValue = freezed,
    Object? result = null,
    Object? remarks = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$QualityResultImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      inspectionId: null == inspectionId
          ? _value.inspectionId
          : inspectionId // ignore: cast_nullable_to_non_nullable
              as String,
      parameter: null == parameter
          ? _value.parameter
          : parameter // ignore: cast_nullable_to_non_nullable
              as String,
      expectedValue: freezed == expectedValue
          ? _value.expectedValue
          : expectedValue // ignore: cast_nullable_to_non_nullable
              as String?,
      actualValue: freezed == actualValue
          ? _value.actualValue
          : actualValue // ignore: cast_nullable_to_non_nullable
              as String?,
      result: null == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QualityResultImpl implements _QualityResult {
  const _$QualityResultImpl(
      {required this.id,
      required this.inspectionId,
      required this.parameter,
      this.expectedValue,
      this.actualValue,
      required this.result,
      this.remarks,
      required this.createdAt});

  factory _$QualityResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$QualityResultImplFromJson(json);

  @override
  final String id;
  @override
  final String inspectionId;
  @override
  final String parameter;
  @override
  final String? expectedValue;
  @override
  final String? actualValue;
  @override
  final String result;
  @override
  final String? remarks;
  @override
  final int createdAt;

  @override
  String toString() {
    return 'QualityResult(id: $id, inspectionId: $inspectionId, parameter: $parameter, expectedValue: $expectedValue, actualValue: $actualValue, result: $result, remarks: $remarks, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QualityResultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.inspectionId, inspectionId) ||
                other.inspectionId == inspectionId) &&
            (identical(other.parameter, parameter) ||
                other.parameter == parameter) &&
            (identical(other.expectedValue, expectedValue) ||
                other.expectedValue == expectedValue) &&
            (identical(other.actualValue, actualValue) ||
                other.actualValue == actualValue) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.remarks, remarks) || other.remarks == remarks) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, inspectionId, parameter,
      expectedValue, actualValue, result, remarks, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QualityResultImplCopyWith<_$QualityResultImpl> get copyWith =>
      __$$QualityResultImplCopyWithImpl<_$QualityResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QualityResultImplToJson(
      this,
    );
  }
}

abstract class _QualityResult implements QualityResult {
  const factory _QualityResult(
      {required final String id,
      required final String inspectionId,
      required final String parameter,
      final String? expectedValue,
      final String? actualValue,
      required final String result,
      final String? remarks,
      required final int createdAt}) = _$QualityResultImpl;

  factory _QualityResult.fromJson(Map<String, dynamic> json) =
      _$QualityResultImpl.fromJson;

  @override
  String get id;
  @override
  String get inspectionId;
  @override
  String get parameter;
  @override
  String? get expectedValue;
  @override
  String? get actualValue;
  @override
  String get result;
  @override
  String? get remarks;
  @override
  int get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$QualityResultImplCopyWith<_$QualityResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReworkOrder _$ReworkOrderFromJson(Map<String, dynamic> json) {
  return _ReworkOrder.fromJson(json);
}

/// @nodoc
mixin _$ReworkOrder {
  String get id => throw _privateConstructorUsedError;
  String get reworkNumber => throw _privateConstructorUsedError;
  String get inspectionId => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReworkOrderCopyWith<ReworkOrder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReworkOrderCopyWith<$Res> {
  factory $ReworkOrderCopyWith(
          ReworkOrder value, $Res Function(ReworkOrder) then) =
      _$ReworkOrderCopyWithImpl<$Res, ReworkOrder>;
  @useResult
  $Res call(
      {String id,
      String reworkNumber,
      String inspectionId,
      double quantity,
      String status,
      String? notes,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$ReworkOrderCopyWithImpl<$Res, $Val extends ReworkOrder>
    implements $ReworkOrderCopyWith<$Res> {
  _$ReworkOrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reworkNumber = null,
    Object? inspectionId = null,
    Object? quantity = null,
    Object? status = null,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      reworkNumber: null == reworkNumber
          ? _value.reworkNumber
          : reworkNumber // ignore: cast_nullable_to_non_nullable
              as String,
      inspectionId: null == inspectionId
          ? _value.inspectionId
          : inspectionId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ReworkOrderImplCopyWith<$Res>
    implements $ReworkOrderCopyWith<$Res> {
  factory _$$ReworkOrderImplCopyWith(
          _$ReworkOrderImpl value, $Res Function(_$ReworkOrderImpl) then) =
      __$$ReworkOrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String reworkNumber,
      String inspectionId,
      double quantity,
      String status,
      String? notes,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$ReworkOrderImplCopyWithImpl<$Res>
    extends _$ReworkOrderCopyWithImpl<$Res, _$ReworkOrderImpl>
    implements _$$ReworkOrderImplCopyWith<$Res> {
  __$$ReworkOrderImplCopyWithImpl(
      _$ReworkOrderImpl _value, $Res Function(_$ReworkOrderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reworkNumber = null,
    Object? inspectionId = null,
    Object? quantity = null,
    Object? status = null,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ReworkOrderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      reworkNumber: null == reworkNumber
          ? _value.reworkNumber
          : reworkNumber // ignore: cast_nullable_to_non_nullable
              as String,
      inspectionId: null == inspectionId
          ? _value.inspectionId
          : inspectionId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
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
class _$ReworkOrderImpl implements _ReworkOrder {
  const _$ReworkOrderImpl(
      {required this.id,
      required this.reworkNumber,
      required this.inspectionId,
      required this.quantity,
      required this.status,
      this.notes,
      required this.createdAt,
      required this.updatedAt});

  factory _$ReworkOrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReworkOrderImplFromJson(json);

  @override
  final String id;
  @override
  final String reworkNumber;
  @override
  final String inspectionId;
  @override
  final double quantity;
  @override
  final String status;
  @override
  final String? notes;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'ReworkOrder(id: $id, reworkNumber: $reworkNumber, inspectionId: $inspectionId, quantity: $quantity, status: $status, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReworkOrderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.reworkNumber, reworkNumber) ||
                other.reworkNumber == reworkNumber) &&
            (identical(other.inspectionId, inspectionId) ||
                other.inspectionId == inspectionId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, reworkNumber, inspectionId,
      quantity, status, notes, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReworkOrderImplCopyWith<_$ReworkOrderImpl> get copyWith =>
      __$$ReworkOrderImplCopyWithImpl<_$ReworkOrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReworkOrderImplToJson(
      this,
    );
  }
}

abstract class _ReworkOrder implements ReworkOrder {
  const factory _ReworkOrder(
      {required final String id,
      required final String reworkNumber,
      required final String inspectionId,
      required final double quantity,
      required final String status,
      final String? notes,
      required final int createdAt,
      required final int updatedAt}) = _$ReworkOrderImpl;

  factory _ReworkOrder.fromJson(Map<String, dynamic> json) =
      _$ReworkOrderImpl.fromJson;

  @override
  String get id;
  @override
  String get reworkNumber;
  @override
  String get inspectionId;
  @override
  double get quantity;
  @override
  String get status;
  @override
  String? get notes;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ReworkOrderImplCopyWith<_$ReworkOrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
