import { mongoApi } from '../client';
import type { BomItemRow, MaterialRow } from '../../types/database';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { newId } from '../../utils/id';

export type MaterialFilters = {
  search?: string;
  category?: string;
  lowStockOnly?: boolean;
};

export async function listMaterials(filters: MaterialFilters = {}): Promise<MaterialRow[]> {
  try {
    const list = await mongoApi.getCollection<MaterialRow>('materials');
    if (list && Array.isArray(list)) {
      let result = list.map((m) => ({
        ...m,
        id: m.id || (m as any)._id,
      }));
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
      return result.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    }
  } catch (err) {
    console.warn('MongoDB listMaterials error:', err);
  }
  return [];
}

export async function getMaterialById(id: string): Promise<MaterialRow | null> {
  try {
    const mat = await mongoApi.getById<MaterialRow>('materials', id);
    if (mat) return { ...mat, id: mat.id || (mat as any)._id };
  } catch {
    const all = await listMaterials();
    return all.find((m) => m.id === id || (m as any)._id === id) || null;
  }
  return null;
}

export async function getBomForProduct(productId: string): Promise<BomItemRow[]> {
  try {
    const [boms, bomItems, materials] = await Promise.all([
      mongoApi.getCollection<any>('bom'),
      mongoApi.getCollection<any>('bom_items'),
      mongoApi.getCollection<any>('materials'),
    ]);

    const activeBom = boms.find((b) => b.product_id === productId && (b.is_active === 1 || b.is_active === true));
    if (!activeBom) return [];

    const relevantBomItems = bomItems.filter(
      (bi) => bi.bom_id === activeBom.id || bi.bom_id === activeBom._id
    );
    const matMap = new Map(materials.map((m) => [m.id || m._id, m]));

    return relevantBomItems.map((bi) => {
      const m = matMap.get(bi.material_id);
      return {
        id: bi.id || bi._id,
        bom_id: activeBom.id || activeBom._id,
        material_id: bi.material_id,
        material_code: m?.code || '',
        material_name: m?.name || '',
        quantity: Number(bi.quantity ?? 1),
        unit: bi.unit || m?.unit || 'units',
      };
    });
  } catch (err) {
    console.warn('getBomForProduct error:', err);
    return [];
  }
}

export type ProductBomGroup = {
  product_id: string;
  product_code: string;
  product_name: string;
  items: BomItemRow[];
};

export async function listAllProductBoms(): Promise<ProductBomGroup[]> {
  try {
    const products = await mongoApi.getCollection<any>('products');
    const result: ProductBomGroup[] = [];
    for (const p of products) {
      const pId = p.id || p._id;
      const items = await getBomForProduct(pId);
      result.push({
        product_id: pId,
        product_code: p.code || '',
        product_name: p.name || '',
        items,
      });
    }
    return result;
  } catch (err) {
    console.warn('listAllProductBoms error:', err);
    return [];
  }
}

export async function searchMaterials(query: string, limit = 20): Promise<MaterialRow[]> {
  const all = await listMaterials();
  const q = query.toLowerCase();
  return all
    .filter((m) => m.name?.toLowerCase().includes(q) || m.code?.toLowerCase().includes(q))
    .slice(0, limit);
}

export async function deleteMaterial(id: string): Promise<void> {
  const bomItems = await mongoApi.getCollection<any>('bom_items').catch(() => []);
  const usage = bomItems.filter((bi) => bi.material_id === id);
  if (usage.length > 0) {
    throw new Error(
      `Cannot delete: this material is used in ${usage.length} product BOM line(s). Remove it from the BOM first.`
    );
  }

  await mongoApi.delete('materials', id);
  notifyDataChanged();
}

export async function updateMaterial(
  input: Omit<MaterialRow, 'current_stock' | 'updated_at'>,
): Promise<void> {
  const now = Date.now();
  await mongoApi.update('materials', input.id, {
    code: input.code.trim(),
    name: input.name.trim(),
    category: input.category.trim(),
    unit: input.unit.trim(),
    minimum_stock: input.minimum_stock,
    maximum_stock: input.maximum_stock,
    updated_at: now,
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
  company_id?: string;
};

export async function createMaterial(input: CreateMaterialInput): Promise<MaterialRow> {
  const id = newId();
  const now = Date.now();
  const cat = input.category?.trim() || 'RAW_MATERIAL';
  const unit = input.unit?.trim() || 'pcs';
  const stock = input.current_stock ?? 0;
  const min = input.minimum_stock ?? 0;
  const max = input.maximum_stock ?? 1000;

  const doc: any = {
    _id: id,
    id,
    code: input.code.trim().toUpperCase(),
    name: input.name.trim(),
    category: cat,
    unit,
    current_stock: stock,
    minimum_stock: min,
    maximum_stock: max,
    created_at: now,
    updated_at: now,
  };
  if (input.company_id) {
    doc.company_id = input.company_id;
  }

  await mongoApi.insert('materials', doc);
  notifyDataChanged();

  return {
    id,
    code: doc.code,
    name: doc.name,
    category: cat,
    unit,
    current_stock: stock,
    minimum_stock: min,
    maximum_stock: max,
    updated_at: now,
  };
}
