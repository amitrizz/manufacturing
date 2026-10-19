import type { ProductRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { getDatabase } from '../client';
import { insertActivity } from './activityRepository';

export async function listProducts(): Promise<ProductRow[]> {
  const db = await getDatabase();
  return db.getAllAsync<ProductRow>('SELECT * FROM products ORDER BY code');
}

export async function getProductById(id: string): Promise<ProductRow | null> {
  const db = await getDatabase();
  return db.getFirstAsync<ProductRow>('SELECT * FROM products WHERE id = ?', id);
}

export async function searchProducts(query: string, limit = 20): Promise<ProductRow[]> {
  const db = await getDatabase();
  const q = `%${query}%`;
  return db.getAllAsync<ProductRow>(
    'SELECT * FROM products WHERE name LIKE ? OR code LIKE ? ORDER BY code LIMIT ?',
    q,
    q,
    limit,
  );
}

export type CreateProductBomLine = {
  material_id: string;
  quantity: number;
  unit: string;
};

export type CreateProductInput = {
  code: string;
  name: string;
  unit: string;
  description?: string;
  bom_lines: CreateProductBomLine[];
};

export async function createProductWithBom(input: CreateProductInput): Promise<string> {
  const code = input.code.trim();
  const name = input.name.trim();
  if (!code || !name) throw new Error('Product code and name are required');
  if (!input.unit.trim()) throw new Error('Unit is required');
  if (input.bom_lines.length === 0) {
    throw new Error('Add at least one material to the BOM');
  }
  for (const line of input.bom_lines) {
    if (!Number.isFinite(line.quantity) || line.quantity <= 0) {
      throw new Error('Each BOM quantity must be greater than zero');
    }
  }

  const db = await getDatabase();
  const productId = newId();
  const bomId = newId();
  const now = Date.now();

  const existing = await db.getFirstAsync<{ id: string }>(
    'SELECT id FROM products WHERE code = ?',
    code,
  );
  if (existing) throw new Error(`Product code ${code} already exists`);

  await db.withTransactionAsync(async () => {
    await db.runAsync(
      `INSERT INTO products (id, code, name, category_id, unit, description, created_at)
       VALUES (?, ?, ?, NULL, ?, ?, ?)`,
      productId,
      code,
      name,
      input.unit.trim(),
      input.description?.trim() ?? null,
      now,
    );

    await db.runAsync(
      'INSERT INTO bom (id, product_id, version, is_active, created_at) VALUES (?, ?, ?, 1, ?)',
      bomId,
      productId,
      'v1',
      now,
    );

    for (const line of input.bom_lines) {
      await db.runAsync(
        'INSERT INTO bom_items (id, bom_id, material_id, quantity, unit) VALUES (?, ?, ?, ?, ?)',
        newId(),
        bomId,
        line.material_id,
        line.quantity,
        line.unit,
      );
    }

    await db.runAsync(
      `INSERT INTO finished_goods (
        id, product_id, produced_quantity, quality_passed_quantity,
        rejected_quantity, rework_quantity, available_quantity, updated_at
      ) VALUES (?, ?, 0, 0, 0, 0, 0, ?)`,
      newId(),
      productId,
      now,
    );

    await insertActivity(
      {
        event_type: 'PRODUCT_CREATED',
        title: `Product created: ${code}`,
        description: `${input.bom_lines.length} material(s) on BOM`,
        reference_type: 'product',
        reference_id: productId,
      },
      db,
    );
  });

  notifyDataChanged();
  return productId;
}

export type UpdateProductInput = {
  product_id: string;
  code: string;
  name: string;
  unit: string;
  description?: string;
  bom_lines: CreateProductBomLine[];
};

export async function updateProductWithBom(input: UpdateProductInput): Promise<void> {
  const code = input.code.trim();
  const name = input.name.trim();
  if (!code || !name) throw new Error('Product code and name are required');
  if (!input.unit.trim()) throw new Error('Unit is required');
  if (input.bom_lines.length === 0) {
    throw new Error('Add at least one material to the BOM');
  }
  for (const line of input.bom_lines) {
    if (!Number.isFinite(line.quantity) || line.quantity <= 0) {
      throw new Error('Each BOM quantity must be greater than zero');
    }
  }

  const db = await getDatabase();
  const existing = await getProductById(input.product_id);
  if (!existing) throw new Error('Product not found');

  const codeTaken = await db.getFirstAsync<{ id: string }>(
    'SELECT id FROM products WHERE code = ? AND id != ?',
    code,
    input.product_id,
  );
  if (codeTaken) throw new Error(`Product code ${code} already exists`);

  const now = Date.now();

  await db.withTransactionAsync(async () => {
    await db.runAsync(
      `UPDATE products SET code = ?, name = ?, unit = ?, description = ? WHERE id = ?`,
      code,
      name,
      input.unit.trim(),
      input.description?.trim() ?? null,
      input.product_id,
    );

    let bom = await db.getFirstAsync<{ id: string }>(
      'SELECT id FROM bom WHERE product_id = ? AND is_active = 1 LIMIT 1',
      input.product_id,
    );

    let bomId = bom?.id;
    if (!bomId) {
      bomId = newId();
      await db.runAsync(
        'INSERT INTO bom (id, product_id, version, is_active, created_at) VALUES (?, ?, ?, 1, ?)',
        bomId,
        input.product_id,
        'v1',
        now,
      );
    }

    await db.runAsync('DELETE FROM bom_items WHERE bom_id = ?', bomId);

    for (const line of input.bom_lines) {
      await db.runAsync(
        'INSERT INTO bom_items (id, bom_id, material_id, quantity, unit) VALUES (?, ?, ?, ?, ?)',
        newId(),
        bomId,
        line.material_id,
        line.quantity,
        line.unit,
      );
    }

    await insertActivity(
      {
        event_type: 'PRODUCT_UPDATED',
        title: `Product updated: ${code}`,
        description: `${input.bom_lines.length} material(s) on BOM`,
        reference_type: 'product',
        reference_id: input.product_id,
      },
      db,
    );
  });

  notifyDataChanged();
}

export async function deleteProduct(productId: string): Promise<void> {
  const db = await getDatabase();
  // Check if product has active production orders
  const activeOrders = await db.getFirstAsync<{ count: number }>(
    `SELECT COUNT(*) as count FROM production_orders WHERE product_id = ? AND status IN ('PENDING', 'IN_PROGRESS')`,
    productId,
  );
  if (activeOrders && activeOrders.count > 0) {
    throw new Error(
      `Cannot delete: product is used in ${activeOrders.count} active or in-progress order(s).`,
    );
  }

  await db.withTransactionAsync(async () => {
    // Delete from bom_items
    await db.runAsync(
      `DELETE FROM bom_items WHERE bom_id IN (SELECT id FROM bom WHERE product_id = ?)`,
      productId,
    );
    // Delete from bom
    await db.runAsync(`DELETE FROM bom WHERE product_id = ?`, productId);
    // Delete from finished_goods
    await db.runAsync(`DELETE FROM finished_goods WHERE product_id = ?`, productId);
    // Delete product
    await db.runAsync(`DELETE FROM products WHERE id = ?`, productId);

    await insertActivity(
      {
        event_type: 'PRODUCT_DELETED',
        title: `Product deleted: ${productId}`,
        description: 'Product removed from system',
        reference_type: 'product',
        reference_id: productId,
      },
      db,
    );
  });

  notifyDataChanged();
}

