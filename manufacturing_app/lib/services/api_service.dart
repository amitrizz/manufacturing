import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../models/common.dart';
import '../models/dashboard.dart';
import '../models/company.dart';
import '../models/machine.dart';
import '../models/production.dart';
import '../models/purchase.dart';
import '../utils/logger.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  static ApiService get instance => _instance;
  factory ApiService() => _instance;
  ApiService._internal();
  
  late Dio _dio;
  late SharedPreferences _prefs;
  late FlutterSecureStorage _secureStorage;
  
  String _baseUrl = AppConstants.defaultBaseUrl;
  String? _authToken;
  String? _companyId;
  String? _userId;
  
  // Getters
  String get baseUrl => _baseUrl;
  String? get authToken => _authToken;
  String? get companyId => _companyId;
  String? get userId => _userId;
  bool get isAuthenticated => _authToken != null;
  
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage();
    
    // Load saved configuration
    final defaultUrl = kIsWeb ? 'http://localhost:5000/api/v1' : AppConstants.defaultBaseUrl;
    final savedUrl = _prefs.getString(AppConstants.baseUrlKey);
    if (savedUrl != null && !savedUrl.contains('your-production-api.com')) {
      _baseUrl = savedUrl;
    } else {
      _baseUrl = defaultUrl;
    }
    try {
      if (!kIsWeb) {
        _authToken = await _secureStorage.read(key: AppConstants.authTokenKey);
      } else {
        _authToken = _prefs.getString(AppConstants.authTokenKey);
      }
    } catch (_) {
      _authToken = _prefs.getString(AppConstants.authTokenKey);
    }
    _companyId = _prefs.getString(AppConstants.companyIdKey);
    _userId = _prefs.getString(AppConstants.userIdKey);
    
    _setupDio();
  }
  
  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      sendTimeout: AppConstants.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        if (_companyId != null) {
          options.headers['x-company-id'] = _companyId;
        }
        Logger.instance.d('API Request: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        Logger.instance.d('API Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        Logger.instance.e('API Error: ${error.response?.statusCode} ${error.requestOptions.path}', error: error);
        handler.next(error);
      },
    ));
  }
  
  void updateBaseUrl(String url) {
    _baseUrl = url;
    _prefs.setString(AppConstants.baseUrlKey, url);
    _dio.options.baseUrl = url;
  }
  
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    if (!kIsWeb) {
      try {
        await _secureStorage.write(key: AppConstants.authTokenKey, value: token);
      } catch (_) {}
    }
    await _prefs.setString(AppConstants.authTokenKey, token);
  }
  
  Future<void> clearAuthToken() async {
    _authToken = null;
    if (!kIsWeb) {
      try {
        await _secureStorage.delete(key: AppConstants.authTokenKey);
      } catch (_) {}
    }
    await _prefs.remove(AppConstants.authTokenKey);
  }
  
  void setCompanyId(String companyId) {
    _companyId = companyId;
    _prefs.setString(AppConstants.companyIdKey, companyId);
  }
  
  void setUserId(String userId) {
    _userId = userId;
    _prefs.setString(AppConstants.userIdKey, userId);
  }
  
  Future<void> logout() async {
    await clearAuthToken();
    _companyId = null;
    _userId = null;
    await _prefs.remove(AppConstants.companyIdKey);
    await _prefs.remove(AppConstants.userIdKey);
  }
  
  // Generic request methods
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters, T Function(dynamic)? parser}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      if (parser != null) return parser(response.data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<T> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, T Function(dynamic)? parser}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      if (parser != null) return parser(response.data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<T> put<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, T Function(dynamic)? parser}) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: queryParameters);
      if (parser != null) return parser(response.data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<T> delete<T>(String path, {Map<String, dynamic>? queryParameters, T Function(dynamic)? parser}) async {
    try {
      final response = await _dio.delete(path, queryParameters: queryParameters);
      if (parser != null) return parser(response.data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode ?? 500;
      final data = e.response!.data;
      String message = 'API Error: $statusCode';
      
      if (data is Map && data.containsKey('error')) {
        message = data['error'];
      } else if (data is String) {
        message = data;
      }
      
      if (statusCode == 401) {
        // Token expired, clear auth
        logout();
      }
      
      return ApiException(message, statusCode: statusCode, details: data);
    } else {
      return ApiException('Network error: ${e.message}');
    }
  }
  
  // Health Check
  Future<HealthResponse> getHealth() async {
    return get('/health', parser: (data) => HealthResponse.fromJson(data));
  }
  
  // Company APIs
  Future<Company> createCompany(Map<String, dynamic> data) async {
    return post('/companies', data: data, parser: (data) => Company.fromJson(data));
  }
  
  Future<List<Company>> listCompanies() async {
    return get('/companies', parser: (data) {
      final list = data['data'] as List;
      return list.map((e) => Company.fromJson(e)).toList();
    });
  }
  
  Future<Company> getCompany(String id) async {
    return get('/companies/$id', parser: (data) => Company.fromJson(data));
  }
  
  Future<Map<String, dynamic>> verifyAdmin(String emailOrCode, String password) async {
    return post('/companies/verify-admin', data: {
      'emailOrCode': emailOrCode,
      'password': password,
    });
  }

  // Subscription & Payment APIs
  Future<Map<String, dynamic>> getSubscriptionStatus({String? companyId}) async {
    final target = companyId ?? _companyId;
    return get('/subscription/status', queryParameters: target != null ? {'companyId': target} : null);
  }

  Future<Map<String, dynamic>> renewSubscription({String? companyId, String plan = 'PRO_ANNUAL'}) async {
    final target = companyId ?? _companyId;
    return post('/subscription/renew', data: {
      'companyId': target,
      'plan': plan,
    });
  }

  Future<Map<String, dynamic>> createCashfreeOrder({
    required String plan,
    double? amount,
    String? companyId,
  }) async {
    final target = companyId ?? _companyId;
    return post('/payments/cashfree/create-order', data: {
      'companyId': target,
      'plan': plan,
      if (amount != null) 'amount': amount,
    });
  }

  Future<Map<String, dynamic>> verifyCashfreePayment({
    required String orderId,
    String? companyId,
    String plan = 'PRO_MONTHLY',
    bool stubMode = false,
  }) async {
    final target = companyId ?? _companyId;
    return post('/payments/cashfree/verify', data: {
      'orderId': orderId,
      'companyId': target,
      'plan': plan,
      'stubMode': stubMode,
    });
  }
  
  // Dashboard APIs
  Future<DashboardResponse> getDashboardStats({int? start, int? end}) async {
    final queryParams = <String, dynamic>{};
    if (start != null) queryParams['start'] = start;
    if (end != null) queryParams['end'] = end;
    
    return get('/dashboard/stats', queryParameters: queryParams, parser: (data) => DashboardResponse.fromJson(data));
  }
  
  // Machine APIs
  Future<PaginatedResponse<Machine>> listMachines({
    String? status,
    String? lineId,
    String? search,
    int limit = AppConstants.defaultPageSize,
    int skip = 0,
    String sort = 'created_at',
    String order = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'skip': skip,
      'sort': sort,
      'order': order,
    };
    if (status != null) queryParams['status'] = status;
    if (lineId != null) queryParams['lineId'] = lineId;
    if (search != null) queryParams['search'] = search;
    
    return get('/machines', queryParameters: queryParams, parser: (data) {
      final paginated = PaginatedResponse.fromJson(data);
      return PaginatedResponse(
        data: (paginated.data as List).map((e) => Machine.fromJson(e)).toList(),
        pagination: paginated.pagination,
      );
    });
  }
  
  Future<Map<String, dynamic>> updateMachineStatus(String id, String status, {String? reason}) async {
    return post('/machines/$id/status', data: {'status': status, 'reason': reason});
  }
  
  // Production APIs
  Future<PaginatedResponse<ProductionOrder>> listProductionOrders({
    String? status,
    int limit = AppConstants.defaultPageSize,
    int skip = 0,
    String sort = 'created_at',
    String order = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'skip': skip,
      'sort': sort,
      'order': order,
    };
    if (status != null) queryParams['status'] = status;
    
    return get('/production-orders', queryParameters: queryParams, parser: (data) {
      final paginated = PaginatedResponse.fromJson(data);
      return PaginatedResponse(
        data: (paginated.data as List).map((e) => ProductionOrder.fromJson(e)).toList(),
        pagination: paginated.pagination,
      );
    });
  }
  
  Future<Map<String, dynamic>> startProductionOrder(String id) async {
    return post('/production-orders/$id/start');
  }
  
  // Purchase/GRN APIs
  Future<List<GrnReceipt>> listGrnReceipts() async {
    return get('/purchase/grn-receipts', parser: (data) {
      final list = data as List;
      return list.map((e) => GrnReceipt.fromJson(e)).toList();
    });
  }
  
  Future<Map<String, dynamic>> receiveGrn(GrnReceivePayload payload) async {
    return post('/purchase/receive-grn', data: payload.toJson());
  }
  
  Future<Map<String, dynamic>> deleteGrn(String id) async {
    return delete('/purchase/delete-grn/$id');
  }
  
  // Collection APIs (Generic CRUD)
  Future<PaginatedResponse<Map<String, dynamic>>> getCollection(
    String name, {
    Map<String, dynamic>? queryParams,
  }) async {
    final params = <String, dynamic>{
      'limit': AppConstants.defaultPageSize,
      'skip': 0,
      'sort': 'created_at',
      'order': 'desc',
      ...?queryParams,
    };
    
    return get('/collections/$name', queryParameters: params, parser: (data) {
      final paginated = PaginatedResponse.fromJson(data);
      return PaginatedResponse<Map<String, dynamic>>(
        data: (paginated.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        pagination: paginated.pagination,
      );
    });
  }
  
  Future<Map<String, dynamic>> getCollectionItem(String name, String id) async {
    return get('/collections/$name/$id');
  }
  
  Future<Map<String, dynamic>> createCollectionItem(String name, Map<String, dynamic> data) async {
    return post('/collections/$name', data: data);
  }
  
  Future<Map<String, dynamic>> updateCollectionItem(String name, String id, Map<String, dynamic> data) async {
    return put('/collections/$name/$id', data: data);
  }
  
  Future<Map<String, dynamic>> deleteCollectionItem(String name, String id) async {
    return delete('/collections/$name/$id');
  }
  
  // Units
  Future<PaginatedResponse<Unit>> listUnits({
    int limit = AppConstants.defaultPageSize,
    int skip = 0,
    String sort = 'category',
    String order = 'asc',
  }) async {
    return get('/units', queryParameters: {
      'limit': limit,
      'skip': skip,
      'sort': sort,
      'order': order,
    }, parser: (data) {
      final paginated = PaginatedResponse.fromJson(data);
      return PaginatedResponse(
        data: (paginated.data as List).map((e) => Unit.fromJson(e)).toList(),
        pagination: paginated.pagination,
      );
    });
  }
  
  Future<Unit> createUnit(Map<String, dynamic> data) async {
    return post('/units', data: data, parser: (data) => Unit.fromJson(data));
  }
  
  Future<Map<String, dynamic>> seedUnits() async {
    return post('/units/seed');
  }
  
  // Database actions
  Future<Map<String, dynamic>> getAllData() async {
    return get('/database/all');
  }
  
  Future<Map<String, dynamic>> clearAllData() async {
    return post('/database/clear', data: {'confirm': true});
  }
  
  Future<Map<String, dynamic>> seedDemoData() async {
    return post('/database/seed', data: {'confirm': true});
  }
  
  Future<Map<String, dynamic>> resetDemoData() async {
    return post('/database/reset', data: {'confirm': true});
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;
  
  ApiException(this.message, {this.statusCode, this.details});
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}