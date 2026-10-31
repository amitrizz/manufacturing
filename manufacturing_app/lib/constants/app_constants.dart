class AppConstants {
  static const String appName = 'Manufacturing ERP';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String prodBaseUrl = 'https://manufacturing-i0lp.onrender.com/api/v1';
  static const String defaultBaseUrl = prodBaseUrl;
  static const String remoteBaseUrl = prodBaseUrl;
  static const String localEmulatorUrl = 'http://10.0.2.2:5000/api/v1';
  static const String localLanUrl = 'http://192.168.1.53:5000/api/v1';
  static const String localWebUrl = 'http://localhost:5000/api/v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 15);
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String companyIdKey = 'company_id';
  static const String userIdKey = 'user_id';
  static const String baseUrlKey = 'base_url';
  static const String themeModeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingCompleteKey = 'onboarding_complete';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayDateTimeFormat = 'MMM dd, yyyy HH:mm';
  
  // Colors
  static const int primaryColor = 0xFF2563EB;
  static const int successColor = 0xFF16A34A;
  static const int warningColor = 0xFFD97706;
  static const int dangerColor = 0xFFDC2626;
  static const int infoColor = 0xFF0284C7;
  
  // Machine Status Colors
  static const Map<String, int> machineStatusColors = {
    'RUNNING': 0xFF16A34A,
    'IDLE': 0xFF64748B,
    'BREAKDOWN': 0xFFDC2626,
    'MAINTENANCE': 0xFFD97706,
    'OFFLINE': 0xFF94A3B8,
    'STOPPED': 0xFF64748B,
  };
  
  // Order Status Colors
  static const Map<String, int> orderStatusColors = {
    'PENDING': 0xFF64748B,
    'IN_PROGRESS': 0xFF2563EB,
    'COMPLETED': 0xFF16A34A,
    'DELAYED': 0xFFF59E0B,
    'CANCELLED': 0xFFDC2626,
  };
  
  // Priority Colors
  static const Map<String, int> priorityColors = {
    'LOW': 0xFF64748B,
    'MEDIUM': 0xFF2563EB,
    'HIGH': 0xFFF59E0B,
    'CRITICAL': 0xFFDC2626,
  };
  
  // Inspection Result Colors
  static const Map<String, int> inspectionResultColors = {
    'PASS': 0xFF16A34A,
    'PASSED': 0xFF16A34A,
    'FAIL': 0xFFDC2626,
    'FAILED': 0xFFDC2626,
    'REWORK': 0xFFF59E0B,
    'PARTIAL_PASS': 0xFF0284C7,
  };
}