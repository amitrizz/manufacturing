import { mongoApi } from '../../api/client';
import type {
  GrnItemDetail,
  GrnReceiptRow,
  PurchaseOrderItemRow,
  PurchaseOrderRow,
  PurchaseOrderStatus,
  PurchaseRequestRow,
  PurchaseRequestStatus,
} from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { getDatabase } from '../client';
import { insertActivity } from './activityRepository';

// --- Purchase Requests ---
export async function listPurchaseRequests(status?: PurchaseRequestStatus): Promise<PurchaseRequestRow[]> {
  const db = await getDatabase();
  const filterSql = status ? 'WHERE pr.status = ?' : '';
  const params = status ? [status] : [];

  return db.getAllAsync<PurchaseRequestRow>(
    `SELECT pr.*, m.code as material_code, m.name as material_name, m.unit as material_unit,
            po.order_number
     FROM purchase_requests pr
     JOIN materials m ON pr.material_id = m.id
     LEFT JOIN production_orders po ON pr.linked_order_id = po.id
     ${filterSql}
     ORDER BY pr.created_at DESC`,
    ...params,
  );
}

export async function createPurchaseRequest(input: {
  material_id: string;
  quantity: number;
  required_by_date: number;
  linked_order_id?: string | null;
  reason?: string | null;
}): Promise<string> {
  const id = newId();
  const now = Date.now();
  const db = await getDatabase();

  const countRow = await db.getFirstAsync<{ count: number }>(
    'SELECT count(*) as count FROM purchase_requests',
  );
  const seq = ((countRow?.count ?? 0) + 1).toString().padStart(4, '0');
  const requestNumber = `PR-${seq}`;

  await db.runAsync(
    `INSERT INTO purchase_requests (
      id, request_number, material_id, quantity, required_by_date, linked_order_id, reason, status, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, 'PENDING', ?)`,
    id,
    requestNumber,
    input.material_id,
    input.quantity,
    input.required_by_date,
    input.linked_order_id || null,
    input.reason?.trim() || null,
    now,
  );

  await insertActivity({
    event_type: 'PURCHASE_REQUEST_CREATED',
    title: `Purchase request ${requestNumber}`,
    description: `Quantity: ${input.quantity}`,
    reference_type: 'PURCHASE_REQUEST',
    reference_id: id,
  });

  notifyDataChanged();
  return id;
}

// --- Purchase Orders ---
export async function listPurchaseOrders(status?: PurchaseOrderStatus): Promise<PurchaseOrderRow[]> {
  const db = await getDatabase();
  const filterSql = status ? 'WHERE po.status = ?' : '';
  const params = status ? [status] : [];

  return db.getAllAsync<PurchaseOrderRow>(
    `SELECT po.*, s.name as supplier_name,
            (SELECT COUNT(*) FROM purchase_order_items poi WHERE poi.po_id = po.id) as items_count
     FROM purchase_orders po
     JOIN suppliers s ON po.supplier_id = s.id
     ${filterSql}
     ORDER BY po.created_at DESC`,
    ...params,
  );
}

export async function getPurchaseOrderById(id: string): Promise<PurchaseOrderRow | null> {
  const db = await getDatabase();
  return db.getFirstAsync<PurchaseOrderRow>(
    `SELECT po.*, s.name as supplier_name
     FROM purchase_orders po
     JOIN suppliers s ON po.supplier_id = s.id
     WHERE po.id = ?`,
    id,
  );
}

export async function getPurchaseOrderItems(poId: string): Promise<PurchaseOrderItemRow[]> {
  const db = await getDatabase();
  return db.getAllAsync<PurchaseOrderItemRow>(
    `SELECT poi.*, m.code as material_code, m.name as material_name, m.unit as material_unit
     FROM purchase_order_items poi
     JOIN materials m ON poi.material_id = m.id
     WHERE poi.po_id = ?`,
    poId,
  );
}

export type CreatePoItemInput = {
  material_id: string;
  quantity: number;
  unit_rate: number;
  tax_pct?: number;
};

export async function createPurchaseOrder(input: {
  supplier_id: string;
  expected_date: number;
  terms?: string;
  items: CreatePoItemInput[];
}): Promise<string> {
  const id = newId();
  const now = Date.now();
  const db = await getDatabase();

  const countRow = await db.getFirstAsync<{ count: number }>(
    'SELECT count(*) as count FROM purchase_orders',
  );
  const seq = ((countRow?.count ?? 0) + 1).toString().padStart(4, '0');
  const poNumber = `PO-${seq}`;

  let totalAmount = 0;
  let taxAmount = 0;

  for (const item of input.items) {
    const lineTotal = item.quantity * item.unit_rate;
    const lineTax = (lineTotal * (item.tax_pct ?? 0)) / 100;
    totalAmount += lineTotal + lineTax;
    taxAmount += lineTax;
  }

  await db.withTransactionAsync(async () => {
    await db.runAsync(
      `INSERT INTO purchase_orders (
        id, po_number, supplier_id, status, expected_date, total_amount, tax_amount, terms, created_at, updated_at
      ) VALUES (?, ?, ?, 'ISSUED', ?, ?, ?, ?, ?, ?)`,
      id,
      poNumber,
      input.supplier_id,
      input.expected_date,
      totalAmount,
      taxAmount,
      input.terms?.trim() || null,
      now,
      now,
    );

    for (const item of input.items) {
      const itemId = newId();
      await db.runAsync(
        `INSERT INTO purchase_order_items (
          id, po_id, material_id, quantity, unit_rate, tax_pct, received_quantity
        ) VALUES (?, ?, ?, ?, ?, ?, 0)`,
        itemId,
        id,
        item.material_id,
        item.quantity,
        item.unit_rate,
        item.tax_pct ?? 0,
      );
    }

    await insertActivity({
      event_type: 'PURCHASE_ORDER_ISSUED',
      title: `Purchase order ${poNumber} issued`,
      description: `Total: ₹${totalAmount.toFixed(2)}`,
      reference_type: 'PURCHASE_ORDER',
      reference_id: id,
    });
  });

  notifyDataChanged();
  return id;
}

// --- GRN (Goods Received Note) Receipt & Stock In ---
export async function receiveGrn(input: {
  po_id?: string | null;
  supplier_id?: string | null;
  invoice_number?: string | null;
  notes?: string | null;
  received_items: {
    material_id: string;
    received_qty: number;
  }[];
}): Promise<string> {
  try {
    const res = await mongoApi.receiveGrn(input);
    notifyDataChanged();
    return res.grnId;
  } catch (apiErr) {
    console.warn('MongoDB API error, using local fallback:', apiErr instanceof Error ? apiErr.message : apiErr);
  }

  const grnId = newId();
  const now = Date.now();
  const db = await getDatabase();

  const countRow = await db.getFirstAsync<{ count: number }>(
    'SELECT count(*) as count FROM grn_receipts',
  );
  const seq = ((countRow?.count ?? 0) + 1).toString().padStart(4, '0');
  const grnNumber = `GRN-${seq}`;

  await db.withTransactionAsync(async () => {
    // 1. Insert GRN record
    await db.runAsync(
      `INSERT INTO grn_receipts (
        id, grn_number, po_id, supplier_id, received_date, invoice_number, notes, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      grnId,
      grnNumber,
      input.po_id || null,
      input.supplier_id || null,
      now,
      input.invoice_number?.trim() || null,
      input.notes?.trim() || null,
      now,
    );

    // 2. Update stock & PO items received_quantity
    for (const item of input.received_items) {
      if (item.received_qty <= 0) continue;

      // Update material stock
      await db.runAsync(
        'UPDATE materials SET current_stock = current_stock + ?, updated_at = ? WHERE id = ?',
        item.received_qty,
        now,
        item.material_id,
      );

      // If linked to PO, update PO item received quantity
      if (input.po_id) {
        await db.runAsync(
          `UPDATE purchase_order_items
           SET received_quantity = received_quantity + ?
           WHERE po_id = ? AND material_id = ?`,
          item.received_qty,
          input.po_id,
          item.material_id,
        );
      }

      // Record in stock_transactions ledger
      const txId = newId();
      await db.runAsync(
        `INSERT INTO stock_transactions (
          id, material_id, transaction_type, category, quantity, reference_type, reference_id, notes, created_at
        ) VALUES (?, ?, 'IN', 'RAW_MATERIAL', ?, 'GRN', ?, ?, ?)`,
        txId,
        item.material_id,
        item.received_qty,
        grnId,
        `Received via ${grnNumber}`,
        now,
      );
    }

    // 3. If linked to PO, check if all items in PO are fully received
    if (input.po_id) {
      const poItems = await db.getAllAsync<{ quantity: number; received_quantity: number }>(
        'SELECT quantity, received_quantity FROM purchase_order_items WHERE po_id = ?',
        input.po_id,
      );
      if (poItems.length > 0) {
        const allReceived = poItems.every((it) => it.received_quantity >= it.quantity);
        const newStatus: PurchaseOrderStatus = allReceived ? 'RECEIVED' : 'PARTIALLY_RECEIVED';

        await db.runAsync(
          'UPDATE purchase_orders SET status = ?, updated_at = ? WHERE id = ?',
          newStatus,
          now,
          input.po_id,
        );
      }
    }

    await insertActivity({
      event_type: 'GRN_RECEIVED',
      title: `${grnNumber} processed`,
      description: input.po_id ? `Stock updated from PO receipt` : `Direct material inward received`,
      reference_type: 'GRN',
      reference_id: grnId,
    });
  });

  notifyDataChanged();
  return grnId;
}

export async function listGrnReceipts(): Promise<GrnReceiptRow[]> {
  try {
    const list = await mongoApi.listGrnReceipts<GrnReceiptRow>();
    if (list && Array.isArray(list)) {
      return list;
    }
  } catch (apiErr) {
    console.warn('MongoDB API error, using local fallback:', apiErr instanceof Error ? apiErr.message : apiErr);
  }

  const db = await getDatabase();
  const rows = await db.getAllAsync<GrnReceiptRow>(
    `SELECT grn.*, po.po_number, s.name as supplier_name
     FROM grn_receipts grn
     LEFT JOIN purchase_orders po ON grn.po_id = po.id
     LEFT JOIN suppliers s ON grn.supplier_id = s.id
     ORDER BY grn.created_at DESC`,
  );

  if (rows.length === 0) return [];

  const txs = await db.getAllAsync<{
    reference_id: string;
    quantity: number;
    material_id: string;
    material_name: string;
    material_code: string;
    unit: string;
  }>(
    `SELECT st.reference_id, st.quantity, st.material_id, m.name as material_name, m.code as material_code, m.unit
     FROM stock_transactions st
     LEFT JOIN materials m ON st.material_id = m.id
     WHERE st.reference_type = 'GRN'
     ORDER BY st.created_at ASC`,
  );

  const txMap: Record<string, GrnItemDetail[]> = {};
  for (const t of txs) {
    if (!t.reference_id) continue;
    if (!txMap[t.reference_id]) txMap[t.reference_id] = [];
    txMap[t.reference_id].push({
      material_id: t.material_id,
      material_name: t.material_name || 'Material',
      material_code: t.material_code || '',
      quantity: t.quantity,
      unit: t.unit || 'units',
    });
  }

  return rows.map((r) => {
    const items = txMap[r.id] || [];
    const total_qty = items.reduce((sum, it) => sum + (it.quantity || 0), 0);
    const items_summary =
      items.length > 0
        ? items.map((it) => `${it.material_name} (${it.quantity} ${it.unit || ''})`.trim()).join(', ')
        : 'Direct Inward';
    return {
      ...r,
      items,
      total_qty,
      items_summary,
    };
  });
}

export async function deleteGrnReceipt(grnId: string): Promise<void> {
  try {
    await mongoApi.deleteGrn(grnId);
    notifyDataChanged();
    return;
  } catch (apiErr) {
    console.warn('MongoDB API error, using local fallback:', apiErr instanceof Error ? apiErr.message : apiErr);
  }

  const db = await getDatabase();
  const grn = await db.getFirstAsync<{ po_id: string | null }>(
    'SELECT po_id FROM grn_receipts WHERE id = ?',
    grnId,
  );
  const txs = await db.getAllAsync<{ material_id: string; quantity: number }>(
    "SELECT material_id, quantity FROM stock_transactions WHERE reference_type = 'GRN' AND reference_id = ?",
    grnId,
  );

  await db.withTransactionAsync(async () => {
    const now = Date.now();
    for (const tx of txs) {
      if (tx.material_id) {
        // Reverse stock
        await db.runAsync(
          'UPDATE materials SET current_stock = MAX(0, current_stock - ?), updated_at = ? WHERE id = ?',
          tx.quantity,
          now,
          tx.material_id,
        );

        // If this GRN was linked to a PO, reverse received_quantity on po items
        if (grn?.po_id) {
          await db.runAsync(
            `UPDATE purchase_order_items
             SET received_quantity = MAX(0, received_quantity - ?)
             WHERE po_id = ? AND material_id = ?`,
            tx.quantity,
            grn.po_id,
            tx.material_id,
          );
        }
      }
    }

    if (grn?.po_id) {
      const poItems = await db.getAllAsync<{ quantity: number; received_quantity: number }>(
        'SELECT quantity, received_quantity FROM purchase_order_items WHERE po_id = ?',
        grn.po_id,
      );
      const anyReceived = poItems.some((it) => it.received_quantity > 0);
      const allReceived = poItems.length > 0 && poItems.every((it) => it.received_quantity >= it.quantity);
      const newStatus: PurchaseOrderStatus = allReceived
        ? 'RECEIVED'
        : anyReceived
        ? 'PARTIALLY_RECEIVED'
        : 'ISSUED';
      await db.runAsync(
        'UPDATE purchase_orders SET status = ?, updated_at = ? WHERE id = ?',
        newStatus,
        now,
        grn.po_id,
      );
    }

    await db.runAsync(
      "DELETE FROM stock_transactions WHERE reference_type = 'GRN' AND reference_id = ?",
      grnId,
    );
    await db.runAsync('DELETE FROM grn_receipts WHERE id = ?', grnId);

    await insertActivity({
      event_type: 'GRN_DELETED',
      title: 'GRN reversed',
      description: 'GRN receipt deleted and stock reversed',
      reference_type: 'GRN',
      reference_id: grnId,
    });
  });

  notifyDataChanged();
}

export async function updatePurchaseRequestStatus(
  id: string,
  status: PurchaseRequestStatus,
): Promise<void> {
  const db = await getDatabase();
  await db.runAsync('UPDATE purchase_requests SET status = ? WHERE id = ?', status, id);
  notifyDataChanged();
}

export async function deletePurchaseRequest(id: string): Promise<void> {
  const db = await getDatabase();
  await db.runAsync('DELETE FROM purchase_requests WHERE id = ?', id);
  notifyDataChanged();
}

export async function updatePurchaseOrderStatus(
  id: string,
  status: PurchaseOrderStatus,
): Promise<void> {
  const db = await getDatabase();
  await db.runAsync('UPDATE purchase_orders SET status = ?, updated_at = ? WHERE id = ?', status, Date.now(), id);
  notifyDataChanged();
}

export async function deletePurchaseOrder(id: string): Promise<void> {
  const db = await getDatabase();
  const existing = await getPurchaseOrderById(id);
  if (!existing) throw new Error('Purchase order not found');

  if (existing.status === 'RECEIVED' || existing.status === 'PARTIALLY_RECEIVED') {
    throw new Error('Cannot delete purchase order that has received stock via GRN.');
  }

  await db.withTransactionAsync(async () => {
    await db.runAsync('DELETE FROM purchase_order_items WHERE po_id = ?', id);
    await db.runAsync('DELETE FROM purchase_orders WHERE id = ?', id);
    await insertActivity({
      event_type: 'PURCHASE_ORDER_CANCELLED',
      title: `Purchase order ${existing.po_number} deleted`,
      description: 'Order removed',
      reference_type: 'PURCHASE_ORDER',
      reference_id: id,
    });
  });

  notifyDataChanged();
}
