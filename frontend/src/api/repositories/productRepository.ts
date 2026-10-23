import type { ProductRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { mongoApi } from '../client';

export async function listProducts(): Promise<ProductRow[]> {
  try {
    const list = await mongoApi.getCollection<ProductRow>('products');
    if (list && Array.isArray(list)) {
      return list
        .map((p) => ({ ...p, id: p.id || (p as any)._id }))
        .sort((a, b) => (a.code || '').localeCompare(b.code || ''));
    }
  } catch (err) {
    console.warn('MongoDB listProducts error:', err);
  }
  return [];
}

export async function getProductById(id: string): Promise<ProductRow | null> {
  try {
    const p = await mongoApi.getById<ProductRow>('products', id);
    if (p) return { ...p, id: p.id || (p as any)._id };
  } catch {
    const all = await listProducts();
    return all.find((p) => p.id === id || (p as any)._id === id) || null;
  }
  return null;
}

export async function searchProducts(query: string, limit = 20): Promise<ProductRow[]> {
  const all = await listProducts();
  const q = query.toLowerCase();
  return all
    .filter((p) => p.name?.toLowerCase().includes(q) || p.code?.toLowerCase().includes(q))
    .slice(0, limit);
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
  company_id?: string;
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

  const existingProducts = await listProducts();
  if (existingProducts.some((p) => p.code?.toUpperCase() === code.toUpperCase())) {
    throw new Error(`Product code ${code} already exists`);
  }

  const productId = newId();
  const bomId = newId();
  const now = Date.now();
  const compIdProp = input.company_id ? { company_id: input.company_id } : {};

  await mongoApi.insert('products', {
    _id: productId,
    id: productId,
    code,
    name,
    category_id: null,
    unit: input.unit.trim(),
    description: input.description?.trim() ?? null,
    ...compIdProp,
    created_at: now,
    updated_at: now,
  });

  await mongoApi.insert('bom', {
    _id: bomId,
    id: bomId,
    product_id: productId,
    version: 'v1',
    is_active: 1,
    ...compIdProp,
    created_at: now,
  });

  for (const line of input.bom_lines) {
    const itemId = newId();
    await mongoApi.insert('bom_items', {
      _id: itemId,
      id: itemId,
      bom_id: bomId,
      material_id: line.material_id,
      quantity: line.quantity,
      unit: line.unit,
      ...compIdProp,
    });
  }

  await mongoApi.insert('finished_goods', {
    _id: newId(),
    id: newId(),
    product_id: productId,
    produced_quantity: 0,
    quality_passed_quantity: 0,
    rejected_quantity: 0,
    rework_quantity: 0,
    available_quantity: 0,
    ...compIdProp,
    updated_at: now,
  });

  await mongoApi
    .insert('activity_history', {
      event_type: 'PRODUCT_CREATED',
      title: `Product created: ${code}`,
      description: `${input.bom_lines.length} material(s) on BOM`,
      reference_type: 'product',
      reference_id: productId,
      ...compIdProp,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

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

  const existingProducts = await listProducts();
  if (
    existingProducts.some(
      (p) =>
        p.code?.toUpperCase() === code.toUpperCase() &&
        p.id !== input.product_id &&
        (p as any)._id !== input.product_id
    )
  ) {
    throw new Error(`Product code ${code} already exists`);
  }

  const now = Date.now();

  await mongoApi.update('products', input.product_id, {
    code,
    name,
    unit: input.unit.trim(),
    description: input.description?.trim() ?? null,
    updated_at: now,
  });

  const allBoms = await mongoApi.getCollection<any>('bom').catch(() => []);
  let bom = allBoms.find(
    (b) => b.product_id === input.product_id && (b.is_active === 1 || b.is_active === true)
  );
  let bomId = bom?.id || bom?._id;
  if (!bomId) {
    bomId = newId();
    await mongoApi.insert('bom', {
      _id: bomId,
      id: bomId,
      product_id: input.product_id,
      version: 'v1',
      is_active: 1,
      created_at: now,
    });
  }

  const allBomItems = await mongoApi.getCollection<any>('bom_items', { bom_id: bomId }).catch(() => []);
  for (const item of allBomItems) {
    const itId = item.id || item._id;
    if (itId) await mongoApi.delete('bom_items', itId).catch(() => {});
  }

  for (const line of input.bom_lines) {
    const itemId = newId();
    await mongoApi.insert('bom_items', {
      _id: itemId,
      id: itemId,
      bom_id: bomId,
      material_id: line.material_id,
      quantity: line.quantity,
      unit: line.unit,
    });
  }

  await mongoApi
    .insert('activity_history', {
      event_type: 'PRODUCT_UPDATED',
      title: `Product updated: ${code}`,
      description: `${input.bom_lines.length} material(s) on BOM`,
      reference_type: 'product',
      reference_id: input.product_id,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
}

export async function deleteProduct(productId: string): Promise<void> {
  const activeOrders = await mongoApi.listProductionOrders();
  const usingOrders = activeOrders.filter(
    (o) =>
      o.product_id === productId &&
      (o.status === 'PENDING' || o.status === 'IN_PROGRESS')
  );
  if (usingOrders.length > 0) {
    throw new Error(
      `Cannot delete: product is used in ${usingOrders.length} active or in-progress order(s).`
    );
  }

  await mongoApi.delete('products', productId);

  await mongoApi
    .insert('activity_history', {
      event_type: 'PRODUCT_DELETED',
      title: `Product deleted: ${productId}`,
      description: 'Product removed from system',
      reference_type: 'product',
      reference_id: productId,
      timestamp: Date.now(),
      created_at: Date.now(),
    })
    .catch(() => {});

  notifyDataChanged();
}
