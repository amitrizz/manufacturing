import { newId } from '../../utils/id';
import type { SeedContext } from './seedContext';

/** BOM quantities per unit of product (P-100 pattern extrapolated). */
const BOM_BY_PRODUCT_INDEX: { materialIndex: number; qty: number; unit: string }[][] = [
  [
    { materialIndex: 0, qty: 12.5, unit: 'kg' },
    { materialIndex: 3, qty: 1, unit: 'pcs' },
    { materialIndex: 4, qty: 1, unit: 'pcs' },
    { materialIndex: 5, qty: 2, unit: 'pcs' },
    { materialIndex: 8, qty: 0.2, unit: 'pcs' },
  ],
  [
    { materialIndex: 12, qty: 18, unit: 'kg' },
    { materialIndex: 4, qty: 1, unit: 'pcs' },
    { materialIndex: 5, qty: 3, unit: 'pcs' },
    { materialIndex: 8, qty: 0.25, unit: 'pcs' },
  ],
  [
    { materialIndex: 0, qty: 8, unit: 'kg' },
    { materialIndex: 3, qty: 1, unit: 'pcs' },
    { materialIndex: 6, qty: 0.4, unit: 'kg' },
  ],
  [
    { materialIndex: 2, qty: 0.15, unit: 'sqm' },
    { materialIndex: 5, qty: 4, unit: 'pcs' },
    { materialIndex: 7, qty: 0.5, unit: 'L' },
  ],
  [
    { materialIndex: 1, qty: 2.2, unit: 'kg' },
    { materialIndex: 0, qty: 4, unit: 'kg' },
    { materialIndex: 6, qty: 0.25, unit: 'kg' },
  ],
  [
    { materialIndex: 1, qty: 1.5, unit: 'kg' },
    { materialIndex: 10, qty: 2, unit: 'pcs' },
    { materialIndex: 9, qty: 0.1, unit: 'rolls' },
  ],
];

export async function seedBom(ctx: SeedContext): Promise<void> {
  const { db, now, productIds, materialIds } = ctx;

  for (let i = 0; i < productIds.length; i++) {
    const bomId = newId();
    await db.runAsync(
      'INSERT INTO bom (id, product_id, version, is_active, created_at) VALUES (?, ?, ?, 1, ?)',
      bomId,
      productIds[i],
      'v1',
      now,
    );

    const items = BOM_BY_PRODUCT_INDEX[i] ?? BOM_BY_PRODUCT_INDEX[0];
    for (const item of items) {
      await db.runAsync(
        'INSERT INTO bom_items (id, bom_id, material_id, quantity, unit) VALUES (?, ?, ?, ?, ?)',
        newId(),
        bomId,
        materialIds[item.materialIndex],
        item.qty,
        item.unit,
      );
    }
  }
}
