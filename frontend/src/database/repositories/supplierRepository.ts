import { mongoApi } from '../../api/client';
import type { SupplierRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { getDatabase } from '../client';
import { insertActivity } from './activityRepository';

export async function listSuppliers(search?: string): Promise<SupplierRow[]> {
  try {
    const list = await mongoApi.getCollection<SupplierRow>('suppliers');
    if (list && Array.isArray(list) && list.length > 0) {
      if (search && search.trim()) {
        const q = search.trim().toLowerCase();
        return list.filter(
          (s) =>
            s.name?.toLowerCase().includes(q) ||
            s.contact_person?.toLowerCase().includes(q) ||
            s.phone?.toLowerCase().includes(q),
        );
      }
      return list;
    }
  } catch (apiErr) {
    console.warn('MongoDB API suppliers error, using fallback:', apiErr instanceof Error ? apiErr.message : apiErr);
  }

  const db = await getDatabase();
  if (search && search.trim()) {
    const q = `%${search.trim()}%`;
    return db.getAllAsync<SupplierRow>(
      'SELECT * FROM suppliers WHERE name LIKE ? OR contact_person LIKE ? OR phone LIKE ? ORDER BY name ASC',
      q,
      q,
      q,
    );
  }
  return db.getAllAsync<SupplierRow>('SELECT * FROM suppliers ORDER BY name ASC');
}

export async function getSupplierById(id: string): Promise<SupplierRow | null> {
  try {
    const item = await mongoApi.getById<SupplierRow>('suppliers', id);
    if (item) return item;
  } catch {
    // fallback
  }
  const db = await getDatabase();
  return db.getFirstAsync<SupplierRow>('SELECT * FROM suppliers WHERE id = ?', id);
}

export type CreateSupplierInput = {
  name: string;
  contact_person?: string;
  phone?: string;
  email?: string;
  address?: string;
  gst_number?: string;
  supplied_items?: string;
  rating?: number;
  notes?: string;
};

export async function createSupplier(input: CreateSupplierInput): Promise<string> {
  const id = newId();
  const now = Date.now();
  const db = await getDatabase();

  await db.runAsync(
    `INSERT INTO suppliers (
      id, name, contact_person, phone, email, address, gst_number, supplied_items, rating, notes, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    id,
    input.name.trim(),
    input.contact_person?.trim() || null,
    input.phone?.trim() || null,
    input.email?.trim() || null,
    input.address?.trim() || null,
    input.gst_number?.trim() || null,
    input.supplied_items?.trim() || null,
    input.rating ?? 5.0,
    input.notes?.trim() || null,
    now,
    now,
  );

  await insertActivity({
    event_type: 'SUPPLIER_CREATED',
    title: `Supplier created: ${input.name}`,
    description: `Vendor ${input.contact_person ? `(${input.contact_person})` : ''}`,
    reference_type: 'SUPPLIER',
    reference_id: id,
  });

  notifyDataChanged();
  return id;
}

export async function updateSupplier(
  id: string,
  input: Partial<CreateSupplierInput>,
): Promise<void> {
  const db = await getDatabase();
  const existing = await getSupplierById(id);
  if (!existing) throw new Error('Supplier not found');

  const now = Date.now();
  await db.runAsync(
    `UPDATE suppliers SET
      name = ?, contact_person = ?, phone = ?, email = ?,
      address = ?, gst_number = ?, supplied_items = ?, rating = ?, notes = ?, updated_at = ?
     WHERE id = ?`,
    input.name?.trim() ?? existing.name,
    input.contact_person?.trim() ?? existing.contact_person ?? null,
    input.phone?.trim() ?? existing.phone ?? null,
    input.email?.trim() ?? existing.email ?? null,
    input.address?.trim() ?? existing.address ?? null,
    input.gst_number?.trim() ?? existing.gst_number ?? null,
    input.supplied_items?.trim() ?? existing.supplied_items ?? null,
    input.rating ?? existing.rating,
    input.notes?.trim() ?? existing.notes ?? null,
    now,
    id,
  );

  notifyDataChanged();
}

export async function deleteSupplier(id: string): Promise<void> {
  const db = await getDatabase();
  const existing = await getSupplierById(id);
  if (!existing) throw new Error('Supplier not found');

  await db.withTransactionAsync(async () => {
    // Check if there are active purchase orders referencing this supplier
    const activePo = await db.getFirstAsync<{ po_number: string }>(
      "SELECT po_number FROM purchase_orders WHERE supplier_id = ? AND status IN ('DRAFT', 'ISSUED', 'PARTIALLY_RECEIVED')",
      id,
    );
    if (activePo) {
      throw new Error(`Cannot delete supplier with active purchase order (${activePo.po_number}).`);
    }

    await db.runAsync('DELETE FROM suppliers WHERE id = ?', id);
    await insertActivity({
      event_type: 'SUPPLIER_DELETED',
      title: `Supplier deleted: ${existing.name}`,
      description: `Vendor record removed`,
      reference_type: 'SUPPLIER',
      reference_id: id,
    });
  });

  notifyDataChanged();
}
