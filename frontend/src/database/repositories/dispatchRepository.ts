import type { DispatchOrderRow } from '../../types/database';
import { newId } from '../../utils/id';
import { getDatabase } from '../client';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { insertActivity } from './activityRepository';

export async function listDispatchOrders(): Promise<DispatchOrderRow[]> {
  const db = await getDatabase();
  return db.getAllAsync<DispatchOrderRow>(
    `SELECT d.*, p.code as product_code, p.name as product_name
     FROM dispatch_orders d JOIN products p ON p.id = d.product_id
     ORDER BY d.created_at DESC`,
  );
}

export type CreateDispatchInput = {
  dispatch_number: string;
  customer_name: string;
  product_id: string;
  quantity: number;
};

export async function createDispatchOrder(input: CreateDispatchInput): Promise<string> {
  const db = await getDatabase();
  const id = newId();
  const now = Date.now();

  await db.runAsync(
    `INSERT INTO dispatch_orders (id, dispatch_number, customer_name, product_id, quantity, status, created_at, dispatched_at)
     VALUES (?, ?, ?, ?, ?, 'READY', ?, NULL)`,
    id,
    input.dispatch_number,
    input.customer_name,
    input.product_id,
    input.quantity,
    now,
  );

  await insertActivity({
    event_type: 'DISPATCH_CREATED',
    title: 'Dispatch order created',
    description: input.dispatch_number,
    reference_type: 'dispatch_order',
    reference_id: id,
    timestamp: now,
  });

  notifyDataChanged();
  return id;
}

export async function dispatchOrder(orderId: string): Promise<void> {
  const db = await getDatabase();
  const now = Date.now();

  await db.withTransactionAsync(async () => {
    const order = await db.getFirstAsync<{
      product_id: string;
      quantity: number;
      status: string;
    }>('SELECT product_id, quantity, status FROM dispatch_orders WHERE id = ?', orderId);

    if (!order) throw new Error('Dispatch not found');
    if (order.status === 'DISPATCHED') throw new Error('Already dispatched');

    const fg = await db.getFirstAsync<{ available_quantity: number }>(
      'SELECT available_quantity FROM finished_goods WHERE product_id = ?',
      order.product_id,
    );
    const available = fg?.available_quantity ?? 0;
    if (order.quantity > available) {
      throw new Error(`Quantity exceeds available stock (${available})`);
    }

    await db.runAsync(
      `UPDATE dispatch_orders SET status = 'DISPATCHED', dispatched_at = ? WHERE id = ?`,
      now,
      orderId,
    );
    await db.runAsync(
      `UPDATE finished_goods SET available_quantity = available_quantity - ?, updated_at = ? WHERE product_id = ?`,
      order.quantity,
      now,
      order.product_id,
    );

    await insertActivity(
      {
        event_type: 'DISPATCH_DISPATCHED',
        title: 'Order dispatched',
        reference_type: 'dispatch_order',
        reference_id: orderId,
        timestamp: now,
      },
      db,
    );
  });
  notifyDataChanged();
}

export async function searchDispatchOrders(
  query: string,
  limit = 20,
): Promise<DispatchOrderRow[]> {
  const db = await getDatabase();
  const q = `%${query}%`;
  return db.getAllAsync<DispatchOrderRow>(
    `SELECT d.*, p.code as product_code, p.name as product_name
     FROM dispatch_orders d JOIN products p ON p.id = d.product_id
     WHERE d.dispatch_number LIKE ? OR d.customer_name LIKE ? OR p.code LIKE ?
     ORDER BY d.created_at DESC LIMIT ?`,
    q,
    q,
    q,
    limit,
  );
}
