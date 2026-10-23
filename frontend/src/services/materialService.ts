import { mongoApi } from '../api/client';
import { notifyDataChanged } from '../store/dataRefreshStore';
import { getMaterialById } from '../api/repositories/materialRepository';

export class MaterialStockError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'MaterialStockError';
  }
}

async function changeStock(
  materialId: string,
  delta: number,
  activity: { event_type: string; title: string; description: string },
): Promise<void> {
  if (!Number.isFinite(delta) || delta === 0) {
    throw new MaterialStockError('Enter a valid quantity');
  }

  const now = Date.now();
  const material = await getMaterialById(materialId);
  if (!material) throw new MaterialStockError('Material not found');

  const next = (material.current_stock || 0) + delta;
  if (next < 0) {
    throw new MaterialStockError(
      `Not enough stock (have ${material.current_stock || 0} ${material.unit || 'units'})`,
    );
  }

  await mongoApi.update('materials', materialId, {
    current_stock: next,
    updated_at: now,
  });

  await mongoApi
    .insert('activity_history', {
      event_type: activity.event_type,
      title: activity.title,
      description: activity.description,
      reference_type: 'material',
      reference_id: materialId,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
}

export async function receiveMaterialStock(
  materialId: string,
  quantity: number,
  notes?: string,
): Promise<void> {
  if (quantity <= 0) throw new MaterialStockError('Receive quantity must be positive');
  const m = await getMaterialById(materialId);
  if (!m) throw new MaterialStockError('Material not found');
  const note = notes?.trim();
  await changeStock(materialId, quantity, {
    event_type: 'MATERIAL_RECEIVED',
    title: `Received ${m.code}`,
    description: note
      ? `+${quantity} ${m.unit} — ${note}`
      : `+${quantity} ${m.unit}`,
  });
}

export async function issueMaterialStock(
  materialId: string,
  quantity: number,
  notes?: string,
): Promise<void> {
  if (quantity <= 0) throw new MaterialStockError('Issue quantity must be positive');
  const m = await getMaterialById(materialId);
  if (!m) throw new MaterialStockError('Material not found');
  const note = notes?.trim();
  await changeStock(materialId, -quantity, {
    event_type: 'MATERIAL_ISSUED',
    title: `Issued ${m.code}`,
    description: note
      ? `-${quantity} ${m.unit} — ${note}`
      : `-${quantity} ${m.unit}`,
  });
}

export async function adjustMaterialStock(
  materialId: string,
  quantityDelta: number,
  notes?: string,
): Promise<void> {
  const m = await getMaterialById(materialId);
  if (!m) throw new MaterialStockError('Material not found');
  const note = notes?.trim();
  const sign = quantityDelta > 0 ? '+' : '';
  await changeStock(materialId, quantityDelta, {
    event_type: 'MATERIAL_ADJUSTED',
    title: `Adjusted ${m.code}`,
    description: note
      ? `${sign}${quantityDelta} ${m.unit} — ${note}`
      : `${sign}${quantityDelta} ${m.unit}`,
  });
}

export async function updateMaterialMinimumStock(
  materialId: string,
  minimumStock: number,
): Promise<void> {
  if (minimumStock < 0 || !Number.isFinite(minimumStock)) {
    throw new MaterialStockError('Minimum stock must be zero or greater');
  }
  const now = Date.now();
  const m = await getMaterialById(materialId);
  if (!m) throw new MaterialStockError('Material not found');

  await mongoApi.update('materials', materialId, {
    minimum_stock: minimumStock,
    updated_at: now,
  });

  await mongoApi
    .insert('activity_history', {
      event_type: 'MATERIAL_MIN_UPDATED',
      title: `Min stock updated: ${m.code}`,
      description: `Minimum set to ${minimumStock} ${m.unit}`,
      reference_type: 'material',
      reference_id: materialId,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
}
