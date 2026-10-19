import type { StockCategory, StockTransactionRow, StockTransactionType } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { getDatabase } from '../client';
import { insertActivity } from './activityRepository';

export type StockTransactionFilters = {
  category?: StockCategory;
  transactionType?: StockTransactionType;
  materialId?: string;
  productId?: string;
  limit?: number;
};

export async function listStockTransactions(
  filters: StockTransactionFilters = {},
): Promise<StockTransactionRow[]> {
  const db = await getDatabase();
  const clauses: string[] = [];
  const params: (string | number)[] = [];

  if (filters.category) {
    clauses.push('st.category = ?');
    params.push(filters.category);
  }
  if (filters.transactionType) {
    clauses.push('st.transaction_type = ?');
    params.push(filters.transactionType);
  }
  if (filters.materialId) {
    clauses.push('st.material_id = ?');
    params.push(filters.materialId);
  }
  if (filters.productId) {
    clauses.push('st.product_id = ?');
    params.push(filters.productId);
  }

  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
  const limit = filters.limit ?? 50;

  return db.getAllAsync<StockTransactionRow>(
    `SELECT st.*, m.name as material_name, p.name as product_name
     FROM stock_transactions st
     LEFT JOIN materials m ON st.material_id = m.id
     LEFT JOIN products p ON st.product_id = p.id
     ${where}
     ORDER BY st.created_at DESC
     LIMIT ?`,
    ...params,
    limit,
  );
}

export type RecordStockMovementInput = {
  material_id?: string;
  product_id?: string;
  transaction_type: StockTransactionType;
  category: StockCategory;
  quantity: number;
  batch_lot?: string;
  reference_type?: string;
  reference_id?: string;
  performed_by?: string;
  notes?: string;
};

export async function recordStockMovement(input: RecordStockMovementInput): Promise<string> {
  const id = newId();
  const now = Date.now();
  const db = await getDatabase();

  await db.withTransactionAsync(async () => {
    // 1. Insert transaction
    await db.runAsync(
      `INSERT INTO stock_transactions (
        id, material_id, product_id, transaction_type, category, quantity, batch_lot, reference_type, reference_id, performed_by, notes, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      id,
      input.material_id || null,
      input.product_id || null,
      input.transaction_type,
      input.category,
      input.quantity,
      input.batch_lot?.trim() || null,
      input.reference_type?.trim() || null,
      input.reference_id?.trim() || null,
      input.performed_by?.trim() || null,
      input.notes?.trim() || null,
      now,
    );

    // 2. Adjust balance in materials if material_id is present
    if (input.material_id) {
      const delta = input.transaction_type === 'IN' ? input.quantity : -input.quantity;
      await db.runAsync(
        'UPDATE materials SET current_stock = MAX(0, current_stock + ?), updated_at = ? WHERE id = ?',
        delta,
        now,
        input.material_id,
      );
    }

    // 3. Adjust finished goods if product_id is present
    if (input.product_id && input.category === 'FINISHED_GOODS') {
      const delta = input.transaction_type === 'IN' ? input.quantity : -input.quantity;
      await db.runAsync(
        'UPDATE finished_goods SET available_quantity = MAX(0, available_quantity + ?), updated_at = ? WHERE product_id = ?',
        delta,
        now,
        input.product_id,
      );
    }

    await insertActivity({
      event_type: 'STOCK_ADJUSTMENT',
      title: `Stock ${input.transaction_type}: ${input.quantity} units`,
      description: input.notes || `${input.category} movement`,
      reference_type: 'STOCK',
      reference_id: id,
    });
  });

  notifyDataChanged();
  return id;
}
