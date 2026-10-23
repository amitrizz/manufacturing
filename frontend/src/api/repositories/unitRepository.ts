import { mongoApi } from '../client';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import type { UnitRow } from '../../types/database';

export const DEFAULT_APP_UNITS: UnitRow[] = [
  // Count
  { id: 'unit-pcs', code: 'PCS', name: 'Pieces', symbol: 'pcs', category: 'count', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-nos', code: 'NOS', name: 'Numbers', symbol: 'nos', category: 'count', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-set', code: 'SET', name: 'Set', symbol: 'set', category: 'count', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-pair', code: 'PAIR', name: 'Pair', symbol: 'pair', category: 'count', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-dozen', code: 'DOZEN', name: 'Dozen', symbol: 'dz', category: 'count', is_custom: 0, created_at: 0, updated_at: 0 },

  // Weight
  { id: 'unit-kg', code: 'KG', name: 'Kilogram', symbol: 'kg', category: 'weight', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-g', code: 'G', name: 'Gram', symbol: 'g', category: 'weight', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-ton', code: 'TON', name: 'Metric Ton', symbol: 't', category: 'weight', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-mg', code: 'MG', name: 'Milligram', symbol: 'mg', category: 'weight', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-lb', code: 'LB', name: 'Pound', symbol: 'lb', category: 'weight', is_custom: 0, created_at: 0, updated_at: 0 },

  // Volume
  { id: 'unit-l', code: 'L', name: 'Liter', symbol: 'L', category: 'volume', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-ml', code: 'ML', name: 'Milliliter', symbol: 'mL', category: 'volume', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-kl', code: 'KL', name: 'Kiloliter', symbol: 'kL', category: 'volume', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-gal', code: 'GAL', name: 'Gallon', symbol: 'gal', category: 'volume', is_custom: 0, created_at: 0, updated_at: 0 },

  // Length
  { id: 'unit-m', code: 'M', name: 'Meter', symbol: 'm', category: 'length', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-mm', code: 'MM', name: 'Millimeter', symbol: 'mm', category: 'length', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-cm', code: 'CM', name: 'Centimeter', symbol: 'cm', category: 'length', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-inch', code: 'INCH', name: 'Inch', symbol: 'in', category: 'length', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-ft', code: 'FT', name: 'Feet', symbol: 'ft', category: 'length', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-yd', code: 'YD', name: 'Yard', symbol: 'yd', category: 'length', is_custom: 0, created_at: 0, updated_at: 0 },

  // Area
  { id: 'unit-sqm', code: 'SQM', name: 'Square Meter', symbol: 'm²', category: 'area', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-sqft', code: 'SQFT', name: 'Square Feet', symbol: 'sq ft', category: 'area', is_custom: 0, created_at: 0, updated_at: 0 },

  // Packaging
  { id: 'unit-box', code: 'BOX', name: 'Box', symbol: 'box', category: 'packaging', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-roll', code: 'ROLL', name: 'Roll', symbol: 'roll', category: 'packaging', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-bag', code: 'BAG', name: 'Bag', symbol: 'bag', category: 'packaging', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-bundle', code: 'BUNDLE', name: 'Bundle', symbol: 'bdl', category: 'packaging', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-drum', code: 'DRUM', name: 'Drum', symbol: 'drum', category: 'packaging', is_custom: 0, created_at: 0, updated_at: 0 },
  { id: 'unit-can', code: 'CAN', name: 'Can', symbol: 'can', category: 'packaging', is_custom: 0, created_at: 0, updated_at: 0 },
];

export async function listUnits(): Promise<UnitRow[]> {
  try {
    const list = await mongoApi.getCollection<UnitRow>('units');
    if (list && Array.isArray(list) && list.length > 0) {
      return list;
    }
  } catch (err) {
    console.warn('Could not fetch units from MongoDB API, using defaults:', err);
  }
  return DEFAULT_APP_UNITS;
}

export async function getUnitByCode(code: string): Promise<UnitRow | null> {
  const all = await listUnits();
  return all.find((u) => u.code.toUpperCase() === code.toUpperCase()) || null;
}

export async function createUnit(input: {
  code: string;
  name: string;
  symbol: string;
  category: UnitRow['category'];
  description?: string;
  precision?: number;
  is_active?: boolean;
}): Promise<UnitRow> {
  const code = input.code.trim().toUpperCase();
  const name = input.name.trim();
  const symbol = input.symbol.trim();
  const category = input.category || 'count';

  if (!code || !name) throw new Error('Unit code and name are required');

  const now = Date.now();
  const id = `unit-${code.toLowerCase().replace(/[^a-z0-9]/g, '-')}`;

  const created = await mongoApi.insert<UnitRow>('units', {
    id,
    code,
    name,
    symbol,
    category,
    is_custom: 1,
    description: input.description || null,
    created_at: now,
    updated_at: now,
  });

  notifyDataChanged();
  return created;
}
