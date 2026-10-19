import { newId } from '../../utils/id';
import type { SeedContext } from './seedContext';

type MatDef = {
  code: string;
  name: string;
  category: 'RAW_MATERIAL' | 'COMPONENT' | 'CONSUMABLE' | 'PACKAGING' | 'SPARE_PART';
  unit: string;
  stock: number;
  min: number;
  max: number;
  forceLow?: boolean;
};

const MATERIALS: MatDef[] = [
  { code: 'RM-STEEL-45', name: 'Carbon Steel Bar 45mm', category: 'RAW_MATERIAL', unit: 'kg', stock: 4200, min: 800, max: 6000 },
  { code: 'RM-BRASS-ROD', name: 'Brass Rod 25mm', category: 'RAW_MATERIAL', unit: 'kg', stock: 180, min: 250, max: 2000, forceLow: true },
  { code: 'RM-RUBBER-NBR', name: 'NBR Rubber Sheet', category: 'RAW_MATERIAL', unit: 'sqm', stock: 95, min: 120, max: 500, forceLow: true },
  { code: 'CP-BALL-SS', name: 'Stainless Ball 50mm', category: 'COMPONENT', unit: 'pcs', stock: 2400, min: 400, max: 5000 },
  { code: 'CP-STEM-ASSY', name: 'Valve Stem Assembly', category: 'COMPONENT', unit: 'pcs', stock: 890, min: 200, max: 2500 },
  { code: 'CP-SEAL-RING', name: 'PTFE Seal Ring', category: 'COMPONENT', unit: 'pcs', stock: 45, min: 150, max: 3000, forceLow: true },
  { code: 'CS-WELD-WIRE', name: 'MIG Welding Wire', category: 'CONSUMABLE', unit: 'kg', stock: 320, min: 80, max: 600 },
  { code: 'CS-COOLANT', name: 'Cutting Coolant', category: 'CONSUMABLE', unit: 'L', stock: 540, min: 100, max: 800 },
  { code: 'PK-CRATE-STD', name: 'Export Wooden Crate', category: 'PACKAGING', unit: 'pcs', stock: 210, min: 50, max: 400 },
  { code: 'PK-LABEL-HAZ', name: 'Hazmat Label Roll', category: 'PACKAGING', unit: 'rolls', stock: 38, min: 20, max: 100 },
  { code: 'SP-BEARING-6205', name: 'Bearing 6205-2RS', category: 'SPARE_PART', unit: 'pcs', stock: 64, min: 30, max: 200 },
  { code: 'SP-V-BELT-A68', name: 'V-Belt A68', category: 'SPARE_PART', unit: 'pcs', stock: 22, min: 15, max: 80 },
  { code: 'RM-CAST-IRON', name: 'Cast Iron Ingot', category: 'RAW_MATERIAL', unit: 'kg', stock: 3100, min: 600, max: 5000 },
];

export async function seedMaterials(ctx: SeedContext): Promise<void> {
  const { db, now } = ctx;
  ctx.lowStockMaterialIds = [];

  for (const m of MATERIALS) {
    const id = newId();
    ctx.materialIds.push(id);
    if (m.forceLow) {
      ctx.lowStockMaterialIds.push(id);
    }
    await db.runAsync(
      `INSERT INTO materials (id, code, name, category, unit, current_stock, minimum_stock, maximum_stock, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      id,
      m.code,
      m.name,
      m.category,
      m.unit,
      m.stock,
      m.min,
      m.max,
      now,
    );
  }
}
