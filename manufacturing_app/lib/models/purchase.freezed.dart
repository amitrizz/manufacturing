// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Supplier _$SupplierFromJson(Map<String, dynamic> json) {
  return _Supplier.fromJson(json);
}

/// @nodoc
mixin _$Supplier {
  String get id => throw _privateConstructorUsedError;
  String? get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get contactPerson => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get gstNumber => throw _privateConstructorUsedError;
  String? get suppliedItems => throw _privateConstructorUsedError;
  double? get rating => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  int? get isActive => throw _privateConstructorUsedError;
  String? get companyId => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SupplierCopyWith<Supplier> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SupplierCopyWith<$Res> {
  factory $SupplierCopyWith(Supplier value, $Res Function(Supplier) then) =
      _$SupplierCopyWithImpl<$Res, Supplier>;
  @useResult
  $Res call(
      {String id,
      String? code,
      String name,
      String? contactPerson,
      String? phone,
      String? email,
      String? address,
      String? gstNumber,
      String? suppliedItems,
      double? rating,
      String? notes,
      int? isActive,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$SupplierCopyWithImpl<$Res, $Val extends Supplier>
    implements $SupplierCopyWith<$Res> {
  _$SupplierCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = freezed,
    Object? name = null,
    Object? contactPerson = freezed,
    Object? phone = freezed,
    Object? email = freezed,
    Object? address = freezed,
    Object? gstNumber = freezed,
    Object? suppliedItems = freezed,
    Object? rating = freezed,
    Object? notes = freezed,
    Object? isActive = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      contactPerson: freezed == contactPerson
          ? _value.contactPerson
          : contactPerson // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      gstNumber: freezed == gstNumber
          ? _value.gstNumber
          : gstNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      suppliedItems: freezed == suppliedItems
          ? _value.suppliedItems
          : suppliedItems // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: freezed == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
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
abstract class _$$SupplierImplCopyWith<$Res>
    implements $SupplierCopyWith<$Res> {
  factory _$$SupplierImplCopyWith(
          _$SupplierImpl value, $Res Function(_$SupplierImpl) then) =
      __$$SupplierImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? code,
      String name,
      String? contactPerson,
      String? phone,
      String? email,
      String? address,
      String? gstNumber,
      String? suppliedItems,
      double? rating,
      String? notes,
      int? isActive,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$SupplierImplCopyWithImpl<$Res>
    extends _$SupplierCopyWithImpl<$Res, _$SupplierImpl>
    implements _$$SupplierImplCopyWith<$Res> {
  __$$SupplierImplCopyWithImpl(
      _$SupplierImpl _value, $Res Function(_$SupplierImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = freezed,
    Object? name = null,
    Object? contactPerson = freezed,
    Object? phone = freezed,
    Object? email = freezed,
    Object? address = freezed,
    Object? gstNumber = freezed,
    Object? suppliedItems = freezed,
    Object? rating = freezed,
    Object? notes = freezed,
    Object? isActive = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$SupplierImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      contactPerson: freezed == contactPerson
          ? _value.contactPerson
          : contactPerson // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      gstNumber: freezed == gstNumber
          ? _value.gstNumber
          : gstNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      suppliedItems: freezed == suppliedItems
          ? _value.suppliedItems
          : suppliedItems // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: freezed == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
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
class _$SupplierImpl implements _Supplier {
  const _$SupplierImpl(
      {required this.id,
      this.code,
      required this.name,
      this.contactPerson,
      this.phone,
      this.email,
      this.address,
      this.gstNumber,
      this.suppliedItems,
      this.rating,
      this.notes,
      this.isActive,
      this.companyId,
      required this.createdAt,
      required this.updatedAt});

  factory _$SupplierImpl.fromJson(Map<String, dynamic> json) =>
      _$$SupplierImplFromJson(json);

  @override
  final String id;
  @override
  final String? code;
  @override
  final String name;
  @override
  final String? contactPerson;
  @override
  final String? phone;
  @override
  final String? email;
  @override
  final String? address;
  @override
  final String? gstNumber;
  @override
  final String? suppliedItems;
  @override
  final double? rating;
  @override
  final String? notes;
  @override
  final int? isActive;
  @override
  final String? companyId;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'Supplier(id: $id, code: $code, name: $name, contactPerson: $contactPerson, phone: $phone, email: $email, address: $address, gstNumber: $gstNumber, suppliedItems: $suppliedItems, rating: $rating, notes: $notes, isActive: $isActive, companyId: $companyId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SupplierImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.contactPerson, contactPerson) ||
                other.contactPerson == contactPerson) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.gstNumber, gstNumber) ||
                other.gstNumber == gstNumber) &&
            (identical(other.suppliedItems, suppliedItems) ||
                other.suppliedItems == suppliedItems) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
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
      code,
      name,
      contactPerson,
      phone,
      email,
      address,
      gstNumber,
      suppliedItems,
      rating,
      notes,
      isActive,
      companyId,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SupplierImplCopyWith<_$SupplierImpl> get copyWith =>
      __$$SupplierImplCopyWithImpl<_$SupplierImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SupplierImplToJson(
      this,
    );
  }
}

abstract class _Supplier implements Supplier {
  const factory _Supplier(
      {required final String id,
      final String? code,
      required final String name,
      final String? contactPerson,
      final String? phone,
      final String? email,
      final String? address,
      final String? gstNumber,
      final String? suppliedItems,
      final double? rating,
      final String? notes,
      final int? isActive,
      final String? companyId,
      required final int createdAt,
      required final int updatedAt}) = _$SupplierImpl;

  factory _Supplier.fromJson(Map<String, dynamic> json) =
      _$SupplierImpl.fromJson;

  @override
  String get id;
  @override
  String? get code;
  @override
  String get name;
  @override
  String? get contactPerson;
  @override
  String? get phone;
  @override
  String? get email;
  @override
  String? get address;
  @override
  String? get gstNumber;
  @override
  String? get suppliedItems;
  @override
  double? get rating;
  @override
  String? get notes;
  @override
  int? get isActive;
  @override
  String? get companyId;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$SupplierImplCopyWith<_$SupplierImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Customer _$CustomerFromJson(Map<String, dynamic> json) {
  return _Customer.fromJson(json);
}

/// @nodoc
mixin _$Customer {
  String get id => throw _privateConstructorUsedError;
  String? get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get contactPerson => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get gstNumber => throw _privateConstructorUsedError;
  String? get companyId => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CustomerCopyWith<Customer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerCopyWith<$Res> {
  factory $CustomerCopyWith(Customer value, $Res Function(Customer) then) =
      _$CustomerCopyWithImpl<$Res, Customer>;
  @useResult
  $Res call(
      {String id,
      String? code,
      String name,
      String? contactPerson,
      String? phone,
      String? email,
      String? address,
      String? gstNumber,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$CustomerCopyWithImpl<$Res, $Val extends Customer>
    implements $CustomerCopyWith<$Res> {
  _$CustomerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = freezed,
    Object? name = null,
    Object? contactPerson = freezed,
    Object? phone = freezed,
    Object? email = freezed,
    Object? address = freezed,
    Object? gstNumber = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      contactPerson: freezed == contactPerson
          ? _value.contactPerson
          : contactPerson // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      gstNumber: freezed == gstNumber
          ? _value.gstNumber
          : gstNumber // ignore: cast_nullable_to_non_nullable
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
abstract class _$$CustomerImplCopyWith<$Res>
    implements $CustomerCopyWith<$Res> {
  factory _$$CustomerImplCopyWith(
          _$CustomerImpl value, $Res Function(_$CustomerImpl) then) =
      __$$CustomerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? code,
      String name,
      String? contactPerson,
      String? phone,
      String? email,
      String? address,
      String? gstNumber,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$CustomerImplCopyWithImpl<$Res>
    extends _$CustomerCopyWithImpl<$Res, _$CustomerImpl>
    implements _$$CustomerImplCopyWith<$Res> {
  __$$CustomerImplCopyWithImpl(
      _$CustomerImpl _value, $Res Function(_$CustomerImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = freezed,
    Object? name = null,
    Object? contactPerson = freezed,
    Object? phone = freezed,
    Object? email = freezed,
    Object? address = freezed,
    Object? gstNumber = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$CustomerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      contactPerson: freezed == contactPerson
          ? _value.contactPerson
          : contactPerson // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      gstNumber: freezed == gstNumber
          ? _value.gstNumber
          : gstNumber // ignore: cast_nullable_to_non_nullable
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
class _$CustomerImpl implements _Customer {
  const _$CustomerImpl(
      {required this.id,
      this.code,
      required this.name,
      this.contactPerson,
      this.phone,
      this.email,
      this.address,
      this.gstNumber,
      this.companyId,
      required this.createdAt,
      required this.updatedAt});

  factory _$CustomerImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerImplFromJson(json);

  @override
  final String id;
  @override
  final String? code;
  @override
  final String name;
  @override
  final String? contactPerson;
  @override
  final String? phone;
  @override
  final String? email;
  @override
  final String? address;
  @override
  final String? gstNumber;
  @override
  final String? companyId;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'Customer(id: $id, code: $code, name: $name, contactPerson: $contactPerson, phone: $phone, email: $email, address: $address, gstNumber: $gstNumber, companyId: $companyId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.contactPerson, contactPerson) ||
                other.contactPerson == contactPerson) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.gstNumber, gstNumber) ||
                other.gstNumber == gstNumber) &&
            (identical(other.companyId, companyId) ||
                other.companyId == companyId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, code, name, contactPerson,
      phone, email, address, gstNumber, companyId, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerImplCopyWith<_$CustomerImpl> get copyWith =>
      __$$CustomerImplCopyWithImpl<_$CustomerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerImplToJson(
      this,
    );
  }
}

abstract class _Customer implements Customer {
  const factory _Customer(
      {required final String id,
      final String? code,
      required final String name,
      final String? contactPerson,
      final String? phone,
      final String? email,
      final String? address,
      final String? gstNumber,
      final String? companyId,
      required final int createdAt,
      required final int updatedAt}) = _$CustomerImpl;

  factory _Customer.fromJson(Map<String, dynamic> json) =
      _$CustomerImpl.fromJson;

  @override
  String get id;
  @override
  String? get code;
  @override
  String get name;
  @override
  String? get contactPerson;
  @override
  String? get phone;
  @override
  String? get email;
  @override
  String? get address;
  @override
  String? get gstNumber;
  @override
  String? get companyId;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$CustomerImplCopyWith<_$CustomerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PurchaseRequest _$PurchaseRequestFromJson(Map<String, dynamic> json) {
  return _PurchaseRequest.fromJson(json);
}

/// @nodoc
mixin _$PurchaseRequest {
  String get id => throw _privateConstructorUsedError;
  String get requestNumber => throw _privateConstructorUsedError;
  String get materialId => throw _privateConstructorUsedError;
  String? get materialCode => throw _privateConstructorUsedError;
  String? get materialName => throw _privateConstructorUsedError;
  String? get materialUnit => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  int? get requiredByDate => throw _privateConstructorUsedError;
  String? get linkedOrderId => throw _privateConstructorUsedError;
  String? get orderNumber => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PurchaseRequestCopyWith<PurchaseRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseRequestCopyWith<$Res> {
  factory $PurchaseRequestCopyWith(
          PurchaseRequest value, $Res Function(PurchaseRequest) then) =
      _$PurchaseRequestCopyWithImpl<$Res, PurchaseRequest>;
  @useResult
  $Res call(
      {String id,
      String requestNumber,
      String materialId,
      String? materialCode,
      String? materialName,
      String? materialUnit,
      double quantity,
      int? requiredByDate,
      String? linkedOrderId,
      String? orderNumber,
      String? reason,
      String status,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$PurchaseRequestCopyWithImpl<$Res, $Val extends PurchaseRequest>
    implements $PurchaseRequestCopyWith<$Res> {
  _$PurchaseRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? requestNumber = null,
    Object? materialId = null,
    Object? materialCode = freezed,
    Object? materialName = freezed,
    Object? materialUnit = freezed,
    Object? quantity = null,
    Object? requiredByDate = freezed,
    Object? linkedOrderId = freezed,
    Object? orderNumber = freezed,
    Object? reason = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      requestNumber: null == requestNumber
          ? _value.requestNumber
          : requestNumber // ignore: cast_nullable_to_non_nullable
              as String,
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      materialCode: freezed == materialCode
          ? _value.materialCode
          : materialCode // ignore: cast_nullable_to_non_nullable
              as String?,
      materialName: freezed == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String?,
      materialUnit: freezed == materialUnit
          ? _value.materialUnit
          : materialUnit // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      requiredByDate: freezed == requiredByDate
          ? _value.requiredByDate
          : requiredByDate // ignore: cast_nullable_to_non_nullable
              as int?,
      linkedOrderId: freezed == linkedOrderId
          ? _value.linkedOrderId
          : linkedOrderId // ignore: cast_nullable_to_non_nullable
              as String?,
      orderNumber: freezed == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
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
abstract class _$$PurchaseRequestImplCopyWith<$Res>
    implements $PurchaseRequestCopyWith<$Res> {
  factory _$$PurchaseRequestImplCopyWith(_$PurchaseRequestImpl value,
          $Res Function(_$PurchaseRequestImpl) then) =
      __$$PurchaseRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String requestNumber,
      String materialId,
      String? materialCode,
      String? materialName,
      String? materialUnit,
      double quantity,
      int? requiredByDate,
      String? linkedOrderId,
      String? orderNumber,
      String? reason,
      String status,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$PurchaseRequestImplCopyWithImpl<$Res>
    extends _$PurchaseRequestCopyWithImpl<$Res, _$PurchaseRequestImpl>
    implements _$$PurchaseRequestImplCopyWith<$Res> {
  __$$PurchaseRequestImplCopyWithImpl(
      _$PurchaseRequestImpl _value, $Res Function(_$PurchaseRequestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? requestNumber = null,
    Object? materialId = null,
    Object? materialCode = freezed,
    Object? materialName = freezed,
    Object? materialUnit = freezed,
    Object? quantity = null,
    Object? requiredByDate = freezed,
    Object? linkedOrderId = freezed,
    Object? orderNumber = freezed,
    Object? reason = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$PurchaseRequestImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      requestNumber: null == requestNumber
          ? _value.requestNumber
          : requestNumber // ignore: cast_nullable_to_non_nullable
              as String,
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      materialCode: freezed == materialCode
          ? _value.materialCode
          : materialCode // ignore: cast_nullable_to_non_nullable
              as String?,
      materialName: freezed == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String?,
      materialUnit: freezed == materialUnit
          ? _value.materialUnit
          : materialUnit // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      requiredByDate: freezed == requiredByDate
          ? _value.requiredByDate
          : requiredByDate // ignore: cast_nullable_to_non_nullable
              as int?,
      linkedOrderId: freezed == linkedOrderId
          ? _value.linkedOrderId
          : linkedOrderId // ignore: cast_nullable_to_non_nullable
              as String?,
      orderNumber: freezed == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
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
class _$PurchaseRequestImpl implements _PurchaseRequest {
  const _$PurchaseRequestImpl(
      {required this.id,
      required this.requestNumber,
      required this.materialId,
      this.materialCode,
      this.materialName,
      this.materialUnit,
      required this.quantity,
      this.requiredByDate,
      this.linkedOrderId,
      this.orderNumber,
      this.reason,
      required this.status,
      required this.createdAt,
      required this.updatedAt});

  factory _$PurchaseRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseRequestImplFromJson(json);

  @override
  final String id;
  @override
  final String requestNumber;
  @override
  final String materialId;
  @override
  final String? materialCode;
  @override
  final String? materialName;
  @override
  final String? materialUnit;
  @override
  final double quantity;
  @override
  final int? requiredByDate;
  @override
  final String? linkedOrderId;
  @override
  final String? orderNumber;
  @override
  final String? reason;
  @override
  final String status;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'PurchaseRequest(id: $id, requestNumber: $requestNumber, materialId: $materialId, materialCode: $materialCode, materialName: $materialName, materialUnit: $materialUnit, quantity: $quantity, requiredByDate: $requiredByDate, linkedOrderId: $linkedOrderId, orderNumber: $orderNumber, reason: $reason, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.requestNumber, requestNumber) ||
                other.requestNumber == requestNumber) &&
            (identical(other.materialId, materialId) ||
                other.materialId == materialId) &&
            (identical(other.materialCode, materialCode) ||
                other.materialCode == materialCode) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName) &&
            (identical(other.materialUnit, materialUnit) ||
                other.materialUnit == materialUnit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.requiredByDate, requiredByDate) ||
                other.requiredByDate == requiredByDate) &&
            (identical(other.linkedOrderId, linkedOrderId) ||
                other.linkedOrderId == linkedOrderId) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.status, status) || other.status == status) &&
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
      requestNumber,
      materialId,
      materialCode,
      materialName,
      materialUnit,
      quantity,
      requiredByDate,
      linkedOrderId,
      orderNumber,
      reason,
      status,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseRequestImplCopyWith<_$PurchaseRequestImpl> get copyWith =>
      __$$PurchaseRequestImplCopyWithImpl<_$PurchaseRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseRequestImplToJson(
      this,
    );
  }
}

abstract class _PurchaseRequest implements PurchaseRequest {
  const factory _PurchaseRequest(
      {required final String id,
      required final String requestNumber,
      required final String materialId,
      final String? materialCode,
      final String? materialName,
      final String? materialUnit,
      required final double quantity,
      final int? requiredByDate,
      final String? linkedOrderId,
      final String? orderNumber,
      final String? reason,
      required final String status,
      required final int createdAt,
      required final int updatedAt}) = _$PurchaseRequestImpl;

  factory _PurchaseRequest.fromJson(Map<String, dynamic> json) =
      _$PurchaseRequestImpl.fromJson;

  @override
  String get id;
  @override
  String get requestNumber;
  @override
  String get materialId;
  @override
  String? get materialCode;
  @override
  String? get materialName;
  @override
  String? get materialUnit;
  @override
  double get quantity;
  @override
  int? get requiredByDate;
  @override
  String? get linkedOrderId;
  @override
  String? get orderNumber;
  @override
  String? get reason;
  @override
  String get status;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseRequestImplCopyWith<_$PurchaseRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PurchaseOrder _$PurchaseOrderFromJson(Map<String, dynamic> json) {
  return _PurchaseOrder.fromJson(json);
}

/// @nodoc
mixin _$PurchaseOrder {
  String get id => throw _privateConstructorUsedError;
  String get poNumber => throw _privateConstructorUsedError;
  String get supplierId => throw _privateConstructorUsedError;
  String? get supplierName => throw _privateConstructorUsedError;
  String? get supplierCode => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  double get totalAmount => throw _privateConstructorUsedError;
  int get orderDate => throw _privateConstructorUsedError;
  int? get expectedDeliveryDate => throw _privateConstructorUsedError;
  String? get terms => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PurchaseOrderCopyWith<PurchaseOrder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseOrderCopyWith<$Res> {
  factory $PurchaseOrderCopyWith(
          PurchaseOrder value, $Res Function(PurchaseOrder) then) =
      _$PurchaseOrderCopyWithImpl<$Res, PurchaseOrder>;
  @useResult
  $Res call(
      {String id,
      String poNumber,
      String supplierId,
      String? supplierName,
      String? supplierCode,
      String status,
      double totalAmount,
      int orderDate,
      int? expectedDeliveryDate,
      String? terms,
      String? notes,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$PurchaseOrderCopyWithImpl<$Res, $Val extends PurchaseOrder>
    implements $PurchaseOrderCopyWith<$Res> {
  _$PurchaseOrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poNumber = null,
    Object? supplierId = null,
    Object? supplierName = freezed,
    Object? supplierCode = freezed,
    Object? status = null,
    Object? totalAmount = null,
    Object? orderDate = null,
    Object? expectedDeliveryDate = freezed,
    Object? terms = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      poNumber: null == poNumber
          ? _value.poNumber
          : poNumber // ignore: cast_nullable_to_non_nullable
              as String,
      supplierId: null == supplierId
          ? _value.supplierId
          : supplierId // ignore: cast_nullable_to_non_nullable
              as String,
      supplierName: freezed == supplierName
          ? _value.supplierName
          : supplierName // ignore: cast_nullable_to_non_nullable
              as String?,
      supplierCode: freezed == supplierCode
          ? _value.supplierCode
          : supplierCode // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      orderDate: null == orderDate
          ? _value.orderDate
          : orderDate // ignore: cast_nullable_to_non_nullable
              as int,
      expectedDeliveryDate: freezed == expectedDeliveryDate
          ? _value.expectedDeliveryDate
          : expectedDeliveryDate // ignore: cast_nullable_to_non_nullable
              as int?,
      terms: freezed == terms
          ? _value.terms
          : terms // ignore: cast_nullable_to_non_nullable
              as String?,
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
abstract class _$$PurchaseOrderImplCopyWith<$Res>
    implements $PurchaseOrderCopyWith<$Res> {
  factory _$$PurchaseOrderImplCopyWith(
          _$PurchaseOrderImpl value, $Res Function(_$PurchaseOrderImpl) then) =
      __$$PurchaseOrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String poNumber,
      String supplierId,
      String? supplierName,
      String? supplierCode,
      String status,
      double totalAmount,
      int orderDate,
      int? expectedDeliveryDate,
      String? terms,
      String? notes,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$PurchaseOrderImplCopyWithImpl<$Res>
    extends _$PurchaseOrderCopyWithImpl<$Res, _$PurchaseOrderImpl>
    implements _$$PurchaseOrderImplCopyWith<$Res> {
  __$$PurchaseOrderImplCopyWithImpl(
      _$PurchaseOrderImpl _value, $Res Function(_$PurchaseOrderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poNumber = null,
    Object? supplierId = null,
    Object? supplierName = freezed,
    Object? supplierCode = freezed,
    Object? status = null,
    Object? totalAmount = null,
    Object? orderDate = null,
    Object? expectedDeliveryDate = freezed,
    Object? terms = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$PurchaseOrderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      poNumber: null == poNumber
          ? _value.poNumber
          : poNumber // ignore: cast_nullable_to_non_nullable
              as String,
      supplierId: null == supplierId
          ? _value.supplierId
          : supplierId // ignore: cast_nullable_to_non_nullable
              as String,
      supplierName: freezed == supplierName
          ? _value.supplierName
          : supplierName // ignore: cast_nullable_to_non_nullable
              as String?,
      supplierCode: freezed == supplierCode
          ? _value.supplierCode
          : supplierCode // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      orderDate: null == orderDate
          ? _value.orderDate
          : orderDate // ignore: cast_nullable_to_non_nullable
              as int,
      expectedDeliveryDate: freezed == expectedDeliveryDate
          ? _value.expectedDeliveryDate
          : expectedDeliveryDate // ignore: cast_nullable_to_non_nullable
              as int?,
      terms: freezed == terms
          ? _value.terms
          : terms // ignore: cast_nullable_to_non_nullable
              as String?,
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
class _$PurchaseOrderImpl implements _PurchaseOrder {
  const _$PurchaseOrderImpl(
      {required this.id,
      required this.poNumber,
      required this.supplierId,
      this.supplierName,
      this.supplierCode,
      required this.status,
      required this.totalAmount,
      required this.orderDate,
      this.expectedDeliveryDate,
      this.terms,
      this.notes,
      required this.createdAt,
      required this.updatedAt});

  factory _$PurchaseOrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseOrderImplFromJson(json);

  @override
  final String id;
  @override
  final String poNumber;
  @override
  final String supplierId;
  @override
  final String? supplierName;
  @override
  final String? supplierCode;
  @override
  final String status;
  @override
  final double totalAmount;
  @override
  final int orderDate;
  @override
  final int? expectedDeliveryDate;
  @override
  final String? terms;
  @override
  final String? notes;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'PurchaseOrder(id: $id, poNumber: $poNumber, supplierId: $supplierId, supplierName: $supplierName, supplierCode: $supplierCode, status: $status, totalAmount: $totalAmount, orderDate: $orderDate, expectedDeliveryDate: $expectedDeliveryDate, terms: $terms, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseOrderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.poNumber, poNumber) ||
                other.poNumber == poNumber) &&
            (identical(other.supplierId, supplierId) ||
                other.supplierId == supplierId) &&
            (identical(other.supplierName, supplierName) ||
                other.supplierName == supplierName) &&
            (identical(other.supplierCode, supplierCode) ||
                other.supplierCode == supplierCode) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.orderDate, orderDate) ||
                other.orderDate == orderDate) &&
            (identical(other.expectedDeliveryDate, expectedDeliveryDate) ||
                other.expectedDeliveryDate == expectedDeliveryDate) &&
            (identical(other.terms, terms) || other.terms == terms) &&
            (identical(other.notes, notes) || other.notes == notes) &&
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
      poNumber,
      supplierId,
      supplierName,
      supplierCode,
      status,
      totalAmount,
      orderDate,
      expectedDeliveryDate,
      terms,
      notes,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseOrderImplCopyWith<_$PurchaseOrderImpl> get copyWith =>
      __$$PurchaseOrderImplCopyWithImpl<_$PurchaseOrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseOrderImplToJson(
      this,
    );
  }
}

abstract class _PurchaseOrder implements PurchaseOrder {
  const factory _PurchaseOrder(
      {required final String id,
      required final String poNumber,
      required final String supplierId,
      final String? supplierName,
      final String? supplierCode,
      required final String status,
      required final double totalAmount,
      required final int orderDate,
      final int? expectedDeliveryDate,
      final String? terms,
      final String? notes,
      required final int createdAt,
      required final int updatedAt}) = _$PurchaseOrderImpl;

  factory _PurchaseOrder.fromJson(Map<String, dynamic> json) =
      _$PurchaseOrderImpl.fromJson;

  @override
  String get id;
  @override
  String get poNumber;
  @override
  String get supplierId;
  @override
  String? get supplierName;
  @override
  String? get supplierCode;
  @override
  String get status;
  @override
  double get totalAmount;
  @override
  int get orderDate;
  @override
  int? get expectedDeliveryDate;
  @override
  String? get terms;
  @override
  String? get notes;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseOrderImplCopyWith<_$PurchaseOrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PurchaseOrderItem _$PurchaseOrderItemFromJson(Map<String, dynamic> json) {
  return _PurchaseOrderItem.fromJson(json);
}

/// @nodoc
mixin _$PurchaseOrderItem {
  String get id => throw _privateConstructorUsedError;
  String get poId => throw _privateConstructorUsedError;
  String get materialId => throw _privateConstructorUsedError;
  String? get materialCode => throw _privateConstructorUsedError;
  String? get materialName => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  double get unitPrice => throw _privateConstructorUsedError;
  double get totalPrice => throw _privateConstructorUsedError;
  double get receivedQuantity => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PurchaseOrderItemCopyWith<PurchaseOrderItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseOrderItemCopyWith<$Res> {
  factory $PurchaseOrderItemCopyWith(
          PurchaseOrderItem value, $Res Function(PurchaseOrderItem) then) =
      _$PurchaseOrderItemCopyWithImpl<$Res, PurchaseOrderItem>;
  @useResult
  $Res call(
      {String id,
      String poId,
      String materialId,
      String? materialCode,
      String? materialName,
      String? unit,
      double quantity,
      double unitPrice,
      double totalPrice,
      double receivedQuantity,
      String? notes,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$PurchaseOrderItemCopyWithImpl<$Res, $Val extends PurchaseOrderItem>
    implements $PurchaseOrderItemCopyWith<$Res> {
  _$PurchaseOrderItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poId = null,
    Object? materialId = null,
    Object? materialCode = freezed,
    Object? materialName = freezed,
    Object? unit = freezed,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? totalPrice = null,
    Object? receivedQuantity = null,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      poId: null == poId
          ? _value.poId
          : poId // ignore: cast_nullable_to_non_nullable
              as String,
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      materialCode: freezed == materialCode
          ? _value.materialCode
          : materialCode // ignore: cast_nullable_to_non_nullable
              as String?,
      materialName: freezed == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      totalPrice: null == totalPrice
          ? _value.totalPrice
          : totalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      receivedQuantity: null == receivedQuantity
          ? _value.receivedQuantity
          : receivedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
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
abstract class _$$PurchaseOrderItemImplCopyWith<$Res>
    implements $PurchaseOrderItemCopyWith<$Res> {
  factory _$$PurchaseOrderItemImplCopyWith(_$PurchaseOrderItemImpl value,
          $Res Function(_$PurchaseOrderItemImpl) then) =
      __$$PurchaseOrderItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String poId,
      String materialId,
      String? materialCode,
      String? materialName,
      String? unit,
      double quantity,
      double unitPrice,
      double totalPrice,
      double receivedQuantity,
      String? notes,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$PurchaseOrderItemImplCopyWithImpl<$Res>
    extends _$PurchaseOrderItemCopyWithImpl<$Res, _$PurchaseOrderItemImpl>
    implements _$$PurchaseOrderItemImplCopyWith<$Res> {
  __$$PurchaseOrderItemImplCopyWithImpl(_$PurchaseOrderItemImpl _value,
      $Res Function(_$PurchaseOrderItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poId = null,
    Object? materialId = null,
    Object? materialCode = freezed,
    Object? materialName = freezed,
    Object? unit = freezed,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? totalPrice = null,
    Object? receivedQuantity = null,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$PurchaseOrderItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      poId: null == poId
          ? _value.poId
          : poId // ignore: cast_nullable_to_non_nullable
              as String,
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      materialCode: freezed == materialCode
          ? _value.materialCode
          : materialCode // ignore: cast_nullable_to_non_nullable
              as String?,
      materialName: freezed == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      totalPrice: null == totalPrice
          ? _value.totalPrice
          : totalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      receivedQuantity: null == receivedQuantity
          ? _value.receivedQuantity
          : receivedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
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
class _$PurchaseOrderItemImpl implements _PurchaseOrderItem {
  const _$PurchaseOrderItemImpl(
      {required this.id,
      required this.poId,
      required this.materialId,
      this.materialCode,
      this.materialName,
      this.unit,
      required this.quantity,
      required this.unitPrice,
      required this.totalPrice,
      required this.receivedQuantity,
      this.notes,
      required this.createdAt,
      required this.updatedAt});

  factory _$PurchaseOrderItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseOrderItemImplFromJson(json);

  @override
  final String id;
  @override
  final String poId;
  @override
  final String materialId;
  @override
  final String? materialCode;
  @override
  final String? materialName;
  @override
  final String? unit;
  @override
  final double quantity;
  @override
  final double unitPrice;
  @override
  final double totalPrice;
  @override
  final double receivedQuantity;
  @override
  final String? notes;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'PurchaseOrderItem(id: $id, poId: $poId, materialId: $materialId, materialCode: $materialCode, materialName: $materialName, unit: $unit, quantity: $quantity, unitPrice: $unitPrice, totalPrice: $totalPrice, receivedQuantity: $receivedQuantity, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseOrderItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.poId, poId) || other.poId == poId) &&
            (identical(other.materialId, materialId) ||
                other.materialId == materialId) &&
            (identical(other.materialCode, materialCode) ||
                other.materialCode == materialCode) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.totalPrice, totalPrice) ||
                other.totalPrice == totalPrice) &&
            (identical(other.receivedQuantity, receivedQuantity) ||
                other.receivedQuantity == receivedQuantity) &&
            (identical(other.notes, notes) || other.notes == notes) &&
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
      poId,
      materialId,
      materialCode,
      materialName,
      unit,
      quantity,
      unitPrice,
      totalPrice,
      receivedQuantity,
      notes,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseOrderItemImplCopyWith<_$PurchaseOrderItemImpl> get copyWith =>
      __$$PurchaseOrderItemImplCopyWithImpl<_$PurchaseOrderItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseOrderItemImplToJson(
      this,
    );
  }
}

abstract class _PurchaseOrderItem implements PurchaseOrderItem {
  const factory _PurchaseOrderItem(
      {required final String id,
      required final String poId,
      required final String materialId,
      final String? materialCode,
      final String? materialName,
      final String? unit,
      required final double quantity,
      required final double unitPrice,
      required final double totalPrice,
      required final double receivedQuantity,
      final String? notes,
      required final int createdAt,
      required final int updatedAt}) = _$PurchaseOrderItemImpl;

  factory _PurchaseOrderItem.fromJson(Map<String, dynamic> json) =
      _$PurchaseOrderItemImpl.fromJson;

  @override
  String get id;
  @override
  String get poId;
  @override
  String get materialId;
  @override
  String? get materialCode;
  @override
  String? get materialName;
  @override
  String? get unit;
  @override
  double get quantity;
  @override
  double get unitPrice;
  @override
  double get totalPrice;
  @override
  double get receivedQuantity;
  @override
  String? get notes;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseOrderItemImplCopyWith<_$PurchaseOrderItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GrnReceipt _$GrnReceiptFromJson(Map<String, dynamic> json) {
  return _GrnReceipt.fromJson(json);
}

/// @nodoc
mixin _$GrnReceipt {
  String get id => throw _privateConstructorUsedError;
  String get grnNumber => throw _privateConstructorUsedError;
  String? get poId => throw _privateConstructorUsedError;
  String? get poNumber => throw _privateConstructorUsedError;
  String? get supplierId => throw _privateConstructorUsedError;
  String? get supplierName => throw _privateConstructorUsedError;
  String? get invoiceNumber => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  int get receivedAt => throw _privateConstructorUsedError;
  int? get receivedDate => throw _privateConstructorUsedError;
  int? get createdAt => throw _privateConstructorUsedError;
  double? get totalQty => throw _privateConstructorUsedError;
  String? get itemsSummary => throw _privateConstructorUsedError;
  List<GrnItem>? get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GrnReceiptCopyWith<GrnReceipt> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GrnReceiptCopyWith<$Res> {
  factory $GrnReceiptCopyWith(
          GrnReceipt value, $Res Function(GrnReceipt) then) =
      _$GrnReceiptCopyWithImpl<$Res, GrnReceipt>;
  @useResult
  $Res call(
      {String id,
      String grnNumber,
      String? poId,
      String? poNumber,
      String? supplierId,
      String? supplierName,
      String? invoiceNumber,
      String? notes,
      int receivedAt,
      int? receivedDate,
      int? createdAt,
      double? totalQty,
      String? itemsSummary,
      List<GrnItem>? items});
}

/// @nodoc
class _$GrnReceiptCopyWithImpl<$Res, $Val extends GrnReceipt>
    implements $GrnReceiptCopyWith<$Res> {
  _$GrnReceiptCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? grnNumber = null,
    Object? poId = freezed,
    Object? poNumber = freezed,
    Object? supplierId = freezed,
    Object? supplierName = freezed,
    Object? invoiceNumber = freezed,
    Object? notes = freezed,
    Object? receivedAt = null,
    Object? receivedDate = freezed,
    Object? createdAt = freezed,
    Object? totalQty = freezed,
    Object? itemsSummary = freezed,
    Object? items = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      grnNumber: null == grnNumber
          ? _value.grnNumber
          : grnNumber // ignore: cast_nullable_to_non_nullable
              as String,
      poId: freezed == poId
          ? _value.poId
          : poId // ignore: cast_nullable_to_non_nullable
              as String?,
      poNumber: freezed == poNumber
          ? _value.poNumber
          : poNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      supplierId: freezed == supplierId
          ? _value.supplierId
          : supplierId // ignore: cast_nullable_to_non_nullable
              as String?,
      supplierName: freezed == supplierName
          ? _value.supplierName
          : supplierName // ignore: cast_nullable_to_non_nullable
              as String?,
      invoiceNumber: freezed == invoiceNumber
          ? _value.invoiceNumber
          : invoiceNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      receivedAt: null == receivedAt
          ? _value.receivedAt
          : receivedAt // ignore: cast_nullable_to_non_nullable
              as int,
      receivedDate: freezed == receivedDate
          ? _value.receivedDate
          : receivedDate // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int?,
      totalQty: freezed == totalQty
          ? _value.totalQty
          : totalQty // ignore: cast_nullable_to_non_nullable
              as double?,
      itemsSummary: freezed == itemsSummary
          ? _value.itemsSummary
          : itemsSummary // ignore: cast_nullable_to_non_nullable
              as String?,
      items: freezed == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<GrnItem>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GrnReceiptImplCopyWith<$Res>
    implements $GrnReceiptCopyWith<$Res> {
  factory _$$GrnReceiptImplCopyWith(
          _$GrnReceiptImpl value, $Res Function(_$GrnReceiptImpl) then) =
      __$$GrnReceiptImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String grnNumber,
      String? poId,
      String? poNumber,
      String? supplierId,
      String? supplierName,
      String? invoiceNumber,
      String? notes,
      int receivedAt,
      int? receivedDate,
      int? createdAt,
      double? totalQty,
      String? itemsSummary,
      List<GrnItem>? items});
}

/// @nodoc
class __$$GrnReceiptImplCopyWithImpl<$Res>
    extends _$GrnReceiptCopyWithImpl<$Res, _$GrnReceiptImpl>
    implements _$$GrnReceiptImplCopyWith<$Res> {
  __$$GrnReceiptImplCopyWithImpl(
      _$GrnReceiptImpl _value, $Res Function(_$GrnReceiptImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? grnNumber = null,
    Object? poId = freezed,
    Object? poNumber = freezed,
    Object? supplierId = freezed,
    Object? supplierName = freezed,
    Object? invoiceNumber = freezed,
    Object? notes = freezed,
    Object? receivedAt = null,
    Object? receivedDate = freezed,
    Object? createdAt = freezed,
    Object? totalQty = freezed,
    Object? itemsSummary = freezed,
    Object? items = freezed,
  }) {
    return _then(_$GrnReceiptImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      grnNumber: null == grnNumber
          ? _value.grnNumber
          : grnNumber // ignore: cast_nullable_to_non_nullable
              as String,
      poId: freezed == poId
          ? _value.poId
          : poId // ignore: cast_nullable_to_non_nullable
              as String?,
      poNumber: freezed == poNumber
          ? _value.poNumber
          : poNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      supplierId: freezed == supplierId
          ? _value.supplierId
          : supplierId // ignore: cast_nullable_to_non_nullable
              as String?,
      supplierName: freezed == supplierName
          ? _value.supplierName
          : supplierName // ignore: cast_nullable_to_non_nullable
              as String?,
      invoiceNumber: freezed == invoiceNumber
          ? _value.invoiceNumber
          : invoiceNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      receivedAt: null == receivedAt
          ? _value.receivedAt
          : receivedAt // ignore: cast_nullable_to_non_nullable
              as int,
      receivedDate: freezed == receivedDate
          ? _value.receivedDate
          : receivedDate // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int?,
      totalQty: freezed == totalQty
          ? _value.totalQty
          : totalQty // ignore: cast_nullable_to_non_nullable
              as double?,
      itemsSummary: freezed == itemsSummary
          ? _value.itemsSummary
          : itemsSummary // ignore: cast_nullable_to_non_nullable
              as String?,
      items: freezed == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<GrnItem>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GrnReceiptImpl implements _GrnReceipt {
  const _$GrnReceiptImpl(
      {required this.id,
      required this.grnNumber,
      this.poId,
      this.poNumber,
      this.supplierId,
      this.supplierName,
      this.invoiceNumber,
      this.notes,
      required this.receivedAt,
      this.receivedDate,
      this.createdAt,
      this.totalQty,
      this.itemsSummary,
      final List<GrnItem>? items})
      : _items = items;

  factory _$GrnReceiptImpl.fromJson(Map<String, dynamic> json) =>
      _$$GrnReceiptImplFromJson(json);

  @override
  final String id;
  @override
  final String grnNumber;
  @override
  final String? poId;
  @override
  final String? poNumber;
  @override
  final String? supplierId;
  @override
  final String? supplierName;
  @override
  final String? invoiceNumber;
  @override
  final String? notes;
  @override
  final int receivedAt;
  @override
  final int? receivedDate;
  @override
  final int? createdAt;
  @override
  final double? totalQty;
  @override
  final String? itemsSummary;
  final List<GrnItem>? _items;
  @override
  List<GrnItem>? get items {
    final value = _items;
    if (value == null) return null;
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'GrnReceipt(id: $id, grnNumber: $grnNumber, poId: $poId, poNumber: $poNumber, supplierId: $supplierId, supplierName: $supplierName, invoiceNumber: $invoiceNumber, notes: $notes, receivedAt: $receivedAt, receivedDate: $receivedDate, createdAt: $createdAt, totalQty: $totalQty, itemsSummary: $itemsSummary, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GrnReceiptImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.grnNumber, grnNumber) ||
                other.grnNumber == grnNumber) &&
            (identical(other.poId, poId) || other.poId == poId) &&
            (identical(other.poNumber, poNumber) ||
                other.poNumber == poNumber) &&
            (identical(other.supplierId, supplierId) ||
                other.supplierId == supplierId) &&
            (identical(other.supplierName, supplierName) ||
                other.supplierName == supplierName) &&
            (identical(other.invoiceNumber, invoiceNumber) ||
                other.invoiceNumber == invoiceNumber) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.receivedAt, receivedAt) ||
                other.receivedAt == receivedAt) &&
            (identical(other.receivedDate, receivedDate) ||
                other.receivedDate == receivedDate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.totalQty, totalQty) ||
                other.totalQty == totalQty) &&
            (identical(other.itemsSummary, itemsSummary) ||
                other.itemsSummary == itemsSummary) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      grnNumber,
      poId,
      poNumber,
      supplierId,
      supplierName,
      invoiceNumber,
      notes,
      receivedAt,
      receivedDate,
      createdAt,
      totalQty,
      itemsSummary,
      const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GrnReceiptImplCopyWith<_$GrnReceiptImpl> get copyWith =>
      __$$GrnReceiptImplCopyWithImpl<_$GrnReceiptImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GrnReceiptImplToJson(
      this,
    );
  }
}

abstract class _GrnReceipt implements GrnReceipt {
  const factory _GrnReceipt(
      {required final String id,
      required final String grnNumber,
      final String? poId,
      final String? poNumber,
      final String? supplierId,
      final String? supplierName,
      final String? invoiceNumber,
      final String? notes,
      required final int receivedAt,
      final int? receivedDate,
      final int? createdAt,
      final double? totalQty,
      final String? itemsSummary,
      final List<GrnItem>? items}) = _$GrnReceiptImpl;

  factory _GrnReceipt.fromJson(Map<String, dynamic> json) =
      _$GrnReceiptImpl.fromJson;

  @override
  String get id;
  @override
  String get grnNumber;
  @override
  String? get poId;
  @override
  String? get poNumber;
  @override
  String? get supplierId;
  @override
  String? get supplierName;
  @override
  String? get invoiceNumber;
  @override
  String? get notes;
  @override
  int get receivedAt;
  @override
  int? get receivedDate;
  @override
  int? get createdAt;
  @override
  double? get totalQty;
  @override
  String? get itemsSummary;
  @override
  List<GrnItem>? get items;
  @override
  @JsonKey(ignore: true)
  _$$GrnReceiptImplCopyWith<_$GrnReceiptImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GrnItem _$GrnItemFromJson(Map<String, dynamic> json) {
  return _GrnItem.fromJson(json);
}

/// @nodoc
mixin _$GrnItem {
  String get materialId => throw _privateConstructorUsedError;
  String? get materialCode => throw _privateConstructorUsedError;
  String? get materialName => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  double? get quantity => throw _privateConstructorUsedError;
  double get receivedQuantity => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GrnItemCopyWith<GrnItem> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GrnItemCopyWith<$Res> {
  factory $GrnItemCopyWith(GrnItem value, $Res Function(GrnItem) then) =
      _$GrnItemCopyWithImpl<$Res, GrnItem>;
  @useResult
  $Res call(
      {String materialId,
      String? materialCode,
      String? materialName,
      String? unit,
      double? quantity,
      double receivedQuantity});
}

/// @nodoc
class _$GrnItemCopyWithImpl<$Res, $Val extends GrnItem>
    implements $GrnItemCopyWith<$Res> {
  _$GrnItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? materialId = null,
    Object? materialCode = freezed,
    Object? materialName = freezed,
    Object? unit = freezed,
    Object? quantity = freezed,
    Object? receivedQuantity = null,
  }) {
    return _then(_value.copyWith(
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      materialCode: freezed == materialCode
          ? _value.materialCode
          : materialCode // ignore: cast_nullable_to_non_nullable
              as String?,
      materialName: freezed == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      receivedQuantity: null == receivedQuantity
          ? _value.receivedQuantity
          : receivedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GrnItemImplCopyWith<$Res> implements $GrnItemCopyWith<$Res> {
  factory _$$GrnItemImplCopyWith(
          _$GrnItemImpl value, $Res Function(_$GrnItemImpl) then) =
      __$$GrnItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String materialId,
      String? materialCode,
      String? materialName,
      String? unit,
      double? quantity,
      double receivedQuantity});
}

/// @nodoc
class __$$GrnItemImplCopyWithImpl<$Res>
    extends _$GrnItemCopyWithImpl<$Res, _$GrnItemImpl>
    implements _$$GrnItemImplCopyWith<$Res> {
  __$$GrnItemImplCopyWithImpl(
      _$GrnItemImpl _value, $Res Function(_$GrnItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? materialId = null,
    Object? materialCode = freezed,
    Object? materialName = freezed,
    Object? unit = freezed,
    Object? quantity = freezed,
    Object? receivedQuantity = null,
  }) {
    return _then(_$GrnItemImpl(
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      materialCode: freezed == materialCode
          ? _value.materialCode
          : materialCode // ignore: cast_nullable_to_non_nullable
              as String?,
      materialName: freezed == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      receivedQuantity: null == receivedQuantity
          ? _value.receivedQuantity
          : receivedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GrnItemImpl implements _GrnItem {
  const _$GrnItemImpl(
      {required this.materialId,
      this.materialCode,
      this.materialName,
      this.unit,
      this.quantity,
      required this.receivedQuantity});

  factory _$GrnItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$GrnItemImplFromJson(json);

  @override
  final String materialId;
  @override
  final String? materialCode;
  @override
  final String? materialName;
  @override
  final String? unit;
  @override
  final double? quantity;
  @override
  final double receivedQuantity;

  @override
  String toString() {
    return 'GrnItem(materialId: $materialId, materialCode: $materialCode, materialName: $materialName, unit: $unit, quantity: $quantity, receivedQuantity: $receivedQuantity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GrnItemImpl &&
            (identical(other.materialId, materialId) ||
                other.materialId == materialId) &&
            (identical(other.materialCode, materialCode) ||
                other.materialCode == materialCode) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.receivedQuantity, receivedQuantity) ||
                other.receivedQuantity == receivedQuantity));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, materialId, materialCode,
      materialName, unit, quantity, receivedQuantity);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GrnItemImplCopyWith<_$GrnItemImpl> get copyWith =>
      __$$GrnItemImplCopyWithImpl<_$GrnItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GrnItemImplToJson(
      this,
    );
  }
}

abstract class _GrnItem implements GrnItem {
  const factory _GrnItem(
      {required final String materialId,
      final String? materialCode,
      final String? materialName,
      final String? unit,
      final double? quantity,
      required final double receivedQuantity}) = _$GrnItemImpl;

  factory _GrnItem.fromJson(Map<String, dynamic> json) = _$GrnItemImpl.fromJson;

  @override
  String get materialId;
  @override
  String? get materialCode;
  @override
  String? get materialName;
  @override
  String? get unit;
  @override
  double? get quantity;
  @override
  double get receivedQuantity;
  @override
  @JsonKey(ignore: true)
  _$$GrnItemImplCopyWith<_$GrnItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GrnReceivePayload _$GrnReceivePayloadFromJson(Map<String, dynamic> json) {
  return _GrnReceivePayload.fromJson(json);
}

/// @nodoc
mixin _$GrnReceivePayload {
  String? get poId => throw _privateConstructorUsedError;
  String? get supplierId => throw _privateConstructorUsedError;
  String? get invoiceNumber => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  List<GrnReceiveItem> get receivedItems => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GrnReceivePayloadCopyWith<GrnReceivePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GrnReceivePayloadCopyWith<$Res> {
  factory $GrnReceivePayloadCopyWith(
          GrnReceivePayload value, $Res Function(GrnReceivePayload) then) =
      _$GrnReceivePayloadCopyWithImpl<$Res, GrnReceivePayload>;
  @useResult
  $Res call(
      {String? poId,
      String? supplierId,
      String? invoiceNumber,
      String? notes,
      List<GrnReceiveItem> receivedItems});
}

/// @nodoc
class _$GrnReceivePayloadCopyWithImpl<$Res, $Val extends GrnReceivePayload>
    implements $GrnReceivePayloadCopyWith<$Res> {
  _$GrnReceivePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? poId = freezed,
    Object? supplierId = freezed,
    Object? invoiceNumber = freezed,
    Object? notes = freezed,
    Object? receivedItems = null,
  }) {
    return _then(_value.copyWith(
      poId: freezed == poId
          ? _value.poId
          : poId // ignore: cast_nullable_to_non_nullable
              as String?,
      supplierId: freezed == supplierId
          ? _value.supplierId
          : supplierId // ignore: cast_nullable_to_non_nullable
              as String?,
      invoiceNumber: freezed == invoiceNumber
          ? _value.invoiceNumber
          : invoiceNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      receivedItems: null == receivedItems
          ? _value.receivedItems
          : receivedItems // ignore: cast_nullable_to_non_nullable
              as List<GrnReceiveItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GrnReceivePayloadImplCopyWith<$Res>
    implements $GrnReceivePayloadCopyWith<$Res> {
  factory _$$GrnReceivePayloadImplCopyWith(_$GrnReceivePayloadImpl value,
          $Res Function(_$GrnReceivePayloadImpl) then) =
      __$$GrnReceivePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? poId,
      String? supplierId,
      String? invoiceNumber,
      String? notes,
      List<GrnReceiveItem> receivedItems});
}

/// @nodoc
class __$$GrnReceivePayloadImplCopyWithImpl<$Res>
    extends _$GrnReceivePayloadCopyWithImpl<$Res, _$GrnReceivePayloadImpl>
    implements _$$GrnReceivePayloadImplCopyWith<$Res> {
  __$$GrnReceivePayloadImplCopyWithImpl(_$GrnReceivePayloadImpl _value,
      $Res Function(_$GrnReceivePayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? poId = freezed,
    Object? supplierId = freezed,
    Object? invoiceNumber = freezed,
    Object? notes = freezed,
    Object? receivedItems = null,
  }) {
    return _then(_$GrnReceivePayloadImpl(
      poId: freezed == poId
          ? _value.poId
          : poId // ignore: cast_nullable_to_non_nullable
              as String?,
      supplierId: freezed == supplierId
          ? _value.supplierId
          : supplierId // ignore: cast_nullable_to_non_nullable
              as String?,
      invoiceNumber: freezed == invoiceNumber
          ? _value.invoiceNumber
          : invoiceNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      receivedItems: null == receivedItems
          ? _value._receivedItems
          : receivedItems // ignore: cast_nullable_to_non_nullable
              as List<GrnReceiveItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GrnReceivePayloadImpl implements _GrnReceivePayload {
  const _$GrnReceivePayloadImpl(
      {this.poId,
      this.supplierId,
      this.invoiceNumber,
      this.notes,
      required final List<GrnReceiveItem> receivedItems})
      : _receivedItems = receivedItems;

  factory _$GrnReceivePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$GrnReceivePayloadImplFromJson(json);

  @override
  final String? poId;
  @override
  final String? supplierId;
  @override
  final String? invoiceNumber;
  @override
  final String? notes;
  final List<GrnReceiveItem> _receivedItems;
  @override
  List<GrnReceiveItem> get receivedItems {
    if (_receivedItems is EqualUnmodifiableListView) return _receivedItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_receivedItems);
  }

  @override
  String toString() {
    return 'GrnReceivePayload(poId: $poId, supplierId: $supplierId, invoiceNumber: $invoiceNumber, notes: $notes, receivedItems: $receivedItems)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GrnReceivePayloadImpl &&
            (identical(other.poId, poId) || other.poId == poId) &&
            (identical(other.supplierId, supplierId) ||
                other.supplierId == supplierId) &&
            (identical(other.invoiceNumber, invoiceNumber) ||
                other.invoiceNumber == invoiceNumber) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality()
                .equals(other._receivedItems, _receivedItems));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, poId, supplierId, invoiceNumber,
      notes, const DeepCollectionEquality().hash(_receivedItems));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GrnReceivePayloadImplCopyWith<_$GrnReceivePayloadImpl> get copyWith =>
      __$$GrnReceivePayloadImplCopyWithImpl<_$GrnReceivePayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GrnReceivePayloadImplToJson(
      this,
    );
  }
}

abstract class _GrnReceivePayload implements GrnReceivePayload {
  const factory _GrnReceivePayload(
          {final String? poId,
          final String? supplierId,
          final String? invoiceNumber,
          final String? notes,
          required final List<GrnReceiveItem> receivedItems}) =
      _$GrnReceivePayloadImpl;

  factory _GrnReceivePayload.fromJson(Map<String, dynamic> json) =
      _$GrnReceivePayloadImpl.fromJson;

  @override
  String? get poId;
  @override
  String? get supplierId;
  @override
  String? get invoiceNumber;
  @override
  String? get notes;
  @override
  List<GrnReceiveItem> get receivedItems;
  @override
  @JsonKey(ignore: true)
  _$$GrnReceivePayloadImplCopyWith<_$GrnReceivePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GrnReceiveItem _$GrnReceiveItemFromJson(Map<String, dynamic> json) {
  return _GrnReceiveItem.fromJson(json);
}

/// @nodoc
mixin _$GrnReceiveItem {
  String get materialId => throw _privateConstructorUsedError;
  double get receivedQty => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GrnReceiveItemCopyWith<GrnReceiveItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GrnReceiveItemCopyWith<$Res> {
  factory $GrnReceiveItemCopyWith(
          GrnReceiveItem value, $Res Function(GrnReceiveItem) then) =
      _$GrnReceiveItemCopyWithImpl<$Res, GrnReceiveItem>;
  @useResult
  $Res call({String materialId, double receivedQty});
}

/// @nodoc
class _$GrnReceiveItemCopyWithImpl<$Res, $Val extends GrnReceiveItem>
    implements $GrnReceiveItemCopyWith<$Res> {
  _$GrnReceiveItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? materialId = null,
    Object? receivedQty = null,
  }) {
    return _then(_value.copyWith(
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      receivedQty: null == receivedQty
          ? _value.receivedQty
          : receivedQty // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GrnReceiveItemImplCopyWith<$Res>
    implements $GrnReceiveItemCopyWith<$Res> {
  factory _$$GrnReceiveItemImplCopyWith(_$GrnReceiveItemImpl value,
          $Res Function(_$GrnReceiveItemImpl) then) =
      __$$GrnReceiveItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String materialId, double receivedQty});
}

/// @nodoc
class __$$GrnReceiveItemImplCopyWithImpl<$Res>
    extends _$GrnReceiveItemCopyWithImpl<$Res, _$GrnReceiveItemImpl>
    implements _$$GrnReceiveItemImplCopyWith<$Res> {
  __$$GrnReceiveItemImplCopyWithImpl(
      _$GrnReceiveItemImpl _value, $Res Function(_$GrnReceiveItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? materialId = null,
    Object? receivedQty = null,
  }) {
    return _then(_$GrnReceiveItemImpl(
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      receivedQty: null == receivedQty
          ? _value.receivedQty
          : receivedQty // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GrnReceiveItemImpl implements _GrnReceiveItem {
  const _$GrnReceiveItemImpl(
      {required this.materialId, required this.receivedQty});

  factory _$GrnReceiveItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$GrnReceiveItemImplFromJson(json);

  @override
  final String materialId;
  @override
  final double receivedQty;

  @override
  String toString() {
    return 'GrnReceiveItem(materialId: $materialId, receivedQty: $receivedQty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GrnReceiveItemImpl &&
            (identical(other.materialId, materialId) ||
                other.materialId == materialId) &&
            (identical(other.receivedQty, receivedQty) ||
                other.receivedQty == receivedQty));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, materialId, receivedQty);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GrnReceiveItemImplCopyWith<_$GrnReceiveItemImpl> get copyWith =>
      __$$GrnReceiveItemImplCopyWithImpl<_$GrnReceiveItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GrnReceiveItemImplToJson(
      this,
    );
  }
}

abstract class _GrnReceiveItem implements GrnReceiveItem {
  const factory _GrnReceiveItem(
      {required final String materialId,
      required final double receivedQty}) = _$GrnReceiveItemImpl;

  factory _GrnReceiveItem.fromJson(Map<String, dynamic> json) =
      _$GrnReceiveItemImpl.fromJson;

  @override
  String get materialId;
  @override
  double get receivedQty;
  @override
  @JsonKey(ignore: true)
  _$$GrnReceiveItemImplCopyWith<_$GrnReceiveItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
