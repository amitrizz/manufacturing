import type { CustomerRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { mongoApi } from '../../api/client';

export async function listCustomers(search?: string): Promise<CustomerRow[]> {
  try {
    const list = await mongoApi.getCollection<CustomerRow>('customers');
    if (list && Array.isArray(list)) {
      if (search && search.trim()) {
        const q = search.trim().toLowerCase();
        return list.filter(
          (c) =>
            c.name?.toLowerCase().includes(q) ||
            c.company?.toLowerCase().includes(q) ||
            c.phone?.toLowerCase().includes(q)
        );
      }
      return list.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    }
  } catch (err) {
    console.warn('MongoDB listCustomers error:', err);
  }
  return [];
}

export async function getCustomerById(id: string): Promise<CustomerRow | null> {
  try {
    return await mongoApi.getById<CustomerRow>('customers', id);
  } catch {
    const all = await listCustomers();
    return all.find((c) => c.id === id || (c as any)._id === id) || null;
  }
}

export type CreateCustomerInput = {
  name: string;
  company: string;
  phone?: string;
  email?: string;
  billing_address?: string;
  delivery_address?: string;
  gst_number?: string;
  notes?: string;
};

export async function createCustomer(input: CreateCustomerInput): Promise<string> {
  const id = newId();
  const now = Date.now();

  const doc = {
    _id: id,
    id,
    name: input.name.trim(),
    company: input.company.trim(),
    phone: input.phone?.trim() || null,
    email: input.email?.trim() || null,
    billing_address: input.billing_address?.trim() || null,
    delivery_address: input.delivery_address?.trim() || null,
    gst_number: input.gst_number?.trim() || null,
    notes: input.notes?.trim() || null,
    created_at: now,
    updated_at: now,
  };

  await mongoApi.insert('customers', doc);

  await mongoApi
    .insert('activity_history', {
      event_type: 'CUSTOMER_CREATED',
      title: `Customer created: ${input.name}`,
      description: `${input.company}`,
      reference_type: 'CUSTOMER',
      reference_id: id,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
  return id;
}

export async function updateCustomer(
  id: string,
  input: Partial<CreateCustomerInput>,
): Promise<void> {
  const now = Date.now();
  await mongoApi.update('customers', id, {
    ...input,
    updated_at: now,
  });

  notifyDataChanged();
}

export async function deleteCustomer(id: string): Promise<void> {
  await mongoApi.delete('customers', id);

  await mongoApi
    .insert('activity_history', {
      event_type: 'CUSTOMER_DELETED',
      title: `Customer deleted: ${id}`,
      description: 'Customer removed',
      reference_type: 'CUSTOMER',
      reference_id: id,
      timestamp: Date.now(),
      created_at: Date.now(),
    })
    .catch(() => {});

  notifyDataChanged();
}
