import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../routes/app_router.dart';
import '../services/api_service.dart';
import '../models/dashboard.dart';
import '../models/company.dart';
import '../models/machine.dart';
import '../models/production.dart';
import '../models/common.dart';
import '../constants/app_constants.dart';
import '../constants/permissions.dart';

part 'app_providers.freezed.dart';

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Theme Mode Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }
  
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(AppConstants.themeModeKey) ?? 0;
    state = ThemeMode.values[themeIndex];
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.themeModeKey, mode.index);
  }
}

// Subscription Provider
enum SubscriptionStatus { trial, paid, grace, expired }

class SubscriptionState {
  final SubscriptionStatus status;
  final String plan;
  final int trialDays;
  final int totalDays;
  final int daysRemaining;
  final int? validUntil;
  final String validUntilFormatted;
  final bool isReadOnly;
  final bool isLoading;
  final String? error;

  const SubscriptionState({
    this.status = SubscriptionStatus.trial,
    this.plan = 'FREE_TRIAL',
    this.trialDays = 7,
    this.totalDays = 7,
    this.daysRemaining = 7,
    this.validUntil,
    this.validUntilFormatted = '',
    this.isReadOnly = false,
    this.isLoading = false,
    this.error,
  });

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    String? plan,
    int? trialDays,
    int? totalDays,
    int? daysRemaining,
    int? validUntil,
    String? validUntilFormatted,
    bool? isReadOnly,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      trialDays: trialDays ?? this.trialDays,
      totalDays: totalDays ?? this.totalDays,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      validUntil: validUntil ?? this.validUntil,
      validUntilFormatted: validUntilFormatted ?? this.validUntilFormatted,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SubscriptionNotifier(apiService);
});

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final ApiService _apiService;

  SubscriptionNotifier(this._apiService) : super(const SubscriptionState()) {
    refreshSubscription();
  }

  Future<void> refreshSubscription({String? companyId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getSubscriptionStatus(companyId: companyId);
      if (res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        final statusStr = (data['status'] as String? ?? 'TRIAL').toUpperCase();
        final plan = data['plan'] as String? ?? 'FREE_TRIAL';
        final trialDays = (data['trialDays'] as num?)?.toInt() ?? 7;
        final totalDays = (data['totalDays'] as num?)?.toInt() ?? 7;
        final daysRemaining = (data['daysRemaining'] as num?)?.toInt() ?? 7;
        final validUntil = (data['validUntil'] as num?)?.toInt();
        final validUntilFormatted = data['validUntilFormatted'] as String? ?? '';
        final isReadOnly = data['isReadOnly'] as bool? ?? false;

        state = SubscriptionState(
          status: _parseStatus(statusStr),
          plan: plan,
          trialDays: trialDays,
          totalDays: totalDays,
          daysRemaining: daysRemaining,
          validUntil: validUntil,
          validUntilFormatted: validUntilFormatted,
          isReadOnly: isReadOnly,
          isLoading: false,
        );
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  static SubscriptionStatus _parseStatus(String str) {
    switch (str.toUpperCase()) {
      case 'PAID':
        return SubscriptionStatus.paid;
      case 'GRACE':
        return SubscriptionStatus.grace;
      case 'EXPIRED':
        return SubscriptionStatus.expired;
      default:
        return SubscriptionStatus.trial;
    }
  }

  Future<Map<String, dynamic>> createCashfreeOrder({
    required String plan,
    double? amount,
    String? companyId,
  }) async {
    return await _apiService.createCashfreeOrder(plan: plan, amount: amount, companyId: companyId);
  }

  Future<bool> verifyAndActivatePayment({
    required String orderId,
    String? companyId,
    String plan = 'PRO_MONTHLY',
    bool stubMode = false,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _apiService.verifyCashfreePayment(
        orderId: orderId,
        companyId: companyId,
        plan: plan,
        stubMode: stubMode,
      );
      if (res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        final statusStr = (data['status'] as String? ?? 'PAID').toUpperCase();
        final totalDays = (data['totalDays'] as num?)?.toInt() ?? (plan == 'PRO_ANNUAL' ? 365 : 30);
        final daysRemaining = (data['daysRemaining'] as num?)?.toInt() ?? totalDays;
        final validUntil = (data['validUntil'] as num?)?.toInt();
        final validUntilFormatted = data['validUntilFormatted'] as String? ?? '';

        state = SubscriptionState(
          status: _parseStatus(statusStr),
          plan: plan,
          trialDays: 7,
          totalDays: totalDays,
          daysRemaining: daysRemaining,
          validUntil: validUntil,
          validUntilFormatted: validUntilFormatted,
          isReadOnly: false,
          isLoading: false,
        );
        return true;
      }
      await refreshSubscription(companyId: companyId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> renewSubscription({String? companyId, String plan = 'PRO_ANNUAL'}) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _apiService.renewSubscription(companyId: companyId, plan: plan);
      if (res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        final statusStr = (data['status'] as String? ?? 'PAID').toUpperCase();
        final totalDays = (data['totalDays'] as num?)?.toInt() ?? 365;
        final daysRemaining = (data['daysRemaining'] as num?)?.toInt() ?? totalDays;
        final validUntil = (data['validUntil'] as num?)?.toInt();
        final validUntilFormatted = data['validUntilFormatted'] as String? ?? '';

        state = SubscriptionState(
          status: _parseStatus(statusStr),
          plan: plan,
          trialDays: 7,
          totalDays: totalDays,
          daysRemaining: daysRemaining,
          validUntil: validUntil,
          validUntilFormatted: validUntilFormatted,
          isReadOnly: false,
          isLoading: false,
        );
        return;
      }
      await refreshSubscription(companyId: companyId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> simulateStatus(SubscriptionStatus newStatus) async {
    final days = newStatus == SubscriptionStatus.paid
        ? 365
        : newStatus == SubscriptionStatus.grace
            ? 3
            : newStatus == SubscriptionStatus.trial
                ? 7
                : 0;
    state = state.copyWith(
      status: newStatus,
      totalDays: newStatus == SubscriptionStatus.paid ? 365 : 7,
      daysRemaining: days,
      isReadOnly: newStatus == SubscriptionStatus.expired,
    );
  }
}

// Auth State Provider
@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isAuthenticated,
    @Default(false) bool isLoading,
    String? userId,
    String? companyId,
    String? userName,
    String? userRole,
    String? error,
  }) = _AuthState;
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  
  AuthNotifier(this._apiService) : super(const AuthState()) {
    _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    if (_apiService.isAuthenticated) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        userId: _apiService.userId,
        companyId: _apiService.companyId,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }
  
  Future<void> login(String emailOrCode, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _apiService.verifyAdmin(emailOrCode, password);
      
      const mockToken = 'mock-jwt-token';
      await _apiService.setAuthToken(mockToken);
      _apiService.setCompanyId(result['id'] as String);
      _apiService.setUserId(result['id'] as String);
      
      final cleanCode = (result['code'] as String? ?? result['company_code'] as String? ?? result['id'] as String).trim();
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        userId: result['id'] as String,
        companyId: cleanCode,
        userName: result['name'] as String?,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
  
  Future<void> registerCompany({
    required String name,
    required String companyCode,
    required String adminEmail,
    required String adminPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final company = await _apiService.createCompany({
        'name': name,
        'code': companyCode,
        'company_code': companyCode,
        'admin_email': adminEmail,
        'admin_password': adminPassword,
      });
      
      const mockToken = 'mock-jwt-token';
      await _apiService.setAuthToken(mockToken);
      _apiService.setCompanyId(company.id);
      _apiService.setUserId(company.id);
      
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        userId: company.id,
        companyId: company.code,
        userName: company.name,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> loginStaff({
    required String companyCode,
    required String employeeIdOrName,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final companies = await _apiService.listCompanies();
      final cleanCode = companyCode.trim().toUpperCase();
      final company = companies.firstWhere(
        (c) => c.code.trim().toUpperCase() == cleanCode ||
               c.id.trim().toUpperCase() == cleanCode ||
               c.name.trim().toUpperCase() == cleanCode,
        orElse: () => throw Exception('Company "$companyCode" not found. Please verify the Company Code.'),
      );

      _apiService.setCompanyId(company.id);

      final staffResponse = await _apiService.getCollection('staff', queryParams: {
        'limit': 500,
      });

      final allStaff = staffResponse.data;
      final staffList = allStaff.where((s) {
        final cId = (s['company_id']?.toString() ?? '').trim();
        final cCode = (s['company_code']?.toString() ?? '').trim().toUpperCase();
        return cId.isEmpty ||
               cId == company.id ||
               cId == company.code ||
               cCode == cleanCode ||
               cCode == company.code.toUpperCase();
      }).toList();

      final cleanInput = employeeIdOrName.trim().toLowerCase();
      final cleanEmp = cleanInput.replaceAll('-', '').replaceAll(' ', '');
      final cleanPin = pin.trim();

      final staff = staffList.firstWhere(
        (s) {
          final rawEmpId = (s['employee_id']?.toString() ?? s['code']?.toString() ?? s['id']?.toString() ?? '').toLowerCase().trim();
          final sEmpId = rawEmpId.replaceAll('-', '').replaceAll(' ', '');
          final sName = (s['name']?.toString() ?? '').toLowerCase().trim();
          final sNameNoSpace = sName.replaceAll(' ', '');
          final sPhone = (s['phone']?.toString() ?? '').replaceAll(' ', '').replaceAll('-', '');
          final sPin = (s['login_pin']?.toString() ?? '1234').trim();

          final matchesEmp = (sEmpId.isNotEmpty && sEmpId == cleanEmp) ||
                             (rawEmpId.isNotEmpty && rawEmpId == cleanInput) ||
                             (sName.isNotEmpty && sName == cleanInput) ||
                             (sNameNoSpace.isNotEmpty && sNameNoSpace == cleanEmp) ||
                             (sName.isNotEmpty && cleanInput.isNotEmpty && (sName.contains(cleanInput) || cleanInput.contains(sName))) ||
                             (cleanEmp.length >= 4 && sPhone.endsWith(cleanEmp));
          final matchesPin = sPin == cleanPin || 
                             (cleanPin.isEmpty && (sPin == '1234' || sPin.isEmpty)) ||
                             (cleanPin == '1234' && sPin.isEmpty);
          return matchesEmp && matchesPin;
        },
        orElse: () => throw Exception('Invalid Employee ID/Name or PIN. Please verify staff enrollment.'),
      );

      const mockToken = 'mock-staff-token';
      await _apiService.setAuthToken(mockToken);
      final staffId = staff['id']?.toString() ?? staff['_id']?.toString() ?? company.id;
      _apiService.setUserId(staffId);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        userId: staffId,
        companyId: company.code,
        userName: staff['name']?.toString() ?? 'Staff Member',
        userRole: (staff['role']?.toString() ?? 'OPERATOR').toUpperCase(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    state = const AuthState();
  }
  
  void updateUserInfo({String? name, String? role}) {
    state = state.copyWith(
      userName: name ?? state.userName,
      userRole: role ?? state.userRole,
    );
  }
}

// Dashboard Provider
final dashboardProvider = FutureProvider.autoDispose<DashboardResponse>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getDashboardStats();
});

// Companies Provider
final companiesProvider = FutureProvider.autoDispose<List<Company>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.listCompanies();
});

// Machines Provider
final machinesProvider = FutureProvider.autoDispose.family<PaginatedResponse<Machine>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.listMachines(
    status: params['status'] as String?,
    lineId: params['lineId'] as String?,
    search: params['search'] as String?,
    limit: params['limit'] as int? ?? AppConstants.defaultPageSize,
    skip: params['skip'] as int? ?? 0,
  );
});

// Production Orders Provider
final productionOrdersProvider = FutureProvider.autoDispose.family<PaginatedResponse<ProductionOrder>, String?>((ref, status) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.listProductionOrders(
    status: status,
    limit: 50,
    skip: 0,
  );
});

// Production Plans Provider
final productionPlansProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('production_plans', queryParams: params);
});

// Production Lines Provider
final productionLinesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final res = await apiService.getCollection('production_lines', queryParams: const {'limit': 100});
  return res.data;
});

// Materials Provider
final materialsProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('materials', queryParams: params);
});

// Products Provider
final productsProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('products', queryParams: params);
});

// BOM Provider
final bomProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('bom', queryParams: params);
});

// BOM Items Provider
final bomItemsProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('bom_items', queryParams: params);
});

// Stock Transactions Provider
final stockTransactionsProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('stock_transactions', queryParams: params);
});

// Finished Goods Provider
final finishedGoodsProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('finished_goods', queryParams: params);
});

// Suppliers Provider
final suppliersProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('suppliers', queryParams: params);
});

// Customers Provider
final customersProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('customers', queryParams: params);
});

// Staff Provider
final staffProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('staff', queryParams: params);
});

// Staff Attendance Provider
final staffAttendanceProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('staff_attendance', queryParams: params);
});

// Notifications Provider
final notificationsProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('notifications', queryParams: params);
});

// Activity History Provider
final activityHistoryProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('activity_history', queryParams: params);
});

// Maintenance Providers
final maintenanceOrdersProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('maintenance_orders', queryParams: params);
});

final maintenanceHistoryProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('maintenance_history', queryParams: params);
});

// Quality Providers
final qualityInspectionsProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('quality_inspections', queryParams: params);
});

final reworkOrdersProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('rework_orders', queryParams: params);
});

// Purchase Providers
final grnReceiptsProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('grn_receipts', queryParams: params);
});

final purchaseOrdersProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('purchase_orders', queryParams: params);
});

final purchaseRequestsProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('purchase_requests', queryParams: params);
});

// Dispatch Providers
final dispatchOrdersProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('dispatch_orders', queryParams: params);
});

// Units Provider
final unitsProvider = FutureProvider.autoDispose<List<Unit>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.listUnits();
  return response.data;
});

// Company Roles Provider (Paginated Family)
final paginatedCompanyRolesProvider = FutureProvider.autoDispose.family<PaginatedResponse<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCollection('company_roles', queryParams: params);
});

// Role Preview Provider
class RolePreviewState {
  final String? roleName;
  final List<String> permissions;
  final bool isPreviewing;

  const RolePreviewState({
    this.roleName,
    this.permissions = const [],
    this.isPreviewing = false,
  });
}

class RolePreviewNotifier extends StateNotifier<RolePreviewState> {
  RolePreviewNotifier() : super(const RolePreviewState());

  void startPreview(String roleName, List<String> permissions) {
    state = RolePreviewState(
      roleName: roleName,
      permissions: permissions,
      isPreviewing: true,
    );
  }

  void exitPreview() {
    state = const RolePreviewState();
  }

  bool hasPermission(String perm) {
    if (!state.isPreviewing) return true;
    return state.permissions.contains(perm) || state.permissions.contains('*');
  }
}

final rolePreviewProvider = StateNotifierProvider<RolePreviewNotifier, RolePreviewState>((ref) {
  return RolePreviewNotifier();
});

// =============================================================================
// Staff Impersonation State & Notifier (View as Staff)
// =============================================================================

class ImpersonationState {
  final bool isImpersonating;
  final String? staffId;
  final String? staffName;
  final String? employeeId;
  final String? role;
  final String? shift;
  final String? department;
  final Set<String> permissions;
  final String? originalAdminName;

  const ImpersonationState({
    this.isImpersonating = false,
    this.staffId,
    this.staffName,
    this.employeeId,
    this.role,
    this.shift,
    this.department,
    this.permissions = const {},
    this.originalAdminName,
  });
}

class ImpersonationNotifier extends StateNotifier<ImpersonationState> {
  ImpersonationNotifier() : super(const ImpersonationState());

  void startImpersonation(Map<String, dynamic> staff, {String? adminName}) {
    final role = (staff['role']?.toString() ?? 'OPERATOR').toUpperCase();
    final perms = getPermissionsForRole(role);

    state = ImpersonationState(
      isImpersonating: true,
      staffId: staff['id']?.toString() ?? staff['_id']?.toString(),
      staffName: staff['name']?.toString() ?? 'Staff Member',
      employeeId: staff['employee_id']?.toString() ?? 'EMP-000',
      role: role,
      shift: staff['shift']?.toString() ?? 'MORNING',
      department: staff['department']?.toString(),
      permissions: perms,
      originalAdminName: adminName,
    );
  }

  void exitImpersonation() {
    state = const ImpersonationState();
  }
}

final impersonationProvider = StateNotifierProvider<ImpersonationNotifier, ImpersonationState>((ref) {
  return ImpersonationNotifier();
});

// =============================================================================
// Live Company Roles Provider (Dynamic Database RBAC Permissions)
// =============================================================================

class CompanyRolesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final ApiService _apiService;
  CompanyRolesNotifier(this._apiService) : super([]);

  Future<List<Map<String, dynamic>>> loadRoles() async {
    try {
      final response = await _apiService.getCollection('company_roles', queryParams: {'limit': 100});
      final list = List<Map<String, dynamic>>.from(response.data);
      if (list.isNotEmpty) {
        state = list;
      }
      return list;
    } catch (_) {
      return state;
    }
  }

  void setRoles(List<Map<String, dynamic>> roles) {
    state = roles;
  }
}

final companyRolesProvider = StateNotifierProvider<CompanyRolesNotifier, List<Map<String, dynamic>>>((ref) {
  final api = ref.read(apiServiceProvider);
  final notifier = CompanyRolesNotifier(api);
  final auth = ref.watch(authStateProvider);
  if (auth.isAuthenticated) {
    notifier.loadRoles();
  }
  return notifier;
});

// =============================================================================
// Unified Effective User Provider (Single Source of Truth for RBAC)
// =============================================================================

class EffectiveUser {
  final String id;
  final String name;
  final String role; // 'ADMIN', 'OPERATOR', 'SUPERVISOR', 'TECHNICIAN', etc.
  final bool isImpersonating;
  final bool isAdmin;
  final String? employeeId;
  final String? shift;
  final String? department;
  final Set<String> permissions;
  final String? originalAdminName;

  const EffectiveUser({
    required this.id,
    required this.name,
    required this.role,
    required this.isImpersonating,
    required this.isAdmin,
    this.employeeId,
    this.shift,
    this.department,
    required this.permissions,
    this.originalAdminName,
  });

  bool hasPermission(String perm) {
    if (isAdmin) return true;
    return permissions.contains('*') || permissions.contains(perm);
  }

  bool canAccessRoute(String route) {
    return hasRoutePermission(route, permissions, isAdmin: isAdmin);
  }
}

final effectiveUserProvider = Provider<EffectiveUser>((ref) {
  final authState = ref.watch(authStateProvider);
  final impersonation = ref.watch(impersonationProvider);
  final rolePreview = ref.watch(rolePreviewProvider);
  final customRoles = ref.watch(companyRolesProvider);

  // 1. If actively impersonating a staff member
  if (impersonation.isImpersonating) {
    final role = impersonation.role ?? 'OPERATOR';
    final perms = getPermissionsForRole(role, customRoles);
    return EffectiveUser(
      id: impersonation.staffId ?? authState.userId ?? 'impersonated-staff',
      name: impersonation.staffName ?? 'Staff Member',
      role: role,
      isImpersonating: true,
      isAdmin: false,
      employeeId: impersonation.employeeId,
      shift: impersonation.shift,
      department: impersonation.department,
      permissions: perms.isNotEmpty ? perms : impersonation.permissions,
      originalAdminName: impersonation.originalAdminName ?? authState.userName ?? 'Admin',
    );
  }

  // 2. If previewing a role in RolesScreen
  if (rolePreview.isPreviewing) {
    final roleName = rolePreview.roleName ?? 'OPERATOR';
    final perms = getPermissionsForRole(roleName, customRoles);
    return EffectiveUser(
      id: authState.userId ?? 'role-preview',
      name: '${authState.userName ?? "Admin"} (Preview)',
      role: roleName,
      isImpersonating: true,
      isAdmin: roleName.toUpperCase() == 'ADMIN',
      permissions: perms.isNotEmpty ? perms : rolePreview.permissions.toSet(),
      originalAdminName: authState.userName ?? 'Admin',
    );
  }

  // 3. Normal logged in user
  final role = (authState.userRole ?? 'ADMIN').toUpperCase();
  final isAdmin = role == 'ADMIN';
  final perms = isAdmin ? {'*'} : getPermissionsForRole(role, customRoles);

  return EffectiveUser(
    id: authState.userId ?? '',
    name: authState.userName ?? 'Admin',
    role: role,
    isImpersonating: false,
    isAdmin: isAdmin,
    permissions: perms,
  );
});

// Auth Listenable Provider for GoRouter refresh
final authListenableProvider = Provider<Listenable>((ref) {
  final notifier = ValueNotifier<AuthState>(ref.read(authStateProvider));
  ref.listen<AuthState>(authStateProvider, (_, next) {
    notifier.value = next;
  });
  ref.listen<ImpersonationState>(impersonationProvider, (_, __) {
    notifier.value = ref.read(authStateProvider);
  });
  ref.listen<RolePreviewState>(rolePreviewProvider, (_, __) {
    notifier.value = ref.read(authStateProvider);
  });
  ref.listen<List<Map<String, dynamic>>>(companyRolesProvider, (_, __) {
    notifier.value = ref.read(authStateProvider);
  });
  ref.listen<SubscriptionState>(subscriptionProvider, (_, __) {
    notifier.value = ref.read(authStateProvider);
  });
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

// App Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = ref.watch(authListenableProvider);
  return AppRouter(ref: ref, refreshListenable: listenable).router;
});