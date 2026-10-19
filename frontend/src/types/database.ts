export type MachineStatus = 'RUNNING' | 'IDLE' | 'BREAKDOWN' | 'MAINTENANCE' | 'OFFLINE';
export type OrderStatus = 'PENDING' | 'IN_PROGRESS' | 'COMPLETED' | 'DELAYED' | 'CANCELLED';
export type PlanStatus = 'PLANNED' | 'IN_PROGRESS' | 'COMPLETED' | 'DELAYED' | 'CANCELLED';
export type Priority = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
export type InspectionResult = 'PASS' | 'FAIL' | 'REWORK' | 'PARTIAL_PASS';
export type NotificationSeverity = 'INFO' | 'WARNING' | 'CRITICAL';

export type MaterialRow = {
  id: string;
  code: string;
  name: string;
  category: string;
  unit: string;
  current_stock: number;
  minimum_stock: number;
  maximum_stock: number;
  updated_at: number;
};

export type ProductRow = {
  id: string;
  code: string;
  name: string;
  category_id: string | null;
  unit: string;
  description: string | null;
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
  efficiency: number;
  runtime_seconds: number;
  downtime_seconds: number;
  last_maintenance_at: number | null;
  next_maintenance_at: number | null;
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
  target_quantity: number;
  produced_quantity: number;
  rejected_quantity: number;
  priority: Priority;
  status: OrderStatus;
  start_date: number | null;
  due_date: number | null;
  started_at: number | null;
  completed_at: number | null;
  created_at: number;
  updated_at: number;
  qc_status?: 'PENDING' | 'PASSED' | 'FAILED' | 'WAIVED' | null;
  qc_inspected_at?: number | null;
  qc_inspector?: string | null;
  qc_notes?: string | null;
};

export type ActivityRow = {
  id: string;
  event_type: string;
  title: string;
  description: string | null;
  reference_type: string | null;
  reference_id: string | null;
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
  /** BOM qty per 1 finished unit */
  per_unit: number;
  /** Already consumed for units produced on this order (BOM × produced qty) */
  used_total: number;
  /** Still needed to finish remaining target on this order */
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
  product_id: string;
  product_code?: string;
  product_name?: string;
  quantity: number;
  status: string;
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
  rejection_reason?: string | null;
  rejection_action?: string | null;
  inspected_at: number;
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

export type CustomerRow = {
  id: string;
  name: string;
  company: string;
  phone?: string | null;
  email?: string | null;
  billing_address?: string | null;
  delivery_address?: string | null;
  gst_number?: string | null;
  notes?: string | null;
  created_at: number;
  updated_at: number;
};

export type SupplierRow = {
  id: string;
  name: string;
  contact_person?: string | null;
  phone?: string | null;
  email?: string | null;
  address?: string | null;
  gst_number?: string | null;
  supplied_items?: string | null;
  rating: number;
  notes?: string | null;
  created_at: number;
  updated_at: number;
};

export type StaffRole =
  | 'OPERATOR'
  | 'SUPERVISOR'
  | 'TECHNICIAN'
  | 'QUALITY_INSPECTOR'
  | 'MANAGER'
  | string;

export type CompanyRow = {
  id: string;
  company_code: string;
  name: string;
  admin_email: string;
  admin_password: string;
  created_at: number;
  updated_at: number;
};

export type StaffRow = {
  id: string;
  company_id?: string | null;
  role_id?: string | null;
  employee_id: string;
  name: string;
  role: StaffRole;
  phone?: string | null;
  skills?: string | null;
  shift: string;
  login_pin?: string;
  is_active: number;
  created_at: number;
  updated_at: number;
};

export type AttendanceStatus = 'PRESENT' | 'ABSENT' | 'LEAVE' | 'HALF_DAY';

export type StaffAttendanceRow = {
  id: string;
  staff_id: string;
  staff_name?: string;
  employee_id?: string;
  role?: string;
  date: string;
  shift: string;
  status: AttendanceStatus;
  overtime_hours: number;
  notes?: string | null;
  created_at: number;
};

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
};

export type PurchaseOrderStatus = 'DRAFT' | 'ISSUED' | 'PARTIALLY_RECEIVED' | 'RECEIVED' | 'CANCELLED';

export type PurchaseOrderRow = {
  id: string;
  po_number: string;
  supplier_id: string;
  supplier_name?: string;
  status: PurchaseOrderStatus;
  expected_date: number;
  total_amount: number;
  tax_amount: number;
  terms?: string | null;
  items_count?: number;
  created_at: number;
  updated_at: number;
};

export type PurchaseOrderItemRow = {
  id: string;
  po_id: string;
  material_id: string;
  material_code?: string;
  material_name?: string;
  material_unit?: string;
  quantity: number;
  unit_rate: number;
  tax_pct: number;
  received_quantity: number;
};

export type GrnItemDetail = {
  material_id: string;
  material_name: string;
  material_code?: string;
  quantity: number;
  unit?: string;
};

export type GrnReceiptRow = {
  id: string;
  grn_number: string;
  po_id?: string | null;
  po_number?: string | null;
  supplier_id: string;
  supplier_name?: string | null;
  received_date: number;
  invoice_number?: string | null;
  notes?: string | null;
  created_at: number;
  items_summary?: string;
  total_qty?: number;
  items?: GrnItemDetail[];
};

export type StockTransactionType = 'IN' | 'OUT' | 'ADJUSTMENT' | 'SCRAP';
export type StockCategory = 'RAW_MATERIAL' | 'WIP' | 'FINISHED_GOODS' | 'SCRAP';

export type StockTransactionRow = {
  id: string;
  material_id?: string | null;
  material_name?: string | null;
  product_id?: string | null;
  product_name?: string | null;
  transaction_type: StockTransactionType;
  category: StockCategory;
  quantity: number;
  batch_lot?: string | null;
  reference_type?: string | null;
  reference_id?: string | null;
  performed_by?: string | null;
  notes?: string | null;
  created_at: number;
};

export type ProductionEntryRow = {
  id: string;
  production_order_id: string;
  machine_id: string;
  shift: string;
  good_quantity: number;
  rejected_quantity: number;
  operator: string | null;
  notes: string | null;
  entry_timestamp: number;
};

export type MachineOperatorEntry = {
  id: string;
  machine_id: string;
  machine_code: string;
  machine_name: string;
  machine_status: MachineStatus;
  line_code: string;
  operator: string;
  shift: string;
  good_quantity: number;
  rejected_quantity: number;
  entry_timestamp: number;
  order_number: string;
  product_code: string;
  product_name: string;
};

export type ShiftAssignmentInfo = {
  shift: 'Morning' | 'Evening' | 'Night';
  operator: string | null;
  total_produced: number;
  last_active_at: number | null;
};

export type MachineOperatorSummary = {
  machine_id: string;
  machine_code: string;
  machine_name: string;
  machine_status: MachineStatus;
  machine_type?: string;
  line_id?: string;
  line_code: string;
  line_name?: string;
  current_operator: string | null;
  current_shift: string | null;
  current_product: string | null;
  last_active_at: number | null;
  total_produced: number;
  total_rejected: number;
  shift_assignments: ShiftAssignmentInfo[];
  operators: {
    name: string;
    shift: string;
    produced: number;
    rejected: number;
    last_seen: number;
    order_number: string;
  }[];
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

export type OperatorAssignedMachine = {
  machineId: string;
  machineCode: string;
  machineName: string;
  lineCode: string;
  shift: string;
  assignedAt: number;
};

export type ActiveOperatorAssignment = {
  operatorName: string;
  machines: OperatorAssignedMachine[];
  totalMachines: number;
};
