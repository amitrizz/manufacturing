import type { StockCategory, StockTransactionRow, StockTransactionType } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { mongoApi } from '../client';

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
  try {
    const [txs, materials, products] = await Promise.all([
      mongoApi.getCollection<any>('stock_transactions'),
      mongoApi.getCollection<any>('materials'),
      mongoApi.getCollection<any>('products'),
    ]);

    const matMap = new Map(materials.map((m) => [m.id || m._id, m.name]));
    const prodMap = new Map(products.map((p) => [p.id || p._id, p.name]));

    let result = txs.map((st) => ({
      ...st,
      id: st.id || st._id,
      material_name: matMap.get(st.material_id) || undefined,
      product_name: prodMap.get(st.product_id) || undefined,
    }));

    if (filters.category) result = result.filter((t) => t.category === filters.category);
    if (filters.transactionType) result = result.filter((t) => t.transaction_type === filters.transactionType);
    if (filters.materialId) result = result.filter((t) => t.material_id === filters.materialId);
    if (filters.productId) result = result.filter((t) => t.product_id === filters.productId);

    return result
      .sort((a, b) => (b.created_at || 0) - (a.created_at || 0))
      .slice(0, filters.limit ?? 50);
  } catch (err) {
    console.warn('MongoDB listStockTransactions error:', err);
    return [];
  }
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

  await mongoApi.insert('stock_transactions', {
    _id: id,
    id,
    material_id: input.material_id || null,
    product_id: input.product_id || null,
    transaction_type: input.transaction_type,
    category: input.category,
    quantity: input.quantity,
    batch_lot: input.batch_lot?.trim() || null,
    reference_type: input.reference_type?.trim() || null,
    reference_id: input.reference_id?.trim() || null,
    performed_by: input.performed_by?.trim() || null,
    notes: input.notes?.trim() || null,
    created_at: now,
  });

  if (input.material_id) {
    const mat = await mongoApi.getById<any>('materials', input.material_id).catch(() => null);
    if (mat) {
      const current = mat.current_stock || 0;
      const delta = input.transaction_type === 'IN' ? input.quantity : -input.quantity;
      await mongoApi.update('materials', input.material_id, {
        current_stock: Math.max(0, current + delta),
        updated_at: now,
      });
    }
  }

  await mongoApi
    .insert('activity_history', {
      event_type: 'STOCK_MOVEMENT',
      title: `${input.transaction_type} ${input.quantity} units`,
      description: input.notes || `Stock movement for ${input.category}`,
      reference_type: 'stock_transaction',
      reference_id: id,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
  return id;
}
