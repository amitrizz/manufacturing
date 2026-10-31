// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'common.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Notification _$NotificationFromJson(Map<String, dynamic> json) {
  return _Notification.fromJson(json);
}

/// @nodoc
mixin _$Notification {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  String get severity => throw _privateConstructorUsedError;
  int get isRead => throw _privateConstructorUsedError;
  String? get referenceType => throw _privateConstructorUsedError;
  String? get referenceId => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NotificationCopyWith<Notification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationCopyWith<$Res> {
  factory $NotificationCopyWith(
          Notification value, $Res Function(Notification) then) =
      _$NotificationCopyWithImpl<$Res, Notification>;
  @useResult
  $Res call(
      {String id,
      String title,
      String body,
      String severity,
      int isRead,
      String? referenceType,
      String? referenceId,
      int createdAt});
}

/// @nodoc
class _$NotificationCopyWithImpl<$Res, $Val extends Notification>
    implements $NotificationCopyWith<$Res> {
  _$NotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? body = null,
    Object? severity = null,
    Object? isRead = null,
    Object? referenceType = freezed,
    Object? referenceId = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as String,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as int,
      referenceType: freezed == referenceType
          ? _value.referenceType
          : referenceType // ignore: cast_nullable_to_non_nullable
              as String?,
      referenceId: freezed == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationImplCopyWith<$Res>
    implements $NotificationCopyWith<$Res> {
  factory _$$NotificationImplCopyWith(
          _$NotificationImpl value, $Res Function(_$NotificationImpl) then) =
      __$$NotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String body,
      String severity,
      int isRead,
      String? referenceType,
      String? referenceId,
      int createdAt});
}

/// @nodoc
class __$$NotificationImplCopyWithImpl<$Res>
    extends _$NotificationCopyWithImpl<$Res, _$NotificationImpl>
    implements _$$NotificationImplCopyWith<$Res> {
  __$$NotificationImplCopyWithImpl(
      _$NotificationImpl _value, $Res Function(_$NotificationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? body = null,
    Object? severity = null,
    Object? isRead = null,
    Object? referenceType = freezed,
    Object? referenceId = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$NotificationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as String,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as int,
      referenceType: freezed == referenceType
          ? _value.referenceType
          : referenceType // ignore: cast_nullable_to_non_nullable
              as String?,
      referenceId: freezed == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
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
class _$NotificationImpl extends _Notification {
  const _$NotificationImpl(
      {required this.id,
      required this.title,
      required this.body,
      required this.severity,
      required this.isRead,
      this.referenceType,
      this.referenceId,
      required this.createdAt})
      : super._();

  factory _$NotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String body;
  @override
  final String severity;
  @override
  final int isRead;
  @override
  final String? referenceType;
  @override
  final String? referenceId;
  @override
  final int createdAt;

  @override
  String toString() {
    return 'Notification(id: $id, title: $title, body: $body, severity: $severity, isRead: $isRead, referenceType: $referenceType, referenceId: $referenceId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.referenceType, referenceType) ||
                other.referenceType == referenceType) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, body, severity,
      isRead, referenceType, referenceId, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      __$$NotificationImplCopyWithImpl<_$NotificationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationImplToJson(
      this,
    );
  }
}

abstract class _Notification extends Notification {
  const factory _Notification(
      {required final String id,
      required final String title,
      required final String body,
      required final String severity,
      required final int isRead,
      final String? referenceType,
      final String? referenceId,
      required final int createdAt}) = _$NotificationImpl;
  const _Notification._() : super._();

  factory _Notification.fromJson(Map<String, dynamic> json) =
      _$NotificationImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get body;
  @override
  String get severity;
  @override
  int get isRead;
  @override
  String? get referenceType;
  @override
  String? get referenceId;
  @override
  int get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Unit _$UnitFromJson(Map<String, dynamic> json) {
  return _Unit.fromJson(json);
}

/// @nodoc
mixin _$Unit {
  String get id => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get symbol => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  int get precision => throw _privateConstructorUsedError;
  bool? get isCustom => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UnitCopyWith<Unit> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnitCopyWith<$Res> {
  factory $UnitCopyWith(Unit value, $Res Function(Unit) then) =
      _$UnitCopyWithImpl<$Res, Unit>;
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      String symbol,
      String category,
      int precision,
      bool? isCustom,
      String? description,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class _$UnitCopyWithImpl<$Res, $Val extends Unit>
    implements $UnitCopyWith<$Res> {
  _$UnitCopyWithImpl(this._value, this._then);

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
    Object? symbol = null,
    Object? category = null,
    Object? precision = null,
    Object? isCustom = freezed,
    Object? description = freezed,
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
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      precision: null == precision
          ? _value.precision
          : precision // ignore: cast_nullable_to_non_nullable
              as int,
      isCustom: freezed == isCustom
          ? _value.isCustom
          : isCustom // ignore: cast_nullable_to_non_nullable
              as bool?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
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
abstract class _$$UnitImplCopyWith<$Res> implements $UnitCopyWith<$Res> {
  factory _$$UnitImplCopyWith(
          _$UnitImpl value, $Res Function(_$UnitImpl) then) =
      __$$UnitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      String symbol,
      String category,
      int precision,
      bool? isCustom,
      String? description,
      int createdAt,
      int updatedAt});
}

/// @nodoc
class __$$UnitImplCopyWithImpl<$Res>
    extends _$UnitCopyWithImpl<$Res, _$UnitImpl>
    implements _$$UnitImplCopyWith<$Res> {
  __$$UnitImplCopyWithImpl(_$UnitImpl _value, $Res Function(_$UnitImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? symbol = null,
    Object? category = null,
    Object? precision = null,
    Object? isCustom = freezed,
    Object? description = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$UnitImpl(
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
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      precision: null == precision
          ? _value.precision
          : precision // ignore: cast_nullable_to_non_nullable
              as int,
      isCustom: freezed == isCustom
          ? _value.isCustom
          : isCustom // ignore: cast_nullable_to_non_nullable
              as bool?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
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
class _$UnitImpl implements _Unit {
  const _$UnitImpl(
      {required this.id,
      required this.code,
      required this.name,
      required this.symbol,
      required this.category,
      required this.precision,
      this.isCustom,
      this.description,
      required this.createdAt,
      required this.updatedAt});

  factory _$UnitImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnitImplFromJson(json);

  @override
  final String id;
  @override
  final String code;
  @override
  final String name;
  @override
  final String symbol;
  @override
  final String category;
  @override
  final int precision;
  @override
  final bool? isCustom;
  @override
  final String? description;
  @override
  final int createdAt;
  @override
  final int updatedAt;

  @override
  String toString() {
    return 'Unit(id: $id, code: $code, name: $name, symbol: $symbol, category: $category, precision: $precision, isCustom: $isCustom, description: $description, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnitImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.precision, precision) ||
                other.precision == precision) &&
            (identical(other.isCustom, isCustom) ||
                other.isCustom == isCustom) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, code, name, symbol, category,
      precision, isCustom, description, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UnitImplCopyWith<_$UnitImpl> get copyWith =>
      __$$UnitImplCopyWithImpl<_$UnitImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UnitImplToJson(
      this,
    );
  }
}

abstract class _Unit implements Unit {
  const factory _Unit(
      {required final String id,
      required final String code,
      required final String name,
      required final String symbol,
      required final String category,
      required final int precision,
      final bool? isCustom,
      final String? description,
      required final int createdAt,
      required final int updatedAt}) = _$UnitImpl;

  factory _Unit.fromJson(Map<String, dynamic> json) = _$UnitImpl.fromJson;

  @override
  String get id;
  @override
  String get code;
  @override
  String get name;
  @override
  String get symbol;
  @override
  String get category;
  @override
  int get precision;
  @override
  bool? get isCustom;
  @override
  String? get description;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$UnitImplCopyWith<_$UnitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Pagination _$PaginationFromJson(Map<String, dynamic> json) {
  return _Pagination.fromJson(json);
}

/// @nodoc
mixin _$Pagination {
  int get total => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  int get skip => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PaginationCopyWith<Pagination> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaginationCopyWith<$Res> {
  factory $PaginationCopyWith(
          Pagination value, $Res Function(Pagination) then) =
      _$PaginationCopyWithImpl<$Res, Pagination>;
  @useResult
  $Res call({int total, int limit, int skip, bool hasMore});
}

/// @nodoc
class _$PaginationCopyWithImpl<$Res, $Val extends Pagination>
    implements $PaginationCopyWith<$Res> {
  _$PaginationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? limit = null,
    Object? skip = null,
    Object? hasMore = null,
  }) {
    return _then(_value.copyWith(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      skip: null == skip
          ? _value.skip
          : skip // ignore: cast_nullable_to_non_nullable
              as int,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaginationImplCopyWith<$Res>
    implements $PaginationCopyWith<$Res> {
  factory _$$PaginationImplCopyWith(
          _$PaginationImpl value, $Res Function(_$PaginationImpl) then) =
      __$$PaginationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int total, int limit, int skip, bool hasMore});
}

/// @nodoc
class __$$PaginationImplCopyWithImpl<$Res>
    extends _$PaginationCopyWithImpl<$Res, _$PaginationImpl>
    implements _$$PaginationImplCopyWith<$Res> {
  __$$PaginationImplCopyWithImpl(
      _$PaginationImpl _value, $Res Function(_$PaginationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? limit = null,
    Object? skip = null,
    Object? hasMore = null,
  }) {
    return _then(_$PaginationImpl(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      skip: null == skip
          ? _value.skip
          : skip // ignore: cast_nullable_to_non_nullable
              as int,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PaginationImpl implements _Pagination {
  const _$PaginationImpl(
      {required this.total,
      required this.limit,
      required this.skip,
      required this.hasMore});

  factory _$PaginationImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaginationImplFromJson(json);

  @override
  final int total;
  @override
  final int limit;
  @override
  final int skip;
  @override
  final bool hasMore;

  @override
  String toString() {
    return 'Pagination(total: $total, limit: $limit, skip: $skip, hasMore: $hasMore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaginationImpl &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.skip, skip) || other.skip == skip) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, total, limit, skip, hasMore);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PaginationImplCopyWith<_$PaginationImpl> get copyWith =>
      __$$PaginationImplCopyWithImpl<_$PaginationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaginationImplToJson(
      this,
    );
  }
}

abstract class _Pagination implements Pagination {
  const factory _Pagination(
      {required final int total,
      required final int limit,
      required final int skip,
      required final bool hasMore}) = _$PaginationImpl;

  factory _Pagination.fromJson(Map<String, dynamic> json) =
      _$PaginationImpl.fromJson;

  @override
  int get total;
  @override
  int get limit;
  @override
  int get skip;
  @override
  bool get hasMore;
  @override
  @JsonKey(ignore: true)
  _$$PaginationImplCopyWith<_$PaginationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ApiError _$ApiErrorFromJson(Map<String, dynamic> json) {
  return _ApiError.fromJson(json);
}

/// @nodoc
mixin _$ApiError {
  String get error => throw _privateConstructorUsedError;
  int? get status => throw _privateConstructorUsedError;
  Map<String, dynamic>? get details => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ApiErrorCopyWith<ApiError> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiErrorCopyWith<$Res> {
  factory $ApiErrorCopyWith(ApiError value, $Res Function(ApiError) then) =
      _$ApiErrorCopyWithImpl<$Res, ApiError>;
  @useResult
  $Res call({String error, int? status, Map<String, dynamic>? details});
}

/// @nodoc
class _$ApiErrorCopyWithImpl<$Res, $Val extends ApiError>
    implements $ApiErrorCopyWith<$Res> {
  _$ApiErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = null,
    Object? status = freezed,
    Object? details = freezed,
  }) {
    return _then(_value.copyWith(
      error: null == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as int?,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApiErrorImplCopyWith<$Res>
    implements $ApiErrorCopyWith<$Res> {
  factory _$$ApiErrorImplCopyWith(
          _$ApiErrorImpl value, $Res Function(_$ApiErrorImpl) then) =
      __$$ApiErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String error, int? status, Map<String, dynamic>? details});
}

/// @nodoc
class __$$ApiErrorImplCopyWithImpl<$Res>
    extends _$ApiErrorCopyWithImpl<$Res, _$ApiErrorImpl>
    implements _$$ApiErrorImplCopyWith<$Res> {
  __$$ApiErrorImplCopyWithImpl(
      _$ApiErrorImpl _value, $Res Function(_$ApiErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = null,
    Object? status = freezed,
    Object? details = freezed,
  }) {
    return _then(_$ApiErrorImpl(
      error: null == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as int?,
      details: freezed == details
          ? _value._details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApiErrorImpl implements _ApiError {
  const _$ApiErrorImpl(
      {required this.error, this.status, final Map<String, dynamic>? details})
      : _details = details;

  factory _$ApiErrorImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApiErrorImplFromJson(json);

  @override
  final String error;
  @override
  final int? status;
  final Map<String, dynamic>? _details;
  @override
  Map<String, dynamic>? get details {
    final value = _details;
    if (value == null) return null;
    if (_details is EqualUnmodifiableMapView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'ApiError(error: $error, status: $status, details: $details)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiErrorImpl &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._details, _details));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, error, status,
      const DeepCollectionEquality().hash(_details));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiErrorImplCopyWith<_$ApiErrorImpl> get copyWith =>
      __$$ApiErrorImplCopyWithImpl<_$ApiErrorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApiErrorImplToJson(
      this,
    );
  }
}

abstract class _ApiError implements ApiError {
  const factory _ApiError(
      {required final String error,
      final int? status,
      final Map<String, dynamic>? details}) = _$ApiErrorImpl;

  factory _ApiError.fromJson(Map<String, dynamic> json) =
      _$ApiErrorImpl.fromJson;

  @override
  String get error;
  @override
  int? get status;
  @override
  Map<String, dynamic>? get details;
  @override
  @JsonKey(ignore: true)
  _$$ApiErrorImplCopyWith<_$ApiErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HealthResponse _$HealthResponseFromJson(Map<String, dynamic> json) {
  return _HealthResponse.fromJson(json);
}

/// @nodoc
mixin _$HealthResponse {
  String get status => throw _privateConstructorUsedError;
  String get database => throw _privateConstructorUsedError;
  int get collectionsCount => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  int get timestamp => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HealthResponseCopyWith<HealthResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthResponseCopyWith<$Res> {
  factory $HealthResponseCopyWith(
          HealthResponse value, $Res Function(HealthResponse) then) =
      _$HealthResponseCopyWithImpl<$Res, HealthResponse>;
  @useResult
  $Res call(
      {String status,
      String database,
      int collectionsCount,
      String version,
      int timestamp});
}

/// @nodoc
class _$HealthResponseCopyWithImpl<$Res, $Val extends HealthResponse>
    implements $HealthResponseCopyWith<$Res> {
  _$HealthResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? database = null,
    Object? collectionsCount = null,
    Object? version = null,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      database: null == database
          ? _value.database
          : database // ignore: cast_nullable_to_non_nullable
              as String,
      collectionsCount: null == collectionsCount
          ? _value.collectionsCount
          : collectionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HealthResponseImplCopyWith<$Res>
    implements $HealthResponseCopyWith<$Res> {
  factory _$$HealthResponseImplCopyWith(_$HealthResponseImpl value,
          $Res Function(_$HealthResponseImpl) then) =
      __$$HealthResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String status,
      String database,
      int collectionsCount,
      String version,
      int timestamp});
}

/// @nodoc
class __$$HealthResponseImplCopyWithImpl<$Res>
    extends _$HealthResponseCopyWithImpl<$Res, _$HealthResponseImpl>
    implements _$$HealthResponseImplCopyWith<$Res> {
  __$$HealthResponseImplCopyWithImpl(
      _$HealthResponseImpl _value, $Res Function(_$HealthResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? database = null,
    Object? collectionsCount = null,
    Object? version = null,
    Object? timestamp = null,
  }) {
    return _then(_$HealthResponseImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      database: null == database
          ? _value.database
          : database // ignore: cast_nullable_to_non_nullable
              as String,
      collectionsCount: null == collectionsCount
          ? _value.collectionsCount
          : collectionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HealthResponseImpl implements _HealthResponse {
  const _$HealthResponseImpl(
      {required this.status,
      required this.database,
      required this.collectionsCount,
      required this.version,
      required this.timestamp});

  factory _$HealthResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$HealthResponseImplFromJson(json);

  @override
  final String status;
  @override
  final String database;
  @override
  final int collectionsCount;
  @override
  final String version;
  @override
  final int timestamp;

  @override
  String toString() {
    return 'HealthResponse(status: $status, database: $database, collectionsCount: $collectionsCount, version: $version, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthResponseImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.database, database) ||
                other.database == database) &&
            (identical(other.collectionsCount, collectionsCount) ||
                other.collectionsCount == collectionsCount) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, status, database, collectionsCount, version, timestamp);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthResponseImplCopyWith<_$HealthResponseImpl> get copyWith =>
      __$$HealthResponseImplCopyWithImpl<_$HealthResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HealthResponseImplToJson(
      this,
    );
  }
}

abstract class _HealthResponse implements HealthResponse {
  const factory _HealthResponse(
      {required final String status,
      required final String database,
      required final int collectionsCount,
      required final String version,
      required final int timestamp}) = _$HealthResponseImpl;

  factory _HealthResponse.fromJson(Map<String, dynamic> json) =
      _$HealthResponseImpl.fromJson;

  @override
  String get status;
  @override
  String get database;
  @override
  int get collectionsCount;
  @override
  String get version;
  @override
  int get timestamp;
  @override
  @JsonKey(ignore: true)
  _$$HealthResponseImplCopyWith<_$HealthResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
