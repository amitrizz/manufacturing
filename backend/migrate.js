import { MongoClient } from 'mongodb';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const MONGODB_URI =
  process.env.DATABASE_URL ||
  'mongodb+srv://amit:amit@cluster0.tysk0hr.mongodb.net/manufacturing?retryWrites=true&w=majority&appName=Cluster0';

const DB_NAME = process.env.MONGODB_DB_NAME || 'manufacturing';

console.log('--------------------------------------------------');
console.log('🚀 Manufacturing Data Migration to MongoDB');
console.log(`📦 Target Database: ${DB_NAME}`);
console.log(`🌐 Target Cluster: cluster0.tysk0hr.mongodb.net`);
console.log('--------------------------------------------------');

export async function runMigration(existingDb = null) {
  let client = null;

  try {
    let db = existingDb;
    if (!db) {
      client = new MongoClient(MONGODB_URI);
      console.log('Connecting to MongoDB cluster...');
      await client.connect();
      console.log('✅ Connected successfully!');
      db = client.db(DB_NAME);
    }

    // Check if an exported JSON file from device exists
    const dumpPath = path.resolve(__dirname, '../local-db-dump.json');
    let importedData = null;

    if (fs.existsSync(dumpPath)) {
      console.log(`Found exported device database dump at: ${dumpPath}`);
      try {
        importedData = JSON.parse(fs.readFileSync(dumpPath, 'utf8'));
        console.log('Loaded device database dump successfully.');
      } catch (err) {
        console.warn('Could not parse local-db-dump.json, will use default manufacturing seed.', err);
      }
    }

    const now = Date.now();

    // 1. Companies
    const companies = importedData?.companies || [
      {
        _id: 'comp-apex-01',
        id: 'comp-apex-01',
        company_code: 'APEX01',
        name: 'Apex Manufacturing Ltd',
        admin_email: 'admin@apex.com',
        admin_password: 'admin123',
        created_at: now,
        updated_at: now,
      },
    ];

    // 2. Company Roles
    const companyRoles = importedData?.company_roles || [
      {
        _id: 'role-mgr-01',
        id: 'role-mgr-01',
        company_id: 'comp-apex-01',
        name: 'MANAGER',
        description: 'Plant operations manager with full access',
        permissions: [
          'home_kpis', 'home_production', 'home_machines', 'home_quality', 'home_inventory', 'home_dispatch', 'home_recent_orders',
          'tasks_production', 'tasks_qc', 'tasks_maintenance', 'tasks_dispatch',
          'manage_staff', 'manage_machines', 'manage_materials', 'manage_orders', 'manage_reports', 'manage_roles',
        ],
        created_at: now,
      },
      {
        _id: 'role-sup-01',
        id: 'role-sup-01',
        company_id: 'comp-apex-01',
        name: 'SUPERVISOR',
        description: 'Shift supervisor overseeing lines and production runs',
        permissions: [
          'home_kpis', 'home_production', 'home_machines', 'home_quality', 'home_recent_orders',
          'tasks_production', 'tasks_qc', 'tasks_maintenance',
          'manage_staff', 'manage_orders',
        ],
        created_at: now,
      },
      {
        _id: 'role-op-01',
        id: 'role-op-01',
        company_id: 'comp-apex-01',
        name: 'OPERATOR',
        description: 'Machine & assembly operator recording shifts',
        permissions: [
          'home_production', 'home_machines',
          'tasks_production',
        ],
        created_at: now,
      },
      {
        _id: 'role-qc-01',
        id: 'role-qc-01',
        company_id: 'comp-apex-01',
        name: 'QUALITY_INSPECTOR',
        description: 'Quality assurance and inspection officer',
        permissions: [
          'home_production', 'home_quality',
          'tasks_qc',
          'manage_reports',
        ],
        created_at: now,
      },
      {
        _id: 'role-tech-01',
        id: 'role-tech-01',
        company_id: 'comp-apex-01',
        name: 'TECHNICIAN',
        description: 'Maintenance technician for machine breakdowns and PM',
        permissions: [
          'home_machines',
          'tasks_maintenance',
          'manage_machines',
        ],
        created_at: now,
      },
    ];

    // 3. Staff
    const staff = importedData?.staff || [
      {
        _id: 'staff-01',
        id: 'staff-01',
        company_id: 'comp-apex-01',
        employee_id: 'EMP-001',
        name: 'Vikram Sharma',
        role: 'OPERATOR',
        role_id: 'role-op-01',
        phone: '+91 98201 11223',
        skills: 'CNC Lathe, Milling, Safety Certified',
        shift: 'Morning',
        login_pin: '1234',
        is_active: 1,
        created_at: now,
        updated_at: now,
      },
      {
        _id: 'staff-02',
        id: 'staff-02',
        company_id: 'comp-apex-01',
        employee_id: 'EMP-002',
        name: 'Pooja Verma',
        role: 'SUPERVISOR',
        role_id: 'role-sup-01',
        phone: '+91 98450 33445',
        skills: 'Line Management, Production Planning, 5S',
        shift: 'Morning',
        login_pin: '1234',
        is_active: 1,
        created_at: now,
        updated_at: now,
      },
      {
        _id: 'staff-03',
        id: 'staff-03',
        company_id: 'comp-apex-01',
        employee_id: 'EMP-003',
        name: 'Arjun Kulkarni',
        role: 'TECHNICIAN',
        role_id: 'role-tech-01',
        phone: '+91 97110 55667',
        skills: 'Hydraulics, Electrical Diagnostics, Motor Overhauls',
        shift: 'Evening',
        login_pin: '1234',
        is_active: 1,
        created_at: now,
        updated_at: now,
      },
      {
        _id: 'staff-04',
        id: 'staff-04',
        company_id: 'comp-apex-01',
        employee_id: 'EMP-004',
        name: 'Sneha Patel',
        role: 'QUALITY_INSPECTOR',
        role_id: 'role-qc-01',
        phone: '+91 99302 77889',
        skills: 'CMM, Vernier Caliper, ISO 9001 Compliance',
        shift: 'Morning',
        login_pin: '1234',
        is_active: 1,
        created_at: now,
        updated_at: now,
      },
      {
        _id: 'staff-05',
        id: 'staff-05',
        company_id: 'comp-apex-01',
        employee_id: 'EMP-005',
        name: 'Rahul Deshmukh',
        role: 'OPERATOR',
        role_id: 'role-op-01',
        phone: '+91 98199 99001',
        skills: 'Press Stamping, Sheet Metal Form',
        shift: 'Night',
        login_pin: '1234',
        is_active: 1,
        created_at: now,
        updated_at: now,
      },
    ];

    // 4. Staff Attendance
    const todayStr = new Date().toISOString().slice(0, 10);
    const staffAttendance = importedData?.staff_attendance || [
      {
        _id: `att-staff-01-${todayStr}`,
        id: `att-staff-01-${todayStr}`,
        staff_id: 'staff-01',
        date: todayStr,
        shift: 'Morning',
        status: 'PRESENT',
        overtime_hours: 1.5,
        notes: 'Clocked in on time for Machining Line A',
        created_at: now - 3600000 * 4,
      },
      {
        _id: `att-staff-02-${todayStr}`,
        id: `att-staff-02-${todayStr}`,
        staff_id: 'staff-02',
        date: todayStr,
        shift: 'Morning',
        status: 'PRESENT',
        overtime_hours: 0,
        notes: 'Floor supervisor shift start',
        created_at: now - 3600000 * 4.2,
      },
      {
        _id: `att-staff-03-${todayStr}`,
        id: `att-staff-03-${todayStr}`,
        staff_id: 'staff-03',
        date: todayStr,
        shift: 'Evening',
        status: 'PRESENT',
        overtime_hours: 2,
        notes: 'Covered hydraulic press maintenance overhaul',
        created_at: now - 3600000 * 2,
      },
      {
        _id: `att-staff-04-${todayStr}`,
        id: `att-staff-04-${todayStr}`,
        staff_id: 'staff-04',
        date: todayStr,
        shift: 'Morning',
        status: 'PRESENT',
        overtime_hours: 0,
        notes: 'Passed 4 batch inspections',
        created_at: now - 3600000 * 3.8,
      },
    ];

    // 5. Factories & Lines
    const factories = importedData?.factories || [
      {
        _id: 'fac-01',
        id: 'fac-01',
        name: 'Apex Manufacturing Plant',
        code: 'AMP-01',
        location: 'MIDC Industrial Area, Pune, IN',
      },
    ];

    const productionLines = importedData?.production_lines || [
      { _id: 'line-01', id: 'line-01', factory_id: 'fac-01', code: 'LINE-A', name: 'Machining Line A' },
      { _id: 'line-02', id: 'line-02', factory_id: 'fac-01', code: 'LINE-B', name: 'Assembly Line B' },
      { _id: 'line-03', id: 'line-03', factory_id: 'fac-01', code: 'LINE-C', name: 'Press & Form Line C' },
      { _id: 'line-04', id: 'line-04', factory_id: 'fac-01', code: 'LINE-D', name: 'Finish & Test Line D' },
    ];

    // 6. Machines
    const machines = importedData?.machines || [
      {
        _id: 'mach-01',
        id: 'mach-01',
        code: 'CNC-01',
        name: 'Haas CNC Lathe 01',
        type: 'Lathe',
        line_id: 'line-01',
        status: 'RUNNING',
        runtime_seconds: 142000,
        downtime_seconds: 4800,
        created_at: now,
      },
      {
        _id: 'mach-02',
        id: 'mach-02',
        code: 'MILL-01',
        name: 'Mazak 3-Axis Mill',
        type: 'Milling',
        line_id: 'line-01',
        status: 'RUNNING',
        runtime_seconds: 128000,
        downtime_seconds: 3200,
        created_at: now,
      },
      {
        _id: 'mach-03',
        id: 'mach-03',
        code: 'PRESS-01',
        name: 'Schuler 200T Hydraulic Press',
        type: 'Stamping Press',
        line_id: 'line-03',
        status: 'IDLE',
        runtime_seconds: 98000,
        downtime_seconds: 6400,
        created_at: now,
      },
      {
        _id: 'mach-04',
        id: 'mach-04',
        code: 'TEST-01',
        name: 'Hydrostatic Pressure Test Rig',
        type: 'Testing Rig',
        line_id: 'line-04',
        status: 'RUNNING',
        runtime_seconds: 110000,
        downtime_seconds: 1800,
        created_at: now,
      },
    ];

    // 7. Materials & Products
    const materials = importedData?.materials || [
      { _id: 'mat-01', id: 'mat-01', code: 'RM-STL-01', name: 'Stainless Steel Rod 316L', unit: 'kg', stock_quantity: 850, min_stock_level: 200, unit_cost: 320 },
      { _id: 'mat-02', id: 'mat-02', code: 'RM-ALU-02', name: 'Aluminum Billet 6061-T6', unit: 'kg', stock_quantity: 620, min_stock_level: 150, unit_cost: 240 },
      { _id: 'mat-03', id: 'mat-03', code: 'COMP-SEAL-01', name: 'High Temp Viton O-Ring Seal', unit: 'pcs', stock_quantity: 1400, min_stock_level: 300, unit_cost: 18 },
      { _id: 'mat-04', id: 'mat-04', code: 'COMP-BRG-01', name: 'SKF Precision Deep Groove Bearing', unit: 'pcs', stock_quantity: 450, min_stock_level: 100, unit_cost: 160 },
      { _id: 'mat-05', id: 'mat-05', code: 'FAST-M8-01', name: 'M8 Hex Head Fasteners (Grade 8.8)', unit: 'pcs', stock_quantity: 3200, min_stock_level: 800, unit_cost: 4.5 },
    ];

    const products = importedData?.products || [
      {
        _id: 'prod-01',
        id: 'prod-01',
        code: 'PRD-VLV-01',
        name: 'Industrial High-Pressure Gate Valve',
        category: 'Valves & Actuators',
        unit: 'pcs',
        standard_cost: 1850,
        sale_price: 3400,
        created_at: now,
      },
      {
        _id: 'prod-02',
        id: 'prod-02',
        code: 'PRD-PMP-01',
        name: 'Rotary Hydraulic Gear Pump 120cc',
        category: 'Hydraulics',
        unit: 'pcs',
        standard_cost: 4200,
        sale_price: 7800,
        created_at: now,
      },
      {
        _id: 'prod-03',
        id: 'prod-03',
        code: 'PRD-FLG-01',
        name: 'Precision Forged Carbon Steel Flange DN50',
        category: 'Piping & Flanges',
        unit: 'pcs',
        standard_cost: 650,
        sale_price: 1250,
        created_at: now,
      },
    ];

    // 8. Customers & Suppliers
    const customers = importedData?.customers || [
      {
        _id: 'cust-01',
        id: 'cust-01',
        name: 'Rajesh Sharma',
        company: 'Apex Engineering Ltd',
        phone: '+91 98201 44521',
        email: 'rajesh@apexeng.in',
        billing_address: 'Plot 42, MIDC Industrial Area, Pune',
        delivery_address: 'Warehouse 3, Chakan Plant, Pune',
        gst_number: '27AABCA1234F1Z1',
        notes: 'Tier-1 client for valve assemblies',
        created_at: now,
      },
      {
        _id: 'cust-02',
        id: 'cust-02',
        name: 'Vikram Mehta',
        company: 'Mehta Dynamics Pvt Ltd',
        phone: '+91 98450 11982',
        email: 'procurement@mehtadynamics.com',
        billing_address: '102 Industrial Suburb, Peenya, Bengaluru',
        delivery_address: '102 Industrial Suburb, Peenya, Bengaluru',
        gst_number: '29AABCM5678G1Z4',
        notes: 'Regular monthly order',
        created_at: now,
      },
    ];

    const suppliers = importedData?.suppliers || [
      {
        _id: 'sup-01',
        id: 'sup-01',
        name: 'Kalyani Steels Ltd',
        contact_person: 'Anil Kalyani',
        phone: '+91 98110 22334',
        email: 'sales@kalyanisteels.com',
        address: 'Mundhwa, Pune, MH',
        gst_number: '27AAACK1122D1Z9',
        rating: 4.8,
        notes: 'Primary steel supplier with mill certificates',
        created_at: now,
      },
      {
        _id: 'sup-02',
        id: 'sup-02',
        name: 'Hindalco Industries',
        contact_person: 'Gaurav Singhal',
        phone: '+91 98220 33445',
        email: 'orders@hindalco.adityabirla.com',
        address: 'Bandra Kurla Complex, Mumbai',
        gst_number: '27AAACH3344E1Z2',
        rating: 4.6,
        notes: 'Aluminum billets supplier',
        created_at: now,
      },
    ];

    // 9. Production Orders & Finished Goods
    const productionOrders = importedData?.production_orders || [
      {
        _id: 'po-01',
        id: 'po-01',
        order_number: 'ORD-2026-001',
        product_id: 'prod-01',
        line_id: 'line-01',
        target_quantity: 120,
        produced_quantity: 110,
        rejected_quantity: 3,
        status: 'IN_PROGRESS',
        priority: 'HIGH',
        start_date: now - 86400000 * 2,
        due_date: now + 86400000 * 3,
        created_at: now - 86400000 * 2,
      },
      {
        _id: 'po-02',
        id: 'po-02',
        order_number: 'ORD-2026-002',
        product_id: 'prod-02',
        line_id: 'line-02',
        target_quantity: 60,
        produced_quantity: 60,
        rejected_quantity: 1,
        status: 'COMPLETED',
        priority: 'MEDIUM',
        start_date: now - 86400000 * 5,
        due_date: now - 86400000,
        created_at: now - 86400000 * 5,
      },
    ];

    const finishedGoods = importedData?.finished_goods || [
      {
        _id: 'fg-01',
        id: 'fg-01',
        product_id: 'prod-01',
        produced_quantity: 110,
        quality_passed_quantity: 107,
        rejected_quantity: 3,
        rework_quantity: 2,
        available_quantity: 85,
        updated_at: now,
      },
      {
        _id: 'fg-02',
        id: 'fg-02',
        product_id: 'prod-02',
        produced_quantity: 60,
        quality_passed_quantity: 59,
        rejected_quantity: 1,
        rework_quantity: 1,
        available_quantity: 50,
        updated_at: now,
      },
    ];

    // 10. Purchase Orders, Items, GRN & Stock Transactions
    const purchaseOrders = importedData?.purchase_orders || [
      {
        _id: 'po-mat-01',
        id: 'po-mat-01',
        po_number: 'PO-2026-101',
        supplier_id: 'sup-01',
        status: 'RECEIVED',
        expected_date: now - 86400000,
        total_amount: 145000,
        tax_amount: 26100,
        terms: '30 Days Net, factory delivery',
        created_at: now - 86400000 * 7,
        updated_at: now - 86400000,
      },
      {
        _id: 'po-mat-02',
        id: 'po-mat-02',
        po_number: 'PO-2026-102',
        supplier_id: 'sup-02',
        status: 'ISSUED',
        expected_date: now + 86400000 * 4,
        total_amount: 95000,
        tax_amount: 17100,
        terms: 'Advance 50%, balance on delivery',
        created_at: now - 86400000,
        updated_at: now,
      },
    ];

    const purchaseOrderItems = importedData?.purchase_order_items || [
      {
        _id: 'poi-01',
        id: 'poi-01',
        po_id: 'po-mat-01',
        material_id: 'mat-01',
        quantity: 1000,
        unit_rate: 145,
        tax_pct: 18,
        received_quantity: 1000,
      },
      {
        _id: 'poi-02',
        id: 'poi-02',
        po_id: 'po-mat-02',
        material_id: 'mat-02',
        quantity: 500,
        unit_rate: 190,
        tax_pct: 18,
        received_quantity: 0,
      },
    ];

    const purchaseRequests = importedData?.purchase_requests || [
      {
        _id: 'pr-01',
        id: 'pr-01',
        request_number: 'PR-2026-001',
        material_id: 'mat-02',
        quantity: 500,
        required_by_date: now + 86400000 * 5,
        reason: 'Low stock safety reorder',
        status: 'APPROVED',
        created_at: now - 86400000 * 2,
      },
    ];

    const grnReceipts = importedData?.grn_receipts || [
      {
        _id: 'grn-01',
        id: 'grn-01',
        grn_number: 'GRN-0001',
        po_id: 'po-mat-01',
        supplier_id: 'sup-01',
        received_date: now - 86400000,
        invoice_number: 'INV-KALYANI-9812',
        notes: 'Mill test certificates verified, stored in Rack A-01',
        created_at: now - 86400000,
      },
    ];

    const stockTransactions = importedData?.stock_transactions || [
      {
        _id: 'st-01',
        id: 'st-01',
        material_id: 'mat-01',
        product_id: null,
        transaction_type: 'IN',
        category: 'RAW_MATERIAL',
        quantity: 1000,
        batch_lot: 'LOT-2026-S12',
        reference_type: 'GRN',
        reference_id: 'grn-01',
        performed_by: 'EMP-001',
        notes: 'Received via GRN-0001',
        created_at: now - 86400000,
      },
      {
        _id: 'st-02',
        id: 'st-02',
        material_id: 'mat-01',
        product_id: null,
        transaction_type: 'OUT',
        category: 'RAW_MATERIAL',
        quantity: 150,
        batch_lot: 'LOT-2026-S12',
        reference_type: 'PRODUCTION_ORDER',
        reference_id: 'po-01',
        performed_by: 'EMP-001',
        notes: 'Issued to Line 1 for ORD-2026-001',
        created_at: now - 86400000 / 2,
      },
    ];

    // 11. Quality Inspections & Results
    const qualityInspections = importedData?.quality_inspections || [
      {
        _id: 'qi-01',
        id: 'qi-01',
        batch_number: 'BATCH-2026-001',
        production_order_id: 'po-01',
        product_id: 'prod-01',
        quantity: 110,
        inspector: 'Sneha Nair',
        overall_result: 'PASS',
        rejected_quantity: 3,
        rejection_reason: 'Minor thread pitch deviation',
        rejection_action: 'REWORK',
        inspected_at: now - 86400000,
      },
    ];

    const qualityResults = importedData?.quality_results || [
      {
        _id: 'qr-01',
        id: 'qr-01',
        inspection_id: 'qi-01',
        parameter_name: 'Outer Diameter',
        parameter_type: 'DIMENSION',
        expected_value: '25.00 mm ± 0.05',
        actual_value: '25.02 mm',
        result: 'PASS',
        notes: 'Within tolerance range',
      },
    ];

    const reworkOrders = importedData?.rework_orders || [
      {
        _id: 'ro-01',
        id: 'ro-01',
        rework_number: 'RW-2026-001',
        product_id: 'prod-01',
        quantity: 2,
        reason: 'Thread deburring needed',
        status: 'PENDING',
        created_at: now - 86400000,
      },
    ];

    // 12. Maintenance Orders & History
    const maintenanceOrders = importedData?.maintenance_orders || [
      {
        _id: 'mo-01',
        id: 'mo-01',
        machine_id: 'mach-01',
        maintenance_type: 'PREVENTIVE',
        priority: 'MEDIUM',
        status: 'COMPLETED',
        title: 'Monthly lubrication and spindle alignment',
        description: 'Complete oil filter change and runout check',
        scheduled_date: now - 86400000 * 5,
        created_at: now - 86400000 * 10,
        updated_at: now - 86400000 * 5,
      },
    ];

    const maintenanceHistory = importedData?.maintenance_history || [
      {
        _id: 'mh-01',
        id: 'mh-01',
        machine_id: 'mach-01',
        maintenance_type: 'PREVENTIVE',
        technician_name: 'Deepak Patil',
        findings: 'Spindle lubrication topped up, runout checked < 0.008mm',
        completed_at: now - 86400000 * 5,
      },
    ];

    const machineDowntime = importedData?.machine_downtime || [
      {
        _id: 'md-01',
        id: 'md-01',
        machine_id: 'mach-02',
        start_time: now - 86400000 * 2,
        end_time: now - 86400000 * 2 + 1800000,
        duration_minutes: 30,
        reason: 'Tool wear replacement',
        recorded_by: 'EMP-001',
      },
    ];

    // 13. Product Categories, BOM, Production Plans & Entries
    const productCategories = importedData?.product_categories || [
      {
        _id: 'cat-01',
        id: 'cat-01',
        name: 'Precision Turned Components',
        description: 'CNC turned hydraulic valves, pins, and bushings',
        created_at: now,
      },
    ];

    const bomList = importedData?.bom || [
      {
        _id: 'bom-01',
        id: 'bom-01',
        product_id: 'prod-01',
        version: '1.0',
        is_active: 1,
        created_at: now,
      },
    ];

    const bomItems = importedData?.bom_items || [
      {
        _id: 'bomi-01',
        id: 'bomi-01',
        bom_id: 'bom-01',
        material_id: 'mat-01',
        quantity_required: 1.25,
        unit: 'kg',
      },
    ];

    const productionPlans = importedData?.production_plans || [
      {
        _id: 'plan-01',
        id: 'plan-01',
        plan_number: 'PLN-2026-W42',
        line_id: 'line-01',
        start_date: now - 86400000 * 7,
        end_date: now + 86400000 * 7,
        status: 'IN_PROGRESS',
        notes: 'Target weekly dispatch batch',
        created_at: now - 86400000 * 7,
      },
    ];

    const productionEntries = importedData?.production_entries || [
      {
        _id: 'pe-01',
        id: 'pe-01',
        production_order_id: 'po-01',
        machine_id: 'mach-01',
        operator_id: 'staff-01',
        shift: 'Morning',
        quantity_produced: 55,
        scrap_quantity: 1,
        created_at: now - 86400000,
      },
    ];

    // 14. Dispatch, Activities & Notifications
    const dispatchOrders = importedData?.dispatch_orders || [
      {
        _id: 'disp-01',
        id: 'disp-01',
        dispatch_number: 'DSP-2026-001',
        customer_id: 'cust-01',
        product_id: 'prod-01',
        quantity: 85,
        status: 'DISPATCHED',
        transporter: 'V-Trans Express',
        vehicle_number: 'MH-12-PQ-9912',
        tracking_number: 'TRK-981120',
        dispatch_date: now - 86400000,
        created_at: now - 86400000,
      },
    ];

    const activityHistory = importedData?.activity_history || [
      {
        _id: 'act-01',
        id: 'act-01',
        event_type: 'GRN_RECEIVED',
        title: 'GRN-0001 processed',
        description: 'Stock updated from PO receipt',
        reference_type: 'GRN',
        reference_id: 'grn-01',
        created_at: now - 86400000,
      },
    ];

    const notifications = importedData?.notifications || [
      {
        _id: 'notif-01',
        id: 'notif-01',
        title: 'Goods Inward Received',
        message: 'GRN-0001 inwarded 1,000 kg steel rod into raw material inventory.',
        type: 'SUCCESS',
        is_read: 0,
        created_at: now - 86400000,
      },
    ];

    const ALL_TABLE_DEFAULTS = {
      companies: { data: companies, key: 'company_code' },
      company_roles: { data: companyRoles, key: 'id' },
      staff: { data: staff, key: 'employee_id' },
      staff_attendance: { data: staffAttendance, key: 'id' },
      factories: { data: factories, key: 'code' },
      production_lines: { data: productionLines, key: 'code' },
      machines: { data: machines, key: 'code' },
      machine_downtime: { data: machineDowntime, key: 'id' },
      materials: { data: materials, key: 'code' },
      product_categories: { data: productCategories, key: 'id' },
      products: { data: products, key: 'code' },
      bom: { data: bomList, key: 'id' },
      bom_items: { data: bomItems, key: 'id' },
      production_plans: { data: productionPlans, key: 'plan_number' },
      production_orders: { data: productionOrders, key: 'order_number' },
      production_entries: { data: productionEntries, key: 'id' },
      quality_inspections: { data: qualityInspections, key: 'batch_number' },
      quality_results: { data: qualityResults, key: 'id' },
      rework_orders: { data: reworkOrders, key: 'rework_number' },
      maintenance_orders: { data: maintenanceOrders, key: 'id' },
      maintenance_history: { data: maintenanceHistory, key: 'id' },
      finished_goods: { data: finishedGoods, key: 'id' },
      dispatch_orders: { data: dispatchOrders, key: 'dispatch_number' },
      suppliers: { data: suppliers, key: 'id' },
      customers: { data: customers, key: 'id' },
      purchase_requests: { data: purchaseRequests, key: 'request_number' },
      purchase_orders: { data: purchaseOrders, key: 'po_number' },
      purchase_order_items: { data: purchaseOrderItems, key: 'id' },
      grn_receipts: { data: grnReceipts, key: 'grn_number' },
      stock_transactions: { data: stockTransactions, key: 'id' },
      activity_history: { data: activityHistory, key: 'id' },
      notifications: { data: notifications, key: 'id' },
    };

    console.log('\n--- Migrating Collections to MongoDB Atlas ---');

    for (const [collectionName, config] of Object.entries(ALL_TABLE_DEFAULTS)) {
      const col = db.collection(collectionName);
      const dataset = (importedData && importedData[collectionName]?.length > 0)
        ? importedData[collectionName]
        : config.data;

      const count = dataset.length;
      const key = config.key;

      for (const rawDoc of dataset) {
        const doc = { ...rawDoc };
        if (!doc._id) {
          doc._id = doc.id || doc[key] || `id-${Date.now()}-${Math.random().toString(36).substr(2, 6)}`;
        }
        const filter = doc[key] ? { [key]: doc[key] } : { _id: doc._id };
        await col.replaceOne(filter, doc, { upsert: true });
      }

      console.log(`✅ Collection '${collectionName}': Migrated ${count} records.`);
    }

    // Set up unique indexes
    console.log('\n--- Creating Indexes ---');
    try {
      await db.collection('companies').createIndex({ company_code: 1 }, { unique: true });
      await db.collection('staff').createIndex({ employee_id: 1, company_id: 1 }, { unique: true });
      await db.collection('staff_attendance').createIndex({ staff_id: 1, date: 1, shift: 1 });
      await db.collection('products').createIndex({ code: 1 }, { unique: true });
      await db.collection('materials').createIndex({ code: 1 }, { unique: true });
      await db.collection('machines').createIndex({ code: 1 }, { unique: true });
      await db.collection('production_orders').createIndex({ order_number: 1 }, { unique: true });
      await db.collection('purchase_orders').createIndex({ po_number: 1 }, { unique: true });
      await db.collection('grn_receipts').createIndex({ grn_number: 1 }, { unique: true });
      await db.collection('purchase_requests').createIndex({ request_number: 1 }, { unique: true });
      await db.collection('stock_transactions').createIndex({ reference_type: 1, reference_id: 1 });
      console.log('✅ Unique indexes created.');
    } catch (idxErr) {
      console.warn('Index creation warning:', idxErr.message);
    }

    const summary = await db.listCollections().toArray();
    console.log('\n--------------------------------------------------');
    console.log('🎉 Migration to MongoDB Completed Successfully!');
    console.log(`Database: ${DB_NAME}`);
    console.log(`Total Collections: ${summary.length}`);
    console.log('Collections list:', summary.map((c) => c.name).join(', '));
    return { success: true, count: summary.length };
  } catch (err) {
    console.error('❌ Migration failed:', err);
    throw err;
  } finally {
    if (client) {
      await client.close();
      console.log('Connection closed.');
    }
  }
}

// Run directly if invoked from CLI
if (process.argv[1] && process.argv[1].endsWith('migrate.js')) {
  runMigration().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
