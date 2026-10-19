import { newId } from '../../utils/id';
import type { SeedContext } from './seedContext';

const CATEGORIES = ['Valve Assemblies', 'Pump Components', 'Industrial Fittings'];

const PRODUCTS_DEFS = [
  { code: 'P-100', name: 'Ball Valve Assembly 2"', unit: 'pcs', cat: 0 },
  { code: 'P-101', name: 'Gate Valve Body 4"', unit: 'pcs', cat: 0 },
  { code: 'P-102', name: 'Centrifugal Pump Impeller', unit: 'pcs', cat: 1 },
  { code: 'P-103', name: 'Mechanical Seal Kit', unit: 'kits', cat: 1 },
  { code: 'P-104', name: 'Flanged Coupling 3"', unit: 'pcs', cat: 2 },
  { code: 'P-105', name: 'Pressure Gauge Manifold', unit: 'pcs', cat: 2 },
];

export async function seedProducts(ctx: SeedContext): Promise<void> {
  const { db, now } = ctx;
  const categoryIds: string[] = [];

  for (const name of CATEGORIES) {
    const id = newId();
    categoryIds.push(id);
    await db.runAsync(
      'INSERT INTO product_categories (id, name) VALUES (?, ?)',
      id,
      name,
    );
  }

  for (const p of PRODUCTS_DEFS) {
    const id = newId();
    ctx.productIds.push(id);
    await db.runAsync(
      `INSERT INTO products (id, code, name, category_id, unit, description, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      id,
      p.code,
      p.name,
      categoryIds[p.cat],
      p.unit,
      `Seeded product ${p.code}`,
      now,
    );
  }
}
