// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Material _$MaterialFromJson(Map<String, dynamic> json) {
  return _Material.fromJson(json);
}

/// @nodoc
mixin _$Material {
  String get id => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  double get currentStock => throw _privateConstructorUsedError;
  double get minimumStock => throw _privateConstructorUsedError;
  double get maximumStock => throw _privateConstructorUsedError;
  double? get unitCost => throw _privateConstructorUsedError;
  String? get companyId => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MaterialCopyWith<Material> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaterialCopyWith<$Res> {
  factory $MaterialCopyWith(Material value, $Res Function(Material) then) =
      _$MaterialCopyWithImpl<$Res, Material>;
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      String category,
      String unit,
      double currentStock,
      double minimumStock,
      double maximumStock,
      double? unitCost,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$MaterialCopyWithImpl<$Res, $Val extends Material>
    implements $MaterialCopyWith<$Res> {
  _$MaterialCopyWithImpl(this._value, this._then);

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
    Object? category = null,
    Object? unit = null,
    Object? currentStock = null,
    Object? minimumStock = null,
    Object? maximumStock = null,
    Object? unitCost = freezed,
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
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      currentStock: null == currentStock
          ? _value.currentStock
          : currentStock // ignore: cast_nullable_to_non_nullable
              as double,
      minimumStock: null == minimumStock
          ? _value.minimumStock
          : minimumStock // ignore: cast_nullable_to_non_nullable
              as double,
      maximumStock: null == maximumStock
          ? _value.maximumStock
          : maximumStock // ignore: cast_nullable_to_non_nullable
              as double,
      unitCost: freezed == unitCost
          ? _value.unitCost
          : unitCost // ignore: cast_nullable_to_non_nullable
              as double?,
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
abstract class _$$MaterialImplCopyWith<$Res>
    implements $MaterialCopyWith<$Res> {
  factory _$$MaterialImplCopyWith(
          _$MaterialImpl value, $Res Function(_$MaterialImpl) then) =
      __$$MaterialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      String category,
      String unit,
      double currentStock,
      double minimumStock,
      double maximumStock,
      double? unitCost,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$MaterialImplCopyWithImpl<$Res>
    extends _$MaterialCopyWithImpl<$Res, _$MaterialImpl>
    implements _$$MaterialImplCopyWith<$Res> {
  __$$MaterialImplCopyWithImpl(
      _$MaterialImpl _value, $Res Function(_$MaterialImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? category = null,
    Object? unit = null,
    Object? currentStock = null,
    Object? minimumStock = null,
    Object? maximumStock = null,
    Object? unitCost = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$MaterialImpl(
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
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      currentStock: null == currentStock
          ? _value.currentStock
          : currentStock // ignore: cast_nullable_to_non_nullable
              as double,
      minimumStock: null == minimumStock
          ? _value.minimumStock
          : minimumStock // ignore: cast_nullable_to_non_nullable
              as double,
      maximumStock: null == maximumStock
          ? _value.maximumStock
          : maximumStock // ignore: cast_nullable_to_non_nullable
              as double,
      unitCost: freezed == unitCost
          ? _value.unitCost
          : unitCost // ignore: cast_nullable_to_non_nullable
              as double?,
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
class _$MaterialImpl extends _Material {
  const _$MaterialImpl(
      {required this.id,
      required this.code,
      required this.name,
      required this.category,
      required this.unit,
      required this.currentStock,
      required this.minimumStock,
      required this.maximumStock,
      this.unitCost,
      this.companyId,
      required this.createdAt,
      required this.updatedAt})
      : super._();

  factory _$MaterialImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaterialImplFromJson(json);

  @override
  final String id;
  @override
  final String code;
  @override
  final String name;
  @override
  final String category;
  @override
  final String unit;
  @override
  final double currentStock;
  @override
  final double minimumStock;
  @override
  final double maximumStock;
  @override
  final double? unitCost;
  @override
  final String? companyId;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'Material(id: $id, code: $code, name: $name, category: $category, unit: $unit, currentStock: $currentStock, minimumStock: $minimumStock, maximumStock: $maximumStock, unitCost: $unitCost, companyId: $companyId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaterialImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.currentStock, currentStock) ||
                other.currentStock == currentStock) &&
            (identical(other.minimumStock, minimumStock) ||
                other.minimumStock == minimumStock) &&
            (identical(other.maximumStock, maximumStock) ||
                other.maximumStock == maximumStock) &&
            (identical(other.unitCost, unitCost) ||
                other.unitCost == unitCost) &&
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
      category,
      unit,
      currentStock,
      minimumStock,
      maximumStock,
      unitCost,
      companyId,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MaterialImplCopyWith<_$MaterialImpl> get copyWith =>
      __$$MaterialImplCopyWithImpl<_$MaterialImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MaterialImplToJson(
      this,
    );
  }
}

abstract class _Material extends Material {
  const factory _Material(
      {required final String id,
      required final String code,
      required final String name,
      required final String category,
      required final String unit,
      required final double currentStock,
      required final double minimumStock,
      required final double maximumStock,
      final double? unitCost,
      final String? companyId,
      required final int createdAt,
      required final int updatedAt}) = _$MaterialImpl;
  const _Material._() : super._();

  factory _Material.fromJson(Map<String, dynamic> json) =
      _$MaterialImpl.fromJson;

  @override
  String get id;
  @override
  String get code;
  @override
  String get name;
  @override
  String get category;
  @override
  String get unit;
  @override
  double get currentStock;
  @override
  double get minimumStock;
  @override
  double get maximumStock;
  @override
  double? get unitCost;
  @override
  String? get companyId;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$MaterialImplCopyWith<_$MaterialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Product _$ProductFromJson(Map<String, dynamic> json) {
  return _Product.fromJson(json);
}

/// @nodoc
mixin _$Product {
  String get id => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  double? get standardRate => throw _privateConstructorUsedError;
  String? get companyId => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProductCopyWith<Product> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductCopyWith<$Res> {
  factory $ProductCopyWith(Product value, $Res Function(Product) then) =
      _$ProductCopyWithImpl<$Res, Product>;
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      String? categoryId,
      String unit,
      String? description,
      double? standardRate,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$ProductCopyWithImpl<$Res, $Val extends Product>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._value, this._then);

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
    Object? categoryId = freezed,
    Object? unit = null,
    Object? description = freezed,
    Object? standardRate = freezed,
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
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      standardRate: freezed == standardRate
          ? _value.standardRate
          : standardRate // ignore: cast_nullable_to_non_nullable
              as double?,
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
abstract class _$$ProductImplCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$$ProductImplCopyWith(
          _$ProductImpl value, $Res Function(_$ProductImpl) then) =
      __$$ProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      String? categoryId,
      String unit,
      String? description,
      double? standardRate,
      String? companyId,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$ProductImplCopyWithImpl<$Res>
    extends _$ProductCopyWithImpl<$Res, _$ProductImpl>
    implements _$$ProductImplCopyWith<$Res> {
  __$$ProductImplCopyWithImpl(
      _$ProductImpl _value, $Res Function(_$ProductImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? categoryId = freezed,
    Object? unit = null,
    Object? description = freezed,
    Object? standardRate = freezed,
    Object? companyId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ProductImpl(
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
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      standardRate: freezed == standardRate
          ? _value.standardRate
          : standardRate // ignore: cast_nullable_to_non_nullable
              as double?,
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
class _$ProductImpl implements _Product {
  const _$ProductImpl(
      {required this.id,
      required this.code,
      required this.name,
      this.categoryId,
      required this.unit,
      this.description,
      this.standardRate,
      this.companyId,
      required this.createdAt,
      required this.updatedAt});

  factory _$ProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductImplFromJson(json);

  @override
  final String id;
  @override
  final String code;
  @override
  final String name;
  @override
  final String? categoryId;
  @override
  final String unit;
  @override
  final String? description;
  @override
  final double? standardRate;
  @override
  final String? companyId;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'Product(id: $id, code: $code, name: $name, categoryId: $categoryId, unit: $unit, description: $description, standardRate: $standardRate, companyId: $companyId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.standardRate, standardRate) ||
                other.standardRate == standardRate) &&
            (identical(other.companyId, companyId) ||
                other.companyId == companyId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, code, name, categoryId, unit,
      description, standardRate, companyId, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      __$$ProductImplCopyWithImpl<_$ProductImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductImplToJson(
      this,
    );
  }
}

abstract class _Product implements Product {
  const factory _Product(
      {required final String id,
      required final String code,
      required final String name,
      final String? categoryId,
      required final String unit,
      final String? description,
      final double? standardRate,
      final String? companyId,
      required final int createdAt,
      required final int updatedAt}) = _$ProductImpl;

  factory _Product.fromJson(Map<String, dynamic> json) = _$ProductImpl.fromJson;

  @override
  String get id;
  @override
  String get code;
  @override
  String get name;
  @override
  String? get categoryId;
  @override
  String get unit;
  @override
  String? get description;
  @override
  double? get standardRate;
  @override
  String? get companyId;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProductCategory _$ProductCategoryFromJson(Map<String, dynamic> json) {
  return _ProductCategory.fromJson(json);
}

/// @nodoc
mixin _$ProductCategory {
  String get id => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProductCategoryCopyWith<ProductCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductCategoryCopyWith<$Res> {
  factory $ProductCategoryCopyWith(
          ProductCategory value, $Res Function(ProductCategory) then) =
      _$ProductCategoryCopyWithImpl<$Res, ProductCategory>;
  @useResult
  $Res call({String id, String code, String name, int createdAt});
}

/// @nodoc
class _$ProductCategoryCopyWithImpl<$Res, $Val extends ProductCategory>
    implements $ProductCategoryCopyWith<$Res> {
  _$ProductCategoryCopyWithImpl(this._value, this._then);

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
    Object? createdAt = null,
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
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProductCategoryImplCopyWith<$Res>
    implements $ProductCategoryCopyWith<$Res> {
  factory _$$ProductCategoryImplCopyWith(_$ProductCategoryImpl value,
          $Res Function(_$ProductCategoryImpl) then) =
      __$$ProductCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String code, String name, int createdAt});
}

/// @nodoc
class __$$ProductCategoryImplCopyWithImpl<$Res>
    extends _$ProductCategoryCopyWithImpl<$Res, _$ProductCategoryImpl>
    implements _$$ProductCategoryImplCopyWith<$Res> {
  __$$ProductCategoryImplCopyWithImpl(
      _$ProductCategoryImpl _value, $Res Function(_$ProductCategoryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? createdAt = null,
  }) {
    return _then(_$ProductCategoryImpl(
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
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductCategoryImpl implements _ProductCategory {
  const _$ProductCategoryImpl(
      {required this.id,
      required this.code,
      required this.name,
      required this.createdAt});

  factory _$ProductCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductCategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String code;
  @override
  final String name;
  @override
  final int createdAt;

  @override
  String toString() {
    return 'ProductCategory(id: $id, code: $code, name: $name, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, code, name, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductCategoryImplCopyWith<_$ProductCategoryImpl> get copyWith =>
      __$$ProductCategoryImplCopyWithImpl<_$ProductCategoryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductCategoryImplToJson(
      this,
    );
  }
}

abstract class _ProductCategory implements ProductCategory {
  const factory _ProductCategory(
      {required final String id,
      required final String code,
      required final String name,
      required final int createdAt}) = _$ProductCategoryImpl;

  factory _ProductCategory.fromJson(Map<String, dynamic> json) =
      _$ProductCategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get code;
  @override
  String get name;
  @override
  int get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ProductCategoryImplCopyWith<_$ProductCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Bom _$BomFromJson(Map<String, dynamic> json) {
  return _Bom.fromJson(json);
}

/// @nodoc
mixin _$Bom {
  String get id => throw _privateConstructorUsedError;
  String get productId => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  bool? get isActive => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BomCopyWith<Bom> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BomCopyWith<$Res> {
  factory $BomCopyWith(Bom value, $Res Function(Bom) then) =
      _$BomCopyWithImpl<$Res, Bom>;
  @useResult
  $Res call(
      {String id,
      String productId,
      String version,
      bool? isActive,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$BomCopyWithImpl<$Res, $Val extends Bom> implements $BomCopyWith<$Res> {
  _$BomCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = null,
    Object? version = null,
    Object? isActive = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: freezed == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool?,
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
abstract class _$$BomImplCopyWith<$Res> implements $BomCopyWith<$Res> {
  factory _$$BomImplCopyWith(_$BomImpl value, $Res Function(_$BomImpl) then) =
      __$$BomImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String productId,
      String version,
      bool? isActive,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$BomImplCopyWithImpl<$Res> extends _$BomCopyWithImpl<$Res, _$BomImpl>
    implements _$$BomImplCopyWith<$Res> {
  __$$BomImplCopyWithImpl(_$BomImpl _value, $Res Function(_$BomImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = null,
    Object? version = null,
    Object? isActive = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$BomImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: freezed == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool?,
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
class _$BomImpl implements _Bom {
  const _$BomImpl(
      {required this.id,
      required this.productId,
      required this.version,
      this.isActive,
      required this.createdAt,
      required this.updatedAt});

  factory _$BomImpl.fromJson(Map<String, dynamic> json) =>
      _$$BomImplFromJson(json);

  @override
  final String id;
  @override
  final String productId;
  @override
  final String version;
  @override
  final bool? isActive;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'Bom(id: $id, productId: $productId, version: $version, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BomImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, productId, version, isActive, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BomImplCopyWith<_$BomImpl> get copyWith =>
      __$$BomImplCopyWithImpl<_$BomImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BomImplToJson(
      this,
    );
  }
}

abstract class _Bom implements Bom {
  const factory _Bom(
      {required final String id,
      required final String productId,
      required final String version,
      final bool? isActive,
      required final int createdAt,
      required final int updatedAt}) = _$BomImpl;

  factory _Bom.fromJson(Map<String, dynamic> json) = _$BomImpl.fromJson;

  @override
  String get id;
  @override
  String get productId;
  @override
  String get version;
  @override
  bool? get isActive;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$BomImplCopyWith<_$BomImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BomItem _$BomItemFromJson(Map<String, dynamic> json) {
  return _BomItem.fromJson(json);
}

/// @nodoc
mixin _$BomItem {
  String get id => throw _privateConstructorUsedError;
  String get bomId => throw _privateConstructorUsedError;
  String get materialId => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  String? get materialCode => throw _privateConstructorUsedError;
  String? get materialName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BomItemCopyWith<BomItem> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BomItemCopyWith<$Res> {
  factory $BomItemCopyWith(BomItem value, $Res Function(BomItem) then) =
      _$BomItemCopyWithImpl<$Res, BomItem>;
  @useResult
  $Res call(
      {String id,
      String bomId,
      String materialId,
      double quantity,
      String unit,
      String? materialCode,
      String? materialName});
}

/// @nodoc
class _$BomItemCopyWithImpl<$Res, $Val extends BomItem>
    implements $BomItemCopyWith<$Res> {
  _$BomItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bomId = null,
    Object? materialId = null,
    Object? quantity = null,
    Object? unit = null,
    Object? materialCode = freezed,
    Object? materialName = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      bomId: null == bomId
          ? _value.bomId
          : bomId // ignore: cast_nullable_to_non_nullable
              as String,
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      materialCode: freezed == materialCode
          ? _value.materialCode
          : materialCode // ignore: cast_nullable_to_non_nullable
              as String?,
      materialName: freezed == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BomItemImplCopyWith<$Res> implements $BomItemCopyWith<$Res> {
  factory _$$BomItemImplCopyWith(
          _$BomItemImpl value, $Res Function(_$BomItemImpl) then) =
      __$$BomItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String bomId,
      String materialId,
      double quantity,
      String unit,
      String? materialCode,
      String? materialName});
}

/// @nodoc
class __$$BomItemImplCopyWithImpl<$Res>
    extends _$BomItemCopyWithImpl<$Res, _$BomItemImpl>
    implements _$$BomItemImplCopyWith<$Res> {
  __$$BomItemImplCopyWithImpl(
      _$BomItemImpl _value, $Res Function(_$BomItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bomId = null,
    Object? materialId = null,
    Object? quantity = null,
    Object? unit = null,
    Object? materialCode = freezed,
    Object? materialName = freezed,
  }) {
    return _then(_$BomItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      bomId: null == bomId
          ? _value.bomId
          : bomId // ignore: cast_nullable_to_non_nullable
              as String,
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      materialCode: freezed == materialCode
          ? _value.materialCode
          : materialCode // ignore: cast_nullable_to_non_nullable
              as String?,
      materialName: freezed == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BomItemImpl implements _BomItem {
  const _$BomItemImpl(
      {required this.id,
      required this.bomId,
      required this.materialId,
      required this.quantity,
      required this.unit,
      this.materialCode,
      this.materialName});

  factory _$BomItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$BomItemImplFromJson(json);

  @override
  final String id;
  @override
  final String bomId;
  @override
  final String materialId;
  @override
  final double quantity;
  @override
  final String unit;
  @override
  final String? materialCode;
  @override
  final String? materialName;

  @override
  String toString() {
    return 'BomItem(id: $id, bomId: $bomId, materialId: $materialId, quantity: $quantity, unit: $unit, materialCode: $materialCode, materialName: $materialName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BomItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bomId, bomId) || other.bomId == bomId) &&
            (identical(other.materialId, materialId) ||
                other.materialId == materialId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.materialCode, materialCode) ||
                other.materialCode == materialCode) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, bomId, materialId, quantity,
      unit, materialCode, materialName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BomItemImplCopyWith<_$BomItemImpl> get copyWith =>
      __$$BomItemImplCopyWithImpl<_$BomItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BomItemImplToJson(
      this,
    );
  }
}

abstract class _BomItem implements BomItem {
  const factory _BomItem(
      {required final String id,
      required final String bomId,
      required final String materialId,
      required final double quantity,
      required final String unit,
      final String? materialCode,
      final String? materialName}) = _$BomItemImpl;

  factory _BomItem.fromJson(Map<String, dynamic> json) = _$BomItemImpl.fromJson;

  @override
  String get id;
  @override
  String get bomId;
  @override
  String get materialId;
  @override
  double get quantity;
  @override
  String get unit;
  @override
  String? get materialCode;
  @override
  String? get materialName;
  @override
  @JsonKey(ignore: true)
  _$$BomItemImplCopyWith<_$BomItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StockTransaction _$StockTransactionFromJson(Map<String, dynamic> json) {
  return _StockTransaction.fromJson(json);
}

/// @nodoc
mixin _$StockTransaction {
  String get id => throw _privateConstructorUsedError;
  String get materialId => throw _privateConstructorUsedError;
  String? get materialCode => throw _privateConstructorUsedError;
  String? get materialName => throw _privateConstructorUsedError;
  String? get productName => throw _privateConstructorUsedError;
  String get transactionType => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  double get balanceAfter => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  String? get referenceType => throw _privateConstructorUsedError;
  String? get referenceId => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StockTransactionCopyWith<StockTransaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockTransactionCopyWith<$Res> {
  factory $StockTransactionCopyWith(
          StockTransaction value, $Res Function(StockTransaction) then) =
      _$StockTransactionCopyWithImpl<$Res, StockTransaction>;
  @useResult
  $Res call(
      {String id,
      String materialId,
      String? materialCode,
      String? materialName,
      String? productName,
      String transactionType,
      double quantity,
      double balanceAfter,
      String unit,
      String? referenceType,
      String? referenceId,
      String? notes,
      int createdAt});
}

/// @nodoc
class _$StockTransactionCopyWithImpl<$Res, $Val extends StockTransaction>
    implements $StockTransactionCopyWith<$Res> {
  _$StockTransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? materialId = null,
    Object? materialCode = freezed,
    Object? materialName = freezed,
    Object? productName = freezed,
    Object? transactionType = null,
    Object? quantity = null,
    Object? balanceAfter = null,
    Object? unit = null,
    Object? referenceType = freezed,
    Object? referenceId = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      productName: freezed == productName
          ? _value.productName
          : productName // ignore: cast_nullable_to_non_nullable
              as String?,
      transactionType: null == transactionType
          ? _value.transactionType
          : transactionType // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      balanceAfter: null == balanceAfter
          ? _value.balanceAfter
          : balanceAfter // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      referenceType: freezed == referenceType
          ? _value.referenceType
          : referenceType // ignore: cast_nullable_to_non_nullable
              as String?,
      referenceId: freezed == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StockTransactionImplCopyWith<$Res>
    implements $StockTransactionCopyWith<$Res> {
  factory _$$StockTransactionImplCopyWith(_$StockTransactionImpl value,
          $Res Function(_$StockTransactionImpl) then) =
      __$$StockTransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String materialId,
      String? materialCode,
      String? materialName,
      String? productName,
      String transactionType,
      double quantity,
      double balanceAfter,
      String unit,
      String? referenceType,
      String? referenceId,
      String? notes,
      int createdAt});
}

/// @nodoc
class __$$StockTransactionImplCopyWithImpl<$Res>
    extends _$StockTransactionCopyWithImpl<$Res, _$StockTransactionImpl>
    implements _$$StockTransactionImplCopyWith<$Res> {
  __$$StockTransactionImplCopyWithImpl(_$StockTransactionImpl _value,
      $Res Function(_$StockTransactionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? materialId = null,
    Object? materialCode = freezed,
    Object? materialName = freezed,
    Object? productName = freezed,
    Object? transactionType = null,
    Object? quantity = null,
    Object? balanceAfter = null,
    Object? unit = null,
    Object? referenceType = freezed,
    Object? referenceId = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$StockTransactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      productName: freezed == productName
          ? _value.productName
          : productName // ignore: cast_nullable_to_non_nullable
              as String?,
      transactionType: null == transactionType
          ? _value.transactionType
          : transactionType // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      balanceAfter: null == balanceAfter
          ? _value.balanceAfter
          : balanceAfter // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      referenceType: freezed == referenceType
          ? _value.referenceType
          : referenceType // ignore: cast_nullable_to_non_nullable
              as String?,
      referenceId: freezed == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
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
class _$StockTransactionImpl implements _StockTransaction {
  const _$StockTransactionImpl(
      {required this.id,
      required this.materialId,
      this.materialCode,
      this.materialName,
      this.productName,
      required this.transactionType,
      required this.quantity,
      required this.balanceAfter,
      required this.unit,
      this.referenceType,
      this.referenceId,
      this.notes,
      required this.createdAt});

  factory _$StockTransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$StockTransactionImplFromJson(json);

  @override
  final String id;
  @override
  final String materialId;
  @override
  final String? materialCode;
  @override
  final String? materialName;
  @override
  final String? productName;
  @override
  final String transactionType;
  @override
  final double quantity;
  @override
  final double balanceAfter;
  @override
  final String unit;
  @override
  final String? referenceType;
  @override
  final String? referenceId;
  @override
  final String? notes;
  @override
  final int createdAt;

  @override
  String toString() {
    return 'StockTransaction(id: $id, materialId: $materialId, materialCode: $materialCode, materialName: $materialName, productName: $productName, transactionType: $transactionType, quantity: $quantity, balanceAfter: $balanceAfter, unit: $unit, referenceType: $referenceType, referenceId: $referenceId, notes: $notes, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockTransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.materialId, materialId) ||
                other.materialId == materialId) &&
            (identical(other.materialCode, materialCode) ||
                other.materialCode == materialCode) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.transactionType, transactionType) ||
                other.transactionType == transactionType) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.balanceAfter, balanceAfter) ||
                other.balanceAfter == balanceAfter) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.referenceType, referenceType) ||
                other.referenceType == referenceType) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      materialId,
      materialCode,
      materialName,
      productName,
      transactionType,
      quantity,
      balanceAfter,
      unit,
      referenceType,
      referenceId,
      notes,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StockTransactionImplCopyWith<_$StockTransactionImpl> get copyWith =>
      __$$StockTransactionImplCopyWithImpl<_$StockTransactionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StockTransactionImplToJson(
      this,
    );
  }
}

abstract class _StockTransaction implements StockTransaction {
  const factory _StockTransaction(
      {required final String id,
      required final String materialId,
      final String? materialCode,
      final String? materialName,
      final String? productName,
      required final String transactionType,
      required final double quantity,
      required final double balanceAfter,
      required final String unit,
      final String? referenceType,
      final String? referenceId,
      final String? notes,
      required final int createdAt}) = _$StockTransactionImpl;

  factory _StockTransaction.fromJson(Map<String, dynamic> json) =
      _$StockTransactionImpl.fromJson;

  @override
  String get id;
  @override
  String get materialId;
  @override
  String? get materialCode;
  @override
  String? get materialName;
  @override
  String? get productName;
  @override
  String get transactionType;
  @override
  double get quantity;
  @override
  double get balanceAfter;
  @override
  String get unit;
  @override
  String? get referenceType;
  @override
  String? get referenceId;
  @override
  String? get notes;
  @override
  int get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$StockTransactionImplCopyWith<_$StockTransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
