/**
 * Formal MongoDB Collection Schemas for Manufacturing ERP
 * Each schema defines the collection structure, field types, required fields, and validations.
 */

export const MongoSchemas = {
  // 1. Companies & Organization
  companies: {
    bsonType: 'object',
    required: ['code', 'name'],
    properties: {
      id: { bsonType: 'string', description: 'Unique identifier' },
      code: { bsonType: 'string', description: 'Unique company short code' },
      name: { bsonType: 'string', description: 'Legal company name' },
      gst_number: { bsonType: ['string', 'null'] },
      phone: { bsonType: ['string', 'null'] },
      email: { bsonType: ['string', 'null'] },
      address: { bsonType: ['string', 'null'] },
      currency: { bsonType: 'string' },
      fiscal_year_start: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  company_roles: {
    bsonType: 'object',
    required: ['code', 'name'],
    properties: {
      id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      description: { bsonType: ['string', 'null'] },
      permissions: { bsonType: ['array', 'string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  // 2. Staff & Workforce
  staff: {
    bsonType: 'object',
    required: ['employee_id', 'name', 'phone'],
    properties: {
      id: { bsonType: 'string' },
      employee_id: { bsonType: 'string' },
      name: { bsonType: 'string' },
      phone: { bsonType: 'string' },
      email: { bsonType: ['string', 'null'] },
      role_id: { bsonType: ['string', 'null'] },
      department: { bsonType: ['string', 'null'] },
      shift: { enum: ['MORNING', 'EVENING', 'NIGHT', 'GENERAL'], bsonType: 'string' },
      hourly_rate: { bsonType: 'number' },
      status: { enum: ['ACTIVE', 'INACTIVE', 'ON_LEAVE'], bsonType: 'string' },
      joined_date: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  staff_attendance: {
    bsonType: 'object',
    required: ['staff_id', 'date', 'status'],
    properties: {
      id: { bsonType: 'string' },
      staff_id: { bsonType: 'string' },
      date: { bsonType: 'string', description: 'YYYY-MM-DD' },
      shift: { bsonType: 'string' },
      status: { enum: ['PRESENT', 'ABSENT', 'HALF_DAY', 'LEAVE'], bsonType: 'string' },
      check_in: { bsonType: ['number', 'null'] },
      check_out: { bsonType: ['number', 'null'] },
      overtime_hours: { bsonType: 'number' },
      notes: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  // 3. Plant, Lines & Machines
  factories: {
    bsonType: 'object',
    required: ['code', 'name'],
    properties: {
      id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      location: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
    },
  },

  production_lines: {
    bsonType: 'object',
    required: ['code', 'name', 'factory_id'],
    properties: {
      id: { bsonType: 'string' },
      factory_id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  machines: {
    bsonType: 'object',
    required: ['code', 'name', 'line_id', 'status'],
    properties: {
      id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      machine_type: { bsonType: ['string', 'null'] },
      line_id: { bsonType: 'string' },
      status: { enum: ['RUNNING', 'IDLE', 'BREAKDOWN', 'MAINTENANCE', 'OFFLINE', 'STOPPED'], bsonType: 'string' },
      current_product_id: { bsonType: ['string', 'null'] },
      efficiency: { bsonType: 'number' },
      runtime_seconds: { bsonType: 'number' },
      downtime_seconds: { bsonType: 'number' },
      last_maintenance_at: { bsonType: ['number', 'null'] },
      next_maintenance_at: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  machine_downtime: {
    bsonType: 'object',
    required: ['machine_id', 'start_time'],
    properties: {
      id: { bsonType: 'string' },
      machine_id: { bsonType: 'string' },
      reason: { bsonType: 'string' },
      start_time: { bsonType: 'number' },
      end_time: { bsonType: ['number', 'null'] },
      duration_minutes: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
    },
  },

  // 4. Inventory, Materials & BOM
  materials: {
    bsonType: 'object',
    required: ['code', 'name', 'unit', 'current_stock'],
    properties: {
      id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      category: { bsonType: 'string' },
      unit: { bsonType: 'string' },
      current_stock: { bsonType: 'number' },
      minimum_stock: { bsonType: 'number' },
      maximum_stock: { bsonType: 'number' },
      unit_cost: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  product_categories: {
    bsonType: 'object',
    required: ['code', 'name'],
    properties: {
      id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      created_at: { bsonType: 'number' },
    },
  },

  products: {
    bsonType: 'object',
    required: ['code', 'name', 'unit'],
    properties: {
      id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      category_id: { bsonType: ['string', 'null'] },
      unit: { bsonType: 'string' },
      description: { bsonType: ['string', 'null'] },
      standard_rate: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  bom: {
    bsonType: 'object',
    required: ['product_id', 'version'],
    properties: {
      id: { bsonType: 'string' },
      product_id: { bsonType: 'string' },
      version: { bsonType: 'string' },
      is_active: { bsonType: ['number', 'boolean', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  bom_items: {
    bsonType: 'object',
    required: ['bom_id', 'material_id', 'quantity'],
    properties: {
      id: { bsonType: 'string' },
      bom_id: { bsonType: 'string' },
      material_id: { bsonType: 'string' },
      quantity: { bsonType: 'number' },
      unit: { bsonType: 'string' },
    },
  },

  // 5. Production Planning & Orders
  production_plans: {
    bsonType: 'object',
    required: ['plan_number', 'product_id', 'target_quantity', 'line_id', 'status'],
    properties: {
      id: { bsonType: 'string' },
      plan_number: { bsonType: 'string' },
      product_id: { bsonType: 'string' },
      line_id: { bsonType: 'string' },
      target_quantity: { bsonType: 'number' },
      priority: { enum: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'], bsonType: 'string' },
      status: { enum: ['PLANNED', 'IN_PROGRESS', 'COMPLETED', 'DELAYED', 'CANCELLED'], bsonType: 'string' },
      start_date: { bsonType: ['number', 'null'] },
      expected_completion: { bsonType: ['number', 'null'] },
      notes: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  production_orders: {
    bsonType: 'object',
    required: ['order_number', 'product_id', 'line_id', 'target_quantity', 'status'],
    properties: {
      id: { bsonType: 'string' },
      order_number: { bsonType: 'string' },
      plan_id: { bsonType: ['string', 'null'] },
      product_id: { bsonType: 'string' },
      line_id: { bsonType: 'string' },
      machine_id: { bsonType: ['string', 'null'] },
      target_quantity: { bsonType: 'number' },
      produced_quantity: { bsonType: 'number' },
      rejected_quantity: { bsonType: 'number' },
      priority: { enum: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'], bsonType: 'string' },
      status: { enum: ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'DELAYED', 'CANCELLED'], bsonType: 'string' },
      start_date: { bsonType: ['number', 'null'] },
      due_date: { bsonType: ['number', 'null'] },
      started_at: { bsonType: ['number', 'null'] },
      completed_at: { bsonType: ['number', 'null'] },
      qc_status: { enum: ['PENDING', 'PASSED', 'FAILED', 'WAIVED', null], bsonType: ['string', 'null'] },
      qc_inspected_at: { bsonType: ['number', 'null'] },
      qc_inspector: { bsonType: ['string', 'null'] },
      qc_notes: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  production_entries: {
    bsonType: 'object',
    required: ['production_order_id', 'good_quantity'],
    properties: {
      id: { bsonType: 'string' },
      production_order_id: { bsonType: 'string' },
      machine_id: { bsonType: ['string', 'null'] },
      operator_id: { bsonType: ['string', 'null'] },
      good_quantity: { bsonType: 'number' },
      rejected_quantity: { bsonType: 'number' },
      scrap_quantity: { bsonType: ['number', 'null'] },
      rejection_reason: { bsonType: ['string', 'null'] },
      entry_timestamp: { bsonType: 'number' },
      created_at: { bsonType: 'number' },
    },
  },

  // 6. Quality & Inspections
  quality_inspections: {
    bsonType: 'object',
    required: ['inspection_number', 'production_order_id', 'status'],
    properties: {
      id: { bsonType: 'string' },
      inspection_number: { bsonType: 'string' },
      production_order_id: { bsonType: 'string' },
      inspector_id: { bsonType: ['string', 'null'] },
      quantity: { bsonType: 'number' },
      sample_size: { bsonType: ['number', 'null'] },
      rejected_quantity: { bsonType: 'number' },
      result: { enum: ['PASS', 'FAIL', 'REWORK', 'PARTIAL_PASS', null], bsonType: ['string', 'null'] },
      status: { enum: ['PENDING', 'COMPLETED', 'CANCELLED'], bsonType: 'string' },
      remarks: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  quality_results: {
    bsonType: 'object',
    required: ['inspection_id', 'parameter', 'result'],
    properties: {
      id: { bsonType: 'string' },
      inspection_id: { bsonType: 'string' },
      parameter: { bsonType: 'string' },
      expected_value: { bsonType: ['string', 'null'] },
      actual_value: { bsonType: ['string', 'null'] },
      result: { enum: ['PASS', 'FAIL'], bsonType: 'string' },
      remarks: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
    },
  },

  rework_orders: {
    bsonType: 'object',
    required: ['rework_number', 'inspection_id', 'quantity'],
    properties: {
      id: { bsonType: 'string' },
      rework_number: { bsonType: 'string' },
      inspection_id: { bsonType: 'string' },
      quantity: { bsonType: 'number' },
      status: { enum: ['PENDING', 'IN_PROGRESS', 'RESOLVED', 'SCRAPPED'], bsonType: 'string' },
      notes: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  // 7. Maintenance
  maintenance_orders: {
    bsonType: 'object',
    required: ['machine_id', 'order_type', 'status'],
    properties: {
      id: { bsonType: 'string' },
      machine_id: { bsonType: 'string' },
      order_type: { enum: ['PREVENTIVE', 'BREAKDOWN', 'CALIBRATION'], bsonType: 'string' },
      priority: { enum: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'], bsonType: 'string' },
      status: { enum: ['OPEN', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'], bsonType: 'string' },
      assigned_to: { bsonType: ['string', 'null'] },
      description: { bsonType: 'string' },
      scheduled_date: { bsonType: ['number', 'null'] },
      completed_at: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  maintenance_history: {
    bsonType: 'object',
    required: ['machine_id', 'performed_at', 'summary'],
    properties: {
      id: { bsonType: 'string' },
      machine_id: { bsonType: 'string' },
      maintenance_order_id: { bsonType: ['string', 'null'] },
      performed_at: { bsonType: 'number' },
      summary: { bsonType: 'string' },
      cost: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
    },
  },

  // 8. Finished Goods & Dispatch
  finished_goods: {
    bsonType: 'object',
    required: ['product_id', 'quantity'],
    properties: {
      id: { bsonType: 'string' },
      product_id: { bsonType: 'string' },
      production_order_id: { bsonType: ['string', 'null'] },
      batch_number: { bsonType: ['string', 'null'] },
      quantity: { bsonType: 'number' },
      location: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  dispatch_orders: {
    bsonType: 'object',
    required: ['dispatch_number', 'customer_name', 'product_id', 'quantity', 'status'],
    properties: {
      id: { bsonType: 'string' },
      dispatch_number: { bsonType: 'string' },
      customer_id: { bsonType: ['string', 'null'] },
      customer_name: { bsonType: 'string' },
      product_id: { bsonType: 'string' },
      quantity: { bsonType: 'number' },
      status: { enum: ['PENDING', 'DISPATCHED', 'DELIVERED', 'CANCELLED'], bsonType: 'string' },
      dispatched_at: { bsonType: ['number', 'null'] },
      notes: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  // 9. Procurement, Suppliers & Purchase
  suppliers: {
    bsonType: 'object',
    required: ['name'],
    properties: {
      id: { bsonType: 'string' },
      name: { bsonType: 'string' },
      contact_person: { bsonType: ['string', 'null'] },
      phone: { bsonType: ['string', 'null'] },
      email: { bsonType: ['string', 'null'] },
      address: { bsonType: ['string', 'null'] },
      gst_number: { bsonType: ['string', 'null'] },
      supplied_items: { bsonType: ['string', 'null'] },
      rating: { bsonType: ['number', 'null'] },
      notes: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  customers: {
    bsonType: 'object',
    required: ['name'],
    properties: {
      id: { bsonType: 'string' },
      name: { bsonType: 'string' },
      contact_person: { bsonType: ['string', 'null'] },
      phone: { bsonType: ['string', 'null'] },
      email: { bsonType: ['string', 'null'] },
      address: { bsonType: ['string', 'null'] },
      gst_number: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  purchase_requests: {
    bsonType: 'object',
    required: ['request_number', 'material_id', 'quantity', 'status'],
    properties: {
      id: { bsonType: 'string' },
      request_number: { bsonType: 'string' },
      material_id: { bsonType: 'string' },
      quantity: { bsonType: 'number' },
      required_by: { bsonType: ['number', 'null'] },
      requested_by: { bsonType: ['string', 'null'] },
      status: { enum: ['PENDING', 'APPROVED', 'REJECTED', 'ORDERED'], bsonType: 'string' },
      linked_order_id: { bsonType: ['string', 'null'] },
      reason: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  purchase_orders: {
    bsonType: 'object',
    required: ['po_number', 'supplier_id', 'status'],
    properties: {
      id: { bsonType: 'string' },
      po_number: { bsonType: 'string' },
      supplier_id: { bsonType: 'string' },
      status: { enum: ['ISSUED', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED'], bsonType: 'string' },
      expected_date: { bsonType: ['number', 'null'] },
      total_amount: { bsonType: 'number' },
      tax_amount: { bsonType: 'number' },
      terms: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  purchase_order_items: {
    bsonType: 'object',
    required: ['po_id', 'material_id', 'quantity', 'unit_rate'],
    properties: {
      id: { bsonType: 'string' },
      po_id: { bsonType: 'string' },
      material_id: { bsonType: 'string' },
      quantity: { bsonType: 'number' },
      unit_rate: { bsonType: 'number' },
      tax_pct: { bsonType: 'number' },
      received_quantity: { bsonType: 'number' },
      created_at: { bsonType: 'number' },
    },
  },

  grn_receipts: {
    bsonType: 'object',
    required: ['grn_number', 'received_date'],
    properties: {
      id: { bsonType: 'string' },
      grn_number: { bsonType: 'string' },
      po_id: { bsonType: ['string', 'null'] },
      supplier_id: { bsonType: ['string', 'null'] },
      received_date: { bsonType: 'number' },
      invoice_number: { bsonType: ['string', 'null'] },
      notes: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  stock_transactions: {
    bsonType: 'object',
    required: ['material_id', 'transaction_type', 'quantity'],
    properties: {
      id: { bsonType: 'string' },
      material_id: { bsonType: 'string' },
      transaction_type: { enum: ['IN', 'OUT', 'ADJUSTMENT', 'TRANSFER'], bsonType: 'string' },
      category: { bsonType: ['string', 'null'] },
      quantity: { bsonType: 'number' },
      reference_type: { bsonType: ['string', 'null'] },
      reference_id: { bsonType: ['string', 'null'] },
      notes: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
    },
  },

  // 10. Audit, History & Notifications
  activity_history: {
    bsonType: 'object',
    required: ['event_type', 'title'],
    properties: {
      id: { bsonType: 'string' },
      event_type: { bsonType: 'string' },
      title: { bsonType: 'string' },
      description: { bsonType: ['string', 'null'] },
      reference_type: { bsonType: ['string', 'null'] },
      reference_id: { bsonType: ['string', 'null'] },
      timestamp: { bsonType: 'number' },
      created_at: { bsonType: 'number' },
    },
  },

  notifications: {
    bsonType: 'object',
    required: ['title'],
    properties: {
      id: { bsonType: 'string' },
      title: { bsonType: 'string' },
      body: { bsonType: ['string', 'null'] },
      severity: { enum: ['INFO', 'WARNING', 'CRITICAL'], bsonType: 'string' },
      is_read: { bsonType: ['boolean', 'number'] },
      reference_type: { bsonType: ['string', 'null'] },
      reference_id: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
    },
  },
};
