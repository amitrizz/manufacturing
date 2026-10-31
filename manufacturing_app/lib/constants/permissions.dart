// =============================================================================
// Available Permissions Definitions (Role-Based Access Control - RBAC)
// =============================================================================

class PermissionItem {
  final String key;
  final String label;
  final String description;
  final String category; // 'home' | 'tasks' | 'management'

  const PermissionItem({
    required this.key,
    required this.label,
    required this.description,
    required this.category,
  });
}

const List<PermissionItem> kAvailablePermissions = [
  // 1. Operations & Floor Modules (in Management / Home)
  PermissionItem(
    key: 'home_orders',
    label: 'Orders & Work Orders',
    description: 'View customer orders and production order book in Management tab',
    category: 'home',
  ),
  PermissionItem(
    key: 'home_production',
    label: 'Production Floor & Output',
    description: 'View live floor tracking and log production output in Management tab',
    category: 'home',
  ),
  PermissionItem(
    key: 'home_stock',
    label: 'Stock & Inventory',
    description: 'View materials, warehouse stock levels & ledgers in Management tab',
    category: 'home',
  ),
  PermissionItem(
    key: 'home_machines',
    label: 'Machine Telemetry & Status',
    description: 'View machine cards, breakdown status & operator info in Management tab',
    category: 'home',
  ),
  PermissionItem(
    key: 'home_quality',
    label: 'Quality & Rework',
    description: 'View QA inspections, defect rework orders & QC tests in Management tab',
    category: 'home',
  ),
  PermissionItem(
    key: 'home_maintenance',
    label: 'Machine Maintenance',
    description: 'View scheduled machine service & repair maintenance in Management tab',
    category: 'home',
  ),
  PermissionItem(
    key: 'home_products',
    label: 'Products & BOM Catalog',
    description: 'View finished goods catalogue and bill of materials in Management tab',
    category: 'home',
  ),

  // 2. My Tasks Activities
  PermissionItem(
    key: 'tasks_production',
    label: 'Production Order Tasks',
    description: 'View pending and active production jobs waiting to be recorded',
    category: 'tasks',
  ),
  PermissionItem(
    key: 'tasks_machines',
    label: 'Machine Breakdown Tasks',
    description: 'View machines under breakdown requiring urgent attention',
    category: 'tasks',
  ),
  PermissionItem(
    key: 'tasks_materials',
    label: 'Low Stock & Shortage Alerts',
    description: 'View material shortages and reorder alerts in My Tasks',
    category: 'tasks',
  ),
  PermissionItem(
    key: 'tasks_maintenance',
    label: 'Maintenance Orders',
    description: 'View pending machine maintenance work orders',
    category: 'tasks',
  ),
  PermissionItem(
    key: 'tasks_quality',
    label: 'Quality Rework Items',
    description: 'View defective parts flagged for rework',
    category: 'tasks',
  ),
  PermissionItem(
    key: 'tasks_dispatch',
    label: 'Ready Dispatches',
    description: 'View orders ready to ship out to customers',
    category: 'tasks',
  ),
  PermissionItem(
    key: 'tasks_quick_actions',
    label: 'Execute 1-Tap Quick Actions',
    description: 'Permission to trigger direct dispatch and complete rework actions',
    category: 'tasks',
  ),

  // 3. Management Tab Modules
  PermissionItem(
    key: 'mgmt_purchase',
    label: 'Purchase & GRN Receipts',
    description: 'Manage material purchase requests, POs and Goods Receipts',
    category: 'management',
  ),
  PermissionItem(
    key: 'mgmt_staff',
    label: 'Staff & Attendance Roster',
    description: 'Manage staff records, daily shifts and check-in attendance',
    category: 'management',
  ),
  PermissionItem(
    key: 'mgmt_reports',
    label: 'Factory Reports & Analytics',
    description: 'View high-level production, OEE and financial reporting',
    category: 'management',
  ),
  PermissionItem(
    key: 'mgmt_dispatch',
    label: 'Dispatch Logistics',
    description: 'Manage delivery orders, packing slips and shipments',
    category: 'management',
  ),
  PermissionItem(
    key: 'mgmt_contacts',
    label: 'Customers & Suppliers Directory',
    description: 'Manage customer accounts and approved vendor list',
    category: 'management',
  ),
  PermissionItem(
    key: 'mgmt_alerts',
    label: 'Alerts & System Notifications',
    description: 'View central notification alarms and factory events',
    category: 'management',
  ),
  PermissionItem(
    key: 'mgmt_settings',
    label: 'Settings & Data Backup',
    description: 'Configure company profile and system preferences',
    category: 'management',
  ),
  PermissionItem(
    key: 'mgmt_roles',
    label: 'Roles & Access Permissions',
    description: 'Create, modify and assign access permissions to custom roles',
    category: 'management',
  ),
];

// Standard Seed Roles
final List<Map<String, dynamic>> kStandardCompanyRoles = [
  {
    'name': 'OPERATOR',
    'description': 'Machine operations, live production output logging & breakdown view',
    'permissions': [
      'home_production',
      'home_machines',
      'home_orders',
      'tasks_production',
      'tasks_machines',
      'mgmt_alerts',
    ],
    'is_system': 1,
  },
  {
    'name': 'SUPERVISOR',
    'description': 'Floor supervision, attendance, orders, task dispatch & inspections',
    'permissions': [
      'home_orders',
      'home_production',
      'home_stock',
      'home_machines',
      'home_quality',
      'home_maintenance',
      'home_products',
      'tasks_production',
      'tasks_machines',
      'tasks_materials',
      'tasks_maintenance',
      'tasks_quality',
      'tasks_dispatch',
      'tasks_quick_actions',
      'mgmt_staff',
      'mgmt_reports',
      'mgmt_dispatch',
      'mgmt_alerts',
    ],
    'is_system': 1,
  },
  {
    'name': 'TECHNICIAN',
    'description': 'Machine repairs, routine maintenance servicing & breakdown response',
    'permissions': [
      'home_machines',
      'home_maintenance',
      'home_production',
      'tasks_machines',
      'tasks_maintenance',
      'mgmt_alerts',
    ],
    'is_system': 1,
  },
  {
    'name': 'QUALITY_INSPECTOR',
    'description': 'Part inspections, defect recording & rework order verification',
    'permissions': [
      'home_quality',
      'home_production',
      'home_products',
      'tasks_quality',
      'tasks_quick_actions',
      'mgmt_alerts',
    ],
    'is_system': 1,
  },
  {
    'name': 'MANAGER',
    'description': 'Full plant operations, purchase, dispatch, roles & configuration',
    'permissions': kAvailablePermissions.map((p) => p.key).toList(),
    'is_system': 1,
  },
  {
    'name': 'ADMIN',
    'description': 'Super-user with unrestricted root factory permissions',
    'permissions': ['*'],
    'is_system': 1,
  },
];

/// Get permissions set for a given role name
Set<String> getPermissionsForRole(String roleName, [List<Map<String, dynamic>>? customRoles]) {
  final cleanName = roleName.trim().toUpperCase();
  if (cleanName == 'ADMIN') {
    return {'*'};
  }

  // Check custom roles if passed
  if (customRoles != null && customRoles.isNotEmpty) {
    final custom = customRoles.firstWhere(
      (r) => (r['name']?.toString() ?? '').toUpperCase() == cleanName,
      orElse: () => <String, dynamic>{},
    );
    if (custom.isNotEmpty && custom['permissions'] != null) {
      final perms = custom['permissions'];
      if (perms is List) {
        return perms.map((p) => p.toString()).toSet();
      }
    }
  }

  // Check standard company roles
  final standard = kStandardCompanyRoles.firstWhere(
    (r) => r['name'] == cleanName,
    orElse: () => {
      'permissions': [
        'home_production',
        'home_machines',
        'tasks_production',
        'mgmt_alerts',
      ],
    },
  );

  final perms = standard['permissions'];
  if (perms is List) {
    return perms.map((p) => p.toString()).toSet();
  }
  return {'home_production', 'home_machines', 'mgmt_alerts'};
}

/// Route-to-Permission Mapping for RBAC route guards
const Map<String, String> kRoutePermissionMap = {
  // Orders
  '/production/orders': 'home_orders',
  '/orders': 'home_orders',

  // Production
  '/production/floor': 'home_production',
  '/production/plans': 'home_production',
  '/production': 'home_production',

  // Inventory & Stock
  '/inventory/stock': 'home_stock',
  '/materials': 'home_stock',
  '/inventory/finished-goods': 'home_stock',
  '/inventory/products': 'home_products',
  '/inventory/bom': 'home_products',

  // Machines
  '/machines': 'home_machines',
  '/maintenance': 'home_maintenance',

  // Quality
  '/quality/inspections': 'home_quality',
  '/quality': 'home_quality',
  '/rework': 'home_quality',

  // Management Tab Modules
  '/purchase/orders': 'mgmt_purchase',
  '/purchase': 'mgmt_purchase',
  '/staff': 'mgmt_staff',
  '/staff/attendance': 'mgmt_staff',
  '/reports': 'mgmt_reports',
  '/reports/production': 'mgmt_reports',
  '/reports/center': 'mgmt_reports',
  '/reports/oee': 'mgmt_reports',
  '/costing': 'mgmt_reports',
  '/dispatch': 'mgmt_dispatch',
  '/dispatch/orders': 'mgmt_dispatch',
  '/dispatch/customers': 'mgmt_contacts',
  '/contacts': 'mgmt_contacts',
  '/notifications': 'mgmt_alerts',
  '/roles': 'mgmt_roles',
  '/settings/api': 'mgmt_settings',
};

/// Check if a given route is accessible with a set of permissions
bool hasRoutePermission(String routePath, Set<String> permissions, {bool isAdmin = false}) {
  if (isAdmin || permissions.contains('*')) return true;

  // Exact match
  final requiredPerm = kRoutePermissionMap[routePath];
  if (requiredPerm == null) {
    // Check prefix match
    for (final entry in kRoutePermissionMap.entries) {
      if (routePath.startsWith(entry.key)) {
        return permissions.contains(entry.value);
      }
    }
    // If not in the restricted map (e.g. /dashboard, /tasks, /profile), allowed
    return true;
  }

  return permissions.contains(requiredPerm);
}
