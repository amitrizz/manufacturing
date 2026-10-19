import type { CustomerRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { getDatabase } from '../client';
import { insertActivity } from './activityRepository';

export async function listCustomers(search?: string): Promise<CustomerRow[]> {
  const db = await getDatabase();
  if (search && search.trim()) {
    const q = `%${search.trim()}%`;
    return db.getAllAsync<CustomerRow>(
      'SELECT * FROM customers WHERE name LIKE ? OR company LIKE ? OR phone LIKE ? ORDER BY name ASC',
      q,
      q,
      q,
    );
  }
  return db.getAllAsync<CustomerRow>('SELECT * FROM customers ORDER BY name ASC');
}

export async function getCustomerById(id: string): Promise<CustomerRow | null> {
  const db = await getDatabase();
  return db.getFirstAsync<CustomerRow>('SELECT * FROM customers WHERE id = ?', id);
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
  const db = await getDatabase();

  await db.runAsync(
    `INSERT INTO customers (
      id, name, company, phone, email, billing_address, delivery_address, gst_number, notes, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    id,
    input.name.trim(),
    input.company.trim(),
    input.phone?.trim() || null,
    input.email?.trim() || null,
    input.billing_address?.trim() || null,
    input.delivery_address?.trim() || null,
    input.gst_number?.trim() || null,
    input.notes?.trim() || null,
    now,
    now,
  );

  await insertActivity({
    event_type: 'CUSTOMER_CREATED',
    title: `Customer created: ${input.name}`,
    description: `${input.company}`,
    reference_type: 'CUSTOMER',
    reference_id: id,
  });

  notifyDataChanged();
  return id;
}

export async function updateCustomer(
  id: string,
  input: Partial<CreateCustomerInput>,
): Promise<void> {
  const db = await getDatabase();
  const existing = await getCustomerById(id);
  if (!existing) throw new Error('Customer not found');

  const now = Date.now();
  await db.runAsync(
    `UPDATE customers SET
      name = ?, company = ?, phone = ?, email = ?,
      billing_address = ?, delivery_address = ?, gst_number = ?, notes = ?, updated_at = ?
     WHERE id = ?`,
    input.name?.trim() ?? existing.name,
    input.company?.trim() ?? existing.company,
    input.phone?.trim() ?? existing.phone ?? null,
    input.email?.trim() ?? existing.email ?? null,
    input.billing_address?.trim() ?? existing.billing_address ?? null,
    input.delivery_address?.trim() ?? existing.delivery_address ?? null,
    input.gst_number?.trim() ?? existing.gst_number ?? null,
    input.notes?.trim() ?? existing.notes ?? null,
    now,
    id,
  );

  notifyDataChanged();
}

export async function deleteCustomer(id: string): Promise<void> {
  const db = await getDatabase();
  const existing = await getCustomerById(id);
  if (!existing) throw new Error('Customer not found');

  await db.withTransactionAsync(async () => {
    await db.runAsync('DELETE FROM customers WHERE id = ?', id);
    await insertActivity({
      event_type: 'CUSTOMER_DELETED',
      title: `Customer deleted: ${existing.name}`,
      description: `${existing.company}`,
      reference_type: 'CUSTOMER',
      reference_id: id,
    });
  });

  notifyDataChanged();
}
