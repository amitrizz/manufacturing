import { mongoApi } from '../client';
import type {
  GrnReceiptRow,
  PurchaseOrderItemRow,
  PurchaseOrderRow,
  PurchaseOrderStatus,
  PurchaseRequestRow,
  PurchaseRequestStatus,
} from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';

// --- Purchase Requests ---
export async function listPurchaseRequests(status?: PurchaseRequestStatus): Promise<PurchaseRequestRow[]> {
  try {
    const [requests, materials, orders] = await Promise.all([
      mongoApi.getCollection<any>('purchase_requests'),
      mongoApi.getCollection<any>('materials'),
      mongoApi.getCollection<any>('production_orders'),
    ]);

    const matMap = new Map(materials.map((m) => [m.id || m._id, m]));
    const ordMap = new Map(orders.map((o) => [o.id || o._id, o]));

    let result = requests.map((pr) => {
      const mat = matMap.get(pr.material_id);
      const ord = ordMap.get(pr.linked_order_id);
      return {
        ...pr,
        id: pr.id || pr._id,
        material_code: mat?.code || '',
        material_name: mat?.name || 'Material',
        material_unit: mat?.unit || 'units',
        order_number: ord?.order_number || '',
      };
    });

    if (status) {
      result = result.filter((pr) => pr.status === status);
    }

    return result.sort((a, b) => (b.created_at || 0) - (a.created_at || 0));
  } catch (err) {
    console.warn('MongoDB listPurchaseRequests error:', err);
    return [];
  }
}

export async function createPurchaseRequest(input: {
  material_id: string;
  quantity: number;
  required_by_date: number;
  linked_order_id?: string | null;
  reason?: string | null;
  company_id?: string;
}): Promise<string> {
  const id = newId();
  const now = Date.now();
  const existing = await mongoApi.getCollection<any>('purchase_requests').catch(() => []);
  const seq = (existing.length + 1).toString().padStart(4, '0');
  const requestNumber = `PR-${seq}`;

  await mongoApi.insert('purchase_requests', {
    _id: id,
    id,
    request_number: requestNumber,
    material_id: input.material_id,
    quantity: input.quantity,
    required_by_date: input.required_by_date,
    linked_order_id: input.linked_order_id || null,
    reason: input.reason?.trim() || null,
    status: 'PENDING',
    ...(input.company_id ? { company_id: input.company_id } : {}),
    created_at: now,
    updated_at: now,
  });

  notifyDataChanged();
  return id;
}

export async function updatePurchaseRequestStatus(
  id: string,
  status: PurchaseRequestStatus,
): Promise<void> {
  await mongoApi.update('purchase_requests', id, { status, updated_at: Date.now() });
  notifyDataChanged();
}

export async function deletePurchaseRequest(id: string): Promise<void> {
  await mongoApi.delete('purchase_requests', id);
  notifyDataChanged();
}

// --- Purchase Orders ---
export async function listPurchaseOrders(status?: PurchaseOrderStatus): Promise<PurchaseOrderRow[]> {
  try {
    const [orders, suppliers, items] = await Promise.all([
      mongoApi.getCollection<any>('purchase_orders'),
      mongoApi.getCollection<any>('suppliers'),
      mongoApi.getCollection<any>('purchase_order_items'),
    ]);

    const supMap = new Map(suppliers.map((s) => [s.id || s._id, s]));

    let result = orders.map((po) => {
      const sup = supMap.get(po.supplier_id);
      const poItems = items.filter((i) => i.po_id === po.id || i.po_id === po._id);
      const totalAmount = poItems.reduce((acc, it) => acc + (Number(it.total_price) || (Number(it.quantity) * Number(it.unit_price)) || 0), 0);
      return {
        ...po,
        id: po.id || po._id,
        supplier_name: sup?.name || 'Supplier',
        supplier_contact: sup?.contact_person || '',
        items_count: poItems.length,
        total_amount: po.total_amount || totalAmount,
      };
    });

    if (status) {
      result = result.filter((po) => po.status === status);
    }

    return result.sort((a, b) => (b.created_at || 0) - (a.created_at || 0));
  } catch (err) {
    console.warn('MongoDB listPurchaseOrders error:', err);
    return [];
  }
}

export async function getPurchaseOrderById(id: string): Promise<PurchaseOrderRow | null> {
  const all = await listPurchaseOrders();
  return all.find((po) => po.id === id || (po as any)._id === id) || null;
}

export async function getPurchaseOrderItems(orderId: string): Promise<PurchaseOrderItemRow[]> {
  try {
    const [items, materials] = await Promise.all([
      mongoApi.getCollection<any>('purchase_order_items'),
      mongoApi.getCollection<any>('materials'),
    ]);

    const matMap = new Map(materials.map((m) => [m.id || m._id, m]));

    return items
      .filter((it) => it.po_id === orderId)
      .map((it) => {
        const mat = matMap.get(it.material_id);
        return {
          ...it,
          id: it.id || it._id,
          material_code: mat?.code || '',
          material_name: mat?.name || 'Material',
          material_unit: mat?.unit || 'units',
        };
      });
  } catch (err) {
    console.warn('getPurchaseOrderItems error:', err);
    return [];
  }
}

export type CreatePoItemInput = {
  material_id: string;
  quantity: number;
  unit_price?: number;
  unit_rate?: number;
  tax_pct?: number;
  notes?: string;
};

export async function createPurchaseOrder(input: {
  supplier_id: string;
  expected_delivery_date?: number;
  expected_date?: number;
  terms?: string;
  items: CreatePoItemInput[];
  notes?: string;
  company_id?: string;
}): Promise<string> {
  const poId = newId();
  const now = Date.now();
  const existing = await mongoApi.getCollection<any>('purchase_orders').catch(() => []);
  const seq = (existing.length + 1).toString().padStart(4, '0');
  const poNumber = `PO-${seq}`;

  let totalAmount = 0;
  for (const it of input.items) {
    const price = it.unit_price ?? it.unit_rate ?? 0;
    totalAmount += it.quantity * price;
  }

  const expDate = input.expected_delivery_date ?? input.expected_date ?? now + 7 * 86400000;

  await mongoApi.insert('purchase_orders', {
    _id: poId,
    id: poId,
    po_number: poNumber,
    supplier_id: input.supplier_id,
    order_date: now,
    expected_delivery_date: expDate,
    terms: input.terms || null,
    status: 'PLACED',
    total_amount: totalAmount,
    notes: input.notes?.trim() || null,
    ...(input.company_id ? { company_id: input.company_id } : {}),
    created_at: now,
    updated_at: now,
  });

  for (const it of input.items) {
    const itemId = newId();
    const price = it.unit_price ?? it.unit_rate ?? 0;
    await mongoApi.insert('purchase_order_items', {
      _id: itemId,
      id: itemId,
      po_id: poId,
      material_id: it.material_id,
      quantity: it.quantity,
      unit_price: price,
      total_price: it.quantity * price,
      received_quantity: 0,
      notes: it.notes?.trim() || null,
      created_at: now,
      updated_at: now,
    });
  }

  notifyDataChanged();
  return poId;
}

export async function receiveGrn(input: {
  po_id?: string | null;
  supplier_id?: string | null;
  invoice_number?: string | null;
  notes?: string | null;
  items?: { material_id: string; received_quantity: number }[];
  received_items?: { material_id: string; received_qty: number }[];
}): Promise<string> {
  const items = input.received_items
    ? input.received_items
    : (input.items || []).map((i) => ({
        material_id: i.material_id,
        received_qty: i.received_quantity,
      }));

  const res = await mongoApi.receiveGrn({
    po_id: input.po_id || null,
    supplier_id: input.supplier_id || null,
    invoice_number: input.invoice_number || null,
    notes: input.notes || null,
    received_items: items,
  });

  notifyDataChanged();
  return res.grnId || res.grnNumber;
}

export async function listGrnReceipts(): Promise<GrnReceiptRow[]> {
  try {
    return await mongoApi.listGrnReceipts<GrnReceiptRow>();
  } catch (err) {
    console.warn('listGrnReceipts error:', err);
    return [];
  }
}

export async function deleteGrnReceipt(id: string): Promise<void> {
  await mongoApi.delete('grn_receipts', id);
  notifyDataChanged();
}

export async function updatePurchaseOrderStatus(
  id: string,
  status: PurchaseOrderStatus,
): Promise<void> {
  await mongoApi.update('purchase_orders', id, { status, updated_at: Date.now() });
  notifyDataChanged();
}

export async function deletePurchaseOrder(id: string): Promise<void> {
  await mongoApi.delete('purchase_orders', id);
  notifyDataChanged();
}
