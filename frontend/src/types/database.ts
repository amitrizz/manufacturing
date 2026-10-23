export type MachineStatus = 'RUNNING' | 'IDLE' | 'BREAKDOWN' | 'MAINTENANCE' | 'OFFLINE';
export type OrderStatus = 'PENDING' | 'IN_PROGRESS' | 'COMPLETED' | 'DELAYED' | 'CANCELLED';
export type PlanStatus = 'PLANNED' | 'IN_PROGRESS' | 'COMPLETED' | 'DELAYED' | 'CANCELLED';
export type Priority = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
export type InspectionResult = 'PASS' | 'FAIL' | 'REWORK' | 'PARTIAL_PASS' | 'PASSED' | 'FAILED';
export type NotificationSeverity = 'INFO' | 'WARNING' | 'CRITICAL';
export type StockCategory = 'RAW_MATERIAL' | 'SEMI_FINISHED' | 'FINISHED_GOODS' | 'PACKAGING' | 'CONSUMABLE' | string;

export type MaterialRow = {
  id: string;
  code: string;
  name: string;
  category: string;
  unit: string;
  current_stock: number;
  minimum_stock: number;
  maximum_stock: number;
  company_id?: string | null;
  updated_at: number;
};

export type ProductRow = {
  id: string;
  code: string;
  name: string;
  category_id: string | null;
  unit: string;
  description: string | null;
  company_id?: string | null;
  created_at: number;
};

export type MachineRow = {
  id: string;
  code: string;
  name: string;
  machine_type: string;
  line_id: string;
  line_code?: string;
  line_name?: string;
  status: MachineStatus;
  current_product_id: string | null;
  product_code?: string | null;
  current_operator?: string | null;
  efficiency: number;
  runtime_seconds: number;
  downtime_seconds: number;
  last_maintenance_at: number | null;
  next_maintenance_at: number | null;
  company_id?: string | null;
  created_at: number;
  updated_at: number;
};

export type ProductionPlanRow = {
  id: string;
  plan_number: string;
  product_id: string;
  product_code?: string;
  product_name?: string;
  target_quantity: number;
  line_id: string;
  line_code?: string;
  start_date: number;
  expected_completion: number;
  priority: Priority;
  status: PlanStatus;
  notes: string | null;
  company_id?: string | null;
  created_at: number;
  updated_at: number;
};

export type ProductionOrderRow = {
  id: string;
  order_number: string;
  plan_id: string | null;
  product_id: string;
  product_code?: string;
  product_name?: string;
  line_id: string;
  line_code?: string;
  machine_id: string | null;
  machine_code?: string | null;
  assigned_machines?: string[] | string | null;
  assigned_workers?: string[] | string | null;
  target_quantity: number;
  produced_quantity: number;
  rejected_quantity: number;
  priority: Priority;
  status: OrderStatus;
  qc_status?: string | null;
  qc_notes?: string | null;
  qc_inspected_at?: number | null;
  qc_inspector?: string | null;
  start_date: number | null;
  due_date: number | null;
  started_at: number | null;
  completed_at: number | null;
  company_id?: string | null;
  created_at: number;
  updated_at: number;
};

export type ActivityRow = {
  id: string;
  event_type: string;
  title: string;
  description: string | null;
  reference_type: string | null;
  reference_id: string | null;
  company_id?: string | null;
  timestamp: number;
};

export type NotificationRow = {
  id: string;
  title: string;
  body: string;
  severity: NotificationSeverity;
  is_read: number;
  reference_type: string | null;
  reference_id: string | null;
  created_at: number;
};

export type BomItemRow = {
  id?: string;
  bom_id?: string;
  material_id: string;
  material_code: string;
  material_name: string;
  quantity: number;
  unit: string;
};

export type MaterialAvailabilityRow = {
  material_id: string;
  code: string;
  name: string;
  per_unit: number;
  used_total: number;
  required: number;
  available: number;
  minimum_stock: number;
  unit: string;
  status: 'AVAILABLE' | 'NEAR_MINIMUM' | 'SHORTAGE';
};

export type MaterialConsumptionLine = {
  material_id: string;
  code: string;
  name: string;
  unit: string;
  per_unit: number;
  quantity: number;
};

export type FinishedGoodsRow = {
  id: string;
  product_id: string;
  product_code?: string;
  product_name?: string;
  produced_quantity: number;
  quality_passed_quantity: number;
  rejected_quantity: number;
  rework_quantity: number;
  available_quantity: number;
  updated_at: number;
};

export type DispatchOrderRow = {
  id: string;
  dispatch_number: string;
  customer_name: string;
  customer_id?: string | null;
  product_id: string;
  product_code?: string;
  product_name?: string;
  quantity: number;
  status: string;
  delivery_address?: string | null;
  vehicle_number?: string | null;
  driver_name?: string | null;
  notes?: string | null;
  created_at: number;
  dispatched_at: number | null;
};

export type MaintenanceOrderRow = {
  id: string;
  order_number: string;
  machine_id: string;
  machine_code?: string;
  type: string;
  issue: string | null;
  priority: Priority;
  assigned_team: string | null;
  status: string;
  root_cause: string | null;
  action_taken: string | null;
  created_at: number;
  completed_at: number | null;
};

export type QualityInspectionRow = {
  id: string;
  batch_number: string;
  production_order_id: string;
  order_number?: string;
  product_id: string;
  product_code?: string;
  quantity: number;
  inspector: string;
  overall_result: InspectionResult;
  rejected_quantity: number;
  inspected_at: number;
  rejection_reason?: string | null;
  rejection_action?: string | null;
};

export type ReworkOrderRow = {
  id: string;
  rework_number: string;
  product_id: string;
  product_code?: string;
  quantity: number;
  reason: string;
  status: string;
  created_at: number;
};

export type UnitCategory = 'count' | 'weight' | 'volume' | 'length' | 'area' | 'packaging' | 'custom' | string;

export type UnitRow = {
  id: string;
  code: string;
  name: string;
  symbol: string;
  category: UnitCategory;
  is_custom: number;
  description?: string | null;
  created_at: number;
  updated_at: number;
};

export type CustomerRow = {
  id: string;
  code?: string;
  name: string;
  company?: string | null;
  contact_person?: string | null;
  phone?: string | null;
  email?: string | null;
  address?: string | null;
  billing_address?: string | null;
  delivery_address?: string | null;
  gst_number?: string | null;
  company_id?: string | null;
  created_at: number;
  updated_at: number;
};

export type ShiftAssignmentInfo = {
  shift: string;
  operator: string | null;
  total_produced: number;
  last_active_at: number | null;
};

export type ActiveOperatorAssignmentMachine = {
  machineId: string;
  machineCode?: string;
  machineName?: string;
  lineCode?: string;
  shift?: string;
  assignedAt?: number;
};

export type ActiveOperatorAssignment = {
  id?: string;
  machine_id?: string;
  machine_code?: string;
  staff_id?: string;
  operator_id?: string;
  operator_name?: string;
  operatorName?: string;
  name?: string;
  employee_id?: string;
  role?: string;
  shift?: string;
  assigned_at?: number;
  machines?: ActiveOperatorAssignmentMachine[];
  totalMachines?: number;
  [key: string]: any;
};

export type MachineOperatorEntry = {
  id: string;
  machine_id: string;
  machine_code?: string;
  machine_name?: string;
  machine_status?: MachineStatus;
  machine_type?: string;
  line_id?: string;
  line_code?: string;
  line_name?: string;
  operator?: string;
  operator_name?: string;
  current_operator?: string | null;
  current_shift?: string | null;
  current_product?: string | null;
  shift?: string;
  good_quantity?: number;
  rejected_quantity?: number;
  total_produced?: number;
  total_rejected?: number;
  entry_timestamp?: number;
  order_number?: string;
  product_code?: string;
  product_name?: string;
  staff_id?: string;
  staff_name?: string;
  employee_id?: string;
  role?: string;
  assigned_at?: number;
  last_active_at?: number | null;
  status?: string;
  shift_assignments?: ShiftAssignmentInfo[];
  operators?: any[];
  [key: string]: any;
};

export type MachineOperatorSummary = {
  machine_id: string;
  machine_code: string;
  machine_name: string;
  machine_status: MachineStatus;
  machine_type?: string;
  line_id: string;
  line_code?: string;
  line_name?: string;
  current_operator?: string | null;
  current_shift?: string | null;
  current_product?: string | null;
  last_active_at?: number | null;
  total_produced: number;
  total_rejected: number;
  shift_assignments?: ShiftAssignmentInfo[];
  operators?: any[];
};

export type OperatorMachineSummary = {
  operator_name: string;
  machines: string[];
  total_produced: number;
  total_rejected: number;
  shifts: string[];
  entry_count: number;
  last_active_at: number;
  latest_machine: string;
  latest_order: string;
};

export type StaffRole = 'OPERATOR' | 'SUPERVISOR' | 'TECHNICIAN' | 'QUALITY_INSPECTOR' | 'MANAGER' | 'ADMIN' | string;
export type AttendanceStatus = 'PRESENT' | 'HALF_DAY' | 'LEAVE' | 'ABSENT';

export type StaffRow = {
  id: string;
  company_id?: string | null;
  employee_id: string;
  name: string;
  role: StaffRole;
  role_id?: string | null;
  phone?: string | null;
  skills?: string | null;
  shift?: string;
  login_pin?: string;
  is_active?: number | boolean;
  created_at: number;
  updated_at: number;
};

export type StaffAttendanceRow = {
  id: string;
  staff_id: string;
  staff_name?: string;
  employee_id?: string;
  role?: string;
  shift?: string;
  date: string;
  status: AttendanceStatus;
  check_in_time?: string | null;
  check_out_time?: string | null;
  overtime_hours?: number;
  notes?: string | null;
  created_at: number;
};

export type CompanyRow = {
  id: string;
  code?: string;
  company_code?: string;
  name: string;
  address?: string | null;
  contact_email?: string | null;
  admin_email?: string | null;
  admin_password?: string | null;
  contact_phone?: string | null;
  tax_id?: string | null;
  created_at: number;
  updated_at: number;
};

export type StockTransactionType = 'RECEIPT' | 'ISSUE' | 'ADJUSTMENT' | 'RETURN' | 'SCRAP' | string;

export type StockTransactionRow = {
  id: string;
  material_id: string;
  material_code?: string;
  material_name?: string;
  product_name?: string;
  transaction_type: StockTransactionType;
  quantity: number;
  balance_after: number;
  unit: string;
  reference_type?: string | null;
  reference_id?: string | null;
  notes?: string | null;
  created_at: number;
};

export type SupplierRow = {
  id: string;
  code?: string;
  name: string;
  contact_person?: string | null;
  phone?: string | null;
  email?: string | null;
  address?: string | null;
  supplied_items?: string | null;
  gst_number?: string | null;
  rating?: number | null;
  notes?: string | null;
  is_active?: number;
  company_id?: string | null;
  created_at: number;
  updated_at: number;
};

export type PurchaseOrderStatus = 'DRAFT' | 'ORDERED' | 'PARTIAL' | 'PARTIALLY_RECEIVED' | 'RECEIVED' | 'CANCELLED' | string;
export type PurchaseRequestStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'ORDERED';

export type PurchaseRequestRow = {
  id: string;
  request_number: string;
  material_id: string;
  material_code?: string;
  material_name?: string;
  material_unit?: string;
  quantity: number;
  required_by_date: number;
  linked_order_id?: string | null;
  order_number?: string | null;
  reason?: string | null;
  status: PurchaseRequestStatus;
  created_at: number;
  updated_at: number;
};

export type PurchaseOrderRow = {
  id: string;
  po_number: string;
  supplier_id: string;
  supplier_name?: string;
  supplier_code?: string;
  status: PurchaseOrderStatus;
  total_amount: number;
  order_date: number;
  expected_delivery_date?: number | null;
  terms?: string | null;
  notes?: string | null;
  created_at: number;
  updated_at: number;
};

export type PurchaseOrderItemRow = {
  id: string;
  po_id: string;
  material_id: string;
  material_code?: string;
  material_name?: string;
  unit?: string;
  quantity: number;
  unit_price: number;
  total_price: number;
  received_quantity: number;
  notes?: string | null;
  created_at: number;
  updated_at: number;
};

export type GrnReceiptRow = {
  id: string;
  grn_number: string;
  po_id: string;
  po_number?: string;
  supplier_id?: string | null;
  supplier_name?: string | null;
  invoice_number?: string | null;
  notes?: string | null;
  received_at: number;
  received_date?: number | null;
  created_at?: number | null;
  total_qty?: number;
  items_summary?: string;
  items?: Array<{
    material_id: string;
    material_code?: string;
    material_name?: string;
    unit?: string;
    quantity?: number;
    received_quantity: number;
  }>;
};
