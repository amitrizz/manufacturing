import { mongoApi } from '../../api/client';
import type { BomItemRow, MaterialRow } from '../../types/database';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { newId } from '../../utils/id';
import { getDatabase } from '../client';

export type MaterialFilters = {
  search?: string;
  category?: string;
  lowStockOnly?: boolean;
};

export async function listMaterials(filters: MaterialFilters = {}): Promise<MaterialRow[]> {
  try {
    const list = await mongoApi.getCollection<MaterialRow>('materials');
    if (list && Array.isArray(list) && list.length > 0) {
      let result = list;
      if (filters.search) {
        const q = filters.search.toLowerCase();
        result = result.filter(
          (m) => m.name?.toLowerCase().includes(q) || m.code?.toLowerCase().includes(q),
        );
      }
      if (filters.category) {
        result = result.filter((m) => m.category === filters.category);
      }
      if (filters.lowStockOnly) {
        result = result.filter((m) => (m.current_stock ?? 0) <= (m.minimum_stock ?? 0));
      }
      return result;
    }
  } catch (apiErr) {
    console.warn('MongoDB API materials error, using fallback:', apiErr instanceof Error ? apiErr.message : apiErr);
  }

  const db = await getDatabase();
  const clauses: string[] = [];
  const params: (string | number)[] = [];

  if (filters.search) {
    clauses.push('(name LIKE ? OR code LIKE ?)');
    const q = `%${filters.search}%`;
    params.push(q, q);
  }
  if (filters.category) {
    clauses.push('category = ?');
    params.push(filters.category);
  }
  if (filters.lowStockOnly) {
    clauses.push('current_stock <= minimum_stock');
  }

  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
  return db.getAllAsync<MaterialRow>(
    `SELECT * FROM materials ${where} ORDER BY name`,
    ...params,
  );
}

export async function getMaterialById(id: string): Promise<MaterialRow | null> {
  try {
    const item = await mongoApi.getById<MaterialRow>('materials', id);
    if (item) return item;
  } catch {
    // fallback
  }
  const db = await getDatabase();
  return db.getFirstAsync<MaterialRow>('SELECT * FROM materials WHERE id = ?', id);
}

export type ProductBomGroup = {
  product_id: string;
  product_code: string;
  product_name: string;
  items: BomItemRow[];
};

export async function listAllProductBoms(): Promise<ProductBomGroup[]> {
  const db = await getDatabase();
  const rows = await db.getAllAsync<{
    product_id: string;
    product_code: string;
    product_name: string;
    material_id: string;
    material_code: string;
    material_name: string;
    quantity: number;
    unit: string;
  }>(
    `SELECT p.id as product_id, p.code as product_code, p.name as product_name,
            bi.material_id, m.code as material_code, m.name as material_name,
            bi.quantity, bi.unit
     FROM products p
     JOIN bom b ON b.product_id = p.id AND b.is_active = 1
     JOIN bom_items bi ON bi.bom_id = b.id
     JOIN materials m ON m.id = bi.material_id
     ORDER BY p.code, m.code`,
  );

  const map = new Map<string, ProductBomGroup>();
  for (const row of rows) {
    let group = map.get(row.product_id);
    if (!group) {
      group = {
        product_id: row.product_id,
        product_code: row.product_code,
        product_name: row.product_name,
        items: [],
      };
      map.set(row.product_id, group);
    }
    group.items.push({
      material_id: row.material_id,
      material_code: row.material_code,
      material_name: row.material_name,
      quantity: row.quantity,
      unit: row.unit,
    });
  }
  return Array.from(map.values());
}

export async function getBomForProduct(productId: string): Promise<BomItemRow[]> {
  const db = await getDatabase();
  return db.getAllAsync<BomItemRow>(
    `SELECT bi.material_id, m.code as material_code, m.name as material_name, bi.quantity, bi.unit
     FROM bom b
     JOIN bom_items bi ON bi.bom_id = b.id
     JOIN materials m ON m.id = bi.material_id
     WHERE b.product_id = ? AND b.is_active = 1`,
    productId,
  );
}

export async function searchMaterials(query: string, limit = 20): Promise<MaterialRow[]> {
  const db = await getDatabase();
  const q = `%${query}%`;
  return db.getAllAsync<MaterialRow>(
    `SELECT * FROM materials WHERE name LIKE ? OR code LIKE ? ORDER BY name LIMIT ?`,
    q,
    q,
    limit,
  );
}

export type UpdateMaterialInput = {
  id: string;
  code: string;
  name: string;
  category: string;
  unit: string;
  minimum_stock: number;
  maximum_stock: number;
};

export async function updateMaterial(input: UpdateMaterialInput): Promise<void> {
  const db = await getDatabase();
  const now = Date.now();
  await db.runAsync(
    `UPDATE materials SET code = ?, name = ?, category = ?, unit = ?, minimum_stock = ?, maximum_stock = ?, updated_at = ?
     WHERE id = ?`,
    input.code.trim(),
    input.name.trim(),
    input.category.trim(),
    input.unit.trim(),
    input.minimum_stock,
    input.maximum_stock,
    now,
    input.id,
  );
  notifyDataChanged();
}

export async function deleteMaterial(id: string): Promise<void> {
  const db = await getDatabase();
  // Check if material is used in active BOMs
  const bomUsage = await db.getFirstAsync<{ count: number }>(
    `SELECT COUNT(*) as count FROM bom_items WHERE material_id = ?`,
    id,
  );
  if (bomUsage && bomUsage.count > 0) {
    throw new Error(
      `Cannot delete: this material is used in ${bomUsage.count} product BOM(s). Remove it from the BOM first.`,
    );
  }

  await db.withTransactionAsync(async () => {
    // Delete stock transactions referencing this material
    await db.runAsync(`DELETE FROM stock_transactions WHERE material_id = ?`, id);
    // Delete material
    await db.runAsync(`DELETE FROM materials WHERE id = ?`, id);
  });
  notifyDataChanged();
}

export type CreateMaterialInput = {
  code: string;
  name: string;
  category?: string;
  unit?: string;
  current_stock?: number;
  minimum_stock?: number;
  maximum_stock?: number;
};

export async function createMaterial(input: CreateMaterialInput): Promise<MaterialRow> {
  const db = await getDatabase();
  const id = newId();
  const now = Date.now();
  const cat = input.category?.trim() || 'RAW_MATERIAL';
  const unit = input.unit?.trim() || 'pcs';
  const stock = input.current_stock ?? 0;
  const min = input.minimum_stock ?? 0;
  const max = input.maximum_stock ?? 1000;

  await db.runAsync(
    `INSERT INTO materials (id, code, name, category, unit, current_stock, minimum_stock, maximum_stock, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    id,
    input.code.trim(),
    input.name.trim(),
    cat,
    unit,
    stock,
    min,
    max,
    now,
  );
  notifyDataChanged();
  return {
    id,
    code: input.code.trim(),
    name: input.name.trim(),
    category: cat,
    unit,
    current_stock: stock,
    minimum_stock: min,
    maximum_stock: max,
    updated_at: now,
  };
}
