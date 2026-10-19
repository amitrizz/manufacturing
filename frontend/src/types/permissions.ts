export type PermissionCategory = 'home' | 'tasks' | 'management';

export type PermissionItem = {
  key: string;
  label: string;
  description: string;
  category: PermissionCategory;
};

export const AVAILABLE_PERMISSIONS: PermissionItem[] = [
  // 1. Operations & Floor Modules (in Management tab)
  {
    key: 'home_orders',
    label: 'Orders & Work Orders',
    description: 'View customer orders and production order book in Management tab',
    category: 'home',
  },
  {
    key: 'home_production',
    label: 'Production Floor & Output',
    description: 'View live floor tracking and log production output in Management tab',
    category: 'home',
  },
  {
    key: 'home_stock',
    label: 'Stock & Inventory',
    description: 'View materials, warehouse stock levels & ledgers in Management tab',
    category: 'home',
  },
  {
    key: 'home_machines',
    label: 'Machine Telemetry & Status',
    description: 'View machine cards, breakdown status & operator info in Management tab',
    category: 'home',
  },
  {
    key: 'home_quality',
    label: 'Quality & Rework',
    description: 'View QA inspections, defect rework orders & QC tests in Management tab',
    category: 'home',
  },
  {
    key: 'home_maintenance',
    label: 'Machine Maintenance',
    description: 'View scheduled machine service & repair maintenance in Management tab',
    category: 'home',
  },
  {
    key: 'home_products',
    label: 'Products & BOM Catalog',
    description: 'View finished goods catalogue and bill of materials in Management tab',
    category: 'home',
  },

  // 2. My Tasks Activities
  {
    key: 'tasks_production',
    label: 'Production Order Tasks',
    description: 'View pending and active production jobs waiting to be recorded',
    category: 'tasks',
  },
  {
    key: 'tasks_machines',
    label: 'Machine Breakdown Tasks',
    description: 'View machines under breakdown requiring urgent attention',
    category: 'tasks',
  },
  {
    key: 'tasks_materials',
    label: 'Low Stock & Shortage Alerts',
    description: 'View material shortages and reorder alerts in My Tasks',
    category: 'tasks',
  },
  {
    key: 'tasks_maintenance',
    label: 'Maintenance Orders',
    description: 'View pending machine maintenance work orders',
    category: 'tasks',
  },
  {
    key: 'tasks_quality',
    label: 'Quality Rework Items',
    description: 'View defective parts flagged for rework',
    category: 'tasks',
  },
  {
    key: 'tasks_dispatch',
    label: 'Ready Dispatches',
    description: 'View orders ready to ship out to customers',
    category: 'tasks',
  },
  {
    key: 'tasks_quick_actions',
    label: 'Execute 1-Tap Quick Actions',
    description: 'Permission to trigger direct dispatch and complete rework actions',
    category: 'tasks',
  },

  // 3. Management Tab Modules
  {
    key: 'mgmt_purchase',
    label: 'Purchase & GRN Receipts',
    description: 'Manage material purchase requests, POs and Goods Receipts',
    category: 'management',
  },
  {
    key: 'mgmt_staff',
    label: 'Staff & Attendance Roster',
    description: 'Manage staff records, daily shifts and check-in attendance',
    category: 'management',
  },
  {
    key: 'mgmt_reports',
    label: 'Factory Reports & Analytics',
    description: 'View high-level production, OEE and financial reporting',
    category: 'management',
  },
  {
    key: 'mgmt_dispatch',
    label: 'Dispatch Logistics',
    description: 'Manage delivery orders, packing slips and shipments',
    category: 'management',
  },
  {
    key: 'mgmt_contacts',
    label: 'Customers & Suppliers Directory',
    description: 'Manage customer accounts and approved vendor list',
    category: 'management',
  },
  {
    key: 'mgmt_alerts',
    label: 'Alerts & System Notifications',
    description: 'View central notification alarms and factory events',
    category: 'management',
  },
  {
    key: 'mgmt_settings',
    label: 'Settings & Data Backup',
    description: 'Configure company profile and system preferences',
    category: 'management',
  },
  {
    key: 'mgmt_roles',
    label: 'Roles & Access Permissions',
    description: 'Create, modify and assign access permissions to custom roles',
    category: 'management',
  },
];

export type CompanyRoleRow = {
  id: string;
  company_id: string;
  name: string;
  description?: string | null;
  permissions: string[]; // parsed from JSON
  is_system: number;
  created_at: number;
  updated_at: number;
};
