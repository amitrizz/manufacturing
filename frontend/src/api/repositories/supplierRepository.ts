import { mongoApi } from '../client';
import type { SupplierRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { insertActivity } from './activityRepository';

export async function listSuppliers(search?: string): Promise<SupplierRow[]> {
  try {
    const list = await mongoApi.getCollection<SupplierRow>('suppliers');
    if (list && Array.isArray(list)) {
      let result = list.map((s) => ({ ...s, id: s.id || (s as any)._id }));
      if (search && search.trim()) {
        const q = search.trim().toLowerCase();
        result = result.filter(
          (s) =>
            s.name?.toLowerCase().includes(q) ||
            s.contact_person?.toLowerCase().includes(q) ||
            s.phone?.toLowerCase().includes(q),
        );
      }
      return result.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    }
  } catch (err) {
    console.warn('MongoDB listSuppliers error:', err);
  }
  return [];
}

export async function getSupplierById(id: string): Promise<SupplierRow | null> {
  try {
    const item = await mongoApi.getById<SupplierRow>('suppliers', id);
    if (item) return { ...item, id: item.id || (item as any)._id };
  } catch {
    const all = await listSuppliers();
    return all.find((s) => s.id === id || (s as any)._id === id) || null;
  }
  return null;
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
  company_id?: string;
};

export async function createSupplier(input: CreateSupplierInput): Promise<string> {
  const id = newId();
  const now = Date.now();

  const doc: any = {
    id,
    name: input.name.trim(),
    contact_person: input.contact_person?.trim() || null,
    phone: input.phone?.trim() || null,
    email: input.email?.trim() || null,
    address: input.address?.trim() || null,
    gst_number: input.gst_number?.trim() || null,
    supplied_items: input.supplied_items?.trim() || null,
    rating: input.rating ?? 5.0,
    notes: input.notes?.trim() || null,
    created_at: now,
    updated_at: now,
  };
  if (input.company_id) {
    doc.company_id = input.company_id;
  }

  await mongoApi.insert('suppliers', { ...doc, _id: id });

  await insertActivity({
    event_type: 'SUPPLIER_CREATED',
    title: `Supplier created: ${input.name}`,
    description: `Vendor ${input.contact_person ? `(${input.contact_person})` : ''}`,
    reference_type: 'SUPPLIER',
    reference_id: id,
  }).catch(() => {});

  notifyDataChanged();
  return id;
}

export async function updateSupplier(
  id: string,
  input: Partial<CreateSupplierInput>,
): Promise<void> {
  const now = Date.now();
  const updates: Record<string, unknown> = { updated_at: now };
  if (input.name !== undefined) updates.name = input.name.trim();
  if (input.contact_person !== undefined) updates.contact_person = input.contact_person.trim();
  if (input.phone !== undefined) updates.phone = input.phone.trim();
  if (input.email !== undefined) updates.email = input.email.trim();
  if (input.address !== undefined) updates.address = input.address.trim();
  if (input.gst_number !== undefined) updates.gst_number = input.gst_number.trim();
  if (input.supplied_items !== undefined) updates.supplied_items = input.supplied_items.trim();
  if (input.rating !== undefined) updates.rating = input.rating;
  if (input.notes !== undefined) updates.notes = input.notes.trim();

  await mongoApi.update('suppliers', id, updates);
  notifyDataChanged();
}

export async function deleteSupplier(id: string): Promise<void> {
  await mongoApi.delete('suppliers', id);
  notifyDataChanged();
}
