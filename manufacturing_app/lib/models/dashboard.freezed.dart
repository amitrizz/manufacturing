// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DashboardKpis _$DashboardKpisFromJson(Map<String, dynamic> json) {
  return _DashboardKpis.fromJson(json);
}

/// @nodoc
mixin _$DashboardKpis {
  double get target => throw _privateConstructorUsedError;
  double get produced => throw _privateConstructorUsedError;
  int get achievement => throw _privateConstructorUsedError;
  int get qualityRate => throw _privateConstructorUsedError;
  int get machineAvailability => throw _privateConstructorUsedError;
  double get downtimeHours => throw _privateConstructorUsedError;
  Map<String, int> get machineStatusCounts =>
      throw _privateConstructorUsedError;
  List<LineProgress> get lineProgress => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DashboardKpisCopyWith<DashboardKpis> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardKpisCopyWith<$Res> {
  factory $DashboardKpisCopyWith(
          DashboardKpis value, $Res Function(DashboardKpis) then) =
      _$DashboardKpisCopyWithImpl<$Res, DashboardKpis>;
  @useResult
  $Res call(
      {double target,
      double produced,
      int achievement,
      int qualityRate,
      int machineAvailability,
      double downtimeHours,
      Map<String, int> machineStatusCounts,
      List<LineProgress> lineProgress});
}

/// @nodoc
class _$DashboardKpisCopyWithImpl<$Res, $Val extends DashboardKpis>
    implements $DashboardKpisCopyWith<$Res> {
  _$DashboardKpisCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? target = null,
    Object? produced = null,
    Object? achievement = null,
    Object? qualityRate = null,
    Object? machineAvailability = null,
    Object? downtimeHours = null,
    Object? machineStatusCounts = null,
    Object? lineProgress = null,
  }) {
    return _then(_value.copyWith(
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as double,
      produced: null == produced
          ? _value.produced
          : produced // ignore: cast_nullable_to_non_nullable
              as double,
      achievement: null == achievement
          ? _value.achievement
          : achievement // ignore: cast_nullable_to_non_nullable
              as int,
      qualityRate: null == qualityRate
          ? _value.qualityRate
          : qualityRate // ignore: cast_nullable_to_non_nullable
              as int,
      machineAvailability: null == machineAvailability
          ? _value.machineAvailability
          : machineAvailability // ignore: cast_nullable_to_non_nullable
              as int,
      downtimeHours: null == downtimeHours
          ? _value.downtimeHours
          : downtimeHours // ignore: cast_nullable_to_non_nullable
              as double,
      machineStatusCounts: null == machineStatusCounts
          ? _value.machineStatusCounts
          : machineStatusCounts // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      lineProgress: null == lineProgress
          ? _value.lineProgress
          : lineProgress // ignore: cast_nullable_to_non_nullable
              as List<LineProgress>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DashboardKpisImplCopyWith<$Res>
    implements $DashboardKpisCopyWith<$Res> {
  factory _$$DashboardKpisImplCopyWith(
          _$DashboardKpisImpl value, $Res Function(_$DashboardKpisImpl) then) =
      __$$DashboardKpisImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double target,
      double produced,
      int achievement,
      int qualityRate,
      int machineAvailability,
      double downtimeHours,
      Map<String, int> machineStatusCounts,
      List<LineProgress> lineProgress});
}

/// @nodoc
class __$$DashboardKpisImplCopyWithImpl<$Res>
    extends _$DashboardKpisCopyWithImpl<$Res, _$DashboardKpisImpl>
    implements _$$DashboardKpisImplCopyWith<$Res> {
  __$$DashboardKpisImplCopyWithImpl(
      _$DashboardKpisImpl _value, $Res Function(_$DashboardKpisImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? target = null,
    Object? produced = null,
    Object? achievement = null,
    Object? qualityRate = null,
    Object? machineAvailability = null,
    Object? downtimeHours = null,
    Object? machineStatusCounts = null,
    Object? lineProgress = null,
  }) {
    return _then(_$DashboardKpisImpl(
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as double,
      produced: null == produced
          ? _value.produced
          : produced // ignore: cast_nullable_to_non_nullable
              as double,
      achievement: null == achievement
          ? _value.achievement
          : achievement // ignore: cast_nullable_to_non_nullable
              as int,
      qualityRate: null == qualityRate
          ? _value.qualityRate
          : qualityRate // ignore: cast_nullable_to_non_nullable
              as int,
      machineAvailability: null == machineAvailability
          ? _value.machineAvailability
          : machineAvailability // ignore: cast_nullable_to_non_nullable
              as int,
      downtimeHours: null == downtimeHours
          ? _value.downtimeHours
          : downtimeHours // ignore: cast_nullable_to_non_nullable
              as double,
      machineStatusCounts: null == machineStatusCounts
          ? _value._machineStatusCounts
          : machineStatusCounts // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      lineProgress: null == lineProgress
          ? _value._lineProgress
          : lineProgress // ignore: cast_nullable_to_non_nullable
              as List<LineProgress>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DashboardKpisImpl implements _DashboardKpis {
  const _$DashboardKpisImpl(
      {required this.target,
      required this.produced,
      required this.achievement,
      required this.qualityRate,
      required this.machineAvailability,
      required this.downtimeHours,
      required final Map<String, int> machineStatusCounts,
      required final List<LineProgress> lineProgress})
      : _machineStatusCounts = machineStatusCounts,
        _lineProgress = lineProgress;

  factory _$DashboardKpisImpl.fromJson(Map<String, dynamic> json) =>
      _$$DashboardKpisImplFromJson(json);

  @override
  final double target;
  @override
  final double produced;
  @override
  final int achievement;
  @override
  final int qualityRate;
  @override
  final int machineAvailability;
  @override
  final double downtimeHours;
  final Map<String, int> _machineStatusCounts;
  @override
  Map<String, int> get machineStatusCounts {
    if (_machineStatusCounts is EqualUnmodifiableMapView)
      return _machineStatusCounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_machineStatusCounts);
  }

  final List<LineProgress> _lineProgress;
  @override
  List<LineProgress> get lineProgress {
    if (_lineProgress is EqualUnmodifiableListView) return _lineProgress;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lineProgress);
  }

  @override
  String toString() {
    return 'DashboardKpis(target: $target, produced: $produced, achievement: $achievement, qualityRate: $qualityRate, machineAvailability: $machineAvailability, downtimeHours: $downtimeHours, machineStatusCounts: $machineStatusCounts, lineProgress: $lineProgress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardKpisImpl &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.produced, produced) ||
                other.produced == produced) &&
            (identical(other.achievement, achievement) ||
                other.achievement == achievement) &&
            (identical(other.qualityRate, qualityRate) ||
                other.qualityRate == qualityRate) &&
            (identical(other.machineAvailability, machineAvailability) ||
                other.machineAvailability == machineAvailability) &&
            (identical(other.downtimeHours, downtimeHours) ||
                other.downtimeHours == downtimeHours) &&
            const DeepCollectionEquality()
                .equals(other._machineStatusCounts, _machineStatusCounts) &&
            const DeepCollectionEquality()
                .equals(other._lineProgress, _lineProgress));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      target,
      produced,
      achievement,
      qualityRate,
      machineAvailability,
      downtimeHours,
      const DeepCollectionEquality().hash(_machineStatusCounts),
      const DeepCollectionEquality().hash(_lineProgress));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardKpisImplCopyWith<_$DashboardKpisImpl> get copyWith =>
      __$$DashboardKpisImplCopyWithImpl<_$DashboardKpisImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DashboardKpisImplToJson(
      this,
    );
  }
}

abstract class _DashboardKpis implements DashboardKpis {
  const factory _DashboardKpis(
      {required final double target,
      required final double produced,
      required final int achievement,
      required final int qualityRate,
      required final int machineAvailability,
      required final double downtimeHours,
      required final Map<String, int> machineStatusCounts,
      required final List<LineProgress> lineProgress}) = _$DashboardKpisImpl;

  factory _DashboardKpis.fromJson(Map<String, dynamic> json) =
      _$DashboardKpisImpl.fromJson;

  @override
  double get target;
  @override
  double get produced;
  @override
  int get achievement;
  @override
  int get qualityRate;
  @override
  int get machineAvailability;
  @override
  double get downtimeHours;
  @override
  Map<String, int> get machineStatusCounts;
  @override
  List<LineProgress> get lineProgress;
  @override
  @JsonKey(ignore: true)
  _$$DashboardKpisImplCopyWith<_$DashboardKpisImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LineProgress _$LineProgressFromJson(Map<String, dynamic> json) {
  return _LineProgress.fromJson(json);
}

/// @nodoc
mixin _$LineProgress {
  String get lineCode => throw _privateConstructorUsedError;
  String? get lineName => throw _privateConstructorUsedError;
  double get produced => throw _privateConstructorUsedError;
  int get pct => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LineProgressCopyWith<LineProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LineProgressCopyWith<$Res> {
  factory $LineProgressCopyWith(
          LineProgress value, $Res Function(LineProgress) then) =
      _$LineProgressCopyWithImpl<$Res, LineProgress>;
  @useResult
  $Res call({String lineCode, String? lineName, double produced, int pct});
}

/// @nodoc
class _$LineProgressCopyWithImpl<$Res, $Val extends LineProgress>
    implements $LineProgressCopyWith<$Res> {
  _$LineProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lineCode = null,
    Object? lineName = freezed,
    Object? produced = null,
    Object? pct = null,
  }) {
    return _then(_value.copyWith(
      lineCode: null == lineCode
          ? _value.lineCode
          : lineCode // ignore: cast_nullable_to_non_nullable
              as String,
      lineName: freezed == lineName
          ? _value.lineName
          : lineName // ignore: cast_nullable_to_non_nullable
              as String?,
      produced: null == produced
          ? _value.produced
          : produced // ignore: cast_nullable_to_non_nullable
              as double,
      pct: null == pct
          ? _value.pct
          : pct // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LineProgressImplCopyWith<$Res>
    implements $LineProgressCopyWith<$Res> {
  factory _$$LineProgressImplCopyWith(
          _$LineProgressImpl value, $Res Function(_$LineProgressImpl) then) =
      __$$LineProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String lineCode, String? lineName, double produced, int pct});
}

/// @nodoc
class __$$LineProgressImplCopyWithImpl<$Res>
    extends _$LineProgressCopyWithImpl<$Res, _$LineProgressImpl>
    implements _$$LineProgressImplCopyWith<$Res> {
  __$$LineProgressImplCopyWithImpl(
      _$LineProgressImpl _value, $Res Function(_$LineProgressImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lineCode = null,
    Object? lineName = freezed,
    Object? produced = null,
    Object? pct = null,
  }) {
    return _then(_$LineProgressImpl(
      lineCode: null == lineCode
          ? _value.lineCode
          : lineCode // ignore: cast_nullable_to_non_nullable
              as String,
      lineName: freezed == lineName
          ? _value.lineName
          : lineName // ignore: cast_nullable_to_non_nullable
              as String?,
      produced: null == produced
          ? _value.produced
          : produced // ignore: cast_nullable_to_non_nullable
              as double,
      pct: null == pct
          ? _value.pct
          : pct // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LineProgressImpl implements _LineProgress {
  const _$LineProgressImpl(
      {required this.lineCode,
      this.lineName,
      required this.produced,
      required this.pct});

  factory _$LineProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$LineProgressImplFromJson(json);

  @override
  final String lineCode;
  @override
  final String? lineName;
  @override
  final double produced;
  @override
  final int pct;

  @override
  String toString() {
    return 'LineProgress(lineCode: $lineCode, lineName: $lineName, produced: $produced, pct: $pct)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LineProgressImpl &&
            (identical(other.lineCode, lineCode) ||
                other.lineCode == lineCode) &&
            (identical(other.lineName, lineName) ||
                other.lineName == lineName) &&
            (identical(other.produced, produced) ||
                other.produced == produced) &&
            (identical(other.pct, pct) || other.pct == pct));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, lineCode, lineName, produced, pct);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LineProgressImplCopyWith<_$LineProgressImpl> get copyWith =>
      __$$LineProgressImplCopyWithImpl<_$LineProgressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LineProgressImplToJson(
      this,
    );
  }
}

abstract class _LineProgress implements LineProgress {
  const factory _LineProgress(
      {required final String lineCode,
      final String? lineName,
      required final double produced,
      required final int pct}) = _$LineProgressImpl;

  factory _LineProgress.fromJson(Map<String, dynamic> json) =
      _$LineProgressImpl.fromJson;

  @override
  String get lineCode;
  @override
  String? get lineName;
  @override
  double get produced;
  @override
  int get pct;
  @override
  @JsonKey(ignore: true)
  _$$LineProgressImplCopyWith<_$LineProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MachineStats _$MachineStatsFromJson(Map<String, dynamic> json) {
  return _MachineStats.fromJson(json);
}

/// @nodoc
mixin _$MachineStats {
  int get running => throw _privateConstructorUsedError;
  int get breakdown => throw _privateConstructorUsedError;
  int get maintenance => throw _privateConstructorUsedError;
  int get idle => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MachineStatsCopyWith<MachineStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MachineStatsCopyWith<$Res> {
  factory $MachineStatsCopyWith(
          MachineStats value, $Res Function(MachineStats) then) =
      _$MachineStatsCopyWithImpl<$Res, MachineStats>;
  @useResult
  $Res call({int running, int breakdown, int maintenance, int idle, int total});
}

/// @nodoc
class _$MachineStatsCopyWithImpl<$Res, $Val extends MachineStats>
    implements $MachineStatsCopyWith<$Res> {
  _$MachineStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? running = null,
    Object? breakdown = null,
    Object? maintenance = null,
    Object? idle = null,
    Object? total = null,
  }) {
    return _then(_value.copyWith(
      running: null == running
          ? _value.running
          : running // ignore: cast_nullable_to_non_nullable
              as int,
      breakdown: null == breakdown
          ? _value.breakdown
          : breakdown // ignore: cast_nullable_to_non_nullable
              as int,
      maintenance: null == maintenance
          ? _value.maintenance
          : maintenance // ignore: cast_nullable_to_non_nullable
              as int,
      idle: null == idle
          ? _value.idle
          : idle // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MachineStatsImplCopyWith<$Res>
    implements $MachineStatsCopyWith<$Res> {
  factory _$$MachineStatsImplCopyWith(
          _$MachineStatsImpl value, $Res Function(_$MachineStatsImpl) then) =
      __$$MachineStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int running, int breakdown, int maintenance, int idle, int total});
}

/// @nodoc
class __$$MachineStatsImplCopyWithImpl<$Res>
    extends _$MachineStatsCopyWithImpl<$Res, _$MachineStatsImpl>
    implements _$$MachineStatsImplCopyWith<$Res> {
  __$$MachineStatsImplCopyWithImpl(
      _$MachineStatsImpl _value, $Res Function(_$MachineStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? running = null,
    Object? breakdown = null,
    Object? maintenance = null,
    Object? idle = null,
    Object? total = null,
  }) {
    return _then(_$MachineStatsImpl(
      running: null == running
          ? _value.running
          : running // ignore: cast_nullable_to_non_nullable
              as int,
      breakdown: null == breakdown
          ? _value.breakdown
          : breakdown // ignore: cast_nullable_to_non_nullable
              as int,
      maintenance: null == maintenance
          ? _value.maintenance
          : maintenance // ignore: cast_nullable_to_non_nullable
              as int,
      idle: null == idle
          ? _value.idle
          : idle // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MachineStatsImpl implements _MachineStats {
  const _$MachineStatsImpl(
      {required this.running,
      required this.breakdown,
      required this.maintenance,
      required this.idle,
      required this.total});

  factory _$MachineStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$MachineStatsImplFromJson(json);

  @override
  final int running;
  @override
  final int breakdown;
  @override
  final int maintenance;
  @override
  final int idle;
  @override
  final int total;

  @override
  String toString() {
    return 'MachineStats(running: $running, breakdown: $breakdown, maintenance: $maintenance, idle: $idle, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MachineStatsImpl &&
            (identical(other.running, running) || other.running == running) &&
            (identical(other.breakdown, breakdown) ||
                other.breakdown == breakdown) &&
            (identical(other.maintenance, maintenance) ||
                other.maintenance == maintenance) &&
            (identical(other.idle, idle) || other.idle == idle) &&
            (identical(other.total, total) || other.total == total));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, running, breakdown, maintenance, idle, total);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MachineStatsImplCopyWith<_$MachineStatsImpl> get copyWith =>
      __$$MachineStatsImplCopyWithImpl<_$MachineStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MachineStatsImplToJson(
      this,
    );
  }
}

abstract class _MachineStats implements MachineStats {
  const factory _MachineStats(
      {required final int running,
      required final int breakdown,
      required final int maintenance,
      required final int idle,
      required final int total}) = _$MachineStatsImpl;

  factory _MachineStats.fromJson(Map<String, dynamic> json) =
      _$MachineStatsImpl.fromJson;

  @override
  int get running;
  @override
  int get breakdown;
  @override
  int get maintenance;
  @override
  int get idle;
  @override
  int get total;
  @override
  @JsonKey(ignore: true)
  _$$MachineStatsImplCopyWith<_$MachineStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AttendanceStats _$AttendanceStatsFromJson(Map<String, dynamic> json) {
  return _AttendanceStats.fromJson(json);
}

/// @nodoc
mixin _$AttendanceStats {
  int get total => throw _privateConstructorUsedError;
  int get present => throw _privateConstructorUsedError;
  int get halfDay => throw _privateConstructorUsedError;
  int get leave => throw _privateConstructorUsedError;
  int get absent => throw _privateConstructorUsedError;
  int get rate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AttendanceStatsCopyWith<AttendanceStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceStatsCopyWith<$Res> {
  factory $AttendanceStatsCopyWith(
          AttendanceStats value, $Res Function(AttendanceStats) then) =
      _$AttendanceStatsCopyWithImpl<$Res, AttendanceStats>;
  @useResult
  $Res call(
      {int total, int present, int halfDay, int leave, int absent, int rate});
}

/// @nodoc
class _$AttendanceStatsCopyWithImpl<$Res, $Val extends AttendanceStats>
    implements $AttendanceStatsCopyWith<$Res> {
  _$AttendanceStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? present = null,
    Object? halfDay = null,
    Object? leave = null,
    Object? absent = null,
    Object? rate = null,
  }) {
    return _then(_value.copyWith(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      present: null == present
          ? _value.present
          : present // ignore: cast_nullable_to_non_nullable
              as int,
      halfDay: null == halfDay
          ? _value.halfDay
          : halfDay // ignore: cast_nullable_to_non_nullable
              as int,
      leave: null == leave
          ? _value.leave
          : leave // ignore: cast_nullable_to_non_nullable
              as int,
      absent: null == absent
          ? _value.absent
          : absent // ignore: cast_nullable_to_non_nullable
              as int,
      rate: null == rate
          ? _value.rate
          : rate // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttendanceStatsImplCopyWith<$Res>
    implements $AttendanceStatsCopyWith<$Res> {
  factory _$$AttendanceStatsImplCopyWith(_$AttendanceStatsImpl value,
          $Res Function(_$AttendanceStatsImpl) then) =
      __$$AttendanceStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int total, int present, int halfDay, int leave, int absent, int rate});
}

/// @nodoc
class __$$AttendanceStatsImplCopyWithImpl<$Res>
    extends _$AttendanceStatsCopyWithImpl<$Res, _$AttendanceStatsImpl>
    implements _$$AttendanceStatsImplCopyWith<$Res> {
  __$$AttendanceStatsImplCopyWithImpl(
      _$AttendanceStatsImpl _value, $Res Function(_$AttendanceStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? present = null,
    Object? halfDay = null,
    Object? leave = null,
    Object? absent = null,
    Object? rate = null,
  }) {
    return _then(_$AttendanceStatsImpl(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      present: null == present
          ? _value.present
          : present // ignore: cast_nullable_to_non_nullable
              as int,
      halfDay: null == halfDay
          ? _value.halfDay
          : halfDay // ignore: cast_nullable_to_non_nullable
              as int,
      leave: null == leave
          ? _value.leave
          : leave // ignore: cast_nullable_to_non_nullable
              as int,
      absent: null == absent
          ? _value.absent
          : absent // ignore: cast_nullable_to_non_nullable
              as int,
      rate: null == rate
          ? _value.rate
          : rate // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AttendanceStatsImpl implements _AttendanceStats {
  const _$AttendanceStatsImpl(
      {required this.total,
      required this.present,
      required this.halfDay,
      required this.leave,
      required this.absent,
      required this.rate});

  factory _$AttendanceStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttendanceStatsImplFromJson(json);

  @override
  final int total;
  @override
  final int present;
  @override
  final int halfDay;
  @override
  final int leave;
  @override
  final int absent;
  @override
  final int rate;

  @override
  String toString() {
    return 'AttendanceStats(total: $total, present: $present, halfDay: $halfDay, leave: $leave, absent: $absent, rate: $rate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendanceStatsImpl &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.present, present) || other.present == present) &&
            (identical(other.halfDay, halfDay) || other.halfDay == halfDay) &&
            (identical(other.leave, leave) || other.leave == leave) &&
            (identical(other.absent, absent) || other.absent == absent) &&
            (identical(other.rate, rate) || other.rate == rate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, total, present, halfDay, leave, absent, rate);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceStatsImplCopyWith<_$AttendanceStatsImpl> get copyWith =>
      __$$AttendanceStatsImplCopyWithImpl<_$AttendanceStatsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttendanceStatsImplToJson(
      this,
    );
  }
}

abstract class _AttendanceStats implements AttendanceStats {
  const factory _AttendanceStats(
      {required final int total,
      required final int present,
      required final int halfDay,
      required final int leave,
      required final int absent,
      required final int rate}) = _$AttendanceStatsImpl;

  factory _AttendanceStats.fromJson(Map<String, dynamic> json) =
      _$AttendanceStatsImpl.fromJson;

  @override
  int get total;
  @override
  int get present;
  @override
  int get halfDay;
  @override
  int get leave;
  @override
  int get absent;
  @override
  int get rate;
  @override
  @JsonKey(ignore: true)
  _$$AttendanceStatsImplCopyWith<_$AttendanceStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MonthlyData _$MonthlyDataFromJson(Map<String, dynamic> json) {
  return _MonthlyData.fromJson(json);
}

/// @nodoc
mixin _$MonthlyData {
  String get month => throw _privateConstructorUsedError;
  int get year => throw _privateConstructorUsedError;
  int get target => throw _privateConstructorUsedError;
  int get produced => throw _privateConstructorUsedError;
  int get pct => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MonthlyDataCopyWith<MonthlyData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonthlyDataCopyWith<$Res> {
  factory $MonthlyDataCopyWith(
          MonthlyData value, $Res Function(MonthlyData) then) =
      _$MonthlyDataCopyWithImpl<$Res, MonthlyData>;
  @useResult
  $Res call({String month, int year, int target, int produced, int pct});
}

/// @nodoc
class _$MonthlyDataCopyWithImpl<$Res, $Val extends MonthlyData>
    implements $MonthlyDataCopyWith<$Res> {
  _$MonthlyDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? month = null,
    Object? year = null,
    Object? target = null,
    Object? produced = null,
    Object? pct = null,
  }) {
    return _then(_value.copyWith(
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as int,
      produced: null == produced
          ? _value.produced
          : produced // ignore: cast_nullable_to_non_nullable
              as int,
      pct: null == pct
          ? _value.pct
          : pct // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MonthlyDataImplCopyWith<$Res>
    implements $MonthlyDataCopyWith<$Res> {
  factory _$$MonthlyDataImplCopyWith(
          _$MonthlyDataImpl value, $Res Function(_$MonthlyDataImpl) then) =
      __$$MonthlyDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String month, int year, int target, int produced, int pct});
}

/// @nodoc
class __$$MonthlyDataImplCopyWithImpl<$Res>
    extends _$MonthlyDataCopyWithImpl<$Res, _$MonthlyDataImpl>
    implements _$$MonthlyDataImplCopyWith<$Res> {
  __$$MonthlyDataImplCopyWithImpl(
      _$MonthlyDataImpl _value, $Res Function(_$MonthlyDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? month = null,
    Object? year = null,
    Object? target = null,
    Object? produced = null,
    Object? pct = null,
  }) {
    return _then(_$MonthlyDataImpl(
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as int,
      produced: null == produced
          ? _value.produced
          : produced // ignore: cast_nullable_to_non_nullable
              as int,
      pct: null == pct
          ? _value.pct
          : pct // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MonthlyDataImpl implements _MonthlyData {
  const _$MonthlyDataImpl(
      {required this.month,
      required this.year,
      required this.target,
      required this.produced,
      required this.pct});

  factory _$MonthlyDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$MonthlyDataImplFromJson(json);

  @override
  final String month;
  @override
  final int year;
  @override
  final int target;
  @override
  final int produced;
  @override
  final int pct;

  @override
  String toString() {
    return 'MonthlyData(month: $month, year: $year, target: $target, produced: $produced, pct: $pct)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonthlyDataImpl &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.produced, produced) ||
                other.produced == produced) &&
            (identical(other.pct, pct) || other.pct == pct));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, month, year, target, produced, pct);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MonthlyDataImplCopyWith<_$MonthlyDataImpl> get copyWith =>
      __$$MonthlyDataImplCopyWithImpl<_$MonthlyDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MonthlyDataImplToJson(
      this,
    );
  }
}

abstract class _MonthlyData implements MonthlyData {
  const factory _MonthlyData(
      {required final String month,
      required final int year,
      required final int target,
      required final int produced,
      required final int pct}) = _$MonthlyDataImpl;

  factory _MonthlyData.fromJson(Map<String, dynamic> json) =
      _$MonthlyDataImpl.fromJson;

  @override
  String get month;
  @override
  int get year;
  @override
  int get target;
  @override
  int get produced;
  @override
  int get pct;
  @override
  @JsonKey(ignore: true)
  _$$MonthlyDataImplCopyWith<_$MonthlyDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Activity _$ActivityFromJson(Map<String, dynamic> json) {
  return _Activity.fromJson(json);
}

/// @nodoc
mixin _$Activity {
  String get id => throw _privateConstructorUsedError;
  String get eventType => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get referenceType => throw _privateConstructorUsedError;
  String? get referenceId => throw _privateConstructorUsedError;
  String? get companyId => throw _privateConstructorUsedError;
  int get timestamp => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ActivityCopyWith<Activity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActivityCopyWith<$Res> {
  factory $ActivityCopyWith(Activity value, $Res Function(Activity) then) =
      _$ActivityCopyWithImpl<$Res, Activity>;
  @useResult
  $Res call(
      {String id,
      String eventType,
      String title,
      String? description,
      String? referenceType,
      String? referenceId,
      String? companyId,
      int timestamp});
}

/// @nodoc
class _$ActivityCopyWithImpl<$Res, $Val extends Activity>
    implements $ActivityCopyWith<$Res> {
  _$ActivityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? eventType = null,
    Object? title = null,
    Object? description = freezed,
    Object? referenceType = freezed,
    Object? referenceId = freezed,
    Object? companyId = freezed,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      eventType: null == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      referenceType: freezed == referenceType
          ? _value.referenceType
          : referenceType // ignore: cast_nullable_to_non_nullable
              as String?,
      referenceId: freezed == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String?,
      companyId: freezed == companyId
          ? _value.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ActivityImplCopyWith<$Res>
    implements $ActivityCopyWith<$Res> {
  factory _$$ActivityImplCopyWith(
          _$ActivityImpl value, $Res Function(_$ActivityImpl) then) =
      __$$ActivityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String eventType,
      String title,
      String? description,
      String? referenceType,
      String? referenceId,
      String? companyId,
      int timestamp});
}

/// @nodoc
class __$$ActivityImplCopyWithImpl<$Res>
    extends _$ActivityCopyWithImpl<$Res, _$ActivityImpl>
    implements _$$ActivityImplCopyWith<$Res> {
  __$$ActivityImplCopyWithImpl(
      _$ActivityImpl _value, $Res Function(_$ActivityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? eventType = null,
    Object? title = null,
    Object? description = freezed,
    Object? referenceType = freezed,
    Object? referenceId = freezed,
    Object? companyId = freezed,
    Object? timestamp = null,
  }) {
    return _then(_$ActivityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      eventType: null == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      referenceType: freezed == referenceType
          ? _value.referenceType
          : referenceType // ignore: cast_nullable_to_non_nullable
              as String?,
      referenceId: freezed == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String?,
      companyId: freezed == companyId
          ? _value.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ActivityImpl extends _Activity {
  const _$ActivityImpl(
      {required this.id,
      required this.eventType,
      required this.title,
      this.description,
      this.referenceType,
      this.referenceId,
      this.companyId,
      required this.timestamp})
      : super._();

  factory _$ActivityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActivityImplFromJson(json);

  @override
  final String id;
  @override
  final String eventType;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String? referenceType;
  @override
  final String? referenceId;
  @override
  final String? companyId;
  @override
  final int timestamp;

  @override
  String toString() {
    return 'Activity(id: $id, eventType: $eventType, title: $title, description: $description, referenceType: $referenceType, referenceId: $referenceId, companyId: $companyId, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActivityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.referenceType, referenceType) ||
                other.referenceType == referenceType) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId) &&
            (identical(other.companyId, companyId) ||
                other.companyId == companyId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, eventType, title,
      description, referenceType, referenceId, companyId, timestamp);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ActivityImplCopyWith<_$ActivityImpl> get copyWith =>
      __$$ActivityImplCopyWithImpl<_$ActivityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActivityImplToJson(
      this,
    );
  }
}

abstract class _Activity extends Activity {
  const factory _Activity(
      {required final String id,
      required final String eventType,
      required final String title,
      final String? description,
      final String? referenceType,
      final String? referenceId,
      final String? companyId,
      required final int timestamp}) = _$ActivityImpl;
  const _Activity._() : super._();

  factory _Activity.fromJson(Map<String, dynamic> json) =
      _$ActivityImpl.fromJson;

  @override
  String get id;
  @override
  String get eventType;
  @override
  String get title;
  @override
  String? get description;
  @override
  String? get referenceType;
  @override
  String? get referenceId;
  @override
  String? get companyId;
  @override
  int get timestamp;
  @override
  @JsonKey(ignore: true)
  _$$ActivityImplCopyWith<_$ActivityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DashboardResponse _$DashboardResponseFromJson(Map<String, dynamic> json) {
  return _DashboardResponse.fromJson(json);
}

/// @nodoc
mixin _$DashboardResponse {
  DashboardKpis get kpis => throw _privateConstructorUsedError;
  MachineStats get machines => throw _privateConstructorUsedError;
  AttendanceStats get attendance => throw _privateConstructorUsedError;
  int get pendingTasksCount => throw _privateConstructorUsedError;
  List<Activity> get recentActivities => throw _privateConstructorUsedError;
  List<MonthlyData> get monthlyData => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DashboardResponseCopyWith<DashboardResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardResponseCopyWith<$Res> {
  factory $DashboardResponseCopyWith(
          DashboardResponse value, $Res Function(DashboardResponse) then) =
      _$DashboardResponseCopyWithImpl<$Res, DashboardResponse>;
  @useResult
  $Res call(
      {DashboardKpis kpis,
      MachineStats machines,
      AttendanceStats attendance,
      int pendingTasksCount,
      List<Activity> recentActivities,
      List<MonthlyData> monthlyData});

  $DashboardKpisCopyWith<$Res> get kpis;
  $MachineStatsCopyWith<$Res> get machines;
  $AttendanceStatsCopyWith<$Res> get attendance;
}

/// @nodoc
class _$DashboardResponseCopyWithImpl<$Res, $Val extends DashboardResponse>
    implements $DashboardResponseCopyWith<$Res> {
  _$DashboardResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kpis = null,
    Object? machines = null,
    Object? attendance = null,
    Object? pendingTasksCount = null,
    Object? recentActivities = null,
    Object? monthlyData = null,
  }) {
    return _then(_value.copyWith(
      kpis: null == kpis
          ? _value.kpis
          : kpis // ignore: cast_nullable_to_non_nullable
              as DashboardKpis,
      machines: null == machines
          ? _value.machines
          : machines // ignore: cast_nullable_to_non_nullable
              as MachineStats,
      attendance: null == attendance
          ? _value.attendance
          : attendance // ignore: cast_nullable_to_non_nullable
              as AttendanceStats,
      pendingTasksCount: null == pendingTasksCount
          ? _value.pendingTasksCount
          : pendingTasksCount // ignore: cast_nullable_to_non_nullable
              as int,
      recentActivities: null == recentActivities
          ? _value.recentActivities
          : recentActivities // ignore: cast_nullable_to_non_nullable
              as List<Activity>,
      monthlyData: null == monthlyData
          ? _value.monthlyData
          : monthlyData // ignore: cast_nullable_to_non_nullable
              as List<MonthlyData>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $DashboardKpisCopyWith<$Res> get kpis {
    return $DashboardKpisCopyWith<$Res>(_value.kpis, (value) {
      return _then(_value.copyWith(kpis: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $MachineStatsCopyWith<$Res> get machines {
    return $MachineStatsCopyWith<$Res>(_value.machines, (value) {
      return _then(_value.copyWith(machines: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $AttendanceStatsCopyWith<$Res> get attendance {
    return $AttendanceStatsCopyWith<$Res>(_value.attendance, (value) {
      return _then(_value.copyWith(attendance: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DashboardResponseImplCopyWith<$Res>
    implements $DashboardResponseCopyWith<$Res> {
  factory _$$DashboardResponseImplCopyWith(_$DashboardResponseImpl value,
          $Res Function(_$DashboardResponseImpl) then) =
      __$$DashboardResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DashboardKpis kpis,
      MachineStats machines,
      AttendanceStats attendance,
      int pendingTasksCount,
      List<Activity> recentActivities,
      List<MonthlyData> monthlyData});

  @override
  $DashboardKpisCopyWith<$Res> get kpis;
  @override
  $MachineStatsCopyWith<$Res> get machines;
  @override
  $AttendanceStatsCopyWith<$Res> get attendance;
}

/// @nodoc
class __$$DashboardResponseImplCopyWithImpl<$Res>
    extends _$DashboardResponseCopyWithImpl<$Res, _$DashboardResponseImpl>
    implements _$$DashboardResponseImplCopyWith<$Res> {
  __$$DashboardResponseImplCopyWithImpl(_$DashboardResponseImpl _value,
      $Res Function(_$DashboardResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kpis = null,
    Object? machines = null,
    Object? attendance = null,
    Object? pendingTasksCount = null,
    Object? recentActivities = null,
    Object? monthlyData = null,
  }) {
    return _then(_$DashboardResponseImpl(
      kpis: null == kpis
          ? _value.kpis
          : kpis // ignore: cast_nullable_to_non_nullable
              as DashboardKpis,
      machines: null == machines
          ? _value.machines
          : machines // ignore: cast_nullable_to_non_nullable
              as MachineStats,
      attendance: null == attendance
          ? _value.attendance
          : attendance // ignore: cast_nullable_to_non_nullable
              as AttendanceStats,
      pendingTasksCount: null == pendingTasksCount
          ? _value.pendingTasksCount
          : pendingTasksCount // ignore: cast_nullable_to_non_nullable
              as int,
      recentActivities: null == recentActivities
          ? _value._recentActivities
          : recentActivities // ignore: cast_nullable_to_non_nullable
              as List<Activity>,
      monthlyData: null == monthlyData
          ? _value._monthlyData
          : monthlyData // ignore: cast_nullable_to_non_nullable
              as List<MonthlyData>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DashboardResponseImpl implements _DashboardResponse {
  const _$DashboardResponseImpl(
      {required this.kpis,
      required this.machines,
      required this.attendance,
      required this.pendingTasksCount,
      required final List<Activity> recentActivities,
      required final List<MonthlyData> monthlyData})
      : _recentActivities = recentActivities,
        _monthlyData = monthlyData;

  factory _$DashboardResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$DashboardResponseImplFromJson(json);

  @override
  final DashboardKpis kpis;
  @override
  final MachineStats machines;
  @override
  final AttendanceStats attendance;
  @override
  final int pendingTasksCount;
  final List<Activity> _recentActivities;
  @override
  List<Activity> get recentActivities {
    if (_recentActivities is EqualUnmodifiableListView)
      return _recentActivities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentActivities);
  }

  final List<MonthlyData> _monthlyData;
  @override
  List<MonthlyData> get monthlyData {
    if (_monthlyData is EqualUnmodifiableListView) return _monthlyData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_monthlyData);
  }

  @override
  String toString() {
    return 'DashboardResponse(kpis: $kpis, machines: $machines, attendance: $attendance, pendingTasksCount: $pendingTasksCount, recentActivities: $recentActivities, monthlyData: $monthlyData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardResponseImpl &&
            (identical(other.kpis, kpis) || other.kpis == kpis) &&
            (identical(other.machines, machines) ||
                other.machines == machines) &&
            (identical(other.attendance, attendance) ||
                other.attendance == attendance) &&
            (identical(other.pendingTasksCount, pendingTasksCount) ||
                other.pendingTasksCount == pendingTasksCount) &&
            const DeepCollectionEquality()
                .equals(other._recentActivities, _recentActivities) &&
            const DeepCollectionEquality()
                .equals(other._monthlyData, _monthlyData));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      kpis,
      machines,
      attendance,
      pendingTasksCount,
      const DeepCollectionEquality().hash(_recentActivities),
      const DeepCollectionEquality().hash(_monthlyData));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardResponseImplCopyWith<_$DashboardResponseImpl> get copyWith =>
      __$$DashboardResponseImplCopyWithImpl<_$DashboardResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DashboardResponseImplToJson(
      this,
    );
  }
}

abstract class _DashboardResponse implements DashboardResponse {
  const factory _DashboardResponse(
      {required final DashboardKpis kpis,
      required final MachineStats machines,
      required final AttendanceStats attendance,
      required final int pendingTasksCount,
      required final List<Activity> recentActivities,
      required final List<MonthlyData> monthlyData}) = _$DashboardResponseImpl;

  factory _DashboardResponse.fromJson(Map<String, dynamic> json) =
      _$DashboardResponseImpl.fromJson;

  @override
  DashboardKpis get kpis;
  @override
  MachineStats get machines;
  @override
  AttendanceStats get attendance;
  @override
  int get pendingTasksCount;
  @override
  List<Activity> get recentActivities;
  @override
  List<MonthlyData> get monthlyData;
  @override
  @JsonKey(ignore: true)
  _$$DashboardResponseImplCopyWith<_$DashboardResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
