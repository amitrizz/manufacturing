import 'package:flutter/material.dart';

/// Centralized Design System Colors for Manufacturing ERP.
/// Provides consistent chrome, module identities, and semantic status styling across all modules.
class AppColors {
  AppColors._();

  // ===========================================================================
  // 1. Chrome & Layout Tokens
  // ===========================================================================
  /// Unified dark navy header used across all module AppBars and headers
  static const Color headerNavy = Color(0xFF0A1E38);
  /// Elevated/secondary container inside dark navy header (chips, search, filters)
  static const Color headerNavyLight = Color(0xFF162E4E);
  /// Active accent in dark navy header (tab indicators, FABs, highlights)
  static const Color headerAccent = Color(0xFF38BDF8);
  /// Unselected text/icon in dark navy header
  static const Color headerUnselected = Color(0xFF94A3B8);

  /// Scaffold background for light & dark modes
  static const Color scaffoldLight = Color(0xFFF8FAFC);
  static const Color scaffoldDark = Color(0xFF0F172A);

  /// Card & container surface
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E293B);

  /// Borders & dividers
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  /// Typography colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // ===========================================================================
  // 2. Consistent Module Identity Palette
  // ===========================================================================
  /// 1. Orders & Production Tracking
  static const Color moduleOrders = Color(0xFF0284C7);
  static const Color moduleOrdersBg = Color(0xFFEFF6FF);

  /// 2. Production Floor & Assembly Lines
  static const Color moduleFloor = Color(0xFF16A34A);
  static const Color moduleFloorBg = Color(0xFFECFDF5);

  /// 3. Production Plans & Targets
  static const Color modulePlans = Color(0xFF0D9488);
  static const Color modulePlansBg = Color(0xFFF0FDFA);

  /// 4. Stock Inventory & Raw Materials
  static const Color moduleInventory = Color(0xFFEA580C);
  static const Color moduleInventoryBg = Color(0xFFFFFBEB);

  /// 5. Finished Goods & Ready Stock
  static const Color moduleFinishedGoods = Color(0xFF059669);
  static const Color moduleFinishedGoodsBg = Color(0xFFECFDF5);

  /// 6. Products Master Catalog
  static const Color moduleProducts = Color(0xFF7C3AED);
  static const Color moduleProductsBg = Color(0xFFF5F3FF);

  /// 7. Bill of Materials (BOM)
  static const Color moduleBOM = Color(0xFF0284C7);
  static const Color moduleBOMBg = Color(0xFFEFF6FF);

  /// 8. Quality Assurance & Inspections
  static const Color moduleQuality = Color(0xFF0284C7);
  static const Color moduleQualityBg = Color(0xFFEFF6FF);

  /// 9. Machines & IoT Telemetry
  static const Color moduleMachines = Color(0xFFDB2777);
  static const Color moduleMachinesBg = Color(0xFFFDF2F8);

  /// 10. Machine Maintenance & Work Orders
  static const Color moduleMaintenance = Color(0xFFD97706);
  static const Color moduleMaintenanceBg = Color(0xFFFFFBEB);

  /// 11. Rework & Defects
  static const Color moduleRework = Color(0xFFD84315);
  static const Color moduleReworkBg = Color(0xFFFBE9E7);

  /// 12. Reports & Analytics
  static const Color moduleReports = Color(0xFF2563EB);
  static const Color moduleReportsBg = Color(0xFFEFF6FF);

  /// 13. Staff, Shifts & Attendance
  static const Color moduleStaff = Color(0xFF7C3AED);
  static const Color moduleStaffBg = Color(0xFFF5F3FF);

  /// 14. Purchase & Suppliers
  static const Color modulePurchase = Color(0xFF0284C7);
  static const Color modulePurchaseBg = Color(0xFFEFF6FF);

  /// 15. Costing & Accounts
  static const Color moduleCosting = Color(0xFF7C3AED);
  static const Color moduleCostingBg = Color(0xFFF5F3FF);

  /// 16. Customers & Contacts
  static const Color moduleContacts = Color(0xFF0D9488);
  static const Color moduleContactsBg = Color(0xFFF0FDFA);

  /// 17. Dispatch & Logistics
  static const Color moduleDispatch = Color(0xFF1565C0);
  static const Color moduleDispatchBg = Color(0xFFE3F2FD);

  /// 18. Roles & Access Control
  static const Color moduleRoles = Color(0xFF1E40AF);
  static const Color moduleRolesBg = Color(0xFFEFF6FF);

  /// 19. Alerts & Notifications
  static const Color moduleAlerts = Color(0xFFDC2626);
  static const Color moduleAlertsBg = Color(0xFFFEF2F2);

  // ===========================================================================
  // 3. Semantic Status Palette
  // ===========================================================================
  /// Success (Green / Emerald)
  static const Color statusSuccess = Color(0xFF16A34A);
  static const Color statusSuccessBg = Color(0xFFECFDF5);
  static const Color statusSuccessBorder = Color(0xFFA7F3D0);

  /// Warning (Amber / Orange)
  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusWarningBg = Color(0xFFFFFBEB);
  static const Color statusWarningBorder = Color(0xFFFDE68A);

  /// Danger / Critical (Red / Crimson)
  static const Color statusDanger = Color(0xFFDC2626);
  static const Color statusDangerBg = Color(0xFFFEF2F2);
  static const Color statusDangerBorder = Color(0xFFFECACA);

  /// Info / In Progress (Sky / Blue)
  static const Color statusInfo = Color(0xFF0284C7);
  static const Color statusInfoBg = Color(0xFFEFF6FF);
  static const Color statusInfoBorder = Color(0xFFBFDBFE);

  /// Neutral / Idle / Offline (Slate / Grey)
  static const Color statusNeutral = Color(0xFF64748B);
  static const Color statusNeutralBg = Color(0xFFF1F5F9);
  static const Color statusNeutralBorder = Color(0xFFE2E8F0);

  /// Violet / Purple
  static const Color statusPurple = Color(0xFF7C3AED);
  static const Color statusPurpleBg = Color(0xFFF5F3FF);
  static const Color statusPurpleBorder = Color(0xFFDDD6FE);

  // ===========================================================================
  // 4. Status Resolvers
  // ===========================================================================
  /// Resolves the foreground color for any status string across all modules.
  static Color getStatusColor(String? status) {
    if (status == null || status.isEmpty) return statusNeutral;
    final s = status.toUpperCase().trim();

    switch (s) {
      // Success states
      case 'RUNNING':
      case 'COMPLETED':
      case 'PASS':
      case 'PASSED':
      case 'APPROVED':
      case 'DELIVERED':
      case 'PRESENT':
      case 'ACTIVE':
      case 'RESOLVED':
      case 'ON_TIME':
      case 'IN_STOCK':
      case 'ONLINE':
      case 'HEALTHY':
        return statusSuccess;

      // In Progress / Active states
      case 'IN_PROGRESS':
      case 'IN PROGRESS':
      case 'PROCESSING':
      case 'READY':
      case 'SCHEDULED':
      case 'DISPATCHED':
      case 'OPEN':
        return statusInfo;

      // Warning states
      case 'MAINTENANCE':
      case 'DELAYED':
      case 'LOW_STOCK':
      case 'LOW STOCK':
      case 'REWORK':
      case 'HALF_DAY':
      case 'HALF DAY':
      case 'PARTIAL_PASS':
      case 'EXPIRING':
      case 'WARNING':
      case 'HIGH':
        return statusWarning;

      // Critical / Error states
      case 'BREAKDOWN':
      case 'FAIL':
      case 'FAILED':
      case 'CANCELLED':
      case 'CRITICAL':
      case 'OVERDUE':
      case 'ABSENT':
      case 'REJECTED':
      case 'OUT_OF_STOCK':
      case 'OUT OF STOCK':
      case 'URGENT':
      case 'SHORTAGE':
        return statusDanger;

      // Neutral states
      case 'PENDING':
      case 'IDLE':
      case 'OFFLINE':
      case 'STOPPED':
      case 'DRAFT':
      case 'LOW':
      case 'LEAVE':
      default:
        return statusNeutral;
    }
  }

  /// Resolves the background container / pill color for any status string.
  static Color getStatusBgColor(String? status, {bool isDark = false}) {
    final baseColor = getStatusColor(status);
    if (isDark) {
      return baseColor.withValues(alpha: 0.18);
    }
    if (baseColor == statusSuccess) return statusSuccessBg;
    if (baseColor == statusWarning) return statusWarningBg;
    if (baseColor == statusDanger) return statusDangerBg;
    if (baseColor == statusInfo) return statusInfoBg;
    return statusNeutralBg;
  }

  /// Resolves the border color for any status pill.
  static Color getStatusBorderColor(String? status, {bool isDark = false}) {
    final baseColor = getStatusColor(status);
    if (isDark) {
      return baseColor.withValues(alpha: 0.35);
    }
    if (baseColor == statusSuccess) return statusSuccessBorder;
    if (baseColor == statusWarning) return statusWarningBorder;
    if (baseColor == statusDanger) return statusDangerBorder;
    if (baseColor == statusInfo) return statusInfoBorder;
    return statusNeutralBorder;
  }

  /// Resolves the category color for tasks, activities and modules.
  static Color getCategoryColor(String? category) {
    if (category == null) return statusInfo;
    final c = category.toLowerCase().trim();

    if (c.contains('order') || c.contains('production')) return moduleOrders;
    if (c.contains('floor') || c.contains('line')) return moduleFloor;
    if (c.contains('plan')) return modulePlans;
    if (c.contains('stock') || c.contains('material') || c.contains('inventory')) return moduleInventory;
    if (c.contains('finished')) return moduleFinishedGoods;
    if (c.contains('product') || c.contains('catalog')) return moduleProducts;
    if (c.contains('bom')) return moduleBOM;
    if (c.contains('quality') || c.contains('rework') || c.contains('qc') || c.contains('qa')) return moduleQuality;
    if (c.contains('machine')) return moduleMachines;
    if (c.contains('maintenance')) return moduleMaintenance;
    if (c.contains('report') || c.contains('analytics')) return moduleReports;
    if (c.contains('staff') || c.contains('shift') || c.contains('attendance')) return moduleStaff;
    if (c.contains('purchase') || c.contains('supplier')) return modulePurchase;
    if (c.contains('dispatch') || c.contains('ship') || c.contains('logistics')) return moduleDispatch;
    if (c.contains('contact') || c.contains('customer')) return moduleContacts;
    if (c.contains('role') || c.contains('security')) return moduleRoles;

    return statusInfo;
  }
}
