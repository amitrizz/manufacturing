import type { DispatchOrderRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { mongoApi } from '../../api/client';

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
  product_id: string;
  quantity: number;
};

export async function createDispatchOrder(input: CreateDispatchInput): Promise<string> {
  const id = newId();
  const now = Date.now();

  const doc = {
    _id: id,
    id,
    dispatch_number: input.dispatch_number.trim(),
    customer_name: input.customer_name.trim(),
    product_id: input.product_id,
    quantity: input.quantity,
    status: 'READY',
    dispatched_at: null,
    created_at: now,
    updated_at: now,
  };

  await mongoApi.insert('dispatch_orders', doc);

  await mongoApi
    .insert('activity_history', {
      event_type: 'DISPATCH_CREATED',
      title: 'Dispatch order created',
      description: input.dispatch_number,
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
  await mongoApi.update('dispatch_orders', orderId, {
    status: 'DISPATCHED',
    dispatched_at: now,
    updated_at: now,
  });

  await mongoApi
    .insert('activity_history', {
      event_type: 'DISPATCH_DISPATCHED',
      title: 'Order dispatched',
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
