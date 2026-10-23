import type { DispatchOrderRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { mongoApi } from '../client';

export async function listDispatchOrders(): Promise<DispatchOrderRow[]> {
  try {
    const [dispatches, products] = await Promise.all([
      mongoApi.getCollection<any>('dispatch_orders'),
      mongoApi.getCollection<any>('products'),
    ]);

    const prodMap = new Map(products.map((p) => [p.id || p._id, p]));

    return dispatches
      .map((d) => {
        const p = prodMap.get(d.product_id);
        return {
          ...d,
          id: d.id || d._id,
          product_code: p?.code || '',
          product_name: p?.name || 'Product',
        };
      })
      .sort((a, b) => (b.created_at || 0) - (a.created_at || 0));
  } catch (err) {
    console.warn('MongoDB listDispatchOrders error:', err);
    return [];
  }
}

export type CreateDispatchInput = {
  dispatch_number: string;
  customer_name: string;
  customer_id?: string;
  product_id: string;
  quantity: number;
  delivery_address?: string;
  vehicle_number?: string;
  driver_name?: string;
  notes?: string;
  company_id?: string;
};

export async function createDispatchOrder(input: CreateDispatchInput): Promise<string> {
  const id = newId();
  const now = Date.now();

  const doc: any = {
    _id: id,
    id,
    dispatch_number: input.dispatch_number.trim(),
    customer_name: input.customer_name.trim(),
    customer_id: input.customer_id || null,
    product_id: input.product_id,
    quantity: input.quantity,
    delivery_address: input.delivery_address?.trim() || null,
    vehicle_number: input.vehicle_number?.trim() || null,
    driver_name: input.driver_name?.trim() || null,
    notes: input.notes?.trim() || null,
    status: 'READY',
    dispatched_at: null,
    created_at: now,
    updated_at: now,
  };
  if (input.company_id) {
    doc.company_id = input.company_id;
  }

  await mongoApi.insert('dispatch_orders', doc);

  await mongoApi
    .insert('activity_history', {
      event_type: 'DISPATCH_CREATED',
      title: 'Dispatch order created',
      description: `${input.dispatch_number} · ${input.customer_name} (${input.quantity} units)`,
      reference_type: 'dispatch_order',
      reference_id: id,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
  return id;
}

export async function dispatchOrder(orderId: string): Promise<void> {
  const now = Date.now();
  const dList = await listDispatchOrders();
  const order = dList.find((d) => d.id === orderId);

  await mongoApi.update('dispatch_orders', orderId, {
    status: 'DISPATCHED',
    dispatched_at: now,
    updated_at: now,
  });

  if (order && order.product_id) {
    try {
      const fgList = await mongoApi.getCollection<any>('finished_goods', { product_id: order.product_id }).catch(() => []);
      const fg = fgList.find((f: any) => f.product_id === order.product_id);
      if (fg) {
        const remaining = Math.max(0, (fg.available_quantity || 0) - (order.quantity || 0));
        await mongoApi.update('finished_goods', fg.id || fg._id, {
          available_quantity: remaining,
          dispatched_quantity: (fg.dispatched_quantity || 0) + (order.quantity || 0),
          updated_at: now,
        });
      }
    } catch {}
  }

  await mongoApi
    .insert('activity_history', {
      event_type: 'DISPATCH_DISPATCHED',
      title: 'Order dispatched',
      description: `${order?.dispatch_number || orderId} to ${order?.customer_name || 'Customer'}`,
      reference_type: 'dispatch_order',
      reference_id: orderId,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
}

export async function searchDispatchOrders(
  query: string,
  limit = 20,
): Promise<DispatchOrderRow[]> {
  const all = await listDispatchOrders();
  const q = query.toLowerCase();
  return all
    .filter(
      (d) =>
        d.dispatch_number?.toLowerCase().includes(q) ||
        d.customer_name?.toLowerCase().includes(q) ||
        d.product_code?.toLowerCase().includes(q)
    )
    .slice(0, limit);
}
