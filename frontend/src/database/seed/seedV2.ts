import { newId } from '../../utils/id';
import type { SeedContext } from './seedContext';

export async function seedV2(ctx: SeedContext): Promise<void> {
  const { db, now } = ctx;

  // 1. Seed Customers
  const customers = [
    {
      name: 'Rajesh Sharma',
      company: 'Apex Engineering Ltd',
      phone: '+91 98201 44521',
      email: 'rajesh@apexeng.in',
      billing_address: 'Plot 42, MIDC Industrial Area, Pune',
      delivery_address: 'Warehouse 3, Chakan Plant, Pune',
      gst_number: '27AABCA1234F1Z1',
      notes: 'Key tier-1 client for valve assemblies',
    },
    {
      name: 'Vikram Mehta',
      company: 'Mehta Dynamics Pvt Ltd',
      phone: '+91 98450 11982',
      email: 'procurement@mehtadynamics.com',
      billing_address: '102 Industrial Suburb, Peenya, Bengaluru',
      delivery_address: '102 Industrial Suburb, Peenya, Bengaluru',
      gst_number: '29AABCM5678G1Z4',
      notes: 'Regular orders on 15th of each month',
    },
    {
      name: 'Sunita Rao',
      company: 'Precision Hydraulics Corp',
      phone: '+91 97110 88234',
      email: 's.rao@precisionhydraulics.com',
      billing_address: 'Sector 25, Faridabad, Haryana',
      delivery_address: 'Plant 2, Manesar, Haryana',
      gst_number: '06AABCP9012H1Z7',
      notes: 'Strict QA tolerances required',
    },
  ];

  for (const c of customers) {
    const id = newId();
    await db.runAsync(
      `INSERT INTO customers (
        id, name, company, phone, email, billing_address, delivery_address, gst_number, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      id,
      c.name,
      c.company,
      c.phone,
      c.email,
      c.billing_address,
      c.delivery_address,
      c.gst_number,
      c.notes,
      now,
      now,
    );
  }

  // 2. Seed Suppliers
  const suppliers = [
    {
      name: 'Tata Steel Special Plates',
      contact: 'Anil Deshmukh',
      phone: '+91 98220 33441',
      email: 'sales@tatasteel-plates.com',
      address: 'Jamshedpur Works, Jharkhand',
      gst: '20AABCT1907A1ZQ',
      items: 'Carbon Steel Bars, Forgings, Cast Iron',
      rating: 4.8,
    },
    {
      name: 'Parker Hannifin Seals & O-Rings',
      contact: 'Girish Kulkarni',
      phone: '+91 98901 77665',
      email: 'girish@parker-distributors.in',
      address: 'Navi Mumbai, Maharashtra',
      gst: '27AABCP4432K1ZP',
      items: 'PTFE Seal Rings, NBR Rubber, O-Rings',
      rating: 4.6,
    },
    {
      name: 'SKF Bearings India',
      contact: 'Ramesh Iyer',
      phone: '+91 98400 99881',
      email: 'orders@skfindia.com',
      address: 'Bommasandra Industrial Area, Bengaluru',
      gst: '29AABCS8876L1ZM',
      items: 'Bearing 6205, Spindles, Bushings',
      rating: 4.9,
    },
  ];

  const supplierIds: string[] = [];
  for (const s of suppliers) {
    const id = newId();
    supplierIds.push(id);
    await db.runAsync(
      `INSERT INTO suppliers (
        id, name, contact_person, phone, email, address, gst_number, supplied_items, rating, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      id,
      s.name,
      s.contact,
      s.phone,
      s.email,
      s.address,
      s.gst,
      s.items,
      s.rating,
      'Approved vendor list',
      now,
      now,
    );
  }

  // 3. Seed Staff
  const staffMembers = [
    { empId: 'EMP-001', name: 'Arun Kumar', role: 'OPERATOR', phone: '+91 98111 22331', shift: 'Morning', skills: 'CNC Lathe, Milling' },
    { empId: 'EMP-002', name: 'Ramesh Verma', role: 'OPERATOR', phone: '+91 98111 22332', shift: 'Morning', skills: 'Assembly, Drilling' },
    { empId: 'EMP-003', name: 'Kavita Joshi', role: 'SUPERVISOR', phone: '+91 98111 22333', shift: 'Morning', skills: 'Floor Planning, Safety' },
    { empId: 'EMP-004', name: 'Deepak Patil', role: 'TECHNICIAN', phone: '+91 98111 22334', shift: 'Evening', skills: 'Hydraulics, PM Maintenance' },
    { empId: 'EMP-005', name: 'Sneha Nair', role: 'QUALITY_INSPECTOR', phone: '+91 98111 22335', shift: 'Morning', skills: 'CMM, Calipers, Leak Test' },
    { empId: 'EMP-006', name: 'Manoj Tiwari', role: 'OPERATOR', phone: '+91 98111 22336', shift: 'Evening', skills: 'Welding, Grinding' },
  ];

  const todayStr = new Date(now).toISOString().slice(0, 10);

  for (const st of staffMembers) {
    const id = newId();
    await db.runAsync(
      `INSERT INTO staff (
        id, employee_id, name, role, phone, skills, shift, is_active, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)`,
      id,
      st.empId,
      st.name,
      st.role,
      st.phone,
      st.skills,
      st.shift,
      now,
      now,
    );

    // Record today's attendance
    const attId = newId();
    await db.runAsync(
      `INSERT INTO staff_attendance (
        id, staff_id, date, shift, status, overtime_hours, notes, created_at
      ) VALUES (?, ?, ?, ?, 'PRESENT', 0, 'On-time punch', ?)`,
      attId,
      id,
      todayStr,
      st.shift,
      now,
    );
  }

  // 4. Seed Purchase Requests for Low Stock Materials
  if (ctx.lowStockMaterialIds.length > 0) {
    for (let i = 0; i < ctx.lowStockMaterialIds.length; i++) {
      const matId = ctx.lowStockMaterialIds[i];
      const prId = newId();
      const reqNum = `PR-000${i + 1}`;
      await db.runAsync(
        `INSERT INTO purchase_requests (
          id, request_number, material_id, quantity, required_by_date, linked_order_id, reason, status, created_at
        ) VALUES (?, ?, ?, 500, ?, NULL, 'Auto-triggered by low stock threshold', 'PENDING', ?)`,
        prId,
        reqNum,
        matId,
        now + 7 * 86400000,
        now,
      );
    }
  }

  // 5. Seed an active Purchase Order
  if (supplierIds.length > 0 && ctx.materialIds.length > 0) {
    const poId = newId();
    await db.runAsync(
      `INSERT INTO purchase_orders (
        id, po_number, supplier_id, status, expected_date, total_amount, tax_amount, terms, created_at, updated_at
      ) VALUES (?, 'PO-0001', ?, 'ISSUED', ?, 125000, 22500, '30 Days Net, Delivered at factory', ?, ?)`,
      poId,
      supplierIds[0],
      now + 5 * 86400000,
      now,
      now,
    );

    const poiId = newId();
    await db.runAsync(
      `INSERT INTO purchase_order_items (
        id, po_id, material_id, quantity, unit_rate, tax_pct, received_quantity
      ) VALUES (?, ?, ?, 1000, 125, 18, 0)`,
      poiId,
      poId,
      ctx.materialIds[0],
    );
  }

  // 6. Seed a completed Purchase Order with dynamic GRN & stock ledger
  if (supplierIds.length > 1 && ctx.materialIds.length > 1) {
    const po2Id = newId();
    await db.runAsync(
      `INSERT INTO purchase_orders (
        id, po_number, supplier_id, status, expected_date, total_amount, tax_amount, terms, created_at, updated_at
      ) VALUES (?, 'PO-0002', ?, 'RECEIVED', ?, 84000, 15120, 'Net 15 Days, Delivered at factory', ?, ?)`,
      po2Id,
      supplierIds[1],
      now - 86400000 * 2,
      now - 86400000 * 5,
      now - 86400000 * 2,
    );

    const po2ItemId = newId();
    await db.runAsync(
      `INSERT INTO purchase_order_items (
        id, po_id, material_id, quantity, unit_rate, tax_pct, received_quantity
      ) VALUES (?, ?, ?, 500, 140, 18, 500)`,
      po2ItemId,
      po2Id,
      ctx.materialIds[1],
    );

    const grnId = newId();
    await db.runAsync(
      `INSERT INTO grn_receipts (
        id, grn_number, po_id, supplier_id, received_date, invoice_number, notes, created_at
      ) VALUES (?, 'GRN-0001', ?, ?, ?, 'INV-PARKER-991', 'Received at Bay 2, quality approved', ?)`,
      grnId,
      po2Id,
      supplierIds[1],
      now - 86400000 * 2,
      now - 86400000 * 2,
    );

    const txId = newId();
    await db.runAsync(
      `INSERT INTO stock_transactions (
        id, material_id, transaction_type, category, quantity, reference_type, reference_id, notes, created_at
      ) VALUES (?, ?, 'IN', 'RAW_MATERIAL', 500, 'GRN', ?, 'Received via GRN-0001', ?)`,
      txId,
      ctx.materialIds[1],
      grnId,
      now - 86400000 * 2,
    );
  }
}
